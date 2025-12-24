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
        
        context.log(`Processing data from device: ${deviceId}`);
        context.log('Message body:', messageBody);
        
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
        
        context.log(`Successfully updated digital twin: ${digitalTwinId}`);
        
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
        throw error;
    }
}