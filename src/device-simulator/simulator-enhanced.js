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
            console.log(`Device ${deviceTypes[this.deviceType].name}[${this.deviceId}] connected`);
        });

        this.client.on('disconnect', () => {
            this.isConnected = false;
            console.log(`Device ${this.deviceId} disconnected`);
        });

        this.client.on('error', (err) => {
            console.error(`Device ${this.deviceId} error:`, err.message);
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
                messageId: msg--,
                version: '2.0.0',
                schema: 'smart-factory-telemetry-v2'
            }
        };

        this.lastTelemetry = telemetry;
        return telemetry;
    }

    async sendTelemetry() {
        if (!this.isConnected) {
            console.log(`Device ${this.deviceId} not connected, skipping telemetry`);
            return false;
        }

        try {
            const message = this.generateTelemetryMessage();
            await this.client.sendEvent(new require('azure-iot-device').Message(JSON.stringify(message)));
            
            global.totalMessages++;
            console.log(`${deviceTypes[this.deviceType].name}[${this.deviceId}] sent telemetry`);
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

        console.log(`Started telemetry for ${this.deviceId}`);
    }

    simulateStateChange() {
        if (Math.random() < 0.05) { // 5% chance of going into maintenance
            this.state.maintenanceMode = !this.state.maintenanceMode;
            console.log(`Device ${this.deviceId} maintenance mode: ${this.state.maintenanceMode}`);
        }
        
        if (Math.random() < 0.02) { // 2% chance of operational status change
            this.state.operational = !this.state.operational;
            console.log(`Device ${this.deviceId} operational: ${this.state.operational}`);
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
        console.log(`Stopped telemetry for ${this.deviceId}`);
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
        const deviceId = device--;
        const connectionString = config.iotHubConnectionString;
        
        if (!connectionString) {
            console.error('IoT Hub connection string not configured');
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
        
        console.log(`Simulation started with ${connectedDevices.length}/${devices.length} devices connected`);
        
        // Start message rate calculation
        setInterval(() => {
            const currentMessages = global.totalMessages;
            const timeDiff = (Date.now() - (global.lastMessageCount?.timestamp || Date.now())) / 1000;
            global.messagesPerSecond = Math.round((currentMessages - (global.lastMessageCount?.count || 0)) / timeDiff);
            global.lastMessageCount = { count: currentMessages, timestamp: Date.now() };
        }, 5000);
        
    } catch (error) {
        console.error('Failed to start simulation:', error.message);
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
        console.error('Failed to stop simulation:', error.message);
        throw error;
    }
}

// 🌐 Start Web Server
app.listen(config.port, () => {
    console.log(`Smart Factory Edge Simulator running on port ${config.port}`);
    console.log(`Simulation Dashboard: http://localhost:${config.port}`);
    
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
