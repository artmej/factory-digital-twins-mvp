// 🏭 Local IoT Edge Simulator 
// Simula el flujo completo Edge → Hub → Digital Twins

const express = require('express');
const axios = require('axios');
const app = express();

// Configuración
const EDGE_PORT = 3000;
const IOT_HUB_SIMULATOR_PORT = 3001;
const DIGITAL_TWINS_PORT = 3001;
const FACTORY_VM_IP = '130.131.248.173';

// Simulación de datos de la VM de fábrica
const FACTORY_DATA = {
    factoryId: 'factory-001',
    location: 'Production Floor A',
    machines: [
        {
            id: 'cnc-milling-01',
            type: 'CNC Milling Station',
            status: 'operational',
            health: 87,
            temperature: 42.5,
            vibration: 0.23,
            production_rate: 95.2
        },
        {
            id: 'robotic-arm-02', 
            type: 'Robotic Arm',
            status: 'operational',
            health: 92,
            temperature: 38.1,
            vibration: 0.15,
            production_rate: 98.7
        },
        {
            id: 'assembly-line-03',
            type: 'Assembly Line',
            status: 'warning',
            health: 78,
            temperature: 45.8,
            vibration: 0.41,
            production_rate: 82.3
        },
        {
            id: 'quality-control-04',
            type: 'Quality Control',
            status: 'operational', 
            health: 95,
            temperature: 35.2,
            vibration: 0.12,
            production_rate: 99.1
        }
    ]
};

// Middleware
app.use(express.json());

// Simular IoT Edge Runtime
class LocalIoTEdge {
    constructor() {
        this.isConnected = false;
        this.deviceId = 'factory-edge-gateway-001';
        this.messageCount = 0;
    }

    // Simular conexión a IoT Hub
    async connectToHub() {
        try {
            console.log('🔗 Connecting IoT Edge to simulated IoT Hub...');
            this.isConnected = true;
            console.log('✅ IoT Edge connected to IoT Hub');
            return true;
        } catch (error) {
            console.error('❌ Failed to connect to IoT Hub:', error.message);
            return false;
        }
    }

    // Recopilar datos de la VM de fábrica
    async collectFactoryData() {
        try {
            // En un escenario real, esto se conectaría a la VM 130.131.248.173
            console.log(`📡 Collecting data from Factory VM (${FACTORY_VM_IP})...`);
            
            // Simular variaciones en los datos
            const machines = FACTORY_DATA.machines.map(machine => ({
                ...machine,
                temperature: machine.temperature + (Math.random() - 0.5) * 5,
                vibration: Math.max(0, machine.vibration + (Math.random() - 0.5) * 0.1),
                production_rate: Math.max(0, Math.min(100, machine.production_rate + (Math.random() - 0.5) * 10)),
                timestamp: new Date().toISOString()
            }));

            return {
                ...FACTORY_DATA,
                machines,
                edge_gateway: {
                    device_id: this.deviceId,
                    edge_runtime_version: '1.4.0',
                    last_sync: new Date().toISOString()
                }
            };
        } catch (error) {
            console.error('❌ Error collecting factory data:', error.message);
            return null;
        }
    }

    // Procesar y filtrar datos en el edge
    async processDataLocally(factoryData) {
        console.log('⚡ Processing data at edge...');
        
        // Simulación de procesamiento edge (filtros, agregaciones)
        const processedData = {
            ...factoryData,
            edge_processing: {
                anomalies_detected: factoryData.machines.filter(m => 
                    m.health < 80 || m.temperature > 50 || m.vibration > 0.4
                ).length,
                avg_health: factoryData.machines.reduce((sum, m) => sum + m.health, 0) / factoryData.machines.length,
                critical_alerts: factoryData.machines.filter(m => m.health < 70).length,
                processed_at: new Date().toISOString()
            }
        };

        return processedData;
    }

    // Enviar a IoT Hub simulado
    async sendToIoTHub(processedData) {
        try {
            this.messageCount++;
            console.log(`📤 Sending message #${this.messageCount} to IoT Hub...`);

            // Simular envío a IoT Hub (en real sería Azure IoT Hub)
            const response = await axios.post(`http://localhost:${IOT_HUB_SIMULATOR_PORT}/api/telemetry`, {
                deviceId: this.deviceId,
                data: processedData,
                messageId: this.messageCount,
                timestamp: new Date().toISOString()
            }).catch(() => {
                // Si el IoT Hub no está disponible, solo loggeamos
                console.log('📡 IoT Hub not available - data cached locally');
                return { status: 200, data: { cached: true } };
            });

            console.log('✅ Data sent to IoT Hub successfully');
            return true;
        } catch (error) {
            console.error('❌ Failed to send to IoT Hub:', error.message);
            return false;
        }
    }
}

// Inicializar IoT Edge
const iotEdge = new LocalIoTEdge();

// API Endpoints
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'Local IoT Edge Simulator',
        connected_to_hub: iotEdge.isConnected,
        messages_sent: iotEdge.messageCount,
        factory_vm: FACTORY_VM_IP,
        timestamp: new Date().toISOString()
    });
});

app.get('/api/factory-data', async (req, res) => {
    try {
        const data = await iotEdge.collectFactoryData();
        res.json({
            success: true,
            data: data,
            source: 'factory-vm-simulation',
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

app.post('/api/trigger-collection', async (req, res) => {
    try {
        console.log('🚀 Manual data collection triggered...');
        
        // Paso 1: Recopilar datos
        const factoryData = await iotEdge.collectFactoryData();
        if (!factoryData) throw new Error('Failed to collect factory data');

        // Paso 2: Procesar en edge
        const processedData = await iotEdge.processDataLocally(factoryData);

        // Paso 3: Enviar a IoT Hub
        await iotEdge.sendToIoTHub(processedData);

        res.json({
            success: true,
            message: 'End-to-end data flow completed',
            data_summary: {
                machines: processedData.machines.length,
                anomalies: processedData.edge_processing.anomalies_detected,
                avg_health: Math.round(processedData.edge_processing.avg_health),
                message_id: iotEdge.messageCount
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Ciclo automático de recopilación
async function startAutomaticCollection() {
    console.log('🔄 Starting automatic data collection cycle...');
    
    setInterval(async () => {
        try {
            const factoryData = await iotEdge.collectFactoryData();
            const processedData = await iotEdge.processDataLocally(factoryData);
            await iotEdge.sendToIoTHub(processedData);
        } catch (error) {
            console.error('Error in automatic collection:', error.message);
        }
    }, 10000); // Cada 10 segundos
}

// Inicializar servidor
app.listen(EDGE_PORT, async () => {
    console.log('🏭 Local IoT Edge Simulator - Case Study #36');
    console.log(`📡 Server running on http://localhost:${EDGE_PORT}`);
    console.log(`🔗 Factory VM: ${FACTORY_VM_IP} (simulated)`);
    console.log(`📋 Available endpoints:`);
    console.log(`  📊 GET  /health`);
    console.log(`  🏭 GET  /api/factory-data`);
    console.log(`  🚀 POST /api/trigger-collection`);
    
    // Conectar a IoT Hub
    await iotEdge.connectToHub();
    
    // Iniciar recopilación automática
    startAutomaticCollection();
    
    console.log('✅ End-to-End simulation ready!');
});