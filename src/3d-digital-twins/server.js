// 🏭 Smart Factory 3D Digital Twins Server
// Case Study #36 - Phase 3: 3D Visualization

require('dotenv').config();
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');
const cors = require('cors');
const fetch = require('node-fetch'); // Add fetch for server-side calls

// Azure Digital Twins SDK
const { DigitalTwinsClient } = require('@azure/digital-twins-core');
const { DefaultAzureCredential } = require('@azure/identity');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Azure Digital Twins Setup
const dtUrl = process.env.AZURE_DIGITAL_TWINS_URL || 'https://smartfactory-adt.api.wcus.digitaltwins.azure.net';
const credential = new DefaultAzureCredential();
const dtClient = new DigitalTwinsClient(dtUrl, credential);

// 🏭 Factory 3D Data Structure
const factory3DData = {
    machines: [
        {
            id: 'machine-01',
            name: 'CNC Milling Station',
            position: { x: -5, y: 0, z: -3 },
            rotation: { x: 0, y: Math.PI/4, z: 0 },
            status: 'operational',
            health: 85,
            lastMaintenance: '2024-12-20',
            predictions: {
                failureRisk: 0.15,
                nextMaintenance: '2025-01-15',
                anomalyScore: 0.23
            }
        },
        {
            id: 'machine-02', 
            name: 'Assembly Robot',
            position: { x: 5, y: 0, z: -3 },
            rotation: { x: 0, y: -Math.PI/4, z: 0 },
            status: 'operational',
            health: 92,
            lastMaintenance: '2024-12-18',
            predictions: {
                failureRisk: 0.08,
                nextMaintenance: '2025-01-20',
                anomalyScore: 0.12
            }
        },
        {
            id: 'machine-03',
            name: 'Quality Control Station',
            position: { x: 0, y: 0, z: 3 },
            rotation: { x: 0, y: Math.PI, z: 0 },
            status: 'maintenance',
            health: 45,
            lastMaintenance: '2024-12-22',
            predictions: {
                failureRisk: 0.75,
                nextMaintenance: '2024-12-24',
                anomalyScore: 0.89
            }
        }
    ],
    sensors: [
        { id: 'temp-01', position: { x: -5, y: 3, z: -3 }, value: 75.2, unit: '°C' },
        { id: 'vibr-01', position: { x: 5, y: 1, z: -3 }, value: 0.8, unit: 'mm/s' },
        { id: 'pres-01', position: { x: 0, y: 2, z: 3 }, value: 145.7, unit: 'PSI' }
    ],
    factory: {
        layout: {
            width: 20,
            height: 6, 
            depth: 15
        },
        lighting: {
            ambient: 0.4,
            directional: 0.8
        }
    }
};

// 📊 Real-time ML Predictions Simulation
function generateRealtimePredictions() {
    return factory3DData.machines.map(machine => ({
        id: machine.id,
        timestamp: new Date().toISOString(),
        predictions: {
            failureRisk: Math.max(0, machine.predictions.failureRisk + (Math.random() - 0.5) * 0.1),
            anomalyScore: Math.max(0, machine.predictions.anomalyScore + (Math.random() - 0.5) * 0.2),
            health: Math.max(0, Math.min(100, machine.health + (Math.random() - 0.5) * 10))
        },
        telemetry: {
            temperature: 70 + Math.random() * 20,
            vibration: Math.random() * 2,
            pressure: 140 + Math.random() * 20
        }
    }));
}

// 🌐 WebSocket Real-time Updates
io.on('connection', (socket) => {
    console.log('🔗 3D Client connected:', socket.id);
    
    // Send initial factory layout
    socket.emit('factory-layout', factory3DData);
    
    // Send real-time updates every 2 seconds
    const updateInterval = setInterval(() => {
        const predictions = generateRealtimePredictions();
        socket.emit('realtime-predictions', predictions);
    }, 2000);
    
    socket.on('disconnect', () => {
        console.log('❌ 3D Client disconnected:', socket.id);
        clearInterval(updateInterval);
    });
    
    // Handle machine selection
    socket.on('machine-selected', (machineId) => {
        const machine = factory3DData.machines.find(m => m.id === machineId);
        if (machine) {
            socket.emit('machine-details', {
                machine: machine,
                predictions: generateRealtimePredictions().find(p => p.id === machineId)
            });
        }
    });
});

// 🏥 Health Check Endpoint
app.get('/health', async (req, res) => {
    const healthCheck = {
        uptime: process.uptime(),
        message: 'OK',
        timestamp: Date.now(),
        service: '3d-digital-twins',
        version: '1.0.0',
        checks: {
            memory: {
                status: process.memoryUsage().heapUsed < 200000000 ? 'healthy' : 'warning',
                usage: process.memoryUsage()
            },
            websocket: {
                status: io.sockets.sockets.size > 0 ? 'active' : 'idle',
                connections: io.sockets.sockets.size
            },
            adtConnector: await checkADTConnector()
        }
    };
    
    const allHealthy = Object.values(healthCheck.checks)
        .every(check => check.status === 'healthy' || check.status === 'active' || check.status === 'idle');
    
    res.status(allHealthy ? 200 : 503).json(healthCheck);
});

// 🔍 Check ADT Connector Health
async function checkADTConnector() {
    try {
        const response = await fetch('http://localhost:3004/api/status');
        if (response.ok) {
            const status = await response.json();
            return {
                status: status.connected ? 'healthy' : 'degraded',
                connected: status.connected,
                endpoint: status.endpoint
            };
        } else {
            return { status: 'unhealthy', error: 'ADT connector not responding' };
        }
    } catch (error) {
        return { status: 'unhealthy', error: error.message };
    }
}

app.get('/api/factory-data', (req, res) => {
    res.json(factory3DData);
});
// 🔍 Debug endpoint to check 3D viewer progress
app.get('/debug', (req, res) => {
    res.json({
        status: 'Factory 3D Viewer Running ✅',
        timestamp: new Date().toISOString(),
        uptime: `${Math.floor(process.uptime())} seconds`,
        message: 'Server is working fine. If 3D viewer shows "Loading...", check browser console.',
        troubleshooting: {
            step1: 'Open browser console (F12) to see JavaScript logs',
            step2: 'Look for "Demo factory scene ready!" message',
            step3: 'Check for Three.js CDN loading errors',
            step4: 'Verify WebSocket connection status'
        },
        endpoints: {
            main: 'http://localhost:3003/',
            factoryData: 'http://localhost:3003/api/factory-data',
            predictions: 'http://localhost:3003/api/predictions',
            health: 'http://localhost:3003/health'
        }
    });
});
app.get('/api/predictions', async (req, res) => {
    try {
        const predictions = generateRealtimePredictions();
        res.json({ 
            success: true, 
            data: predictions,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Azure Digital Twins integration - connect to real ADT
app.get('/api/digital-twins', async (req, res) => {
    try {
        // Connect to real Azure Digital Twins via connector
        const response = await fetch('http://localhost:3004/api/twins/factory');
        const adtData = await response.json();
        
        if (adtData.success) {
            res.json({
                success: true,
                message: 'Connected to Azure Digital Twins',
                source: adtData.source,
                data: adtData.data,
                simulatedFallback: factory3DData
            });
        } else {
            throw new Error('ADT connector unavailable');
        }
        
    } catch (error) {
        console.warn('Azure Digital Twins connector not available, using simulated data');
        res.json({
            success: true,
            message: 'Using simulated data (ADT connector offline)',
            simulatedData: factory3DData
        });
    }
});

// Real-time ADT status endpoint
app.get('/api/adt-status', async (req, res) => {
    try {
        const response = await fetch('http://localhost:3004/api/status');
        const status = await response.json();
        res.json(status);
    } catch (error) {
        res.json({
            service: 'ADT Connector',
            connected: false,
            error: 'Connector offline',
            fallback: 'Using simulated data'
        });
    }
});

const PORT = process.env.PORT || 3003;
server.listen(PORT, () => {
    console.log('🏭 Smart Factory 3D Digital Twins Server');
    console.log('📊 Case Study #36 - Phase 3: 3D Visualization');
    console.log(`🌐 Server running on http://localhost:${PORT}`);
    console.log('🔗 WebSocket ready for real-time updates');
    console.log('✨ Three.js 3D viewer available at /');
});