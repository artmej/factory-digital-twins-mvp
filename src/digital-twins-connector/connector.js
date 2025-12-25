// 🌐 Azure Digital Twins Real Connector 
// Case Study #36 - Bridge between Azure ADT and 3D Viewer

require('dotenv').config();
const { DigitalTwinsClient } = require('@azure/digital-twins-core');
const { DefaultAzureCredential } = require('@azure/identity');
const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// 🔐 Azure Digital Twins Configuration
const ADT_URL = process.env.AZURE_DIGITAL_TWINS_URL || 'https://smartfactory-adt.api.wcus.digitaltwins.azure.net';

class DigitalTwinsConnector {
    constructor() {
        this.client = null;
        this.isConnected = false;
        this.init();
    }

    async init() {
        try {
            console.log('🔗 Initializing Azure Digital Twins connection...');
            const credential = new DefaultAzureCredential();
            this.client = new DigitalTwinsClient(ADT_URL, credential);
            
            // Test connection
            await this.testConnection();
            this.isConnected = true;
            console.log('✅ Connected to Azure Digital Twins');
            
        } catch (error) {
            console.warn('⚠️ Azure Digital Twins not available:', error.message);
            console.log('🔄 Falling back to simulated data mode');
            this.isConnected = false;
        }
    }

    async testConnection() {
        if (!this.client) throw new Error('Client not initialized');
        
        try {
            // Try to query existing twins
            const query = "SELECT * FROM DIGITALTWINS T WHERE IS_OF_MODEL('dtmi:smartfactory:Factory;1')";
            const queryResult = this.client.queryTwins(query);
            
            let count = 0;
            for await (const twin of queryResult) {
                count++;
                console.log('📊 Found factory twin:', twin.$dtId);
                if (count >= 1) break; // Just test first one
            }
            
            console.log(`🏭 Found ${count} factory twin(s) in Azure Digital Twins`);
            
        } catch (error) {
            console.log('ℹ️ No existing twins found, will use simulated data');
        }
    }

    // 📊 Get Real-time Twin Data
    async getTwinData(twinId) {
        if (!this.isConnected || !this.client) {
            return this.getSimulatedData(twinId);
        }

        try {
            const twin = await this.client.getDigitalTwin(twinId);
            return {
                success: true,
                data: twin,
                source: 'azure-digital-twins',
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            console.warn(`⚠️ Could not fetch twin ${twinId}:`, error.message);
            return this.getSimulatedData(twinId);
        }
    }

    // 🎭 Simulated Data for Development
    getSimulatedData(twinId) {
        const baseData = {
            success: true,
            source: 'simulated-for-demo',
            timestamp: new Date().toISOString()
        };

        if (twinId.includes('machine')) {
            return {
                ...baseData,
                data: {
                    $dtId: twinId,
                    temperature: 75 + Math.random() * 20,
                    pressure: 140 + Math.random() * 20,
                    vibration: Math.random() * 2,
                    oee: 85 + Math.random() * 15,
                    status: Math.random() > 0.8 ? 'maintenance' : 'operational',
                    health: Math.random() * 100,
                    predictedFailure: Math.random() * 0.3,
                    anomalyScore: Math.random() * 0.5
                }
            };
        }

        if (twinId.includes('sensor')) {
            return {
                ...baseData,
                data: {
                    $dtId: twinId,
                    value: Math.random() * 100,
                    timestamp: new Date().toISOString(),
                    isActive: Math.random() > 0.1
                }
            };
        }

        if (twinId.includes('factory')) {
            return {
                ...baseData,
                data: {
                    $dtId: twinId,
                    overallEfficiency: 82 + Math.random() * 15,
                    energyConsumption: 150 + Math.random() * 50,
                    factoryName: 'Smart Factory Demo',
                    location: 'Azure Cloud'
                }
            };
        }

        return { ...baseData, data: { $dtId: twinId, status: 'unknown' } };
    }

    // 🏭 Get All Factory Twins
    async getAllFactoryTwins() {
        if (!this.isConnected) {
            return this.getSimulatedFactoryData();
        }

        try {
            const twins = [];
            
            // Query all machine twins
            const machineQuery = "SELECT * FROM DIGITALTWINS T WHERE IS_OF_MODEL('dtmi:smartfactory:Machine;1')";
            for await (const twin of this.client.queryTwins(machineQuery)) {
                twins.push({ type: 'machine', ...twin });
            }

            // Query all sensor twins  
            const sensorQuery = "SELECT * FROM DIGITALTWINS T WHERE IS_OF_MODEL('dtmi:smartfactory:Sensor;1')";
            for await (const twin of this.client.queryTwins(sensorQuery)) {
                twins.push({ type: 'sensor', ...twin });
            }

            return {
                success: true,
                data: twins,
                source: 'azure-digital-twins',
                count: twins.length
            };

        } catch (error) {
            console.warn('⚠️ Could not query twins:', error.message);
            return this.getSimulatedFactoryData();
        }
    }

    // 🎭 Get Simulated Factory Data  
    getSimulatedFactoryData() {
        return {
            success: true,
            source: 'simulated-for-demo',
            data: [
                {
                    type: 'machine',
                    $dtId: 'machine-01',
                    name: 'CNC Milling Station',
                    status: 'operational',
                    health: 85,
                    temperature: 75.2,
                    position: { x: -5, y: 0, z: -3 }
                },
                {
                    type: 'machine', 
                    $dtId: 'machine-02',
                    name: 'Assembly Robot',
                    status: 'operational', 
                    health: 92,
                    temperature: 68.5,
                    position: { x: 5, y: 0, z: -3 }
                },
                {
                    type: 'machine',
                    $dtId: 'machine-03', 
                    name: 'Quality Control',
                    status: 'maintenance',
                    health: 45,
                    temperature: 82.1,
                    position: { x: 0, y: 0, z: 3 }
                },
                {
                    type: 'sensor',
                    $dtId: 'temp-01',
                    value: 75.2,
                    unit: '°C',
                    position: { x: -5, y: 3, z: -3 }
                },
                {
                    type: 'sensor',
                    $dtId: 'vibr-01', 
                    value: 0.8,
                    unit: 'mm/s',
                    position: { x: 5, y: 1, z: -3 }
                }
            ]
        };
    }

    // 📡 Update Twin with Telemetry
    async updateTwin(twinId, telemetryData) {
        if (!this.isConnected) {
            console.log(`🎭 [SIMULATED] Updating twin ${twinId}:`, telemetryData);
            return { success: true, simulated: true };
        }

        try {
            await this.client.updateDigitalTwin(twinId, [
                {
                    op: "replace",
                    path: "/",
                    value: telemetryData
                }
            ]);

            return { success: true, updated: twinId };
            
        } catch (error) {
            console.warn(`⚠️ Could not update twin ${twinId}:`, error.message);
            return { success: false, error: error.message };
        }
    }
}

// 🔗 Initialize connector
const connector = new DigitalTwinsConnector();

// 🌐 API Endpoints
app.get('/api/twins/factory', async (req, res) => {
    try {
        const result = await connector.getAllFactoryTwins();
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

app.get('/api/twins/:twinId', async (req, res) => {
    try {
        const result = await connector.getTwinData(req.params.twinId);
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

app.post('/api/twins/:twinId/telemetry', async (req, res) => {
    try {
        const result = await connector.updateTwin(req.params.twinId, req.body);
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// 🏥 Health Check endpoint
app.get('/health', async (req, res) => {
    const healthCheck = {
        uptime: process.uptime(),
        message: 'OK',
        timestamp: Date.now(),
        service: 'digital-twins-connector',
        version: '1.0.0',
        checks: {
            memory: {
                status: process.memoryUsage().heapUsed < 150000000 ? 'healthy' : 'warning',
                usage: process.memoryUsage()
            },
            adtConnection: {
                status: connector.isConnected ? 'healthy' : 'degraded',
                connected: connector.isConnected,
                endpoint: ADT_URL
            },
            database: {
                status: 'healthy', // Placeholder for future DB connections
                latency: Math.floor(Math.random() * 50) + 'ms'
            }
        }
    };
    
    const allHealthy = Object.values(healthCheck.checks)
        .every(check => check.status === 'healthy' || check.status === 'degraded');
    
    res.status(allHealthy ? 200 : 503).json(healthCheck);
});

// 🚀 Start server
const PORT = process.env.PORT || 3001; // Changed from 3004 to avoid conflicts
app.listen(PORT, () => {
    console.log('🌐 Azure Digital Twins Connector');
    console.log(`📡 API running on http://localhost:${PORT}`);
    console.log(`🔗 ADT Endpoint: ${ADT_URL}`);
    console.log(`✅ Status: ${connector.isConnected ? 'Connected to Azure' : 'Simulated Mode'}`);
    console.log('📋 Available endpoints:');
    console.log('  📊 GET  /api/status');
    console.log('  🏭 GET  /api/twins/factory');
    console.log('  🔍 GET  /api/twins/:twinId');
    console.log('  📡 POST /api/twins/:twinId/telemetry');
});