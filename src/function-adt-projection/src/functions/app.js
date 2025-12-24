const { app } = require('@azure/functions');

app.http('get-factory-status', {
    methods: ['GET'],
    authLevel: 'anonymous',
    handler: async (request, context) => {
        context.log('HTTP trigger function processed a request.');

        const factoryStatus = {
            timestamp: new Date().toISOString(),
            factory: {
                id: 'factory1',
                name: 'Smart Factory Production',
                location: 'East Plant',
                oee: 87.3 + (Math.random() * 10 - 5), // Simulate variation
                status: 'Running',
                activeLines: 3,
                totalLines: 4
            },
            machines: [
                {
                    id: 'machine1',
                    name: 'CNC Machine A1',
                    status: Math.random() > 0.1 ? 'Running' : 'Maintenance',
                    temperature: 24.5 + (Math.random() * 5 - 2.5),
                    vibration: Math.random() * 0.5,
                    efficiency: 85 + (Math.random() * 15),
                    lastMaintenance: '2025-12-15T08:00:00Z'
                },
                {
                    id: 'machine2', 
                    name: 'CNC Machine A2',
                    status: Math.random() > 0.05 ? 'Running' : 'Alert',
                    temperature: 25.1 + (Math.random() * 4 - 2),
                    vibration: Math.random() * 0.4,
                    efficiency: 88 + (Math.random() * 12),
                    lastMaintenance: '2025-12-10T14:30:00Z'
                }
            ],
            predictions: {
                failureRisk: Math.random() > 0.8 ? 'High' : Math.random() > 0.5 ? 'Medium' : 'Low',
                anomalyDetected: Math.random() > 0.9 ? true : false,
                nextMaintenanceWindow: '2025-12-22T02:00:00Z',
                confidenceScore: 0.923
            },
            metrics: {
                productionRate: 94.2 + (Math.random() * 6 - 3),
                energyConsumption: 245.5 + (Math.random() * 20 - 10),
                qualityScore: 98.1 + (Math.random() * 2 - 1),
                downtime: Math.random() * 30 // minutes
            }
        };

        return {
            status: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify(factoryStatus)
        };
    }
});

app.http('get-machine-alerts', {
    methods: ['GET'],
    authLevel: 'anonymous', 
    handler: async (request, context) => {
        const alerts = [
            {
                id: 'alert1',
                machineId: 'machine1',
                type: 'Temperature',
                severity: Math.random() > 0.7 ? 'High' : 'Medium',
                message: 'Temperature spike detected - exceeding normal range',
                timestamp: new Date(Date.now() - Math.random() * 3600000).toISOString(),
                acknowledged: false
            },
            {
                id: 'alert2',
                machineId: 'machine2',
                type: 'Vibration',
                severity: 'Low',
                message: 'Minor vibration anomaly detected',
                timestamp: new Date(Date.now() - Math.random() * 7200000).toISOString(),
                acknowledged: true
            }
        ].filter(alert => Math.random() > 0.3); // Randomly show alerts

        return {
            status: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({ alerts })
        };
    }
});

app.http('get-latest-predictions', {
    methods: ['GET'],
    authLevel: 'anonymous',
    handler: async (request, context) => {
        const predictions = {
            timestamp: new Date().toISOString(),
            models: {
                failurePrediction: {
                    accuracy: 51.1,
                    prediction: Math.random() > 0.8 ? 'Failure likely in 2 days' : 'Normal operation expected',
                    confidence: 0.511
                },
                anomalyDetection: {
                    accuracy: 92.3,
                    status: Math.random() > 0.1 ? 'Normal' : 'Anomaly detected',
                    confidence: 0.923
                },
                riskClassification: {
                    accuracy: 91.8,
                    level: Math.random() > 0.7 ? 'Medium' : 'Low',
                    confidence: 0.918
                }
            },
            recommendations: [
                'Schedule preventive maintenance for Machine A1',
                'Monitor temperature trends on Line 2',
                'Optimize production speed for efficiency'
            ],
            nextPrediction: new Date(Date.now() + 30000).toISOString()
        };

        return {
            status: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify(predictions)
        };
    }
});