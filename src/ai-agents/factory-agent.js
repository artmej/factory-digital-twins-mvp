// Factory AI Agent - Autonomous Factory Management
// Uses only GA (Generally Available) services for MVP stability

const { DigitalTwinsClient } = require('@azure/digital-twins-core');
const { DefaultAzureCredential } = require('@azure/identity');

class FactoryAIAgent {
    constructor() {
        // Use only GA services - no Azure OpenAI preview features
        const credential = new DefaultAzureCredential();
        this.dtClient = new DigitalTwinsClient(
            process.env.DIGITAL_TWINS_URL,
            credential
        );
        
        this.isAutonomous = true;
        this.decisionHistory = [];
        
        // Rule-based AI instead of preview AI services
        this.thresholds = {
            temperature: { warning: 75, critical: 85 },
            oee: { warning: 0.70, critical: 0.60 },
            throughput: { warning: 80, critical: 60 }
        };
    }

    // Rule-based AI - Stable anomaly detection without preview services
    async analyzeFactoryHealth(telemetryData) {
        const analysis = {
            timestamp: new Date().toISOString(),
            healthStatus: 'Normal',
            anomalies: [],
            recommendations: [],
            metrics: {}
        };

        // Analyze temperature data
        if (telemetryData.temperature !== undefined) {
            analysis.metrics.temperature = telemetryData.temperature;
            if (telemetryData.temperature >= this.thresholds.temperature.critical) {
                analysis.healthStatus = 'Critical';
                analysis.anomalies.push({
                    type: 'temperature',
                    value: telemetryData.temperature,
                    severity: 'critical',
                    description: 'Machine temperature critically high'
                });
                analysis.recommendations.push('Immediate shutdown required - temperature critical');
            } else if (telemetryData.temperature >= this.thresholds.temperature.warning) {
                analysis.healthStatus = 'Warning';
                analysis.anomalies.push({
                    type: 'temperature',
                    value: telemetryData.temperature,
                    severity: 'warning',
                    description: 'Machine temperature elevated'
                });
                analysis.recommendations.push('Schedule maintenance check - temperature warning');
            }
        }

        // Analyze OEE data
        if (telemetryData.oee !== undefined) {
            analysis.metrics.oee = telemetryData.oee;
            if (telemetryData.oee <= this.thresholds.oee.critical) {
                analysis.healthStatus = 'Critical';
                analysis.anomalies.push({
                    type: 'oee',
                    value: telemetryData.oee,
                    severity: 'critical',
                    description: 'OEE critically low'
                });
                analysis.recommendations.push('Investigate production line efficiency immediately');
            } else if (telemetryData.oee <= this.thresholds.oee.warning) {
                if (analysis.healthStatus === 'Normal') analysis.healthStatus = 'Warning';
                analysis.anomalies.push({
                    type: 'oee',
                    value: telemetryData.oee,
                    severity: 'warning',
                    description: 'OEE below target'
                });
                analysis.recommendations.push('Review production parameters and optimize workflow');
            }
        }

        // Analyze throughput data
        if (telemetryData.throughput !== undefined) {
            analysis.metrics.throughput = telemetryData.throughput;
            if (telemetryData.throughput <= this.thresholds.throughput.critical) {
                analysis.healthStatus = 'Critical';
                analysis.anomalies.push({
                    type: 'throughput',
                    value: telemetryData.throughput,
                    severity: 'critical',
                    description: 'Throughput critically low'
                });
                analysis.recommendations.push('Check for production line blockages or equipment failure');
            } else if (telemetryData.throughput <= this.thresholds.throughput.warning) {
                if (analysis.healthStatus === 'Normal') analysis.healthStatus = 'Warning';
                analysis.anomalies.push({
                    type: 'throughput',
                    value: telemetryData.throughput,
                    severity: 'warning',
                    description: 'Throughput below normal'
                });
                analysis.recommendations.push('Monitor production flow and adjust as needed');
            }
        }

        return analysis;
    }

    // Agentic Behavior - Autonomous Decision Making
    async autonomousFactoryManagement() {
        try {
            // Get current factory state
            const factoryState = await this.getFactoryState();
            
            // Rule-based analysis using GA services only
            const aiAnalysis = await this.analyzeFactoryHealth(factoryState.telemetry);
            
            // Autonomous decision making
            if (aiAnalysis.healthStatus === 'Critical') {
                await this.orchestrateEmergencyResponse(aiAnalysis);
            } else if (aiAnalysis.healthStatus === 'Warning') {
                await this.optimizeProduction(aiAnalysis);
            }

            // Log decision for audit
            this.logDecision({
                timestamp: new Date(),
                analysis: aiAnalysis,
                action: 'autonomous_management',
                success: true
            });

        } catch (error) {
            console.error('Autonomous management failed:', error);
            await this.escalateToHuman(error);
        }
    }

    // Multi-Agent Orchestration
    async orchestrateEmergencyResponse(analysis) {
        console.log('🚨 Emergency Response Orchestration');
        
        // Coordinate multiple agents
        const maintenanceAgent = new MaintenanceAgent();
        const productionAgent = new ProductionAgent();
        const notificationAgent = new NotificationAgent();

        // Parallel agent coordination
        await Promise.all([
            maintenanceAgent.scheduleUrgentRepair(analysis.anomalies),
            productionAgent.adjustProductionPlan(analysis.recommendations),
            notificationAgent.alertOperators(analysis)
        ]);

        // Update digital twin status
        await this.updateDigitalTwinStatus('emergency_mode');
    }

    // Rule-based learning without preview AI services
    async learnFromOutcomes(decisionId, outcome) {
        const decision = this.decisionHistory.find(d => d.id === decisionId);
        
        if (decision) {
            decision.outcome = outcome;
            
            // Simple rule-based learning - adjust thresholds based on outcomes
            if (outcome.success && decision.analysis.healthStatus === 'Warning') {
                // If warning was handled successfully, slightly relax thresholds
                this.adjustThresholds('relax', 0.02);
            } else if (!outcome.success && decision.analysis.healthStatus === 'Normal') {
                // If we missed an issue, tighten thresholds
                this.adjustThresholds('tighten', 0.05);
            }
            
            console.log('🧠 Learning Applied: Thresholds adjusted based on outcome');
            console.log(`   Decision ID: ${decisionId}`);
            console.log(`   Outcome Success: ${outcome.success}`);
        }
    }
    
    adjustThresholds(direction, factor) {
        const multiplier = direction === 'tighten' ? (1 - factor) : (1 + factor);
        
        // Adjust warning thresholds (keep within reasonable bounds)
        this.thresholds.temperature.warning = Math.min(90, Math.max(60, 
            this.thresholds.temperature.warning * (direction === 'tighten' ? multiplier : (1 / multiplier))
        ));
        
        this.thresholds.oee.warning = Math.min(0.9, Math.max(0.5,
            this.thresholds.oee.warning * (direction === 'tighten' ? (1 / multiplier) : multiplier)
        ));
        
        this.thresholds.throughput.warning = Math.min(150, Math.max(50,
            this.thresholds.throughput.warning * (direction === 'tighten' ? (1 / multiplier) : multiplier)
        ));
        
        console.log('📊 Thresholds updated:', this.thresholds);
    }

    async getFactoryState() {
        // Query Digital Twins for current factory state
        const query = "SELECT * FROM digitaltwins WHERE IS_OF_MODEL('dtmi:factory:Factory;1')";
        const queryResult = this.dtClient.queryTwins(query);
        
        const factoryData = [];
        for await (const twin of queryResult) {
            factoryData.push(twin);
        }

        return {
            timestamp: new Date(),
            twins: factoryData,
            telemetry: await this.getLatestTelemetry()
        };
    }

    logDecision(decision) {
        decision.id = `decision_${Date.now()}`;
        this.decisionHistory.push(decision);
        console.log('📊 AI Decision Logged:', decision.id);
    }
}

// Specialized agents for different domains
class MaintenanceAgent {
    async scheduleUrgentRepair(anomalies) {
        console.log('🔧 Maintenance Agent: Scheduling urgent repairs');
        // Implementation for maintenance scheduling
    }
}

class ProductionAgent {
    async adjustProductionPlan(recommendations) {
        console.log('🏭 Production Agent: Adjusting production plan');
        // Implementation for production optimization
    }
}

class NotificationAgent {
    async alertOperators(analysis) {
        console.log('📢 Notification Agent: Alerting operators');
        // Implementation for operator notifications
    }
}

module.exports = { FactoryAIAgent, MaintenanceAgent, ProductionAgent, NotificationAgent };