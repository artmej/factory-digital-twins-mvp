const { DigitalTwinsClient } = require('@azure/digital-twins-core');
const { DefaultAzureCredential } = require('@azure/identity');

// Initialize Digital Twins client
let dtClient;

const initializeClient = () => {
  if (!dtClient) {
    const digitalTwinsUrl = process.env.DIGITAL_TWINS_URL;
    if (!digitalTwinsUrl) {
      throw new Error('DIGITAL_TWINS_URL environment variable is not set');
    }
    
    const credential = new DefaultAzureCredential();
    dtClient = new DigitalTwinsClient(digitalTwinsUrl, credential);
  }
  return dtClient;
};

// Helper function to safely update twin property
const updateTwinProperty = async (twinId, propertyName, value, context) => {
  try {
    if (value === null || value === undefined) {
      context.log.warn(`Skipping property update for ${twinId}.${propertyName} - value is null/undefined`);
      return;
    }

    const patch = [
      {
        op: 'replace',
        path: `/${propertyName}`,
        value: value
      }
    ];

    await dtClient.updateDigitalTwin(twinId, patch);
    context.log.info(`Updated ${twinId}.${propertyName} = ${value}`);
  } catch (error) {
    context.log.error(`Failed to update property ${twinId}.${propertyName}:`, error.message);
  }
};

// Helper function to publish telemetry
const publishTelemetry = async (twinId, telemetryName, value, messageId, timestamp, context) => {
  try {
    if (value === null || value === undefined) {
      context.log.warn(`Skipping telemetry for ${twinId}.${telemetryName} - value is null/undefined`);
      return;
    }

    const telemetryPayload = {
      [telemetryName]: value
    };

    await dtClient.publishTelemetry(twinId, telemetryPayload, {
      messageId: messageId,
      timestamp: timestamp
    });
    
    context.log.info(`Published telemetry ${twinId}.${telemetryName} = ${value}`);
  } catch (error) {
    context.log.error(`Failed to publish telemetry ${twinId}.${telemetryName}:`, error.message);
  }
};

// Main function
module.exports = async function (context, messages) {
  context.log.info(`Processing ${messages.length} messages`);
  
  try {
    // Initialize Digital Twins client
    const client = initializeClient();
    
    // Process each message
    for (const message of messages) {
      try {
        context.log.info('Processing message:', JSON.stringify(message));
        
        // Parse message data
        const data = typeof message === 'string' ? JSON.parse(message) : message;
        
        // Extract required fields
        const {
          lineId,
          machineId,
          sensorId,
          throughput,
          temperature,
          value,
          state,
          oee,
          health,
          ts
        } = data;
        
        const timestamp = new Date(ts || new Date().toISOString());
        const messageId = `msg-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
        
        // Update line properties and telemetry
        if (lineId) {
          if (oee !== undefined) {
            await updateTwinProperty(lineId, 'oee', oee, context);
          }
          if (state !== undefined) {
            await updateTwinProperty(lineId, 'state', state, context);
          }
          if (throughput !== undefined) {
            await publishTelemetry(lineId, 'throughput', throughput, messageId, timestamp, context);
          }
        }
        
        // Update machine properties and telemetry
        if (machineId) {
          if (health !== undefined) {
            await updateTwinProperty(machineId, 'health', health, context);
          }
          if (temperature !== undefined) {
            await publishTelemetry(machineId, 'temperature', temperature, messageId, timestamp, context);
          }
        }
        
        // Publish sensor telemetry
        if (sensorId && value !== undefined) {
          await publishTelemetry(sensorId, 'value', value, messageId, timestamp, context);
        }
        
      } catch (messageError) {
        context.log.error('Error processing individual message:', messageError.message);
        context.log.error('Message data:', JSON.stringify(message));
      }
    }
    
  } catch (error) {
    context.log.error('Critical error in function execution:', error.message);
    throw error;
  }
};