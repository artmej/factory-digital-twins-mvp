const { app } = require('@azure/functions');
const { OpenAIClient, AzureKeyCredential } = require('@azure/openai');
const moment = require('moment');

// Azure OpenAI configuration
const openAIClient = new OpenAIClient(
    process.env.OPENAI_ENDPOINT,
    new AzureKeyCredential(process.env.OPENAI_API_KEY)
);

/**
 * AI Analysis Function - Processes Smart Factory telemetry data
 * Triggered directly by IoT Hub messages
 */
app.eventHub('aiAnalysisProcessor', {
    connection: 'IOT_HUB_EVENTS_CONNECTION',
    eventHubName: 'iothub-ehub-smartfactory-iothub-prod',
    consumerGroup: '$Default',
    cardinality: 'many',
    handler: async (messages, context) => {
        context.log('🧠 AI Analysis Function triggered with', messages.length, 'IoT Hub messages');

        for (const message of messages) {
            try {
                // IoT Hub messages come with metadata
                const telemetryData = typeof message.body === 'string' ? JSON.parse(message.body) : message.body;
                const deviceId = message.systemProperties['iothub-connection-device-id'];
                
                context.log('📊 Processing telemetry from device:', deviceId, telemetryData);

                // Perform AI analysis
                const analysis = await performAIAnalysis(telemetryData, deviceId, context);
                
                // Store analysis results or trigger actions
                await processAnalysisResults(analysis, telemetryData, deviceId, context);
                
            } catch (error) {
                context.log.error('❌ Error processing IoT Hub message:', error);
            }
        }
    }
});

/**
 * Factory Insights API - Provides conversational AI interface
 * HTTP triggered function for querying factory insights
 */
app.http('factoryInsights', {
    methods: ['POST'],
    authLevel: 'function',
    handler: async (request, context) => {
        context.log('💬 Factory Insights API called');

        try {
            const requestBody = await request.json();
            const { question, timeRange } = requestBody;

            if (!question) {
                return {
                    status: 400,
                    jsonBody: { error: 'Question is required' }
                };
            }

            // Get factory context data
            const factoryContext = await getFactoryContext(timeRange, context);
            
            // Generate AI response
            const aiResponse = await generateInsightResponse(question, factoryContext, context);

            return {
                status: 200,
                jsonBody: {
                    question: question,
                    answer: aiResponse,
                    timestamp: moment().toISOString(),
                    context: 'Smart Factory AI Assistant'
                }
            };

        } catch (error) {
            context.log.error('❌ Error in Factory Insights:', error);
            return {
                status: 500,
                jsonBody: { error: 'Internal server error' }
            };
        }
    }
});

/**
 * Predictive Maintenance Function - Analyzes machine health
 * Timer triggered function for proactive maintenance insights
 */
app.timer('predictiveMaintenance', {
    schedule: '0 */30 * * * *', // Every 30 minutes
    handler: async (myTimer, context) => {
        context.log('🔧 Predictive Maintenance Analysis starting...');

        try {
            // Get recent machine data
            const machineData = await getMachineHealthData(context);
            
            // Perform predictive analysis
            const predictions = await performPredictiveAnalysis(machineData, context);
            
            // Check for maintenance alerts
            const alerts = filterMaintenanceAlerts(predictions);
            
            if (alerts.length > 0) {
                context.log('⚠️ Maintenance alerts detected:', alerts.length);
                await sendMaintenanceAlerts(alerts, context);
            }

            context.log('✅ Predictive Maintenance Analysis completed');
            
        } catch (error) {
            context.log.error('❌ Error in Predictive Maintenance:', error);
        }
    }
});

// Helper Functions

async function performAIAnalysis(telemetryData, deviceId, context) {
    try {
        const prompt = `
        Analyze this Smart Factory telemetry data and provide insights:
        
        Device: ${deviceId}
        Sensor: ${telemetryData.sensorId}
        Value: ${telemetryData.value}
        Timestamp: ${telemetryData.timestamp}
        Digital Twin Type: ${telemetryData.dtmiType}
        
        Provide analysis on:
        1. Is this value within normal operating ranges?
        2. Any trends or anomalies detected?
        3. Recommended actions if any?
        
        Keep the response concise and actionable.
        `;

        const response = await openAIClient.getChatCompletions(
            'gpt-4o',
            [
                {
                    role: 'system',
                    content: 'You are a Smart Factory AI assistant specializing in industrial IoT analytics and predictive maintenance.'
                },
                {
                    role: 'user',
                    content: prompt
                }
            ],
            {
                maxTokens: 500,
                temperature: 0.3
            }
        );

        return response.choices[0].message.content;

    } catch (error) {
        context.log.error('❌ Error in AI analysis:', error);
        return 'Analysis unavailable';
    }
}

async function generateInsightResponse(question, factoryContext, context) {
    try {
        const prompt = `
        You are a Smart Factory AI Assistant. Answer the following question using the provided factory context data:
        
        Question: ${question}
        
        Factory Context:
        ${JSON.stringify(factoryContext, null, 2)}
        
        Provide a comprehensive, data-driven answer that includes:
        - Direct answer to the question
        - Supporting data from the context
        - Actionable recommendations if applicable
        
        Keep the response professional and focused on Smart Factory operations.
        `;

        const response = await openAIClient.getChatCompletions(
            'gpt-4o',
            [
                {
                    role: 'system',
                    content: 'You are an expert Smart Factory AI assistant with deep knowledge of industrial operations, IoT systems, and predictive analytics.'
                },
                {
                    role: 'user',
                    content: prompt
                }
            ],
            {
                maxTokens: 1000,
                temperature: 0.2
            }
        );

        return response.choices[0].message.content;

    } catch (error) {
        context.log.error('❌ Error generating insight response:', error);
        return 'I apologize, but I cannot provide an answer at this time. Please try again later.';
    }
}

async function performPredictiveAnalysis(machineData, context) {
    try {
        const prompt = `
        Analyze this machine health data for predictive maintenance insights:
        
        ${JSON.stringify(machineData, null, 2)}
        
        For each machine, assess:
        1. Overall health status (Good/Warning/Critical)
        2. Predicted maintenance needs in next 30 days
        3. Risk factors and early warning indicators
        4. Specific component conditions
        
        Return results as JSON with structure:
        {
          "machineId": {
            "healthStatus": "status",
            "maintenanceNeeded": boolean,
            "riskFactors": ["factor1", "factor2"],
            "recommendations": ["rec1", "rec2"]
          }
        }
        `;

        const response = await openAIClient.getChatCompletions(
            'gpt-4o',
            [
                {
                    role: 'system',
                    content: 'You are a predictive maintenance AI specialist for industrial equipment. Respond only with valid JSON.'
                },
                {
                    role: 'user',
                    content: prompt
                }
            ],
            {
                maxTokens: 800,
                temperature: 0.1
            }
        );

        return JSON.parse(response.choices[0].message.content);

    } catch (error) {
        context.log.error('❌ Error in predictive analysis:', error);
        return {};
    }
}

// Mock data functions (replace with real data sources)
async function getFactoryContext(timeRange, context) {
    // This would connect to your actual data sources
    return {
        totalSensors: 3,
        timeRange: timeRange || 'last 1 hour',
        averageEfficiency: 89.5,
        activeMachines: 1,
        lastDataUpdate: moment().toISOString()
    };
}

async function getMachineHealthData(context) {
    // This would connect to your PostgreSQL/Digital Twins
    return {
        machine1: {
            temperature: 26.7,
            efficiency: 87.9,
            lastMaintenance: '2024-12-01',
            operatingHours: 2840
        }
    };
}

async function processAnalysisResults(analysis, telemetryData, deviceId, context) {
    context.log('📈 Analysis result for', deviceId, ':', analysis);
    
    // Store analysis in database, send alerts, update Digital Twins, etc.
    // This could integrate with your existing Digital Twins instance
    
    // Example: Send alert if critical issue detected
    if (analysis.includes('critical') || analysis.includes('urgent') || analysis.includes('immediate')) {
        context.log('🚨 Critical issue detected, sending alert...');
        // Send to notification system
    }
}

function filterMaintenanceAlerts(predictions) {
    return Object.entries(predictions)
        .filter(([machineId, data]) => data.maintenanceNeeded)
        .map(([machineId, data]) => ({ machineId, ...data }));
}

async function sendMaintenanceAlerts(alerts, context) {
    context.log('📧 Sending maintenance alerts:', alerts.length);
    // Send to Event Hub, Teams, email, etc.
}