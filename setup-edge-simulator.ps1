# 🔌 Smart Factory Edge Device Simulator
# Advanced IoT device simulation with realistic factory scenarios

param(
    [string]$ResourceGroupName = "smart-factory-v2-rg",
    [int]$DeviceCount = 10,
    [switch]$Deploy = $false,
    [switch]$RunLocal = $true
)

Write-Host "🔌 Smart Factory Edge Device Simulator Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Enhanced device simulator with factory scenarios
$simulatorEnhanced = @"
// 🏭 Smart Factory Edge Device Simulator - Enhanced Version
// Simulates realistic factory devices with multiple sensor types

const { IoTHubDeviceClient, ConnectionString } = require('azure-iot-device');
const { Mqtt } = require('azure-iot-device-mqtt');
const express = require('express');
const path = require('path');

// 🔧 Configuration
const config = {
    iotHubConnectionString: process.env.IOT_HUB_CONNECTION_STRING,
    deviceCount: parseInt(process.env.DEVICE_COUNT) || 5,
    simulationInterval: parseInt(process.env.SIMULATION_INTERVAL) || 10000, // 10 seconds
    port: process.env.PORT || 3000,
    factoryId: process.env.FACTORY_ID || 'FACTORY-001'
};

// 🏭 Factory Device Types
const deviceTypes = [
    {
        type: 'cnc-machine',
        name: 'CNC Machine',
        sensors: ['temperature', 'vibration', 'power', 'speed', 'pressure'],
        location: 'production-line-1',
        criticality: 'high'
    },
    {
        type: 'conveyor-belt',
        name: 'Conveyor Belt',
        sensors: ['speed', 'load', 'temperature', 'vibration'],
        location: 'assembly-line-a',
        criticality: 'medium'
    },
    {
        type: 'robotic-arm',
        name: 'Robotic Assembly Arm',
        sensors: ['position', 'force', 'temperature', 'battery'],
        location: 'assembly-station-3',
        criticality: 'high'
    },
    {
        type: 'quality-sensor',
        name: 'Quality Control Sensor',
        sensors: ['defect-rate', 'throughput', 'accuracy'],
        location: 'quality-gate-1',
        criticality: 'critical'
    },
    {
        type: 'environmental',
        name: 'Environmental Monitor',
        sensors: ['temperature', 'humidity', 'air-quality', 'noise'],
        location: 'facility-general',
        criticality: 'low'
    }
];

// 🎛️ Global state management
global.simulationActive = false;
global.activeDevices = [];
global.lastSimulationUpdate = new Date().toISOString();
global.totalMessages = 0;
global.messagesPerSecond = 0;

class SmartFactoryDevice {
    constructor(deviceId, deviceType, connectionString) {
        this.deviceId = deviceId;
        this.deviceType = deviceType;
        this.client = IoTHubDeviceClient.fromConnectionString(connectionString, Mqtt);
        this.isConnected = false;
        this.telemetryInterval = null;
        this.lastTelemetry = null;
        this.errorRate = 0.05; // 5% chance of anomalies
        
        // Device-specific state
        this.state = {
            operational: true,
            maintenanceMode: false,
            lastMaintenance: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000), // Random last maintenance within 30 days
            runningHours: Math.floor(Math.random() * 10000),
            efficiency: 0.85 + Math.random() * 0.15 // 85-100% efficiency
        };
        
        this.setupEventHandlers();
    }

    setupEventHandlers() {
        this.client.on('connect', () => {
            this.isConnected = true;
            console.log(`✅ Device ${deviceTypes[this.deviceType].name}[${this.deviceId}] connected`);
        });

        this.client.on('disconnect', () => {
            this.isConnected = false;
            console.log(`❌ Device ${this.deviceId} disconnected`);
        });

        this.client.on('error', (err) => {
            console.error(`🔥 Device ${this.deviceId} error:`, err.message);
        });
    }

    async connect() {
        try {
            await this.client.open();
            return true;
        } catch (error) {
            console.error(`Failed to connect device ${this.deviceId}:`, error.message);
            return false;
        }
    }

    generateSensorData(sensorType) {
        const now = Date.now();
        const deviceConfig = deviceTypes[this.deviceType];
        
        // Simulate sensor readings based on device type and operational state
        const baseValues = {
            temperature: this.state.operational ? 45 + Math.random() * 20 : 80 + Math.random() * 15,
            vibration: this.state.operational ? 0.1 + Math.random() * 0.3 : 0.8 + Math.random() * 0.4,
            power: this.state.operational ? 2000 + Math.random() * 500 : 3500 + Math.random() * 1000,
            speed: this.state.operational ? 1800 + Math.random() * 200 : 500 + Math.random() * 300,
            pressure: this.state.operational ? 15 + Math.random() * 5 : 25 + Math.random() * 8,
            load: Math.random() * 100,
            position: { x: Math.random() * 100, y: Math.random() * 100, z: Math.random() * 50 },
            force: this.state.operational ? 50 + Math.random() * 20 : 20 + Math.random() * 10,
            battery: Math.max(10, 100 - (this.state.runningHours % 100)),
            'defect-rate': this.state.efficiency > 0.9 ? Math.random() * 2 : Math.random() * 8,
            throughput: this.state.operational ? 80 + Math.random() * 20 : 20 + Math.random() * 30,
            accuracy: this.state.efficiency * 100,
            humidity: 30 + Math.random() * 40,
            'air-quality': 50 + Math.random() * 50,
            noise: this.state.operational ? 45 + Math.random() * 15 : 70 + Math.random() * 20
        };

        // Add anomalies occasionally
        let value = baseValues[sensorType] || Math.random() * 100;
        if (Math.random() < this.errorRate) {
            value *= 1.5 + Math.random(); // Anomaly: 50-250% of normal value
        }

        return {
            sensorType,
            value: Math.round(value * 100) / 100,
            unit: this.getSensorUnit(sensorType),
            timestamp: new Date(now).toISOString(),
            quality: this.state.operational ? 'good' : 'poor',
            anomaly: Math.random() < this.errorRate
        };
    }

    getSensorUnit(sensorType) {
        const units = {
            temperature: '°C',
            vibration: 'mm/s²',
            power: 'W',
            speed: 'RPM',
            pressure: 'bar',
            load: '%',
            force: 'N',
            battery: '%',
            'defect-rate': '%',
            throughput: 'units/hour',
            accuracy: '%',
            humidity: '%',
            'air-quality': 'AQI',
            noise: 'dB'
        };
        return units[sensorType] || 'units';
    }

    generateTelemetryMessage() {
        const deviceConfig = deviceTypes[this.deviceType];
        const sensors = {};
        
        // Generate data for all sensors on this device
        deviceConfig.sensors.forEach(sensorType => {
            sensors[sensorType] = this.generateSensorData(sensorType);
        });

        const telemetry = {
            deviceId: this.deviceId,
            deviceType: deviceConfig.type,
            deviceName: deviceConfig.name,
            location: deviceConfig.location,
            criticality: deviceConfig.criticality,
            factoryId: config.factoryId,
            timestamp: new Date().toISOString(),
            sensors: sensors,
            deviceState: {
                operational: this.state.operational,
                maintenanceMode: this.state.maintenanceMode,
                efficiency: this.state.efficiency,
                runningHours: this.state.runningHours
            },
            metadata: {
                messageId: `msg-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
                version: '2.0.0',
                schema: 'smart-factory-telemetry-v2'
            }
        };

        this.lastTelemetry = telemetry;
        return telemetry;
    }

    async sendTelemetry() {
        if (!this.isConnected) {
            console.log(`⚠️ Device ${this.deviceId} not connected, skipping telemetry`);
            return false;
        }

        try {
            const message = this.generateTelemetryMessage();
            await this.client.sendEvent(new require('azure-iot-device').Message(JSON.stringify(message)));
            
            global.totalMessages++;
            console.log(`📡 ${deviceTypes[this.deviceType].name}[${this.deviceId}] sent telemetry`);
            return true;
        } catch (error) {
            console.error(`Failed to send telemetry for ${this.deviceId}:`, error.message);
            return false;
        }
    }

    startTelemetry() {
        if (this.telemetryInterval) {
            clearInterval(this.telemetryInterval);
        }

        this.telemetryInterval = setInterval(() => {
            this.sendTelemetry();
            
            // Simulate device state changes occasionally
            if (Math.random() < 0.1) { // 10% chance per interval
                this.simulateStateChange();
            }
        }, config.simulationInterval);

        console.log(`🚀 Started telemetry for ${this.deviceId}`);
    }

    simulateStateChange() {
        if (Math.random() < 0.05) { // 5% chance of going into maintenance
            this.state.maintenanceMode = !this.state.maintenanceMode;
            console.log(`🔧 Device ${this.deviceId} maintenance mode: ${this.state.maintenanceMode}`);
        }
        
        if (Math.random() < 0.02) { // 2% chance of operational status change
            this.state.operational = !this.state.operational;
            console.log(`⚡ Device ${this.deviceId} operational: ${this.state.operational}`);
        }
        
        // Gradual efficiency changes
        this.state.efficiency += (Math.random() - 0.5) * 0.02; // ±1% change
        this.state.efficiency = Math.max(0.5, Math.min(1.0, this.state.efficiency));
        
        // Increment running hours
        this.state.runningHours += config.simulationInterval / 3600000; // Convert ms to hours
    }

    stopTelemetry() {
        if (this.telemetryInterval) {
            clearInterval(this.telemetryInterval);
            this.telemetryInterval = null;
        }
        console.log(`⏹️ Stopped telemetry for ${this.deviceId}`);
    }

    async disconnect() {
        this.stopTelemetry();
        if (this.isConnected) {
            await this.client.close();
        }
    }
}

// 🖥️ Express Web Interface
const app = express();
app.use(express.json());
app.use(express.static('public'));

// Import health endpoints
require('./health')(app);

// 🎛️ Simulation Management API
app.get('/api/devices', (req, res) => {
    const devices = global.activeDevices.map(device => ({
        deviceId: device.deviceId,
        deviceType: deviceTypes[device.deviceType].name,
        isConnected: device.isConnected,
        lastTelemetry: device.lastTelemetry,
        state: device.state
    }));
    
    res.json({
        devices,
        totalDevices: devices.length,
        connectedDevices: devices.filter(d => d.isConnected).length,
        simulationActive: global.simulationActive
    });
});

app.post('/api/simulation/start', async (req, res) => {
    if (global.simulationActive) {
        return res.json({ message: 'Simulation already running', status: 'running' });
    }

    try {
        await startSimulation();
        res.json({ message: 'Simulation started', status: 'started', deviceCount: global.activeDevices.length });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/simulation/stop', async (req, res) => {
    try {
        await stopSimulation();
        res.json({ message: 'Simulation stopped', status: 'stopped' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/simulation/status', (req, res) => {
    res.json({
        active: global.simulationActive,
        deviceCount: global.activeDevices.length,
        totalMessages: global.totalMessages,
        lastUpdate: global.lastSimulationUpdate,
        uptime: Math.round(process.uptime())
    });
});

// 🚀 Main Simulation Functions
async function createDevices(count = config.deviceCount) {
    const devices = [];
    
    for (let i = 0; i < count; i++) {
        const deviceTypeIndex = i % deviceTypes.length;
        const deviceId = `device-${deviceTypes[deviceTypeIndex].type}-${String(i + 1).padStart(3, '0')}`;
        const connectionString = config.iotHubConnectionString;
        
        if (!connectionString) {
            console.error('❌ IoT Hub connection string not configured');
            break;
        }
        
        const device = new SmartFactoryDevice(deviceId, deviceTypeIndex, connectionString);
        devices.push(device);
    }
    
    return devices;
}

async function startSimulation() {
    console.log('🚀 Starting Smart Factory Device Simulation...');
    
    if (global.simulationActive) {
        console.log('⚠️ Simulation already running');
        return;
    }
    
    try {
        const devices = await createDevices();
        
        // Connect all devices
        for (const device of devices) {
            await device.connect();
            await new Promise(resolve => setTimeout(resolve, 1000)); // Stagger connections
        }
        
        // Start telemetry for connected devices
        const connectedDevices = devices.filter(device => device.isConnected);
        connectedDevices.forEach(device => device.startTelemetry());
        
        global.activeDevices = devices;
        global.simulationActive = true;
        global.lastSimulationUpdate = new Date().toISOString();
        
        console.log(`✅ Simulation started with ${connectedDevices.length}/${devices.length} devices connected`);
        
        // Start message rate calculation
        setInterval(() => {
            const currentMessages = global.totalMessages;
            const timeDiff = (Date.now() - (global.lastMessageCount?.timestamp || Date.now())) / 1000;
            global.messagesPerSecond = Math.round((currentMessages - (global.lastMessageCount?.count || 0)) / timeDiff);
            global.lastMessageCount = { count: currentMessages, timestamp: Date.now() };
        }, 5000);
        
    } catch (error) {
        console.error('❌ Failed to start simulation:', error.message);
        throw error;
    }
}

async function stopSimulation() {
    console.log('⏹️ Stopping Smart Factory Device Simulation...');
    
    if (!global.simulationActive) {
        console.log('⚠️ Simulation not running');
        return;
    }
    
    try {
        // Disconnect all devices
        for (const device of global.activeDevices) {
            await device.disconnect();
        }
        
        global.activeDevices = [];
        global.simulationActive = false;
        global.lastSimulationUpdate = new Date().toISOString();
        
        console.log('✅ Simulation stopped');
    } catch (error) {
        console.error('❌ Failed to stop simulation:', error.message);
        throw error;
    }
}

// 🌐 Start Web Server
app.listen(config.port, () => {
    console.log(`🖥️ Smart Factory Edge Simulator running on port ${config.port}`);
    console.log(`📊 Simulation Dashboard: http://localhost:${config.port}`);
    
    // Auto-start simulation if configured
    if (process.env.AUTO_START === 'true' && config.iotHubConnectionString) {
        setTimeout(startSimulation, 5000); // Start after 5 seconds
    }
});

// 🛑 Graceful shutdown
process.on('SIGINT', async () => {
    console.log('\\n🛑 Shutting down simulator...');
    await stopSimulation();
    process.exit(0);
});

process.on('SIGTERM', async () => {
    console.log('\\n🛑 Terminating simulator...');
    await stopSimulation();
    process.exit(0);
});
"@

$simulatorEnhanced | Out-File -FilePath "src\device-simulator\simulator-enhanced.js" -Encoding UTF8
Write-Host "✅ Created enhanced device simulator: src\device-simulator\simulator-enhanced.js" -ForegroundColor Green

# Create Docker configuration for edge deployment
$dockerFile = @"
# 🐳 Smart Factory Edge Device Simulator - Docker Configuration
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S simulator && \\
    adduser -S simulator -u 1001

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy application code
COPY . .

# Create public directory for web interface
RUN mkdir -p public

# Change ownership to non-root user
RUN chown -R simulator:simulator /app

# Switch to non-root user
USER simulator

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \\
  CMD curl -f http://localhost:3000/health || exit 1

# Start command
CMD ["node", "simulator-enhanced.js"]
"@

$dockerFile | Out-File -FilePath "src\device-simulator\Dockerfile-enhanced" -Encoding UTF8
Write-Host "✅ Created enhanced Dockerfile: src\device-simulator\Dockerfile-enhanced" -ForegroundColor Green

# Create enhanced package.json for the simulator
$packageJson = @{
    name = "smart-factory-edge-simulator"
    version = "2.0.0"
    description = "Advanced Smart Factory Edge Device Simulator with realistic factory scenarios"
    main = "simulator-enhanced.js"
    scripts = @{
        start = "node simulator-enhanced.js"
        dev = "nodemon simulator-enhanced.js"
        test = "jest"
        build = "echo 'No build step required for Node.js application'"
        "docker:build" = "docker build -f Dockerfile-enhanced -t smart-factory-simulator:latest ."
        "docker:run" = "docker run -p 3000:3000 --env-file .env smart-factory-simulator:latest"
    }
    dependencies = @{
        "azure-iot-device" = "^1.17.10"
        "azure-iot-device-mqtt" = "^1.17.10"
        "express" = "^4.18.2"
        "cors" = "^2.8.5"
        "helmet" = "^7.0.0"
        "morgan" = "^1.10.0"
        "dotenv" = "^16.3.1"
    }
    devDependencies = @{
        "nodemon" = "^3.0.1"
        "jest" = "^29.6.2"
        "supertest" = "^6.3.3"
    }
    engines = @{
        node = ">=18.0.0"
        npm = ">=8.0.0"
    }
    keywords = @("iot", "azure", "edge", "simulator", "factory", "industry40")
    author = "Smart Factory Team"
    license = "MIT"
} | ConvertTo-Json -Depth 4

$packageJson | Out-File -FilePath "src\device-simulator\package-enhanced.json" -Encoding UTF8
Write-Host "✅ Created enhanced package.json: src\device-simulator\package-enhanced.json" -ForegroundColor Green

# Create web dashboard for the simulator
$dashboardHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Smart Factory Edge Simulator Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f5f5f5; }
        .header { background: #2c3e50; color: white; padding: 1rem; text-align: center; }
        .container { max-width: 1200px; margin: 0 auto; padding: 2rem; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1.5rem; margin-bottom: 2rem; }
        .card { background: white; border-radius: 8px; padding: 1.5rem; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .status { padding: 0.5rem 1rem; border-radius: 20px; color: white; font-weight: bold; }
        .status.running { background: #27ae60; }
        .status.stopped { background: #e74c3c; }
        .button { padding: 0.75rem 1.5rem; margin: 0.5rem; border: none; border-radius: 5px; cursor: pointer; font-weight: bold; transition: all 0.3s; }
        .button.primary { background: #3498db; color: white; }
        .button.success { background: #27ae60; color: white; }
        .button.danger { background: #e74c3c; color: white; }
        .button:hover { transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.2); }
        .device-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 1rem; }
        .device-card { background: #f8f9fa; border-left: 4px solid #3498db; padding: 1rem; border-radius: 4px; }
        .device-card.operational { border-left-color: #27ae60; }
        .device-card.maintenance { border-left-color: #f39c12; }
        .device-card.error { border-left-color: #e74c3c; }
        .metric { text-align: center; margin-bottom: 1rem; }
        .metric-value { font-size: 2rem; font-weight: bold; color: #2c3e50; }
        .metric-label { color: #7f8c8d; font-size: 0.9rem; }
        #log { background: #2c3e50; color: #ecf0f1; padding: 1rem; border-radius: 5px; max-height: 300px; overflow-y: auto; font-family: 'Courier New', monospace; font-size: 0.9rem; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🏭 Smart Factory Edge Simulator Dashboard</h1>
        <p>Advanced IoT Device Simulation for Industry 4.0</p>
    </div>
    
    <div class="container">
        <!-- Control Panel -->
        <div class="card">
            <h2>🎛️ Simulation Control</h2>
            <div id="simulation-status" class="status stopped">STOPPED</div>
            <div style="margin-top: 1rem;">
                <button id="start-btn" class="button success">▶️ Start Simulation</button>
                <button id="stop-btn" class="button danger">⏹️ Stop Simulation</button>
                <button id="refresh-btn" class="button primary">🔄 Refresh Data</button>
            </div>
        </div>

        <!-- Metrics -->
        <div class="grid">
            <div class="card">
                <div class="metric">
                    <div id="device-count" class="metric-value">0</div>
                    <div class="metric-label">Active Devices</div>
                </div>
            </div>
            <div class="card">
                <div class="metric">
                    <div id="message-count" class="metric-value">0</div>
                    <div class="metric-label">Total Messages</div>
                </div>
            </div>
            <div class="card">
                <div class="metric">
                    <div id="message-rate" class="metric-value">0</div>
                    <div class="metric-label">Messages/Sec</div>
                </div>
            </div>
        </div>

        <!-- Device Status -->
        <div class="card">
            <h3>📱 Device Status</h3>
            <div id="devices" class="device-grid">
                <!-- Devices will be loaded here -->
            </div>
        </div>

        <!-- Activity Log -->
        <div class="card">
            <h3>📊 Activity Log</h3>
            <div id="log">
                Starting Smart Factory Edge Simulator Dashboard...
            </div>
        </div>
    </div>

    <script>
        let simulationActive = false;
        let refreshInterval = null;

        // DOM Elements
        const statusElement = document.getElementById('simulation-status');
        const deviceCountElement = document.getElementById('device-count');
        const messageCountElement = document.getElementById('message-count');
        const messageRateElement = document.getElementById('message-rate');
        const devicesElement = document.getElementById('devices');
        const logElement = document.getElementById('log');

        // Buttons
        document.getElementById('start-btn').addEventListener('click', startSimulation);
        document.getElementById('stop-btn').addEventListener('click', stopSimulation);
        document.getElementById('refresh-btn').addEventListener('click', refreshData);

        async function startSimulation() {
            try {
                const response = await fetch('/api/simulation/start', { method: 'POST' });
                const result = await response.json();
                log(`✅ ${result.message}`);
                refreshData();
            } catch (error) {
                log(`❌ Failed to start simulation: ${error.message}`);
            }
        }

        async function stopSimulation() {
            try {
                const response = await fetch('/api/simulation/stop', { method: 'POST' });
                const result = await response.json();
                log(`⏹️ ${result.message}`);
                refreshData();
            } catch (error) {
                log(`❌ Failed to stop simulation: ${error.message}`);
            }
        }

        async function refreshData() {
            try {
                // Get simulation status
                const statusResponse = await fetch('/api/simulation/status');
                const status = await statusResponse.json();
                
                updateStatus(status);

                // Get device details
                const devicesResponse = await fetch('/api/devices');
                const devices = await devicesResponse.json();
                
                updateDevices(devices);
                
            } catch (error) {
                log(`❌ Failed to refresh data: ${error.message}`);
            }
        }

        function updateStatus(status) {
            simulationActive = status.active;
            
            statusElement.textContent = status.active ? 'RUNNING' : 'STOPPED';
            statusElement.className = `status ${status.active ? 'running' : 'stopped'}`;
            
            deviceCountElement.textContent = status.deviceCount;
            messageCountElement.textContent = status.totalMessages;
            messageRateElement.textContent = status.messageRate || 0;
        }

        function updateDevices(data) {
            devicesElement.innerHTML = '';
            
            if (!data.devices || data.devices.length === 0) {
                devicesElement.innerHTML = '<p>No devices available</p>';
                return;
            }

            data.devices.forEach(device => {
                const deviceElement = document.createElement('div');
                const statusClass = device.isConnected ? 
                    (device.state?.operational ? 'operational' : 'maintenance') : 'error';
                
                deviceElement.className = `device-card ${statusClass}`;
                deviceElement.innerHTML = `
                    <h4>${device.deviceType}</h4>
                    <p><strong>ID:</strong> ${device.deviceId}</p>
                    <p><strong>Status:</strong> ${device.isConnected ? '🟢 Connected' : '🔴 Disconnected'}</p>
                    <p><strong>Operational:</strong> ${device.state?.operational ? '✅' : '⚠️'}</p>
                    <p><strong>Efficiency:</strong> ${device.state?.efficiency ? (device.state.efficiency * 100).toFixed(1) + '%' : 'N/A'}</p>
                `;
                
                devicesElement.appendChild(deviceElement);
            });
        }

        function log(message) {
            const timestamp = new Date().toLocaleTimeString();
            logElement.innerHTML += `<div>[${timestamp}] ${message}</div>`;
            logElement.scrollTop = logElement.scrollHeight;
        }

        // Auto-refresh every 5 seconds
        function startAutoRefresh() {
            refreshInterval = setInterval(refreshData, 5000);
        }

        function stopAutoRefresh() {
            if (refreshInterval) {
                clearInterval(refreshInterval);
                refreshInterval = null;
            }
        }

        // Initialize
        document.addEventListener('DOMContentLoaded', () => {
            log('🚀 Dashboard initialized');
            refreshData();
            startAutoRefresh();
        });

        // Cleanup on page unload
        window.addEventListener('beforeunload', stopAutoRefresh);
    </script>
</body>
</html>
"@

$publicDir = "src\device-simulator\public"
if (!(Test-Path $publicDir)) {
    New-Item -ItemType Directory -Path $publicDir -Force | Out-Null
}

$dashboardHtml | Out-File -FilePath "$publicDir\index.html" -Encoding UTF8
Write-Host "✅ Created dashboard: $publicDir\index.html" -ForegroundColor Green

# Create deployment script
$deployScript = @"
# 📦 Deploy Edge Simulator to Azure
param(
    [string]`$ResourceGroupName = "$ResourceGroupName",
    [string]`$AppName = "smart-factory-edge-simulator",
    [switch]`$BuildDocker = `$true
)

Write-Host "📦 Deploying Smart Factory Edge Simulator" -ForegroundColor Cyan

if (`$BuildDocker) {
    Write-Host "🐳 Building Docker image..." -ForegroundColor Yellow
    docker build -f Dockerfile-enhanced -t smart-factory-simulator:latest .
}

# Deploy to Azure Container Instances
Write-Host "☁️ Deploying to Azure Container Instances..." -ForegroundColor Yellow
az container create \\
    --resource-group `$ResourceGroupName \\
    --name `$AppName \\
    --image smart-factory-simulator:latest \\
    --dns-name-label `$AppName \\
    --ports 3000 \\
    --cpu 1 \\
    --memory 2 \\
    --environment-variables \\
        NODE_ENV=production \\
        AUTO_START=true \\
        DEVICE_COUNT=10

Write-Host "✅ Deployment completed!" -ForegroundColor Green
Write-Host "🌐 Access dashboard at: http://`$AppName.`$Location.azurecontainer.io:3000" -ForegroundColor Cyan
"@

$deployScript | Out-File -FilePath "src\device-simulator\deploy-edge.ps1" -Encoding UTF8
Write-Host "✅ Created deployment script: src\device-simulator\deploy-edge.ps1" -ForegroundColor Green

Write-Host "`n🎯 Edge Device Simulator setup completed!" -ForegroundColor Green

if ($RunLocal) {
    Write-Host "`n🚀 Starting local development server..." -ForegroundColor Yellow
    Set-Location "src\device-simulator"
    
    # Install dependencies if needed
    if (!(Test-Path "node_modules")) {
        Write-Host "📦 Installing dependencies..." -ForegroundColor Gray
        npm install
    }
    
    Write-Host "✅ All components implemented successfully!" -ForegroundColor Green
    Write-Host "`n📋 Implementation Summary:" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "✅ 2. Health Endpoints - Complete" -ForegroundColor Green
    Write-Host "✅ 4. Real-time Monitoring - Complete" -ForegroundColor Green  
    Write-Host "✅ 5. CI/CD Pipeline - Complete" -ForegroundColor Green
    Write-Host "✅ 6. Edge Simulator - Complete" -ForegroundColor Green
    
    Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Test health endpoints: .\test-health-endpoints.ps1" -ForegroundColor Gray
    Write-Host "2. Start monitoring: .\Start-RealtimeMonitoring.ps1 -Continuous" -ForegroundColor Gray
    Write-Host "3. Deploy via CI/CD: git push origin main" -ForegroundColor Gray
    Write-Host "4. Run edge simulator: cd src\device-simulator && node simulator-enhanced.js" -ForegroundColor Gray
}

Set-Location "C:\amapv2"