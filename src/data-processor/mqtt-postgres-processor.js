// 🔗 IoT Edge Module: MQTT → PostgreSQL Local + IoT Hub Cloud
// PostgreSQL: almacenamiento local directo (mismo nivel que IoT Edge)
// DPS/IoT Hub: registro y envío cloud para telemetría y alertas

const mqtt = require('mqtt');
const { Client } = require('pg');
const { Client: IoTHubClient } = require('azure-iot-device');
const { Mqtt: IoTHubTransport } = require('azure-iot-device-mqtt');
const { ProvisioningDeviceClient } = require('azure-iot-provisioning-device');
const { Mqtt: DpsTransport } = require('azure-iot-provisioning-device-mqtt');
const { SymmetricKeySecurityClient } = require('azure-iot-security-symmetric-key');

// 🔧 Configuración
const config = {
    mqtt: {
        broker: process.env.MQTT_BROKER || 'mqtt://mqtt-broker:1883',
        topics: ['factory/+/sensors', 'factory/+/alerts', 'factory/+/ml-predictions']
    },
    postgres: {
        host: process.env.POSTGRES_HOST || 'postgres',
        port: process.env.POSTGRES_PORT || 5432,
        database: process.env.POSTGRES_DB || 'smartfactory',
        user: process.env.POSTGRES_USER || 'factory_user',
        password: process.env.POSTGRES_PASSWORD || 'SmartFactory123!'
    },
    dps: {
        globalDeviceEndpoint: process.env.DPS_GLOBAL_ENDPOINT || 'global.azure-devices-provisioning.net',
        idScope: process.env.DPS_ID_SCOPE || '0ne0012345',
        deviceId: process.env.DEVICE_ID || 'smart-factory-edge-001',
        deviceKey: process.env.DEVICE_KEY || 'your-device-key-here',
        enabled: process.env.DPS_ENABLED === 'true' || false
    },
    iotHub: {
        connectionString: process.env.IOT_HUB_CONNECTION_STRING || '',
        enabled: process.env.IOT_HUB_ENABLED === 'true' || false
    }
};

let pgClient;
let mqttClient;
let iotHubClient;
let deviceConnectionString;

// 🗄️ Inicializar Base de Datos
async function initializeDatabase() {
    try {
        pgClient = new Client(config.postgres);
        await pgClient.connect();
        console.log('✅ Conectado a PostgreSQL');

        // Crear tablas si no existen
        await createTables();
        console.log('✅ Tablas de BD verificadas');
    } catch (error) {
        console.error('❌ Error conectando a PostgreSQL:', error);
        process.exit(1);
    }
}

// 📋 Crear estructura de tablas
async function createTables() {
    const createTablesQueries = [
        `CREATE TABLE IF NOT EXISTS sensor_data (
            id SERIAL PRIMARY KEY,
            device_id VARCHAR(100) NOT NULL,
            line_id VARCHAR(50) NOT NULL,
            sensor_type VARCHAR(50) NOT NULL,
            value DECIMAL(10,2) NOT NULL,
            unit VARCHAR(20),
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`,
        
        `CREATE TABLE IF NOT EXISTS production_lines (
            id SERIAL PRIMARY KEY,
            line_id VARCHAR(50) UNIQUE NOT NULL,
            name VARCHAR(100) NOT NULL,
            status VARCHAR(20) DEFAULT 'ACTIVE',
            target_production INTEGER DEFAULT 0,
            current_production INTEGER DEFAULT 0,
            efficiency DECIMAL(5,2) DEFAULT 0.0,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`,
        
        `CREATE TABLE IF NOT EXISTS alerts (
            id SERIAL PRIMARY KEY,
            alert_id VARCHAR(100) UNIQUE NOT NULL,
            line_id VARCHAR(50) NOT NULL,
            device_id VARCHAR(100) NOT NULL,
            alert_type VARCHAR(50) NOT NULL,
            level VARCHAR(20) NOT NULL,
            message TEXT,
            confidence DECIMAL(4,3),
            resolved BOOLEAN DEFAULT FALSE,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`,
        
        `CREATE TABLE IF NOT EXISTS ml_predictions (
            id SERIAL PRIMARY KEY,
            device_id VARCHAR(100) NOT NULL,
            line_id VARCHAR(50) NOT NULL,
            prediction_type VARCHAR(50) NOT NULL,
            confidence DECIMAL(4,3) NOT NULL,
            recommendation TEXT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`,

        `CREATE INDEX IF NOT EXISTS idx_sensor_data_timestamp ON sensor_data(timestamp);`,
        `CREATE INDEX IF NOT EXISTS idx_sensor_data_device ON sensor_data(device_id);`,
        `CREATE INDEX IF NOT EXISTS idx_alerts_timestamp ON alerts(timestamp);`
    ];

    for (const query of createTablesQueries) {
        await pgClient.query(query);
    }
}

// 🌐 Azure DPS - Device Provisioning Service
async function provisionDeviceWithDPS() {
    if (!config.dps.enabled) {
        console.log('📱 DPS disabled, using direct IoT Hub connection');
        return config.iotHub.connectionString;
    }

    try {
        console.log('🔐 Starting DPS provisioning...');
        
        const securityClient = new SymmetricKeySecurityClient(
            config.dps.deviceId,
            config.dps.deviceKey
        );
        
        const provisioningClient = ProvisioningDeviceClient.create(
            config.dps.globalDeviceEndpoint,
            config.dps.idScope,
            new DpsTransport(),
            securityClient
        );

        const result = await new Promise((resolve, reject) => {
            provisioningClient.register((err, result) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(result);
                }
            });
        });

        const connectionString = `HostName=${result.assignedHub};DeviceId=${result.deviceId};SharedAccessKey=${config.dps.deviceKey}`;
        console.log(`✅ DPS Provisioning successful! Assigned to: ${result.assignedHub}`);
        
        return connectionString;
    } catch (error) {
        console.error('❌ Error during DPS provisioning:', error);
        console.log('🔄 Falling back to direct IoT Hub connection');
        return config.iotHub.connectionString;
    }
}

// 🌐 Conectar a Azure IoT Hub
async function connectToIoTHub() {
    if (!config.iotHub.enabled && !config.dps.enabled) {
        console.log('☁️ IoT Hub disabled, local-only mode');
        return;
    }

    try {
        // Obtener connection string via DPS o directo
        deviceConnectionString = await provisionDeviceWithDPS();
        
        if (!deviceConnectionString) {
            console.log('❌ No IoT Hub connection string available');
            return;
        }

        iotHubClient = IoTHubClient.fromConnectionString(deviceConnectionString, IoTHubTransport);
        
        await new Promise((resolve, reject) => {
            iotHubClient.open((err) => {
                if (err) {
                    reject(err);
                } else {
                    resolve();
                }
            });
        });

        console.log('✅ Conectado a Azure IoT Hub');

        // Manejar comandos cloud-to-device
        iotHubClient.on('message', (msg) => {
            console.log('📩 Cloud-to-Device message received:', msg.data.toString());
            iotHubClient.complete(msg, () => {
                console.log('✅ C2D message processed');
            });
        });

    } catch (error) {
        console.error('❌ Error conectando a IoT Hub:', error);
        iotHubClient = null;
    }
}

// 📤 Enviar datos a IoT Hub
async function sendToIoTHub(messageType, data) {
    if (!iotHubClient) {
        console.log('📴 IoT Hub not connected, skipping cloud sync');
        return;
    }

    try {
        const message = {
            messageType,
            deviceId: data.deviceId,
            lineId: data.lineId,
            timestamp: data.timestamp || new Date(),
            data: data
        };

        const iotMessage = new (require('azure-iot-device').Message)(JSON.stringify(message));
        iotMessage.properties.add('messageType', messageType);
        iotMessage.properties.add('lineId', data.lineId);

        await new Promise((resolve, reject) => {
            iotHubClient.sendEvent(iotMessage, (err) => {
                if (err) {
                    reject(err);
                } else {
                    resolve();
                }
            });
        });

        console.log(`☁️ Sent to IoT Hub: ${messageType} from ${data.deviceId}`);
    } catch (error) {
        console.error('❌ Error sending to IoT Hub:', error);
    }
}

// 📡 Conectar a MQTT
function connectToMQTT() {
    mqttClient = mqtt.connect(config.mqtt.broker);
    
    mqttClient.on('connect', () => {
        console.log('✅ Conectado a MQTT Broker');
        
        // Suscribirse a todos los tópicos
        config.mqtt.topics.forEach(topic => {
            mqttClient.subscribe(topic, (err) => {
                if (err) {
                    console.error(`❌ Error suscribiendo a ${topic}:`, err);
                } else {
                    console.log(`📡 Suscrito a: ${topic}`);
                }
            });
        });
    });

    mqttClient.on('message', async (topic, message) => {
        try {
            const data = JSON.parse(message.toString());
            console.log(`📨 Mensaje recibido en ${topic}:`, data);
            
            // Procesar según el tipo de tópico
            if (topic.includes('/sensors')) {
                await processSensorData(data);
            } else if (topic.includes('/alerts')) {
                await processAlert(data);
            } else if (topic.includes('/ml-predictions')) {
                await processMLPrediction(data);
            }
        } catch (error) {
            console.error('❌ Error procesando mensaje:', error);
        }
    });

    mqttClient.on('error', (error) => {
        console.error('❌ Error MQTT:', error);
    });
}

// 🔍 Procesar datos de sensores
async function processSensorData(data) {
    try {
        const { deviceId, lineId, sensors, timestamp } = data;
        
        // 💾 ALMACENAMIENTO LOCAL: PostgreSQL directo (mismo nivel que IoT Edge)
        for (const [sensorType, value] of Object.entries(sensors)) {
            if (typeof value === 'number') {
                await pgClient.query(`
                    INSERT INTO sensor_data (device_id, line_id, sensor_type, value, timestamp)
                    VALUES ($1, $2, $3, $4, $5)
                `, [deviceId, lineId, sensorType, value, timestamp || new Date()]);
            }
        }
        
        console.log(`💾 [LOCAL] PostgreSQL: ${deviceId} guardado (${Object.keys(sensors).length} sensores)`);
        
        // ☁️ ENVÍO CLOUD: IoT Hub vía DPS (cuando hay conectividad)
        await sendToIoTHub('sensor-data', data);
        
    } catch (error) {
        console.error('❌ Error guardando datos de sensor:', error);
    }
}

// 🚨 Procesar alertas
async function processAlert(data) {
    try {
        const { id, lineId, deviceId, type, level, message, confidence, timestamp } = data;
        
        await pgClient.query(`
            INSERT INTO alerts (alert_id, line_id, device_id, alert_type, level, message, confidence, timestamp)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            ON CONFLICT (alert_id) DO UPDATE SET
                level = $5,
                message = $6,
                confidence = $7,
                timestamp = $8
        `, [id, lineId, deviceId, type, level, message, confidence, timestamp || new Date()]);
        
        console.log(`🚨 Alerta guardada: ${type} - ${level} para ${deviceId}`);
        
        // Enviar alertas críticas a IoT Hub para notificación
        if (level === 'HIGH' || level === 'CRITICAL') {
            await sendToIoTHub('alert', data);
        }
        
    } catch (error) {
        console.error('❌ Error guardando alerta:', error);
    }
}

// 🤖 Procesar predicciones ML
async function processMLPrediction(data) {
    try {
        const { deviceId, lineId, type, confidence, recommendation, timestamp } = data;
        
        await pgClient.query(`
            INSERT INTO ml_predictions (device_id, line_id, prediction_type, confidence, recommendation, timestamp)
            VALUES ($1, $2, $3, $4, $5, $6)
        `, [deviceId, lineId, type, confidence, recommendation, timestamp || new Date()]);
        
        console.log(`🤖 Predicción ML guardada: ${type} para ${deviceId} (confianza: ${confidence})`);
        
        // Enviar predicciones de alta confianza a IoT Hub
        if (confidence > 0.8) {
            await sendToIoTHub('ml-prediction', data);
        }
        
    } catch (error) {
        console.error('❌ Error guardando predicción ML:', error);
    }
}

// 📊 Función para obtener estadísticas (para dashboard)
async function getStats() {
    try {
        const stats = await pgClient.query(`
            SELECT 
                COUNT(*) as total_sensors,
                COUNT(DISTINCT device_id) as active_devices,
                COUNT(DISTINCT line_id) as production_lines,
                MAX(timestamp) as last_update
            FROM sensor_data 
            WHERE timestamp > NOW() - INTERVAL '1 hour'
        `);
        
        return stats.rows[0];
    } catch (error) {
        console.error('❌ Error obteniendo estadísticas:', error);
        return null;
    }
}

// 🏁 Inicialización
async function start() {
    console.log('🚀 Iniciando MQTT-PostgreSQL-IoTHub Data Processor...');
    
    await initializeDatabase();
    connectToMQTT();
    
    // Conectar a Azure IoT Hub con DPS
    await connectToIoTHub();
    
    // Endpoint de health check
    const express = require('express');
    const app = express();
    const port = process.env.PORT || 4000;
    
    app.get('/health', async (req, res) => {
        const stats = await getStats();
        res.json({
            status: 'healthy',
            service: 'mqtt-postgres-iot-processor',
            components: {
                mqtt: mqttClient ? mqttClient.connected : false,
                postgresql: pgClient ? true : false,
                iotHub: iotHubClient ? true : false,
                dps: config.dps.enabled
            },
            stats,
            timestamp: new Date()
        });
    });
    
    app.listen(port, () => {
        console.log(`🏥 Health endpoint disponible en puerto ${port}`);
    });
}

// Manejo de cierre graceful
process.on('SIGINT', async () => {
    console.log('🛑 Cerrando conexiones...');
    if (mqttClient) mqttClient.end();
    if (pgClient) await pgClient.end();
    process.exit(0);
});

// Iniciar el procesador
start().catch(console.error);

module.exports = { getStats, processSensorData, processAlert, processMLPrediction };