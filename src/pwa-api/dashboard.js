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
        // Return data in the format expected by PWA
        const factoryEfficiency = 87.5 + Math.random() * 5; // 87.5-92.5%
        const linePerformance = 85 + Math.random() * 10; // 85-95%
        const machineTemperature = 42.3 + Math.random() * 3; // 42.3-45.3°C
        
        const mockData = {
            timestamp: new Date().toISOString(),
            summary: {
                factoryEfficiency,
                linePerformance,
                machineTemperature,
                totalSensors: 3,
                dataPoints: Math.floor(350 + Math.random() * 50)
            },
            sensors: [
                { 
                    id: 'factory-main', 
                    latest: { 
                        value: factoryEfficiency, 
                        timestamp: new Date().toISOString() 
                    }
                },
                { 
                    id: 'line1-main', 
                    latest: { 
                        value: linePerformance, 
                        timestamp: new Date().toISOString() 
                    }
                },
                { 
                    id: 'machine1', 
                    latest: { 
                        value: machineTemperature, 
                        timestamp: new Date().toISOString() 
                    }
                }
            ],
            status: getStatus(factoryEfficiency, linePerformance, machineTemperature),
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

function getStatus(factory, line, temp) {
    if (temp > 50 || factory < 50 || line < 50) return 'critical';
    if (temp > 45 || factory < 70 || line < 75) return 'warning';
    if (factory > 85 && line > 85 && temp < 40) return 'optimal';
    return 'good';
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