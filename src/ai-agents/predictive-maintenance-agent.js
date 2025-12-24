const { DigitalTwinsClient } = require('@azure/digital-twins-core');
const { DefaultAzureCredential } = require('@azure/identity');

// 🤖 Factory Worker AI Agent for Predictive Maintenance
class PredictiveMaintenanceAgent {
  constructor() {
    this.digitalTwinsUrl = 'https://factory-adt-dev.api.eus.digitaltwins.azure.net';
    this.credential = new DefaultAzureCredential();
    this.dtClient = new DigitalTwinsClient(this.digitalTwinsUrl, this.credential);
    
    this.agentName = 'MaintenanceBot';
    this.isActive = false;
    this.alertThresholds = {
      temperature: { warning: 85, critical: 95 },
      vibration: { warning: 0.8, critical: 1.2 },
      efficiency: { warning: 0.6, critical: 0.4 }
    };
  }

  // 🔮 AI-Powered Failure Prediction
  async analyzeEquipmentHealth(machineId) {
    try {
      const twin = await this.dtClient.getDigitalTwin(machineId);
      const telemetry = await this.getRecentTelemetry(machineId);
      
      const analysis = {
        machineId,
        timestamp: new Date().toISOString(),
        currentHealth: twin.health,
        riskScore: this.calculateRiskScore(telemetry),
        predictions: this.generatePredictions(telemetry),
        recommendations: []
      };

      // Generate maintenance recommendations
      if (analysis.riskScore > 70) {
        analysis.recommendations.push({
          priority: 'HIGH',
          action: 'Schedule immediate maintenance inspection',
          reason: 'Critical failure indicators detected',
          estimatedCost: 5000,
          potentialSavings: 50000
        });
      } else if (analysis.riskScore > 40) {
        analysis.recommendations.push({
          priority: 'MEDIUM',
          action: 'Plan preventive maintenance within 48 hours',
          reason: 'Early warning signs detected',
          estimatedCost: 2000,
          potentialSavings: 15000
        });
      }

      console.log(`🔮 ${this.agentName}: Analyzed ${machineId} - Risk Score: ${analysis.riskScore}%`);
      return analysis;

    } catch (error) {
      console.error(`❌ ${this.agentName}: Failed to analyze ${machineId}:`, error.message);
      return null;
    }
  }

  // 📊 Calculate AI Risk Score
  calculateRiskScore(telemetry) {
    let riskScore = 0;
    
    // Temperature analysis
    if (telemetry.temperature > this.alertThresholds.temperature.critical) {
      riskScore += 40;
    } else if (telemetry.temperature > this.alertThresholds.temperature.warning) {
      riskScore += 20;
    }
    
    // Vibration analysis  
    if (telemetry.vibration > this.alertThresholds.vibration.critical) {
      riskScore += 35;
    } else if (telemetry.vibration > this.alertThresholds.vibration.warning) {
      riskScore += 15;
    }
    
    // Efficiency analysis
    if (telemetry.efficiency < this.alertThresholds.efficiency.critical) {
      riskScore += 25;
    } else if (telemetry.efficiency < this.alertThresholds.efficiency.warning) {
      riskScore += 10;
    }
    
    return Math.min(riskScore, 100);
  }

  // 🎯 Generate Failure Predictions
  generatePredictions(telemetry) {
    const predictions = [];
    
    // Temperature-based predictions
    if (telemetry.temperature > 90) {
      predictions.push({
        component: 'Cooling System',
        failureProbability: 0.85,
        timeToFailure: '12-24 hours',
        impact: 'Production shutdown'
      });
    }
    
    // Vibration-based predictions
    if (telemetry.vibration > 1.0) {
      predictions.push({
        component: 'Bearings/Alignment',
        failureProbability: 0.72,
        timeToFailure: '2-5 days',
        impact: 'Quality degradation'
      });
    }
    
    // Efficiency-based predictions
    if (telemetry.efficiency < 0.5) {
      predictions.push({
        component: 'Drive System',
        failureProbability: 0.68,
        timeToFailure: '1-3 weeks',
        impact: 'Reduced throughput'
      });
    }
    
    return predictions;
  }

  // 🚨 Autonomous Alert Generation
  async generateMaintenanceAlert(analysis) {
    if (analysis.riskScore < 40) return null;

    const alert = {
      id: `alert-${Date.now()}`,
      timestamp: new Date().toISOString(),
      severity: analysis.riskScore > 70 ? 'CRITICAL' : 'WARNING',
      machine: analysis.machineId,
      message: this.generateAlertMessage(analysis),
      actions: analysis.recommendations,
      estimatedDowntime: this.estimateDowntime(analysis.riskScore),
      costImpact: this.calculateCostImpact(analysis.riskScore)
    };

    console.log(`🚨 ${this.agentName}: Generated ${alert.severity} alert for ${analysis.machineId}`);
    
    // Send to monitoring system (simulated)
    await this.sendAlert(alert);
    
    return alert;
  }

  // 💬 Generate Human-Readable Alert Messages
  generateAlertMessage(analysis) {
    if (analysis.riskScore > 70) {
      return `🔴 CRITICAL: Machine ${analysis.machineId} showing signs of imminent failure. Immediate attention required to prevent production shutdown.`;
    } else if (analysis.riskScore > 40) {
      return `🟡 WARNING: Machine ${analysis.machineId} performance degrading. Preventive maintenance recommended within 48 hours.`;
    }
    return `🟢 Machine ${analysis.machineId} operating normally.`;
  }

  // ⏱️ Estimate Downtime Impact
  estimateDowntime(riskScore) {
    if (riskScore > 70) return '4-8 hours';
    if (riskScore > 40) return '1-2 hours';
    return '0 hours';
  }

  // 💰 Calculate Cost Impact
  calculateCostImpact(riskScore) {
    const baseHourlyCost = 12500; // $12.5k per hour downtime
    
    if (riskScore > 70) return baseHourlyCost * 6; // 6 hours avg
    if (riskScore > 40) return baseHourlyCost * 1.5; // 1.5 hours avg
    return 0;
  }

  // 📡 Send Alert to Monitoring System
  async sendAlert(alert) {
    try {
      // In production, this would integrate with Teams/Slack/Email
      console.log(`📡 ${this.agentName}: Alert sent to monitoring system`);
      console.log(`   Alert ID: ${alert.id}`);
      console.log(`   Severity: ${alert.severity}`);
      console.log(`   Estimated Cost Impact: $${alert.costImpact.toLocaleString()}`);
      
      return true;
    } catch (error) {
      console.error(`❌ ${this.agentName}: Failed to send alert:`, error.message);
      return false;
    }
  }

  // 📈 Get Recent Telemetry (Simulated)
  async getRecentTelemetry(machineId) {
    // Simulate getting recent telemetry data
    return {
      temperature: 75 + Math.random() * 20, // 75-95°C
      vibration: 0.3 + Math.random() * 0.9, // 0.3-1.2
      efficiency: 0.5 + Math.random() * 0.4, // 0.5-0.9
      timestamp: new Date().toISOString()
    };
  }

  // 🔄 Start Autonomous Monitoring
  async startAutonomousMonitoring() {
    console.log(`🤖 ${this.agentName}: Starting autonomous predictive maintenance monitoring...`);
    this.isActive = true;
    
    while (this.isActive) {
      try {
        console.log(`🔍 ${this.agentName}: Scanning factory equipment...`);
        
        // Monitor all machines
        const machines = ['machineA', 'machineB', 'machineC'];
        
        for (const machineId of machines) {
          const analysis = await this.analyzeEquipmentHealth(machineId);
          
          if (analysis) {
            const alert = await this.generateMaintenanceAlert(analysis);
            
            if (alert) {
              console.log(`📊 ${this.agentName}: ${alert.message}`);
            }
          }
          
          // Small delay between machines
          await new Promise(resolve => setTimeout(resolve, 1000));
        }
        
        console.log(`⏱️ ${this.agentName}: Monitoring cycle complete. Next scan in 30 seconds...`);
        
        // Wait 30 seconds before next scan
        await new Promise(resolve => setTimeout(resolve, 30000));
        
      } catch (error) {
        console.error(`❌ ${this.agentName}: Monitoring error:`, error.message);
        await new Promise(resolve => setTimeout(resolve, 5000));
      }
    }
  }

  // 🛑 Stop Monitoring
  stopMonitoring() {
    console.log(`🛑 ${this.agentName}: Stopping autonomous monitoring...`);
    this.isActive = false;
  }
}

// 🚀 Execute Predictive Maintenance Agent
if (require.main === module) {
  const maintenanceAgent = new PredictiveMaintenanceAgent();
  
  console.log('🏭 SMART FACTORY PREDICTIVE MAINTENANCE AGENT');
  console.log('═════════════════════════════════════════════════════════');
  console.log('🎯 Case Study #36: AI-Powered Equipment Monitoring');
  console.log('🔮 Autonomous failure prediction and alert generation');
  console.log('💰 Target: $2M+ annual savings through predictive maintenance');
  console.log('');
  
  maintenanceAgent.startAutonomousMonitoring().catch(console.error);
  
  // Graceful shutdown
  process.on('SIGINT', () => {
    maintenanceAgent.stopMonitoring();
    process.exit(0);
  });
}

module.exports = PredictiveMaintenanceAgent;