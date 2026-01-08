const { DefaultAzureCredential } = require('@azure/identity');
const { DigitalTwinsClient } = require('@azure/digital-twins-core');

module.exports = async function (context, iotHubMessage) {
    context.log('Processing IoT Hub message:', JSON.stringify(iotHubMessage));
    
    try {
        // Initialize Azure Digital Twins client
        const credential = new DefaultAzureCredential();
        const serviceUrl = process.env.AZURE_DIGITALTWINS_URL;
        const client = new DigitalTwinsClient(serviceUrl, credential);
        
        // Extract device data from IoT Hub message
        const deviceId = context.bindingData.systemProperties['iothub-connection-device-id'];
        const messageBody = iotHubMessage;
        const enqueuedTime = context.bindingData.systemProperties['iothub-enqueuedtime'];
        
        context.log(`Processing data from device: ${deviceId}`);
        context.log('Message body:', messageBody);
        
        // Save telemetry data to Cosmos DB first
        await saveTelemetryData(context, deviceId, messageBody, enqueuedTime);
        
        // Determine twin type based on device ID or message content
        let digitalTwinId;
        let twinData = {};
        
        if (deviceId.includes('machine')) {
            digitalTwinId = `machine-${deviceId}`;
            twinData = await processMachineTelemetry(messageBody, context);
        } else if (deviceId.includes('sensor')) {
            digitalTwinId = `sensor-${deviceId}`;
            twinData = await processSensorTelemetry(messageBody, context);
        } else if (deviceId.includes('line')) {
            digitalTwinId = `line-${deviceId}`;
            twinData = await processLineTelemetry(messageBody, context);
        } else {
            // Default to factory-level data
            digitalTwinId = `factory-${deviceId}`;
            twinData = await processFactoryTelemetry(messageBody, context);
        }
        
        // Update digital twin
        await updateDigitalTwin(client, digitalTwinId, twinData, context);
        
        // Check for alerts based on thresholds
        await processAlerts(context, deviceId, messageBody, enqueuedTime);
        
        context.log(`Successfully processed data for device: ${deviceId}`);
        
    } catch (error) {
        context.log.error('Error processing IoT Hub message:', error);
        throw error;
    }
};

async function processMachineTelemetry(messageBody, context) {
    return {
        temperature: messageBody.temperature || 0,
        pressure: messageBody.pressure || 0,
        vibration: messageBody.vibration || 0,
        oee: messageBody.oee || 0,
        status: messageBody.status || 'unknown'
    };
}

async function processSensorTelemetry(messageBody, context) {
    return {
        value: messageBody.value || 0,
        timestamp: messageBody.timestamp || new Date().toISOString(),
        isActive: messageBody.isActive || true
    };
}

async function processLineTelemetry(messageBody, context) {
    return {
        throughput: messageBody.throughput || 0,
        quality: messageBody.quality || 0,
        efficiency: messageBody.efficiency || 0,
        status: messageBody.status || 'unknown'
    };
}

async function processFactoryTelemetry(messageBody, context) {
    return {
        overallEfficiency: messageBody.overallEfficiency || 0,
        energyConsumption: messageBody.energyConsumption || 0
    };
}

async function updateDigitalTwin(client, digitalTwinId, twinData, context) {
    try {
        // Create patch document for digital twin update
        const patch = [];
        
        for (const [key, value] of Object.entries(twinData)) {
            patch.push({
                op: 'replace',
                path: `/${key}`,
                value: value
            });
        }
        
        context.log(`Updating twin ${digitalTwinId} with patch:`, JSON.stringify(patch));
        
        // Update the digital twin
        await client.updateDigitalTwin(digitalTwinId, patch);
        
        context.log(`Successfully updated digital twin: ${digitalTwinId}`);
        
    } catch (error) {
        if (error.code === 'DigitalTwinNotFound') {
            context.log(`Digital twin ${digitalTwinId} not found. Creating new twin.`);
            await createDigitalTwin(client, digitalTwinId, twinData, context);
        } else {
            throw error;
        }
    }
}

async function createDigitalTwin(client, digitalTwinId, twinData, context) {
    try {
        // Determine model ID based on twin type
        let modelId;
        if (digitalTwinId.includes('machine')) {
            modelId = 'dtmi:smartfactory:Machine;1';
        } else if (digitalTwinId.includes('sensor')) {
            modelId = 'dtmi:smartfactory:Sensor;1';
        } else if (digitalTwinId.includes('line')) {
            modelId = 'dtmi:smartfactory:Line;1';
        } else {
            modelId = 'dtmi:smartfactory:Factory;1';
        }
        
        const digitalTwin = {
            $metadata: {
                $model: modelId
            },
            ...twinData
        };
        
        context.log(`Creating new digital twin ${digitalTwinId} with model ${modelId}`);
        
        await client.createDigitalTwin(digitalTwinId, digitalTwin);
        
        context.log(`Successfully created digital twin: ${digitalTwinId}`);
        
    } catch (error) {
        context.log.error(`Error creating digital twin ${digitalTwinId}:`, error);
        // Don't throw error for Digital Twins failures - continue with Cosmos DB saves
    }
}

async function saveTelemetryData(context, deviceId, messageBody, enqueuedTime) {
    try {
        // Create telemetry record compatible with API schema
        const telemetryRecord = {
            id: `${deviceId}_${Date.now()}`,
            deviceId: deviceId,
            timestamp: enqueuedTime || new Date().toISOString(),
            sensorData: messageBody,
            messageId: context.bindingData.systemProperties['iothub-message-id'],
            partitionKey: deviceId, // Using deviceId as partition key
            ttl: 2592000 // 30 days retention
        };
        
        // Save to Cosmos DB TelemetryData container
        context.bindings.telemetryOut = telemetryRecord;
        
        context.log(`Saved telemetry data for device ${deviceId} to Cosmos DB`);
        
    } catch (error) {
        context.log.error(`Error saving telemetry data: ${error}`);
        throw error;
    }
}

async function processAlerts(context, deviceId, messageBody, enqueuedTime) {
    try {
        const alerts = [];
        
        // Check temperature thresholds
        if (messageBody.temperature && messageBody.temperature > 85) {
            alerts.push(createAlert(deviceId, 'threshold-violation', 'critical', 
                `High temperature alert: ${messageBody.temperature}°C`, enqueuedTime));
        }
        
        // Check pressure thresholds  
        if (messageBody.pressure && messageBody.pressure > 100) {
            alerts.push(createAlert(deviceId, 'threshold-violation', 'warning',
                `High pressure alert: ${messageBody.pressure} PSI`, enqueuedTime));
        }
        
        // Check vibration thresholds
        if (messageBody.vibration && messageBody.vibration > 5) {
            alerts.push(createAlert(deviceId, 'anomaly-detection', 'warning',
                `High vibration detected: ${messageBody.vibration}`, enqueuedTime));
        }
        
        // Check OEE thresholds
        if (messageBody.oee && messageBody.oee < 0.7) {
            alerts.push(createAlert(deviceId, 'efficiency-decline', 'warning',
                `Low OEE detected: ${(messageBody.oee * 100).toFixed(1)}%`, enqueuedTime));
        }
        
        // Save alerts to Cosmos DB if any
        if (alerts.length > 0) {
            context.bindings.alertsOut = alerts;
            context.log(`Generated ${alerts.length} alerts for device ${deviceId}`);
        }
        
    } catch (error) {
        context.log.error(`Error processing alerts: ${error}`);
    }
}

function createAlert(deviceId, type, severity, message, timestamp) {
    return {
        id: `${deviceId}_${type}_${Date.now()}`,
        alertId: `alert-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        machineId: deviceId,
        deviceId: deviceId,
        type: type,
        severity: severity,
        message: message,
        timestamp: timestamp || new Date().toISOString(),
        acknowledged: false,
        status: 'active',
        partitionKey: deviceId // Using deviceId as partition key for alerts
    };
}