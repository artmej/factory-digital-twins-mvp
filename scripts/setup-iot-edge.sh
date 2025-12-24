#!/bin/bash
# Smart Factory - IoT Edge Gateway Setup Script
# This script configures Azure IoT Edge runtime for autonomous edge processing

set -e

echo "⚡ Starting Smart Factory IoT Edge Gateway Setup..."

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install prerequisites
echo "📦 Installing prerequisites..."
sudo apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    wget \
    software-properties-common \
    jq

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Install Azure IoT Edge
echo "🔗 Installing Azure IoT Edge..."
wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

sudo apt-get update
sudo apt-get install -y aziot-edge

# Create IoT Edge configuration
echo "⚙️ Creating IoT Edge configuration..."

# Note: In production, this would use actual IoT Hub connection string
sudo cat > /etc/aziot/config.toml << 'EOF'
# Azure IoT Edge Configuration
# This is a template - replace with actual connection string from Azure IoT Hub

[provisioning]
# Manual provisioning with connection string (for demo)
# In production, use DPS (Device Provisioning Service)
source = "manual"
connection_string = "HostName=your-iot-hub.azure-devices.net;DeviceId=smart-factory-edge-001;SharedAccessKey=your-shared-access-key"

# Certificates configuration
[cert_issuance.manual]
# cert = "file:///var/secrets/aziot/certs/device-ca.pem"
# pk = "file:///var/secrets/aziot/private/device-ca.key"

[edge_ca]
# cert = "file:///var/secrets/aziot/certs/edge-ca.pem"
# pk = "file:///var/secrets/aziot/private/edge-ca.key"

# Edge Agent configuration
[agent]
name = "edgeAgent"
type = "docker"

[agent.config]
image = "mcr.microsoft.com/azureiotedge-agent:1.4"

# Moby runtime configuration
[moby_runtime]
uri = "unix:///var/run/docker.sock"
network = "azure-iot-edge"

# Networking
[edge_agent.env]
UpstreamProtocol = "MQTT"
StorageFolder = "/iotedge/storage/"

EOF

# Create demo modules configuration
sudo mkdir -p /opt/iot-edge-modules

# Temperature Sensor Simulator Module
cat > /opt/iot-edge-modules/temperature-sensor.py << 'EOF'
#!/usr/bin/env python3
"""
IoT Edge Temperature Sensor Simulator Module
Simulates temperature sensors throughout the factory
"""

import asyncio
import json
import random
import time
import sys
from datetime import datetime, timezone

class TemperatureSensorModule:
    def __init__(self, module_id="TemperatureSensor"):
        self.module_id = module_id
        self.sensors = {
            "factory_floor": {"temp": 22.0, "location": "main_floor"},
            "machine_area": {"temp": 28.0, "location": "machine_area"}, 
            "storage": {"temp": 18.0, "location": "storage_area"},
            "office": {"temp": 21.0, "location": "office_area"}
        }
    
    async def generate_telemetry(self):
        """Generate temperature telemetry data"""
        while True:
            try:
                telemetry_data = {
                    "module_id": self.module_id,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "sensors": {}
                }
                
                # Update each sensor
                for sensor_id, sensor_data in self.sensors.items():
                    # Simulate temperature variations
                    temp_change = random.uniform(-0.5, 0.5)
                    sensor_data["temp"] += temp_change
                    
                    # Keep temperatures in realistic ranges
                    if sensor_id == "factory_floor":
                        sensor_data["temp"] = max(20, min(30, sensor_data["temp"]))
                    elif sensor_id == "machine_area":
                        sensor_data["temp"] = max(25, min(35, sensor_data["temp"]))
                    elif sensor_id == "storage":
                        sensor_data["temp"] = max(15, min(22, sensor_data["temp"]))
                    elif sensor_id == "office":
                        sensor_data["temp"] = max(19, min(25, sensor_data["temp"]))
                    
                    telemetry_data["sensors"][sensor_id] = {
                        "temperature_c": round(sensor_data["temp"], 2),
                        "location": sensor_data["location"],
                        "status": "normal" if 18 <= sensor_data["temp"] <= 32 else "alert"
                    }
                
                # Send telemetry (in production, this would be sent to IoT Hub)
                print(f"[{self.module_id}] Temperature Telemetry:")
                print(json.dumps(telemetry_data, indent=2))
                
                await asyncio.sleep(10)  # Send every 10 seconds
                
            except Exception as e:
                print(f"[{self.module_id}] Error: {e}")
                await asyncio.sleep(5)

async def main():
    print("🌡️ IoT Edge Temperature Sensor Module starting...")
    sensor_module = TemperatureSensorModule()
    await sensor_module.generate_telemetry()

if __name__ == "__main__":
    asyncio.run(main())
EOF

# Data Processing Module
cat > /opt/iot-edge-modules/data-processor.py << 'EOF'
#!/usr/bin/env python3
"""
IoT Edge Data Processing Module
Processes and aggregates data from factory sensors locally
"""

import asyncio
import json
import time
import statistics
from datetime import datetime, timezone
from collections import defaultdict, deque

class DataProcessorModule:
    def __init__(self, module_id="DataProcessor"):
        self.module_id = module_id
        self.sensor_data = defaultdict(lambda: deque(maxlen=100))  # Keep last 100 readings
        self.alerts = []
        self.processing_stats = {
            "messages_processed": 0,
            "alerts_generated": 0,
            "start_time": time.time()
        }
    
    def process_sensor_data(self, data):
        """Process incoming sensor data and generate insights"""
        try:
            # Store data
            timestamp = datetime.now(timezone.utc).isoformat()
            
            if "sensors" in data:
                for sensor_id, sensor_info in data["sensors"].items():
                    self.sensor_data[sensor_id].append({
                        "timestamp": timestamp,
                        "temperature": sensor_info.get("temperature_c", 0),
                        "status": sensor_info.get("status", "unknown")
                    })
            
            self.processing_stats["messages_processed"] += 1
            
            # Generate analytics
            analytics = self.generate_analytics()
            
            return analytics
            
        except Exception as e:
            print(f"[{self.module_id}] Processing error: {e}")
            return None
    
    def generate_analytics(self):
        """Generate real-time analytics from sensor data"""
        analytics = {
            "module_id": self.module_id,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "analytics": {},
            "alerts": [],
            "stats": self.processing_stats.copy()
        }
        
        # Calculate statistics for each sensor
        for sensor_id, readings in self.sensor_data.items():
            if readings:
                temps = [r["temperature"] for r in readings]
                
                sensor_analytics = {
                    "current_temp": temps[-1] if temps else 0,
                    "avg_temp_last_10min": round(statistics.mean(temps), 2),
                    "min_temp": min(temps),
                    "max_temp": max(temps),
                    "readings_count": len(readings),
                    "trend": self.calculate_trend(temps)
                }
                
                # Check for alerts
                if sensor_analytics["current_temp"] > 35:
                    alert = {
                        "sensor_id": sensor_id,
                        "type": "HIGH_TEMPERATURE",
                        "value": sensor_analytics["current_temp"],
                        "threshold": 35,
                        "severity": "HIGH",
                        "timestamp": datetime.now(timezone.utc).isoformat()
                    }
                    analytics["alerts"].append(alert)
                    self.processing_stats["alerts_generated"] += 1
                
                elif sensor_analytics["current_temp"] < 15:
                    alert = {
                        "sensor_id": sensor_id,
                        "type": "LOW_TEMPERATURE", 
                        "value": sensor_analytics["current_temp"],
                        "threshold": 15,
                        "severity": "MEDIUM",
                        "timestamp": datetime.now(timezone.utc).isoformat()
                    }
                    analytics["alerts"].append(alert)
                    self.processing_stats["alerts_generated"] += 1
                
                analytics["analytics"][sensor_id] = sensor_analytics
        
        return analytics
    
    def calculate_trend(self, values):
        """Calculate temperature trend"""
        if len(values) < 2:
            return "stable"
        
        recent = values[-5:] if len(values) >= 5 else values
        if len(recent) < 2:
            return "stable"
        
        slope = (recent[-1] - recent[0]) / len(recent)
        
        if slope > 0.5:
            return "rising"
        elif slope < -0.5:
            return "falling"
        else:
            return "stable"

async def main():
    print("🔄 IoT Edge Data Processor Module starting...")
    processor = DataProcessorModule()
    
    # Simulate processing sensor data
    while True:
        try:
            # Simulate receiving sensor data (in production, this would come from other modules)
            mock_sensor_data = {
                "sensors": {
                    "factory_floor": {"temperature_c": 22 + random.uniform(-2, 2), "status": "normal"},
                    "machine_area": {"temperature_c": 28 + random.uniform(-3, 3), "status": "normal"}
                }
            }
            
            analytics = processor.process_sensor_data(mock_sensor_data)
            
            if analytics:
                print(f"[{processor.module_id}] Analytics:")
                print(json.dumps(analytics, indent=2))
            
            await asyncio.sleep(15)
            
        except Exception as e:
            print(f"[{processor.module_id}] Error: {e}")
            await asyncio.sleep(5)

if __name__ == "__main__":
    import random
    asyncio.run(main())
EOF

# Make scripts executable
chmod +x /opt/iot-edge-modules/*.py

# Create systemd services for edge modules
sudo cat > /etc/systemd/system/iot-edge-temperature-sensor.service << 'EOF'
[Unit]
Description=IoT Edge Temperature Sensor Module
After=network.target aziot-edge.service

[Service]
Type=simple
User=factoryadmin
Group=factoryadmin
WorkingDirectory=/opt/iot-edge-modules
Environment=PATH=/usr/bin:/usr/local/bin
ExecStart=/usr/bin/python3 /opt/iot-edge-modules/temperature-sensor.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo cat > /etc/systemd/system/iot-edge-data-processor.service << 'EOF'
[Unit]
Description=IoT Edge Data Processor Module
After=network.target aziot-edge.service

[Service]
Type=simple
User=factoryadmin
Group=factoryadmin
WorkingDirectory=/opt/iot-edge-modules
Environment=PATH=/usr/bin:/usr/local/bin
ExecStart=/usr/bin/python3 /opt/iot-edge-modules/data-processor.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Install Python packages
pip3 install azure-iot-device

# Apply IoT Edge configuration (this will fail without proper connection string, but sets up the framework)
echo "⚙️ Applying IoT Edge configuration..."
sudo iotedge config apply || echo "⚠️ IoT Edge config apply failed - connection string needed"

# Enable services
sudo systemctl daemon-reload
sudo systemctl enable iot-edge-temperature-sensor
sudo systemctl enable iot-edge-data-processor

# Start demo modules (will work independently of IoT Edge runtime)
sudo systemctl start iot-edge-temperature-sensor
sudo systemctl start iot-edge-data-processor

echo "✅ IoT Edge Gateway setup complete!"
echo "🔗 To complete setup:"
echo "1. Create IoT Hub and Edge device in Azure portal"
echo "2. Update connection string in /etc/aziot/config.toml"
echo "3. Run: sudo iotedge config apply"
echo "4. Restart services: sudo systemctl restart aziot-edge"

echo "📊 Demo modules status:"
sudo systemctl status iot-edge-temperature-sensor --no-pager -l
sudo systemctl status iot-edge-data-processor --no-pager -l

echo "🔍 Live module output:"
echo "Temperature Sensor:"
journalctl -u iot-edge-temperature-sensor -n 5 --no-pager
echo "Data Processor:"
journalctl -u iot-edge-data-processor -n 5 --no-pager