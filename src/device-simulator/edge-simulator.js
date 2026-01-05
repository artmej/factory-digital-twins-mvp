// 🏭 Smart Factory Edge Simulator - Multi Production Lines
// Simulador específico para demostración en IoT Edge

const express = require('express');
const path = require('path');

const app = express();
const port = process.env.PORT || 3000;

// 🔧 Edge Configuration
const edgeConfig = {
    productionLines: parseInt(process.env.PRODUCTION_LINES) || 3,
    edgeMode: process.env.EDGE_MODE === 'true',
    simulationInterval: 5000, // 5 seconds for demo
    factoryId: process.env.FACTORY_ID || 'EDGE-FACTORY-001',
    postgresConnection: process.env.POSTGRES_CONNECTION || 'postgresql://postgres:factory123@localhost:5432/factory_edge'
};

// 🏭 Production Lines Configuration
const productionLines = [];
for (let i = 1; i <= edgeConfig.productionLines; i++) {
    productionLines.push({
        lineId: `LINE-${i}`,
        name: `Línea de Producción ${i}`,
        status: 'ACTIVE',
        targetProduction: 100 * i,
        currentProduction: Math.floor((85 + Math.random() * 15) * i),
        efficiency: 85 + Math.random() * 15,
        devices: [
            { id: `LINE-${i}-CNC-01`, type: 'cnc-machine', status: 'operational', lastSeen: new Date() },
            { id: `LINE-${i}-CNC-02`, type: 'cnc-machine', status: 'operational', lastSeen: new Date() },
            { id: `LINE-${i}-ROBOT-01`, type: 'robotic-arm', status: 'operational', lastSeen: new Date() },
            { id: `LINE-${i}-CONV-01`, type: 'conveyor-belt', status: 'operational', lastSeen: new Date() },
            { id: `LINE-${i}-CONV-02`, type: 'conveyor-belt', status: 'operational', lastSeen: new Date() },
            { id: `LINE-${i}-CONV-03`, type: 'conveyor-belt', status: 'operational', lastSeen: new Date() },
            { id: `LINE-${i}-QC-01`, type: 'quality-sensor', status: 'operational', lastSeen: new Date() },
            { id: `LINE-${i}-ENV-01`, type: 'environmental', status: 'operational', lastSeen: new Date() }
        ]
    });
}

// 📊 Global simulation state
global.simulationState = {
    active: false,
    startTime: null,
    totalMessages: 0,
    messagesPerSecond: 0,
    alerts: [],
    mlPredictions: []
};

// 🎭 Device simulators for each type
const deviceSimulators = {
    'cnc-machine': {
        sensors: ['temperature', 'vibration', 'power', 'speed', 'pressure'],
        generateData: () => ({
            temperature: 45 + Math.random() * 20,
            vibration: 0.1 + Math.random() * 0.3,
            power: 2000 + Math.random() * 500,
            speed: 1800 + Math.random() * 200,
            pressure: 15 + Math.random() * 5
        })
    },
    'robotic-arm': {
        sensors: ['position', 'force', 'temperature', 'battery'],
        generateData: () => ({
            position: { x: Math.random() * 100, y: Math.random() * 100, z: Math.random() * 50 },
            force: 50 + Math.random() * 20,
            temperature: 35 + Math.random() * 15,
            battery: Math.max(10, 100 - Math.random() * 20)
        })
    },
    'conveyor-belt': {
        sensors: ['speed', 'load', 'temperature', 'vibration'],
        generateData: () => ({
            speed: 1.5 + Math.random() * 0.5,
            load: Math.random() * 100,
            temperature: 25 + Math.random() * 10,
            vibration: 0.05 + Math.random() * 0.1
        })
    },
    'quality-sensor': {
        sensors: ['defect-rate', 'throughput', 'accuracy'],
        generateData: () => ({
            'defect-rate': Math.random() * 5,
            throughput: 80 + Math.random() * 20,
            accuracy: 95 + Math.random() * 5
        })
    },
    'environmental': {
        sensors: ['temperature', 'humidity', 'air-quality', 'noise'],
        generateData: () => ({
            temperature: 20 + Math.random() * 15,
            humidity: 30 + Math.random() * 40,
            'air-quality': 50 + Math.random() * 50,
            noise: 45 + Math.random() * 15
        })
    }
};

// 🤖 ML Simulation (Edge Inference)
function runMLInference(deviceData) {
    const predictions = [];
    
    // Anomaly Detection
    if (deviceData.temperature > 70 || deviceData.vibration > 0.4) {
        predictions.push({
            type: 'anomaly_detection',
            confidence: 0.85 + Math.random() * 0.15,
            alert_level: 'HIGH',
            recommendation: 'Revisar equipo - posible sobrecalentamiento o vibración excesiva'
        });
    }
    
    // Predictive Maintenance
    if (Math.random() < 0.1) { // 10% chance of maintenance prediction
        predictions.push({
            type: 'predictive_maintenance',
            confidence: 0.75 + Math.random() * 0.20,
            alert_level: 'MEDIUM',
            recommendation: 'Programar mantenimiento preventivo en próximas 48 horas'
        });
    }
    
    return predictions;
}

// 📡 Simulate IoT Edge message processing
function processEdgeMessage(deviceId, lineId, telemetry) {
    // Simulate edge processing
    console.log(`📡 Edge Processing: ${deviceId} -> IoT Hub`);
    
    // Run ML inference
    const mlPredictions = runMLInference(telemetry.sensors);
    if (mlPredictions.length > 0) {
        global.simulationState.mlPredictions.push(...mlPredictions.map(p => ({
            ...p,
            deviceId,
            lineId,
            timestamp: new Date()
        })));
        
        // Create alerts for high confidence predictions
        mlPredictions.filter(p => p.confidence > 0.8).forEach(prediction => {
            global.simulationState.alerts.push({
                id: Date.now() + Math.random(),
                lineId,
                deviceId,
                type: prediction.type,
                level: prediction.alert_level,
                message: prediction.recommendation,
                timestamp: new Date(),
                acknowledged: false
            });
        });
    }
    
    global.simulationState.totalMessages++;
}

// 🌐 Express API Endpoints

app.use(express.json());
app.use(express.static('public'));

// Production Lines API
app.get('/api/production-lines', (req, res) => {
    res.json({
        factoryId: edgeConfig.factoryId,
        lines: productionLines.map(line => ({
            ...line,
            deviceCount: line.devices.length,
            operationalDevices: line.devices.filter(d => d.status === 'operational').length
        })),
        totalLines: productionLines.length,
        totalDevices: productionLines.reduce((sum, line) => sum + line.devices.length, 0)
    });
});

// Device Status API
app.get('/api/devices', (req, res) => {
    const allDevices = productionLines.flatMap(line => 
        line.devices.map(device => ({
            ...device,
            lineId: line.lineId,
            lineName: line.name
        }))
    );
    
    res.json({
        devices: allDevices,
        summary: {
            total: allDevices.length,
            operational: allDevices.filter(d => d.status === 'operational').length,
            maintenance: allDevices.filter(d => d.status === 'maintenance').length,
            offline: allDevices.filter(d => d.status === 'offline').length
        }
    });
});

// Real-time telemetry simulation
app.get('/api/telemetry/live', (req, res) => {
    const liveData = productionLines.map(line => ({
        lineId: line.lineId,
        lineName: line.name,
        devices: line.devices.map(device => {
            const simulator = deviceSimulators[device.type];
            const sensorData = simulator ? simulator.generateData() : {};
            
            return {
                deviceId: device.id,
                deviceType: device.type,
                status: device.status,
                sensors: sensorData,
                timestamp: new Date()
            };
        })
    }));
    
    res.json({
        timestamp: new Date(),
        factoryId: edgeConfig.factoryId,
        lines: liveData
    });
});

// ML Predictions API
app.get('/api/ml/predictions', (req, res) => {
    res.json({
        predictions: global.simulationState.mlPredictions.slice(-20), // Last 20 predictions
        models: [
            { name: 'Anomaly Detection', status: 'active', accuracy: 94.2 },
            { name: 'Predictive Maintenance', status: 'active', accuracy: 89.7 },
            { name: 'Quality Control', status: 'active', accuracy: 96.1 },
            { name: 'Energy Optimization', status: 'inactive', accuracy: 0 }
        ]
    });
});

// Alerts API
app.get('/api/alerts', (req, res) => {
    res.json({
        alerts: global.simulationState.alerts.slice(-10), // Last 10 alerts
        summary: {
            total: global.simulationState.alerts.length,
            unacknowledged: global.simulationState.alerts.filter(a => !a.acknowledged).length,
            high: global.simulationState.alerts.filter(a => a.level === 'HIGH').length,
            medium: global.simulationState.alerts.filter(a => a.level === 'MEDIUM').length
        }
    });
});

// Simulation control
app.post('/api/simulation/start', (req, res) => {
    if (global.simulationState.active) {
        return res.json({ message: 'Simulation already running', status: 'running' });
    }
    
    global.simulationState.active = true;
    global.simulationState.startTime = new Date();
    
    // Start telemetry generation
    global.simulationInterval = setInterval(() => {
        productionLines.forEach(line => {
            line.devices.forEach(device => {
                if (device.status === 'operational') {
                    const simulator = deviceSimulators[device.type];
                    if (simulator) {
                        const telemetry = {
                            deviceId: device.id,
                            lineId: line.lineId,
                            sensors: simulator.generateData(),
                            timestamp: new Date()
                        };
                        
                        processEdgeMessage(device.id, line.lineId, telemetry);
                    }
                }
            });
        });
    }, edgeConfig.simulationInterval);
    
    res.json({ 
        message: 'Edge simulation started', 
        status: 'started',
        lines: productionLines.length,
        devices: productionLines.reduce((sum, line) => sum + line.devices.length, 0)
    });
});

app.post('/api/simulation/stop', (req, res) => {
    if (!global.simulationState.active) {
        return res.json({ message: 'Simulation not running', status: 'stopped' });
    }
    
    global.simulationState.active = false;
    clearInterval(global.simulationInterval);
    
    res.json({ message: 'Edge simulation stopped', status: 'stopped' });
});

// Health endpoint
app.get('/api/health', (req, res) => {
    res.json({
        service: 'Smart Factory Edge Simulator',
        status: 'healthy',
        timestamp: new Date(),
        edge: {
            mode: edgeConfig.edgeMode,
            factoryId: edgeConfig.factoryId,
            productionLines: edgeConfig.productionLines
        },
        simulation: {
            active: global.simulationState.active,
            uptime: global.simulationState.startTime ? 
                Math.round((Date.now() - global.simulationState.startTime) / 1000) : 0,
            totalMessages: global.simulationState.totalMessages
        }
    });
});

// Start server
app.listen(port, () => {
    console.log(`🏭 Smart Factory Edge Simulator running on port ${port}`);
    console.log(`📊 Production Lines: ${edgeConfig.productionLines}`);
    console.log(`🔧 Edge Mode: ${edgeConfig.edgeMode}`);
    console.log(`🌐 Dashboard: http://localhost:${port}`);
    
    if (edgeConfig.edgeMode) {
        console.log('🚀 Edge mode active - ready for IoT Edge deployment');
    }
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\\n🛑 Shutting down Edge Simulator...');
    if (global.simulationInterval) {
        clearInterval(global.simulationInterval);
    }
    process.exit(0);
});

module.exports = app;