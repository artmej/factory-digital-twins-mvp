const { CosmosClient } = require('@azure/cosmos');
const { BlobServiceClient } = require('@azure/storage-blob');

module.exports = async function (context, req) {
    context.log('Smart Factory Web App Health Check endpoint called');
    
    const healthStatus = {
        service: 'Smart Factory Web App',
        timestamp: new Date().toISOString(),
        status: 'healthy',
        version: '2.0.0',
        environment: process.env.NODE_ENV || 'production',
        checks: {}
    };

    try {
        // Check 1: Basic application health
        healthStatus.checks.application = {
            status: 'healthy',
            responseTime: Date.now()
        };

        // Check 2: Cosmos DB connectivity
        try {
            if (process.env.COSMOS_CONNECTION_STRING) {
                const client = new CosmosClient(process.env.COSMOS_CONNECTION_STRING);
                const { database } = await client.databases.createIfNotExists({ id: 'smartfactory' });
                
                healthStatus.checks.cosmosDb = {
                    status: 'healthy',
                    database: 'smartfactory',
                    connected: true
                };
            } else {
                healthStatus.checks.cosmosDb = {
                    status: 'warning',
                    message: 'Connection string not configured'
                };
            }
        } catch (cosmosError) {
            healthStatus.checks.cosmosDb = {
                status: 'unhealthy',
                error: cosmosError.message
            };
            healthStatus.status = 'degraded';
        }

        // Check 3: Storage Account connectivity
        try {
            if (process.env.STORAGE_CONNECTION_STRING) {
                const blobServiceClient = BlobServiceClient.fromConnectionString(
                    process.env.STORAGE_CONNECTION_STRING
                );
                const serviceProps = await blobServiceClient.getProperties();
                
                healthStatus.checks.storageAccount = {
                    status: 'healthy',
                    connected: true,
                    sku: serviceProps.sku
                };
            } else {
                healthStatus.checks.storageAccount = {
                    status: 'warning',
                    message: 'Storage connection string not configured'
                };
            }
        } catch (storageError) {
            healthStatus.checks.storageAccount = {
                status: 'unhealthy',
                error: storageError.message
            };
            healthStatus.status = 'degraded';
        }

        // Check 4: Application Insights connectivity
        if (process.env.APPLICATIONINSIGHTS_CONNECTION_STRING) {
            healthStatus.checks.applicationInsights = {
                status: 'healthy',
                connected: true
            };
        } else {
            healthStatus.checks.applicationInsights = {
                status: 'warning',
                message: 'Application Insights not configured'
            };
        }

        // Check 5: Memory and performance
        const memoryUsage = process.memoryUsage();
        healthStatus.checks.performance = {
            status: 'healthy',
            memory: {
                used: Math.round(memoryUsage.heapUsed / 1024 / 1024),
                total: Math.round(memoryUsage.heapTotal / 1024 / 1024),
                unit: 'MB'
            },
            uptime: Math.round(process.uptime())
        };

        // Overall health assessment
        const unhealthyChecks = Object.values(healthStatus.checks).filter(check => check.status === 'unhealthy');
        if (unhealthyChecks.length > 0) {
            healthStatus.status = 'unhealthy';
        } else if (Object.values(healthStatus.checks).some(check => check.status === 'warning')) {
            healthStatus.status = 'degraded';
        }

    } catch (error) {
        context.log.error('Health check failed:', error);
        healthStatus.status = 'unhealthy';
        healthStatus.error = error.message;
    }

    // Set appropriate HTTP status code
    const statusCode = healthStatus.status === 'healthy' ? 200 : 
                      healthStatus.status === 'degraded' ? 200 : 503;

    context.res = {
        status: statusCode,
        headers: {
            'Content-Type': 'application/json',
            'Cache-Control': 'no-cache'
        },
        body: healthStatus
    };
};