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

// Helper function to get factory dashboard data
async function getFactoryDashboardData(timeRange, context) {
    context.log(`📊 Getting factory data for range: ${timeRange}`);
    
    try {
        // For now, return mock data since we're focusing on API structure
        // This will be replaced with real Cosmos DB queries
        const mockData = {
            factoryEfficiency: 87.5,
            totalProduction: 12543,
            activeLines: 8,
            totalLines: 10,
            temperature: 42.3,
            alerts: [],
            lastUpdated: new Date().toISOString(),
            systemStatus: "operational"
        };
        
        context.log('✅ Factory dashboard data retrieved successfully');
        return mockData;
        
    } catch (error) {
        context.log.error('❌ Error getting dashboard data:', error);
        throw error;
    }
}

app.http('dashboard', {
    methods: ['GET'],
    authLevel: 'anonymous', // Changed to anonymous for testing
    route: 'dashboard',
    handler: async (request, context) => {
        context.log('📱 Factory Dashboard API called');

        try {
            const timeRange = request.query.get('range') || '1h';
            const dashboardData = await getFactoryDashboardData(timeRange, context);

            return {
                status: 200,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                jsonBody: dashboardData
            };

        } catch (error) {
            context.log.error('❌ Dashboard API error:', error);
            return {
                status: 500,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                jsonBody: { error: 'Dashboard data unavailable', details: error.message }
            };
        }
    }
});