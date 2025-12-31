// 🏭 Smart Factory 3D Digital Twins Server - Modernized
// Connected to Azure Functions API + Cosmos DB + Real-time ML

require('dotenv').config();
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');
const cors = require('cors');
const fetch = require('node-fetch');

// 🔗 Functions API Configuration
const FUNCTIONS_API_URL = process.env.FUNCTIONS_API_URL || 'https://func-smartfactory-prod.azurewebsites.net/api';
const DASHBOARD_ENDPOINT = `${FUNCTIONS_API_URL}/dashboard`;

console.log('🔗 Connecting to Functions API:', FUNCTIONS_API_URL);

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

// 🔐 Solo una ruta de login - simple y limpia
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'login.html'));
});

app.get('/login.html', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'login.html'));
});

app.get('/dashboard.html', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

app.get('/factory-3d.js', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'factory-3d.js'));
});

// 🔍 Test route
app.get('/test', (req, res) => {
    res.json({ 
        status: '✅ Single login route active',
        timestamp: new Date().toISOString(),
        port: 3003,
        routes: ['/login.html', '/dashboard.html']
    });
});



// 📊 Fetch Real Factory Data from Functions API
async function fetchRealFactoryData() {
    try {
        console.log('📡 Fetching data from Functions API...');
        const response = await fetch(DASHBOARD_ENDPOINT);
        
        if (!response.ok) {
            throw new Error(`API Error: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('✅ Real factory data received:', data.summary);
        
        // Transform API data to 3D format
        return transformAPIDataTo3D(data);
        
    } catch (error) {
        console.warn('⚠️ Functions API unavailable, using fallback:', error.message);
        return generateFallbackData();
    }
}

// 🔄 Transform Functions API data to 3D visualization format
function transformAPIDataTo3D(apiData) {
    const { summary, machines, lines, sensors } = apiData;
    
    return {
        machines: [
            {
                id: 'machine-01',
                name: 'CNC Milling Station',
                position: { x: -5, y: 0, z: -3 },
                rotation: { x: 0, y: Math.PI/4, z: 0 },
                status: summary.factoryEfficiency > 85 ? 'operational' : 'warning',
                health: Math.round(summary.factoryEfficiency),
                efficiency: summary.factoryEfficiency,
                predictions: {
                    failureRisk: summary.factoryEfficiency < 80 ? 0.75 : 0.15,
                    anomalyScore: summary.factoryEfficiency < 85 ? 0.6 : 0.2
                }
            },
            {
                id: 'machine-02',
                name: 'Assembly Robot',
                position: { x: 5, y: 0, z: -3 },
                rotation: { x: 0, y: -Math.PI/4, z: 0 },
                status: summary.linePerformance > 90 ? 'operational' : 'maintenance',
                health: Math.round(summary.linePerformance),
                efficiency: summary.linePerformance,
                predictions: {
                    failureRisk: summary.linePerformance < 85 ? 0.6 : 0.08,
                    anomalyScore: summary.linePerformance < 90 ? 0.4 : 0.12
                }
            },
            {
                id: 'machine-03',
                name: 'Quality Control Station',
                position: { x: 0, y: 0, z: 3 },
                rotation: { x: 0, y: Math.PI, z: 0 },
                status: summary.qualityScore > 95 ? 'operational' : 'warning',
                health: Math.round(summary.qualityScore || 95),
                efficiency: summary.qualityScore || 95,
                predictions: {
                    failureRisk: (summary.qualityScore || 95) < 90 ? 0.7 : 0.25,
                    anomalyScore: (summary.qualityScore || 95) < 95 ? 0.5 : 0.15
                }
            }
        ],
        sensors: [
            { id: 'temp-01', position: { x: -5, y: 3, z: -3 }, value: summary.avgTemperature || 75.2, unit: '°C' },
            { id: 'vibr-01', position: { x: 5, y: 1, z: -3 }, value: summary.vibration || 0.8, unit: 'mm/s' },
            { id: 'pres-01', position: { x: 0, y: 2, z: 3 }, value: summary.pressure || 145.7, unit: 'PSI' }
        ],
        realTime: true,
        timestamp: new Date().toISOString(),
        summary: summary
    };
}

// 🚨 Fallback data when API is unavailable
function generateFallbackData() {
    return {
        machines: [
            {
                id: 'machine-01',
                name: 'CNC Milling Station',
                position: { x: -5, y: 0, z: -3 },
                rotation: { x: 0, y: Math.PI/4, z: 0 },
                status: 'operational',
                health: 85,
                predictions: { failureRisk: 0.15, anomalyScore: 0.23 }
            },
            {
                id: 'machine-02',
                name: 'Assembly Robot',
                position: { x: 5, y: 0, z: -3 },
                rotation: { x: 0, y: -Math.PI/4, z: 0 },
                status: 'operational',
                health: 92,
                predictions: { failureRisk: 0.08, anomalyScore: 0.12 }
            },
            {
                id: 'machine-03',
                name: 'Quality Control Station',
                position: { x: 0, y: 0, z: 3 },
                rotation: { x: 0, y: Math.PI, z: 0 },
                status: 'maintenance',
                health: 45,
                predictions: { failureRisk: 0.75, anomalyScore: 0.89 }
            }
        ],
        sensors: [
            { id: 'temp-01', position: { x: -5, y: 3, z: -3 }, value: 75.2, unit: '°C' },
            { id: 'vibr-01', position: { x: 5, y: 1, z: -3 }, value: 0.8, unit: 'mm/s' },
            { id: 'pres-01', position: { x: 0, y: 2, z: 3 }, value: 145.7, unit: 'PSI' }
        ],
        realTime: false,
        timestamp: new Date().toISOString()
    };
}

// 🌐 WebSocket Real-time Updates with Real Data
io.on('connection', async (socket) => {
    console.log('🔗 3D Client connected:', socket.id);
    
    // Send initial factory layout with real data
    const initialData = await fetchRealFactoryData();
    socket.emit('factory-layout', initialData);
    
    // Send real-time updates every 5 seconds (less aggressive for production)
    const updateInterval = setInterval(async () => {
        try {
            const realTimeData = await fetchRealFactoryData();
            socket.emit('realtime-predictions', realTimeData.machines);
            socket.emit('sensor-updates', realTimeData.sensors);
            
            // Send summary stats
            if (realTimeData.summary) {
                socket.emit('factory-summary', realTimeData.summary);
            }
        } catch (error) {
            console.error('❌ Error fetching real-time data:', error.message);
        }
    }, 5000);
    
    socket.on('disconnect', () => {
        console.log('❌ 3D Client disconnected:', socket.id);
        clearInterval(updateInterval);
    });
    
    // Handle machine selection with real data
    socket.on('machine-selected', async (machineId) => {
        try {
            const currentData = await fetchRealFactoryData();
            const machine = currentData.machines.find(m => m.id === machineId);
            if (machine) {
                socket.emit('machine-details', {
                    machine: machine,
                    timestamp: new Date().toISOString(),
                    realTimeData: true
                });
            }
        } catch (error) {
            console.error('❌ Error fetching machine details:', error.message);
        }
    });
});

// 🏥 Health Check Endpoint
app.get('/health', async (req, res) => {
    const healthCheck = {
        uptime: process.uptime(),
        message: 'OK',
        timestamp: Date.now(),
        service: '3d-digital-twins-modernized',
        version: '2.0.0',
        checks: {
            memory: {
                status: process.memoryUsage().heapUsed < 200000000 ? 'healthy' : 'warning',
                usage: process.memoryUsage()
            },
            websocket: {
                status: io.sockets.sockets.size > 0 ? 'active' : 'idle',
                connections: io.sockets.sockets.size
            },
            functionsAPI: await checkFunctionsAPI()
        }
    };
    
    const allHealthy = Object.values(healthCheck.checks)
        .every(check => check.status === 'healthy' || check.status === 'active' || check.status === 'idle');
    
    res.status(allHealthy ? 200 : 503).json(healthCheck);
});

// 🔍 Check Functions API Health
async function checkFunctionsAPI() {
    try {
        const response = await fetch(`${FUNCTIONS_API_URL}/health`);
        if (response.ok) {
            return {
                status: 'healthy',
                connected: true,
                endpoint: FUNCTIONS_API_URL
            };
        } else {
            return { status: 'degraded', error: 'Functions API not responding', endpoint: FUNCTIONS_API_URL };
        }
    } catch (error) {
        return { status: 'unhealthy', error: error.message, endpoint: FUNCTIONS_API_URL };
    }
}

app.get('/api/factory-data', async (req, res) => {
    try {
        const realData = await fetchRealFactoryData();
        res.json({
            success: true,
            data: realData,
            source: realData.realTime ? 'functions-api' : 'fallback',
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message,
            fallback: generateFallbackData()
        });
    }
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
        const factoryData = await fetchRealFactoryData();
        const predictions = factoryData.machines.map(machine => ({
            id: machine.id,
            timestamp: new Date().toISOString(),
            predictions: machine.predictions,
            health: machine.health,
            status: machine.status,
            efficiency: machine.efficiency
        }));
        
        res.json({ 
            success: true, 
            data: predictions,
            source: factoryData.realTime ? 'functions-api' : 'fallback',
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({ 
            success: false, 
            error: error.message,
            fallback: 'Check Functions API connection'
        });
    }
});

// 📊 Functions API Status Check
app.get('/api/functions-status', async (req, res) => {
    try {
        const response = await fetch(`${FUNCTIONS_API_URL}/health`);
        const status = await response.json();
        
        res.json({
            service: 'Azure Functions API',
            connected: response.ok,
            endpoint: FUNCTIONS_API_URL,
            status: status,
            dashboard: `${FUNCTIONS_API_URL}/dashboard`
        });
        
    } catch (error) {
        res.json({
            service: 'Azure Functions API',
            connected: false,
            error: error.message,
            endpoint: FUNCTIONS_API_URL
        });
    }
});

const PORT = process.env.PORT || 3005;
server.listen(PORT, () => {
    console.log('🏭 Smart Factory 3D Digital Twins Server - MODERNIZED');
    console.log('📊 Connected to Azure Functions + Cosmos DB + ML');
    console.log(`🌐 Server running on http://localhost:${PORT}`);
    console.log('🔗 WebSocket ready for real-time updates');
    console.log('✨ Three.js 3D viewer available at /');
    console.log(`🔌 Functions API: ${FUNCTIONS_API_URL}`);
    console.log('');
    console.log('🚀 Ready for production with real data!');
}).on('error', (err) => {
    console.error('❌ Server error:', err.message);
    if (err.code === 'EADDRINUSE') {
        console.log(`⚠️ Port ${PORT} is already in use. Trying port ${PORT + 1}...`);
        server.listen(PORT + 1);
    }
});

// Add process error handlers
process.on('uncaughtException', (error) => {
    console.error('❌ Uncaught Exception:', error.message);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
});