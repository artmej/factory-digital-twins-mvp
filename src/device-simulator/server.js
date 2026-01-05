const express = require('express');
const path = require('path');
const os = require('os');

const app = express();
const port = process.env.PORT || 3000;

// Middleware for JSON parsing
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Initialize global simulation state
global.simulationActive = false;
global.activeDevices = [];
global.lastSimulationUpdate = new Date().toISOString();
global.totalMessages = 0;
global.messagesPerSecond = 0;

// 🏥 Health Endpoints
const healthEndpoints = require('./health');
healthEndpoints(app);

// Legacy health endpoint (for backward compatibility)
app.get('/api/health', async (req, res) => {
    const healthReport = {
        timestamp: new Date().toISOString(),
        status: 'healthy',
        version: '1.0.0',
        environment: process.env.NODE_ENV || 'development',
        checks: {},
        uptime: process.uptime(),
        requestId: req.headers['x-request-id'] || Date.now().toString(),
        server: {
            hostname: os.hostname(),
            platform: os.platform(),
            arch: os.arch(),
            nodeVersion: process.version,
            memory: process.memoryUsage(),
            loadAverage: os.loadavg()
        }
    };

    try {
        // 1. Basic System Health
        healthReport.checks.system = {
            status: 'healthy',
            message: 'System resources available',
            memory: {
                used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
                total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
                unit: 'MB'
            },
            cpu: {
                loadAverage: os.loadavg()[0].toFixed(2),
                cores: os.cpus().length
            }
        };

        // 2. Network Connectivity Test
        const startTime = Date.now();
        try {
            // Test external connectivity
            const response = await fetch('https://jsonplaceholder.typicode.com/posts/1', {
                method: 'GET',
                timeout: 5000
            });
            
            healthReport.checks.network = {
                status: 'healthy',
                responseTime: Date.now() - startTime,
                message: 'External connectivity working',
                testEndpoint: 'jsonplaceholder.typicode.com'
            };
        } catch (error) {
            healthReport.checks.network = {
                status: 'degraded',
                responseTime: Date.now() - startTime,
                error: error.message,
                message: 'External connectivity issues detected'
            };
            healthReport.status = 'degraded';
        }

        // 3. Environment Variables Check
        const requiredEnvVars = [
            'COSMOS_CONNECTION_STRING',
            'IOT_HUB_CONNECTION_STRING',
            'DIGITAL_TWINS_URL'
        ];

        const missingEnvVars = requiredEnvVars.filter(env => !process.env[env]);
        
        healthReport.checks.configuration = {
            status: missingEnvVars.length === 0 ? 'healthy' : 'degraded',
            message: missingEnvVars.length === 0 
                ? 'All required environment variables present'
                : `Missing environment variables: ${missingEnvVars.join(', ')}`,
            requiredVars: requiredEnvVars.length,
            configuredVars: requiredEnvVars.length - missingEnvVars.length
        };

        if (missingEnvVars.length > 0) {
            healthReport.status = 'degraded';
        }

        // 4. Disk Space Check
        try {
            const fs = require('fs').promises;
            const stats = await fs.stat(__dirname);
            
            healthReport.checks.storage = {
                status: 'healthy',
                message: 'Application files accessible',
                path: __dirname,
                accessible: true
            };
        } catch (error) {
            healthReport.checks.storage = {
                status: 'unhealthy',
                error: error.message,
                message: 'Application storage issues'
            };
            healthReport.status = 'unhealthy';
        }

        // 5. Function App Health (if available)
        if (process.env.FUNCTION_APP_URL) {
            const functionStartTime = Date.now();
            try {
                const functionResponse = await fetch(`${process.env.FUNCTION_APP_URL}/api/health`, {
                    method: 'GET',
                    timeout: 10000
                });
                
                if (functionResponse.ok) {
                    healthReport.checks.functionapp = {
                        status: 'healthy',
                        responseTime: Date.now() - functionStartTime,
                        message: 'Function App health endpoint accessible'
                    };
                } else {
                    healthReport.checks.functionapp = {
                        status: 'degraded',
                        responseTime: Date.now() - functionStartTime,
                        message: `Function App returned ${functionResponse.status}`
                    };
                    healthReport.status = 'degraded';
                }
            } catch (error) {
                healthReport.checks.functionapp = {
                    status: 'unhealthy',
                    responseTime: Date.now() - functionStartTime,
                    error: error.message,
                    message: 'Function App not accessible'
                };
                healthReport.status = 'degraded';
            }
        }

        // Overall health calculation
        const checks = Object.values(healthReport.checks);
        const unhealthyCount = checks.filter(c => c.status === 'unhealthy').length;
        const degradedCount = checks.filter(c => c.status === 'degraded').length;
        
        if (unhealthyCount > 0) {
            healthReport.status = 'unhealthy';
            healthReport.summary = `${unhealthyCount} critical issues detected`;
        } else if (degradedCount > 0) {
            healthReport.status = 'degraded';
            healthReport.summary = `${degradedCount} warnings detected`;
        } else {
            healthReport.status = 'healthy';
            healthReport.summary = `All ${checks.length} checks passed`;
        }

        // Set appropriate status code
        const statusCode = healthReport.status === 'unhealthy' ? 503 : 200;

        res.status(statusCode).json(healthReport);

    } catch (error) {
        console.error('Health check error:', error);
        
        res.status(503).json({
            timestamp: new Date().toISOString(),
            status: 'unhealthy',
            error: error.message,
            requestId: req.headers['x-request-id'] || Date.now().toString()
        });
    }
});

// 📊 Metrics endpoint
app.get('/api/metrics', (req, res) => {
    const metrics = {
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        cpu: {
            loadAverage: os.loadavg(),
            cores: os.cpus().length
        },
        system: {
            hostname: os.hostname(),
            platform: os.platform(),
            arch: os.arch(),
            nodeVersion: process.version,
            totalMemory: os.totalmem(),
            freeMemory: os.freemem()
        }
    };
    
    res.json(metrics);
});

// 🔍 Ready endpoint (for Kubernetes-style readiness probes)
app.get('/api/ready', (req, res) => {
    // Simple readiness check
    res.json({
        timestamp: new Date().toISOString(),
        status: 'ready',
        message: 'Application is ready to serve requests'
    });
});

// 💓 Live endpoint (for Kubernetes-style liveness probes)
app.get('/api/live', (req, res) => {
    res.json({
        timestamp: new Date().toISOString(),
        status: 'alive',
        uptime: process.uptime()
    });
});

// Default route to health dashboard
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'health.html'));
});

app.listen(port, () => {
    console.log(`🏭 Smart Factory Web App running on port ${port}`);
    console.log(`🏥 Health dashboard: http://localhost:${port}/`);
    console.log(`🔍 Health API: http://localhost:${port}/api/health`);
});

module.exports = app;