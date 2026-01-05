// 🏥 Smart Factory Device Simulator - Health Endpoint
// Real-time health monitoring for IoT device simulation

const express = require('express');
const { IoTHubServiceClient } = require('@azure/iothub');

module.exports = (app) => {
    app.get('/health', async (req, res) => {
        console.log('Device Simulator Health Check endpoint called');
        
        const healthStatus = {
            service: 'Smart Factory Device Simulator',
            timestamp: new Date().toISOString(),
            status: 'healthy',
            version: '2.0.0',
            environment: process.env.NODE_ENV || 'production',
            checks: {},
            simulation: {}
        };

        try {
            // Check 1: Application runtime health
            const memoryUsage = process.memoryUsage();
            healthStatus.checks.runtime = {
                status: 'healthy',
                nodeVersion: process.version,
                platform: process.platform,
                memory: {
                    used: Math.round(memoryUsage.heapUsed / 1024 / 1024),
                    total: Math.round(memoryUsage.heapTotal / 1024 / 1024),
                    unit: 'MB'
                },
                uptime: Math.round(process.uptime())
            };

            // Check 2: IoT Hub connectivity
            try {
                if (process.env.IOT_HUB_CONNECTION_STRING) {
                    const serviceClient = IoTHubServiceClient.fromConnectionString(
                        process.env.IOT_HUB_CONNECTION_STRING
                    );
                    
                    // Test connection by getting service statistics
                    const stats = await serviceClient.getServiceStatistics();
                    
                    healthStatus.checks.iotHub = {
                        status: 'healthy',
                        connected: true,
                        totalDeviceCount: stats.totalDeviceCount || 0,
                        enabledDeviceCount: stats.enabledDeviceCount || 0,
                        disabledDeviceCount: stats.disabledDeviceCount || 0
                    };
                } else {
                    healthStatus.checks.iotHub = {
                        status: 'warning',
                        message: 'IoT Hub connection string not configured'
                    };
                }
            } catch (iotError) {
                healthStatus.checks.iotHub = {
                    status: 'unhealthy',
                    error: iotError.message
                };
                healthStatus.status = 'degraded';
            }

            // Check 3: Device Provisioning Service (if configured)
            if (process.env.DPS_CONNECTION_STRING || process.env.DPS_SCOPE_ID) {
                healthStatus.checks.deviceProvisioning = {
                    status: 'healthy',
                    configured: true,
                    scopeId: process.env.DPS_SCOPE_ID ? '***configured***' : 'not set'
                };
            } else {
                healthStatus.checks.deviceProvisioning = {
                    status: 'warning',
                    message: 'Device Provisioning Service not configured'
                };
            }

            // Check 4: Simulation status (global simulation state)
            try {
                // Check if simulation is running based on global state
                const simulationActive = global.simulationActive || false;
                const deviceCount = global.activeDevices ? global.activeDevices.length : 0;
                
                healthStatus.simulation = {
                    active: simulationActive,
                    deviceCount: deviceCount,
                    lastUpdate: global.lastSimulationUpdate || new Date().toISOString(),
                    messagesGenerated: global.totalMessages || 0
                };

                if (simulationActive && deviceCount > 0) {
                    healthStatus.checks.simulation = {
                        status: 'healthy',
                        devices: deviceCount,
                        running: true
                    };
                } else {
                    healthStatus.checks.simulation = {
                        status: 'warning',
                        message: 'Simulation not currently active',
                        devices: deviceCount
                    };
                }
            } catch (simError) {
                healthStatus.checks.simulation = {
                    status: 'unhealthy',
                    error: simError.message
                };
                healthStatus.status = 'degraded';
            }

            // Check 5: Configuration validation
            const requiredConfig = ['IOT_HUB_CONNECTION_STRING'];
            const missingConfig = requiredConfig.filter(config => !process.env[config]);
            
            if (missingConfig.length === 0) {
                healthStatus.checks.configuration = {
                    status: 'healthy',
                    allConfigured: true
                };
            } else {
                healthStatus.checks.configuration = {
                    status: 'warning',
                    missing: missingConfig,
                    message: `Missing configuration: ${missingConfig.join(', ')}`
                };
            }

            // Overall health assessment
            const unhealthyChecks = Object.values(healthStatus.checks).filter(check => check.status === 'unhealthy');
            if (unhealthyChecks.length > 0) {
                healthStatus.status = 'unhealthy';
            } else if (Object.values(healthStatus.checks).some(check => check.status === 'warning')) {
                healthStatus.status = 'degraded';
            }

            // Add summary
            healthStatus.summary = {
                totalChecks: Object.keys(healthStatus.checks).length,
                healthy: Object.values(healthStatus.checks).filter(c => c.status === 'healthy').length,
                warnings: Object.values(healthStatus.checks).filter(c => c.status === 'warning').length,
                unhealthy: Object.values(healthStatus.checks).filter(c => c.status === 'unhealthy').length
            };

        } catch (error) {
            console.error('Health check failed:', error);
            healthStatus.status = 'unhealthy';
            healthStatus.error = error.message;
        }

        // Set appropriate HTTP status code
        const statusCode = healthStatus.status === 'healthy' ? 200 : 
                          healthStatus.status === 'degraded' ? 200 : 503;

        res.status(statusCode).json(healthStatus);
    });

    // Additional simulation control endpoints
    app.get('/health/simulation', (req, res) => {
        const simulationStatus = {
            timestamp: new Date().toISOString(),
            active: global.simulationActive || false,
            deviceCount: global.activeDevices ? global.activeDevices.length : 0,
            uptime: Math.round(process.uptime()),
            lastUpdate: global.lastSimulationUpdate || new Date().toISOString(),
            totalMessages: global.totalMessages || 0,
            messagesPerSecond: global.messagesPerSecond || 0
        };

        res.json(simulationStatus);
    });
};