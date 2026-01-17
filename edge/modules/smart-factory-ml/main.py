import asyncio
import json
import os
from datetime import datetime
from typing import Dict, List

import numpy as np
from azure.iot.device import IoTHubModuleClient, Message
from flask import Flask, request, jsonify
from loguru import logger
from pydantic import BaseModel

# Known factory devices for edge inference
FACTORY_DEVICES = [
    "LINE_1_CNC_01", "LINE_1_ROBOT_01", "LINE_1_CONV_01",
    "LINE_2_CNC_02", "LINE_2_ROBOT_02", "LINE_2_CONV_02", 
    "LINE_3_CNC_03", "LINE_3_ROBOT_03", "LINE_3_CONV_03"
]

class TelemetryData(BaseModel):
    deviceId: str
    timestamp: str
    temperature: float
    vibration: float
    pressure: float
    power: float
    status: str

class EdgeMLInference:
    def __init__(self):
        self.model_weights = {
            "temperature": 0.234,
            "vibration": 0.456,
            "pressure": -0.123,
            "power": 0.789
        }
        self.client = None
        
    async def init_iot_client(self):
        """Initialize IoT Hub module client"""
        try:
            self.client = IoTHubModuleClient.create_from_edge_environment()
            await self.client.connect()
            logger.info("Connected to IoT Hub")
            
            # Set message handler
            await self.client.set_message_handler("input1", self.message_handler)
            
        except Exception as e:
            logger.error(f"Failed to connect to IoT Hub: {e}")
            raise
    
    async def message_handler(self, message):
        """Handle incoming telemetry messages"""
        try:
            data = json.loads(message.data.decode('utf-8'))
            telemetry = TelemetryData(**data)
            
            if telemetry.deviceId in FACTORY_DEVICES:
                # Perform ML inference
                prediction = await self.predict_maintenance(telemetry)
                
                # Send prediction to output
                prediction_message = Message(json.dumps(prediction))
                prediction_message.content_type = "application/json"
                prediction_message.content_encoding = "utf-8"
                
                await self.client.send_message_to_output(prediction_message, "output1")
                logger.info(f"Sent prediction for {telemetry.deviceId}")
            
        except Exception as e:
            logger.error(f"Error processing message: {e}")
    
    async def predict_maintenance(self, telemetry: TelemetryData) -> Dict:
        """Perform ML inference on edge"""
        # Calculate risk score using trained model weights
        risk_score = (
            telemetry.temperature * self.model_weights["temperature"] +
            telemetry.vibration * self.model_weights["vibration"] +
            telemetry.pressure * self.model_weights["pressure"] +
            telemetry.power * self.model_weights["power"]
        )
        
        # Convert to days until maintenance
        normalized_score = max(0, min(1, (risk_score + 50) / 100))
        days_until_maintenance = int(30 - (normalized_score * 25))
        
        # Calculate confidence
        variance = self._calculate_variance(telemetry)
        confidence = min(0.95, max(0.65, 0.75 + (0.2 - variance)))
        
        # Determine risk level
        risk_level = "High" if risk_score > 20 else "Medium" if risk_score > 0 else "Low"
        
        return {
            "deviceId": telemetry.deviceId,
            "predictionDate": datetime.utcnow().isoformat(),
            "daysUntilMaintenance": days_until_maintenance,
            "confidence": round(confidence, 3),
            "riskLevel": risk_level,
            "inferenceLocation": "edge",
            "modelVersion": "v1.0.0-edge",
            "features": {
                "temperature": telemetry.temperature,
                "vibration": telemetry.vibration,
                "pressure": telemetry.pressure,
                "power": telemetry.power
            }
        }
    
    def _calculate_variance(self, telemetry: TelemetryData) -> float:
        """Calculate data variance for confidence scoring"""
        values = np.array([
            telemetry.temperature / 100,
            telemetry.vibration,
            telemetry.pressure / 100,
            telemetry.power / 100
        ])
        return float(np.std(values))

# Flask app for health checks
app = Flask(__name__)
ml_inference = EdgeMLInference()

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "module": "smart-factory-ml",
        "version": "1.0.0",
        "devices": len(FACTORY_DEVICES)
    })

@app.route('/predict', methods=['POST'])
def predict_endpoint():
    """HTTP endpoint for direct predictions"""
    try:
        data = request.json
        telemetry = TelemetryData(**data)
        
        if telemetry.deviceId not in FACTORY_DEVICES:
            return jsonify({"error": "Invalid deviceId"}), 400
        
        # Run prediction synchronously for HTTP endpoint
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        prediction = loop.run_until_complete(ml_inference.predict_maintenance(telemetry))
        loop.close()
        
        return jsonify(prediction)
        
    except Exception as e:
        logger.error(f"Prediction error: {e}")
        return jsonify({"error": "Prediction failed"}), 500

async def main():
    """Main application entry point"""
    logger.info("Starting Smart Factory ML Edge Module")
    
    # Initialize IoT client
    await ml_inference.init_iot_client()
    
    # Start Flask app in background
    import threading
    flask_thread = threading.Thread(target=lambda: app.run(host='0.0.0.0', port=5000, debug=False))
    flask_thread.daemon = True
    flask_thread.start()
    
    logger.info("Smart Factory ML Edge Module started successfully")
    
    # Keep the module running
    try:
        while True:
            await asyncio.sleep(10)
    except KeyboardInterrupt:
        logger.info("Shutting down...")
    finally:
        if ml_inference.client:
            await ml_inference.client.disconnect()

if __name__ == "__main__":
    asyncio.run(main())