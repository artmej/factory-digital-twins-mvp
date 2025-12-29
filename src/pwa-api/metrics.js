const { app } = require('@azure/functions');
const { CosmosClient } = require('@azure/cosmos');
const { DefaultAzureCredential } = require('@azure/identity');
const moment = require('moment');

// Cosmos DB configuration with Managed Identity
const credential = new DefaultAzureCredential();
const cosmosClient = new CosmosClient({
    endpoint: process.env.COSMOS_DB_ENDPOINT || "https://smartfactory-prod-cosmos.documents.azure.com:443/",
    aadCredentials: credential
});

const database = cosmosClient.database('smartfactory');
const container = database.container('telemetry');

// Helper function to get metrics data
async function getMetricsData(metric, timeRange, context) {
    context.log(`📈 Getting ${metric} metrics for range: ${timeRange}`);
    
    try {
        // Mock data for now
        const mockMetrics = {
            temperature: [
                { timestamp: new Date(Date.now() - 3600000), value: 41.2 },
                { timestamp: new Date(Date.now() - 1800000), value: 42.1 },
                { timestamp: new Date(), value: 42.3 }
            ],
            efficiency: [
                { timestamp: new Date(Date.now() - 3600000), value: 85.1 },
                { timestamp: new Date(Date.now() - 1800000), value: 86.8 },
                { timestamp: new Date(), value: 87.5 }
            ],
            production: [
                { timestamp: new Date(Date.now() - 3600000), value: 12200 },
                { timestamp: new Date(Date.now() - 1800000), value: 12380 },
                { timestamp: new Date(), value: 12543 }
            ]
        };
        
        return mockMetrics[metric] || [];
        
    } catch (error) {
        context.log.error('❌ Error getting metrics data:', error);
        throw error;
    }
}

app.http('metrics', {
    methods: ['GET'],
    authLevel: 'anonymous',
    route: 'metrics/{metric?}',
    handler: async (request, context) => {
        context.log('📊 Factory Metrics API called');

        try {
            const metric = request.params.metric || 'all';
            const timeRange = request.query.get('range') || '1h';
            
            const metricsData = await getMetricsData(metric, timeRange, context);

            return {
                status: 200,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                jsonBody: {
                    metric,
                    timeRange,
                    data: metricsData,
                    timestamp: new Date().toISOString()
                }
            };

        } catch (error) {
            context.log.error('❌ Metrics API error:', error);
            return {
                status: 500,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                jsonBody: { error: 'Metrics data unavailable', details: error.message }
            };
        }
    }
});