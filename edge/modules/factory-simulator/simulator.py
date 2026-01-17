import asyncio
import json
import os
import random
from datetime import datetime, timedelta
from typing import Dict, List

import numpy as np
from azure.iot.device import IoTHubModuleClient, Message
from loguru import logger
from pydantic import BaseModel

# Factory configuration based on Smart Factory requirements
class FactoryDevice:
    def __init__(self, device_id: str, line: str, device_type: str):
        self.device_id = device_id
        self.line = line
        self.device_type = device_type
        self.status = "Running"
        self.operational_hours = 0
        self.last_maintenance = datetime.utcnow() - timedelta(days=random.randint(1, 90))
        
        # Device-specific parameters based on type
        self.base_params = self._get_base_parameters()
        self.current_cycle = 0
        
    def _get_base_parameters(self) -> Dict[str, Dict[str, float]]:
        """Get realistic base parameters for different device types"""
        if self.device_type == "CNC":
            return {
                "temperature": {"min": 65, "max": 85, "normal": 72, "variance": 3},
                "vibration": {"min": 0.1, "max": 1.2, "normal": 0.4, "variance": 0.1},
                "pressure": {"min": 15, "max": 50, "normal": 30, "variance": 5},
                "power": {"min": 60, "max": 95, "normal": 78, "variance": 8}
            }
        elif self.device_type == "ROBOT":
            return {
                "temperature": {"min": 55, "max": 75, "normal": 62, "variance": 2},
                "vibration": {"min": 0.2, "max": 0.8, "normal": 0.3, "variance": 0.05},
                "pressure": {"min": 20, "max": 45, "normal": 32, "variance": 4},
                "power": {"min": 45, "max": 80, "normal": 65, "variance": 6}
            }
        else:  # CONV (Conveyor)
            return {
                "temperature": {"min": 45, "max": 65, "normal": 52, "variance": 2},
                "vibration": {"min": 0.1, "max": 0.6, "normal": 0.2, "variance": 0.03},
                "pressure": {"min": 10, "max": 25, "normal": 18, "variance": 2},
                "power": {"min": 25, "max": 55, "normal": 35, "variance": 4}
            }
    
    def generate_telemetry(self) -> Dict:
        """Generate realistic telemetry data with wear patterns"""
        self.operational_hours += 0.5  # Increment operational hours
        self.current_cycle += 1
        
        # Calculate wear factor (increases over time since last maintenance)
        days_since_maintenance = (datetime.utcnow() - self.last_maintenance).days
        wear_factor = min(1.5, 1 + (days_since_maintenance / 100))  # Max 50% increase
        
        # Generate base telemetry with wear patterns
        telemetry = {}
        for param, config in self.base_params.items():
            # Add cyclic variations (simulating operational cycles)
            cycle_variation = np.sin(self.current_cycle * 0.1) * 0.1
            
            # Add wear-based degradation
            wear_adjustment = (wear_factor - 1) * config["normal"] * 0.3
            
            # Generate value with normal distribution
            base_value = config["normal"] + wear_adjustment
            noise = np.random.normal(0, config["variance"])
            cycle_adj = cycle_variation * config["normal"]
            
            value = base_value + noise + cycle_adj
            
            # Clamp to realistic bounds
            telemetry[param] = max(config["min"], min(config["max"], value))
        
        # Simulate occasional anomalies (5% chance)
        if random.random() < 0.05:
            anomaly_param = random.choice(list(self.base_params.keys()))
            if anomaly_param == "temperature":
                telemetry[anomaly_param] *= 1.2  # 20% spike
            elif anomaly_param == "vibration":
                telemetry[anomaly_param] *= 1.5  # 50% spike
            elif anomaly_param == "pressure":
                telemetry[anomaly_param] *= 0.7  # 30% drop
            else:  # power
                telemetry[anomaly_param] *= 1.3  # 30% spike
        
        # Determine status based on telemetry
        self._update_status(telemetry)
        
        return {
            "deviceId": self.device_id,
            "timestamp": datetime.utcnow().isoformat(),
            "temperature": round(telemetry["temperature"], 1),
            "vibration": round(telemetry["vibration"], 3),
            "pressure": round(telemetry["pressure"], 1),
            "power": round(telemetry["power"], 1),
            "status": self.status,
            "operationalHours": self.operational_hours,
            "daysSinceMaintenace": days_since_maintenance,
            "line": self.line,
            "deviceType": self.device_type
        }
    
    def _update_status(self, telemetry: Dict):
        """Update device status based on telemetry thresholds"""
        temp_config = self.base_params["temperature"]
        vib_config = self.base_params["vibration"]
        
        if (telemetry["temperature"] > temp_config["max"] * 0.9 or
            telemetry["vibration"] > vib_config["max"] * 0.8):
            self.status = "Warning"
        elif (telemetry["temperature"] > temp_config["max"] or
              telemetry["vibration"] > vib_config["max"]):
            self.status = "Critical"
        else:
            self.status = "Running"

class FactorySimulator:
    def __init__(self):
        # Initialize all 9 factory devices
        self.devices = [
            FactoryDevice("LINE_1_CNC_01", "LINE_1", "CNC"),
            FactoryDevice("LINE_1_ROBOT_01", "LINE_1", "ROBOT"),
            FactoryDevice("LINE_1_CONV_01", "LINE_1", "CONV"),
            FactoryDevice("LINE_2_CNC_02", "LINE_2", "CNC"),
            FactoryDevice("LINE_2_ROBOT_02", "LINE_2", "ROBOT"),
            FactoryDevice("LINE_2_CONV_02", "LINE_2", "CONV"),
            FactoryDevice("LINE_3_CNC_03", "LINE_3", "CNC"),
            FactoryDevice("LINE_3_ROBOT_03", "LINE_3", "ROBOT"),
            FactoryDevice("LINE_3_CONV_03", "LINE_3", "CONV")
        ]
        
        self.client = None
        self.telemetry_interval = int(os.getenv("TELEMETRY_INTERVAL", "30"))
        
    async def init_client(self):
        """Initialize IoT Hub module client"""
        try:
            self.client = IoTHubModuleClient.create_from_edge_environment()
            await self.client.connect()
            logger.info("Factory simulator connected to IoT Hub")
        except Exception as e:
            logger.error(f"Failed to connect to IoT Hub: {e}")
            raise
    
    async def send_telemetry(self):
        """Send telemetry for all devices"""
        try:
            for device in self.devices:
                telemetry_data = device.generate_telemetry()
                
                # Create and send message
                message = Message(json.dumps(telemetry_data))
                message.content_type = "application/json"
                message.content_encoding = "utf-8"
                
                # Add device properties
                message.custom_properties["deviceId"] = device.device_id
                message.custom_properties["deviceType"] = device.device_type
                message.custom_properties["line"] = device.line
                
                await self.client.send_message_to_output(message, "output1")
                
                logger.info(f"Sent telemetry for {device.device_id}: {device.status}")
                
                # Small delay between devices to avoid flooding
                await asyncio.sleep(1)
                
        except Exception as e:
            logger.error(f"Error sending telemetry: {e}")
    
    async def run_simulation(self):
        """Main simulation loop"""
        logger.info(f"Starting factory simulation with {len(self.devices)} devices")
        logger.info(f"Telemetry interval: {self.telemetry_interval} seconds")
        
        while True:
            try:
                await self.send_telemetry()
                await asyncio.sleep(self.telemetry_interval)
            except Exception as e:
                logger.error(f"Simulation error: {e}")
                await asyncio.sleep(5)  # Wait before retrying

async def main():
    """Main application entry point"""
    logger.info("Starting Smart Factory Edge Simulator")
    
    simulator = FactorySimulator()
    
    # Initialize IoT client
    await simulator.init_client()
    
    # Start simulation
    try:
        await simulator.run_simulation()
    except KeyboardInterrupt:
        logger.info("Simulation stopped by user")
    finally:
        if simulator.client:
            await simulator.client.disconnect()
            logger.info("Disconnected from IoT Hub")

if __name__ == "__main__":
    asyncio.run(main())