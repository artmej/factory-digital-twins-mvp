#!/bin/bash
# Smart Factory - Factory Floor VM Setup Script
# This script configures the Factory Floor VM with IoT device simulation

set -e

echo "🏭 Starting Smart Factory Floor VM Setup..."

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
echo "📦 Installing Docker and dependencies..."
sudo apt-get install -y \
    docker.io \
    docker-compose \
    nodejs \
    npm \
    python3 \
    python3-pip \
    mosquitto \
    mosquitto-clients \
    jq \
    curl \
    wget \
    git

# Configure Docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Install Azure IoT Device SDK
echo "📡 Installing Azure IoT Device SDK..."
pip3 install azure-iot-device azure-iot-hub paho-mqtt

# Create application directory
sudo mkdir -p /opt/smart-factory
sudo chown $USER:$USER /opt/smart-factory
cd /opt/smart-factory

# Create advanced factory simulator
cat > factory_simulator.py << 'EOF'
#!/usr/bin/env python3
"""
Smart Factory Floor Simulator
Simulates real factory equipment with realistic data patterns
"""

import asyncio
import json
import random
import time
import threading
from datetime import datetime, timezone
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MachineSimulator:
    def __init__(self, machine_id, machine_type):
        self.machine_id = machine_id
        self.machine_type = machine_type
        self.status = "running"
        self.temperature = 70.0 + random.uniform(-5, 5)
        self.pressure = 14.7 + random.uniform(-1, 1)
        self.vibration = 0.5 + random.uniform(-0.2, 0.2)
        self.efficiency = 95.0 + random.uniform(-5, 5)
        self.cycles_completed = 0
        self.error_count = 0
        self.last_maintenance = time.time()
        
    def simulate_step(self):
        """Simulate one time step of machine operation"""
        # Normal operation variations
        self.temperature += random.uniform(-0.5, 0.5)
        self.pressure += random.uniform(-0.1, 0.1)
        self.vibration += random.uniform(-0.05, 0.05)
        
        # Wear-based degradation
        hours_since_maintenance = (time.time() - self.last_maintenance) / 3600
        degradation_factor = min(hours_since_maintenance / (30 * 24), 0.3)  # Max 30% degradation over 30 days
        
        self.efficiency = max(60, 95 - degradation_factor * 35 + random.uniform(-2, 2))
        
        # Simulate occasional issues
        if random.random() < 0.02:  # 2% chance per step
            self.introduce_anomaly()
        
        # Simulate production cycles
        if self.status == "running":
            if random.random() < 0.1:  # 10% chance to complete cycle
                self.cycles_completed += 1
        
        # Keep values in realistic ranges
        self.temperature = max(40, min(120, self.temperature))
        self.pressure = max(10, min(20, self.pressure))
        self.vibration = max(0, min(2, self.vibration))
        
    def introduce_anomaly(self):
        """Introduce various types of anomalies"""
        anomaly_type = random.choice(['overheat', 'pressure_drop', 'vibration', 'efficiency'])
        
        if anomaly_type == 'overheat':
            self.temperature += random.uniform(10, 25)
            self.status = "warning"
            logger.warning(f"Machine {self.machine_id}: Overheating detected!")
            
        elif anomaly_type == 'pressure_drop':
            self.pressure -= random.uniform(2, 5)
            self.status = "warning"
            logger.warning(f"Machine {self.machine_id}: Pressure drop detected!")
            
        elif anomaly_type == 'vibration':
            self.vibration += random.uniform(0.5, 1.5)
            self.status = "warning"
            logger.warning(f"Machine {self.machine_id}: Excessive vibration!")
            
        elif anomaly_type == 'efficiency':
            self.efficiency -= random.uniform(15, 30)
            self.status = "warning"
            logger.warning(f"Machine {self.machine_id}: Efficiency drop!")
        
        self.error_count += 1
        
    def perform_maintenance(self):
        """Simulate maintenance reset"""
        self.last_maintenance = time.time()
        self.efficiency = 95.0 + random.uniform(-2, 2)
        self.error_count = 0
        self.status = "running"
        logger.info(f"Machine {self.machine_id}: Maintenance completed")
    
    def get_telemetry(self):
        return {
            'machine_id': self.machine_id,
            'machine_type': self.machine_type,
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'status': self.status,
            'temperature': round(self.temperature, 2),
            'pressure': round(self.pressure, 2),
            'vibration': round(self.vibration, 3),
            'efficiency': round(self.efficiency, 2),
            'cycles_completed': self.cycles_completed,
            'error_count': self.error_count,
            'hours_since_maintenance': round((time.time() - self.last_maintenance) / 3600, 1)
        }

class ProductionLineSimulator:
    def __init__(self, line_id):
        self.line_id = line_id
        self.target_rate = 1200 + random.randint(-100, 200)
        self.current_rate = self.target_rate + random.randint(-50, 50)
        self.quality_score = 98.5 + random.uniform(-1, 1.5)
        self.total_produced = 0
        self.defect_count = 0
        
    def simulate_step(self):
        # Production rate variations
        self.current_rate += random.randint(-20, 20)
        self.current_rate = max(800, min(1500, self.current_rate))
        
        # Quality variations
        self.quality_score += random.uniform(-0.3, 0.3)
        self.quality_score = max(95, min(99.8, self.quality_score))
        
        # Simulate production
        produced_this_step = max(0, int(self.current_rate / 3600 * 5))  # 5 second steps
        self.total_produced += produced_this_step
        
        # Simulate defects
        if random.random() < 0.02:  # 2% chance of defect batch
            defects = random.randint(1, 10)
            self.defect_count += defects
            self.quality_score -= 1.0
    
    def get_telemetry(self):
        return {
            'line_id': self.line_id,
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'target_rate': self.target_rate,
            'current_rate': self.current_rate,
            'quality_score': round(self.quality_score, 2),
            'total_produced_today': self.total_produced,
            'defect_count': self.defect_count,
            'efficiency': round((self.current_rate / self.target_rate) * 100, 1)
        }

class SmartFactorySimulator:
    def __init__(self):
        # Initialize machines
        self.machines = {
            'CNC_001': MachineSimulator('CNC_001', 'CNC_Machine'),
            'ROBOT_001': MachineSimulator('ROBOT_001', 'Assembly_Robot'),
            'PRESS_001': MachineSimulator('PRESS_001', 'Hydraulic_Press'),
            'CONVEYOR_001': MachineSimulator('CONVEYOR_001', 'Conveyor_Belt'),
            'QC_001': MachineSimulator('QC_001', 'Quality_Control'),
        }
        
        # Initialize production lines
        self.production_lines = {
            'LINE_A': ProductionLineSimulator('LINE_A'),
            'LINE_B': ProductionLineSimulator('LINE_B')
        }
        
        # Overall factory metrics
        self.total_energy_consumption = 250.0  # kW
        self.ambient_temperature = 22.0
        self.humidity = 45.0
        
    def simulate_step(self):
        """Simulate one time step for entire factory"""
        # Simulate all machines
        for machine in self.machines.values():
            machine.simulate_step()
        
        # Simulate production lines
        for line in self.production_lines.values():
            line.simulate_step()
        
        # Update factory-wide metrics
        self.total_energy_consumption += random.uniform(-10, 15)
        self.total_energy_consumption = max(200, min(400, self.total_energy_consumption))
        
        self.ambient_temperature += random.uniform(-0.5, 0.5)
        self.ambient_temperature = max(18, min(28, self.ambient_temperature))
        
        self.humidity += random.uniform(-2, 2)
        self.humidity = max(35, min(60, self.humidity))
    
    def get_factory_telemetry(self):
        """Get complete factory telemetry data"""
        machine_data = {mid: machine.get_telemetry() for mid, machine in self.machines.items()}
        line_data = {lid: line.get_telemetry() for lid, line in self.production_lines.items()}
        
        # Calculate overall factory status
        avg_efficiency = sum(m['efficiency'] for m in machine_data.values()) / len(machine_data)
        warning_count = sum(1 for m in machine_data.values() if m['status'] == 'warning')
        
        factory_status = 'optimal' if warning_count == 0 and avg_efficiency > 90 else \
                        'warning' if warning_count < 3 or avg_efficiency > 75 else \
                        'critical'
        
        return {
            'factory_id': 'SMART_FACTORY_001',
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'factory_status': factory_status,
            'overall_efficiency': round(avg_efficiency, 2),
            'total_energy_consumption_kw': round(self.total_energy_consumption, 2),
            'ambient_temperature_c': round(self.ambient_temperature, 2),
            'humidity_percent': round(self.humidity, 1),
            'active_warnings': warning_count,
            'machines': machine_data,
            'production_lines': line_data
        }

def main():
    print("🏭 Smart Factory Floor Simulator Starting...")
    simulator = SmartFactorySimulator()
    
    step_count = 0
    while True:
        try:
            # Simulate factory step
            simulator.simulate_step()
            step_count += 1
            
            # Get telemetry
            telemetry = simulator.get_factory_telemetry()
            
            # Print telemetry (in production, this would be sent to IoT Hub)
            print(f"\n=== Factory Telemetry - Step {step_count} ===")
            print(json.dumps(telemetry, indent=2))
            
            # Save to local file for analysis
            with open('/opt/smart-factory/telemetry_log.json', 'a') as f:
                f.write(json.dumps(telemetry) + '\n')
            
            # Check for maintenance needs
            for machine_id, machine_data in telemetry['machines'].items():
                if (machine_data['hours_since_maintenance'] > 168 or  # 1 week
                    machine_data['efficiency'] < 70):
                    machine = simulator.machines[machine_id]
                    machine.perform_maintenance()
            
            # Wait 5 seconds between readings
            time.sleep(5)
            
        except KeyboardInterrupt:
            print("\n🛑 Factory simulator stopped by user")
            break
        except Exception as e:
            logger.error(f"Simulation error: {e}")
            time.sleep(5)

if __name__ == "__main__":
    main()
EOF

# Create MQTT publisher for IoT Hub integration
cat > iot_publisher.py << 'EOF'
#!/usr/bin/env python3
"""
IoT Hub Publisher for Smart Factory Data
Publishes factory telemetry to Azure IoT Hub
"""

import json
import time
import subprocess
import logging
from azure.iot.device import IoTHubDeviceClient, Message

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class IoTHubPublisher:
    def __init__(self, connection_string=None):
        self.connection_string = connection_string or "HostName=your-iot-hub.azure-devices.net;DeviceId=factory-floor-001;SharedAccessKey=your-key"
        self.client = None
        
    def connect(self):
        try:
            self.client = IoTHubDeviceClient.create_from_connection_string(self.connection_string)
            self.client.connect()
            logger.info("Connected to IoT Hub")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to IoT Hub: {e}")
            return False
    
    def send_telemetry(self, telemetry_data):
        if not self.client:
            logger.warning("No IoT Hub connection")
            return False
            
        try:
            message = Message(json.dumps(telemetry_data))
            message.content_encoding = "utf-8"
            message.content_type = "application/json"
            
            self.client.send_message(message)
            logger.info(f"Sent telemetry: {telemetry_data['factory_id']} at {telemetry_data['timestamp']}")
            return True
        except Exception as e:
            logger.error(f"Failed to send telemetry: {e}")
            return False

def main():
    print("📡 IoT Hub Publisher starting...")
    
    # For now, just log telemetry (IoT Hub connection string needed for actual publishing)
    while True:
        try:
            # Read latest telemetry from factory simulator log
            with open('/opt/smart-factory/telemetry_log.json', 'r') as f:
                lines = f.readlines()
                if lines:
                    latest_telemetry = json.loads(lines[-1])
                    print(f"📤 Would publish to IoT Hub: {latest_telemetry['factory_id']} - Status: {latest_telemetry['factory_status']}")
            
            time.sleep(10)
        except Exception as e:
            logger.error(f"Publisher error: {e}")
            time.sleep(10)

if __name__ == "__main__":
    main()
EOF

# Create systemd services
echo "🔧 Creating systemd services..."

sudo cat > /etc/systemd/system/smart-factory-simulator.service << 'EOF'
[Unit]
Description=Smart Factory Floor Simulator
After=network.target

[Service]
Type=simple
User=factoryadmin
Group=factoryadmin
WorkingDirectory=/opt/smart-factory
Environment=PATH=/usr/bin:/usr/local/bin
ExecStart=/usr/bin/python3 /opt/smart-factory/factory_simulator.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo cat > /etc/systemd/system/smart-factory-iot-publisher.service << 'EOF'
[Unit]
Description=Smart Factory IoT Hub Publisher
After=network.target smart-factory-simulator.service

[Service]
Type=simple
User=factoryadmin
Group=factoryadmin
WorkingDirectory=/opt/smart-factory
Environment=PATH=/usr/bin:/usr/local/bin
ExecStart=/usr/bin/python3 /opt/smart-factory/iot_publisher.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create web dashboard for local monitoring
cat > web_dashboard.py << 'EOF'
#!/usr/bin/env python3
"""
Local Web Dashboard for Smart Factory
Provides real-time view of factory status
"""

from flask import Flask, render_template_string, jsonify
import json
import os

app = Flask(__name__)

DASHBOARD_HTML = '''
<!DOCTYPE html>
<html>
<head>
    <title>🏭 Smart Factory Floor - Live Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; background: #f0f0f0; }
        .header { background: #2c3e50; color: white; padding: 20px; text-align: center; }
        .container { padding: 20px; max-width: 1200px; margin: 0 auto; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .card { background: white; border-radius: 10px; padding: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .metric { display: flex; justify-content: space-between; margin: 10px 0; }
        .value { font-weight: bold; color: #27ae60; }
        .status-optimal { color: #27ae60; }
        .status-warning { color: #f39c12; }
        .status-critical { color: #e74c3c; }
        .machine-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px; }
        .machine-card { background: #ecf0f1; padding: 15px; border-radius: 5px; }
        .refresh-btn { background: #3498db; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; }
    </style>
    <script>
        function refreshData() {
            fetch('/api/telemetry')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('factory-status').textContent = data.factory_status.toUpperCase();
                    document.getElementById('factory-status').className = 'status-' + data.factory_status;
                    document.getElementById('overall-efficiency').textContent = data.overall_efficiency + '%';
                    document.getElementById('energy-consumption').textContent = data.total_energy_consumption_kw + ' kW';
                    document.getElementById('ambient-temp').textContent = data.ambient_temperature_c + '°C';
                    document.getElementById('humidity').textContent = data.humidity_percent + '%';
                    document.getElementById('active-warnings').textContent = data.active_warnings;
                    document.getElementById('last-update').textContent = new Date(data.timestamp).toLocaleString();
                    
                    // Update machines
                    const machinesDiv = document.getElementById('machines');
                    machinesDiv.innerHTML = '';
                    for (const [id, machine] of Object.entries(data.machines)) {
                        machinesDiv.innerHTML += `
                            <div class="machine-card">
                                <h4>${machine.machine_id}</h4>
                                <p>Status: <span class="status-${machine.status === 'running' ? 'optimal' : 'warning'}">${machine.status.toUpperCase()}</span></p>
                                <p>Temp: ${machine.temperature}°C</p>
                                <p>Efficiency: ${machine.efficiency}%</p>
                                <p>Cycles: ${machine.cycles_completed}</p>
                            </div>
                        `;
                    }
                })
                .catch(error => console.error('Error:', error));
        }
        
        setInterval(refreshData, 5000); // Refresh every 5 seconds
        window.onload = refreshData;
    </script>
</head>
<body>
    <div class="header">
        <h1>🏭 Smart Factory Floor - Live Dashboard</h1>
        <p>Real-time monitoring and control</p>
        <button class="refresh-btn" onclick="refreshData()">🔄 Refresh Now</button>
    </div>
    
    <div class="container">
        <div class="grid">
            <div class="card">
                <h3>📊 Factory Overview</h3>
                <div class="metric">
                    <span>Status:</span>
                    <span id="factory-status" class="status-optimal">LOADING...</span>
                </div>
                <div class="metric">
                    <span>Overall Efficiency:</span>
                    <span id="overall-efficiency" class="value">--%</span>
                </div>
                <div class="metric">
                    <span>Energy Consumption:</span>
                    <span id="energy-consumption" class="value">-- kW</span>
                </div>
                <div class="metric">
                    <span>Ambient Temperature:</span>
                    <span id="ambient-temp" class="value">--°C</span>
                </div>
                <div class="metric">
                    <span>Humidity:</span>
                    <span id="humidity" class="value">--%</span>
                </div>
                <div class="metric">
                    <span>Active Warnings:</span>
                    <span id="active-warnings" class="value">--</span>
                </div>
                <div class="metric">
                    <span>Last Update:</span>
                    <span id="last-update" style="font-size: 0.9em;">--</span>
                </div>
            </div>
            
            <div class="card">
                <h3>🤖 Machines Status</h3>
                <div id="machines" class="machine-grid">
                    Loading machines...
                </div>
            </div>
        </div>
    </div>
</body>
</html>
'''

@app.route('/')
def dashboard():
    return render_template_string(DASHBOARD_HTML)

@app.route('/api/telemetry')
def get_telemetry():
    try:
        if os.path.exists('/opt/smart-factory/telemetry_log.json'):
            with open('/opt/smart-factory/telemetry_log.json', 'r') as f:
                lines = f.readlines()
                if lines:
                    return jsonify(json.loads(lines[-1]))
    except Exception as e:
        print(f"Error reading telemetry: {e}")
    
    return jsonify({"error": "No telemetry data available"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=False)
EOF

# Install Flask
pip3 install flask

# Create web dashboard service
sudo cat > /etc/systemd/system/smart-factory-dashboard.service << 'EOF'
[Unit]
Description=Smart Factory Local Dashboard
After=network.target

[Service]
Type=simple
User=factoryadmin
Group=factoryadmin
WorkingDirectory=/opt/smart-factory
Environment=PATH=/usr/bin:/usr/local/bin
ExecStart=/usr/bin/python3 /opt/smart-factory/web_dashboard.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
sudo chown -R factoryadmin:factoryadmin /opt/smart-factory
chmod +x /opt/smart-factory/*.py

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable smart-factory-simulator
sudo systemctl enable smart-factory-iot-publisher
sudo systemctl enable smart-factory-dashboard

sudo systemctl start smart-factory-simulator
sleep 5
sudo systemctl start smart-factory-iot-publisher
sudo systemctl start smart-factory-dashboard

echo "✅ Smart Factory Floor VM setup complete!"
echo "🌐 Local dashboard available at: http://$(curl -s ifconfig.me)/"
echo "📊 Services status:"
sudo systemctl status smart-factory-simulator --no-pager -l
sudo systemctl status smart-factory-iot-publisher --no-pager -l
sudo systemctl status smart-factory-dashboard --no-pager -l

echo "🔍 Live telemetry sample:"
tail -n 1 /opt/smart-factory/telemetry_log.json | jq .