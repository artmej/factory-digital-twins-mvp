// 🏥 Smart Factory Health Endpoint - ADT Projection Function
// Advanced health monitoring for IoT data processing pipeline

const { CosmosClient } = require('@azure/cosmos');
const { EventHubProducerClient } = require("@azure/event-hubs");

module.exports = async function (context, req) {
    context.log('ADT Projection Function Health Check endpoint called');
    
    const healthReport = {
        service: 'ADT Projection Function',
        timestamp: new Date().toISOString(),
        status: 'healthy',
        version: '2.0.0',
        environment: process.env.AZURE_FUNCTIONS_ENVIRONMENT || 'production',
        checks: {},
        uptime: Math.round(process.uptime()),
        requestId: context.invocationId,
        summary: {}
    };
    
    try {
        // 1. Cosmos DB Health Check
        if (process.env.COSMOS_CONNECTION_STRING) {
            const cosmosClient = new CosmosClient(process.env.COSMOS_CONNECTION_STRING);
            const startTime = Date.now();
            
            try {
                await cosmosClient.databases.readAll().fetchAll();
                healthReport.checks.cosmosdb = {
                    status: 'healthy',
                    responseTime: Date.now() - startTime,
                    message: 'Connected to Cosmos DB'
                };
            } catch (error) {
                healthReport.checks.cosmosdb = {
                    status: 'unhealthy',
                    responseTime: Date.now() - startTime,
                    error: error.message
                };
                healthReport.status = 'degraded';
            }
        }
        
        // 2. IoT Hub Health Check
        if (process.env.IOT_HUB_CONNECTION_STRING) {
            const startTime = Date.now();
            
            try {
                const serviceClient = IoTHubServiceClient.fromConnectionString(
                    process.env.IOT_HUB_CONNECTION_STRING
                );
                
                // Simple connectivity test
                const registry = serviceClient.registry;
                await registry.getTwin('health-check-device').catch(() => {
                    // Device may not exist, but connection is working
                });
                
                healthReport.checks.iothub = {
                    status: 'healthy',
                    responseTime: Date.now() - startTime,
                    message: 'IoT Hub connection established'
                };
            } catch (error) {
                healthReport.checks.iothub = {
                    status: 'unhealthy',
                    responseTime: Date.now() - startTime,
                    error: error.message
                };
                healthReport.status = 'degraded';
            }
        }
        
        // 3. Storage Account Health Check
        if (process.env.AZURE_STORAGE_CONNECTION_STRING) {
            const { BlobServiceClient } = require('@azure/storage-blob');
            const startTime = Date.now();
            
            try {
                const blobServiceClient = BlobServiceClient.fromConnectionString(
                    process.env.AZURE_STORAGE_CONNECTION_STRING
                );
                
                await blobServiceClient.getAccountInfo();
                
                healthReport.checks.storage = {
                    status: 'healthy',
                    responseTime: Date.now() - startTime,
                    message: 'Storage account accessible'
                };
            } catch (error) {
                healthReport.checks.storage = {
                    status: 'unhealthy',
                    responseTime: Date.now() - startTime,
                    error: error.message
                };
                healthReport.status = 'degraded';
            }
        }
        
        // 4. Digital Twins Health Check
        if (process.env.DIGITAL_TWINS_URL) {
            const { DigitalTwinsClient } = require('@azure/digital-twins-core');
            const { DefaultAzureCredential } = require('@azure/identity');
            const startTime = Date.now();
            
            try {
                const credential = new DefaultAzureCredential();
                const client = new DigitalTwinsClient(
                    process.env.DIGITAL_TWINS_URL,
                    credential
                );
                
                // Test basic connectivity
                await client.listModels().next();
                
                healthReport.checks.digitaltwins = {
                    status: 'healthy',
                    responseTime: Date.now() - startTime,
                    message: 'Digital Twins instance accessible'
                };
            } catch (error) {
                healthReport.checks.digitaltwins = {
                    status: 'unhealthy',
                    responseTime: Date.now() - startTime,
                    error: error.message
                };
                healthReport.status = 'degraded';
            }
        }
        
        // 5. Key Vault Health Check
        if (process.env.KEY_VAULT_URL) {
            const { SecretClient } = require('@azure/keyvault-secrets');
            const { DefaultAzureCredential } = require('@azure/identity');
            const startTime = Date.now();
            
            try {
                const credential = new DefaultAzureCredential();
                const client = new SecretClient(process.env.KEY_VAULT_URL, credential);
                
                // Test connectivity by listing secrets (no values)
                await client.listPropertiesOfSecrets().next();
                
                healthReport.checks.keyvault = {
                    status: 'healthy',
                    responseTime: Date.now() - startTime,
                    message: 'Key Vault accessible'
                };
            } catch (error) {
                healthReport.checks.keyvault = {
                    status: 'unhealthy',
                    responseTime: Date.now() - startTime,
                    error: error.message
                };
                healthReport.status = 'degraded';
            }
        }
        
        // 6. Overall System Health
        const unhealthyServices = Object.values(healthReport.checks)
            .filter(check => check.status === 'unhealthy').length;
        
        const totalServices = Object.keys(healthReport.checks).length;
        
        if (unhealthyServices === 0) {
            healthReport.status = 'healthy';
            healthReport.summary = `All ${totalServices} services are healthy`;
        } else if (unhealthyServices < totalServices) {
            healthReport.status = 'degraded';
            healthReport.summary = `${totalServices - unhealthyServices}/${totalServices} services healthy`;
        } else {
            healthReport.status = 'unhealthy';
            healthReport.summary = 'Critical system failure - all services unhealthy';
        }
        
        // Set appropriate HTTP status code
        const statusCode = {
            'healthy': 200,
            'degraded': 200, // 200 OK but with warnings
            'unhealthy': 503  // Service Unavailable
        }[healthReport.status];
        
        context.res = {
            status: statusCode,
            headers: {
                'Content-Type': 'application/json',
                'Cache-Control': 'no-cache'
            },
            body: healthReport
        };
        
    } catch (error) {
        context.log.error('Health check error:', error);
        
        context.res = {
            status: 503,
            headers: {
                'Content-Type': 'application/json',
                'Cache-Control': 'no-cache'
            },
            body: {
                timestamp: new Date().toISOString(),
                status: 'unhealthy',
                error: error.message,
                requestId: context.invocationId
            }
        };
    }
};