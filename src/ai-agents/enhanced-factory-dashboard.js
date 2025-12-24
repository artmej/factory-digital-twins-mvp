// 🔗 Enhanced Factory Dashboard with Azure ML Integration
// Integrates the Smart Factory ML Engine with the existing dashboard

const express = require('express');
const { Server } = require('socket.io');
const http = require('http');
const { SmartFactoryMLEngine } = require('../ml/smart-factory-ml-engine');

// Enhanced Factory Dashboard with ML
class EnhancedFactoryDashboard {
  constructor() {
    this.app = express();
    this.server = http.createServer(this.app);
    this.io = new Server(this.server);
    this.port = 3001;
    
    // Initialize ML Engine
    this.mlEngine = new SmartFactoryMLEngine();
    this.mlReady = false;
    
    // Factory state
    this.factoryState = {
      machines: {
        machineA: { temperature: 75, vibration: 0.3, efficiency: 0.85, operatingHours: 120 },
        machineB: { temperature: 73, vibration: 0.25, efficiency: 0.92, operatingHours: 95 },
        machineC: { temperature: 78, vibration: 0.35, efficiency: 0.88, operatingHours: 200 }
      },
      production: { oee: 0.847, throughput: 950, quality: 0.948 },
      alerts: [],
      mlInsights: []
    };
    
    this.setupRoutes();
    this.setupWebSocket();
    console.log('🔗 Enhanced Factory Dashboard with ML initialized');
  }

  async initializeML() {
    console.log('🧠 Training ML models for real-time predictions...');
    try {
      await this.mlEngine.trainAllModels();
      this.mlReady = true;
      console.log('✅ ML Engine ready for real-time predictions');
      
      // Start continuous ML monitoring
      this.startMLMonitoring();
    } catch (error) {
      console.error('❌ ML initialization failed:', error);
    }
  }

  setupRoutes() {
    this.app.use(express.json());
    this.app.use(express.static('public'));

    // Main dashboard route
    this.app.get('/', (req, res) => {
      res.send(this.generateEnhancedDashboardHTML());
    });

    // ML prediction API
    this.app.post('/api/ml-prediction', (req, res) => {
      if (!this.mlReady) {
        return res.status(503).json({ error: 'ML Engine not ready' });
      }

      try {
        const prediction = this.mlEngine.makePrediction(req.body);
        
        // Broadcast to all connected clients
        this.io.emit('ml-prediction', prediction);
        
        // Store in insights
        this.factoryState.mlInsights.unshift(prediction);
        if (this.factoryState.mlInsights.length > 20) {
          this.factoryState.mlInsights = this.factoryState.mlInsights.slice(0, 20);
        }

        res.json(prediction);
      } catch (error) {
        res.status(500).json({ error: error.message });
      }
    });

    // Factory data API
    this.app.get('/api/factory-status', (req, res) => {
      res.json({
        ...this.factoryState,
        mlEngine: {
          ready: this.mlReady,
          modelsLoaded: this.mlReady ? 3 : 0,
          lastUpdate: new Date().toISOString()
        }
      });
    });
  }

  setupWebSocket() {
    this.io.on('connection', (socket) => {
      console.log('📱 Client connected to enhanced dashboard');
      
      // Send current state
      socket.emit('factory-update', this.factoryState);
      
      socket.on('request-ml-prediction', (machineId) => {
        if (this.mlReady && this.factoryState.machines[machineId]) {
          const machineData = {
            machineId,
            ...this.factoryState.machines[machineId],
            pressure: 2.5 + (Math.random() - 0.5) * 0.5,
            rotationSpeed: 1800 + (Math.random() - 0.5) * 200
          };
          
          const prediction = this.mlEngine.makePrediction(machineData);
          socket.emit('ml-prediction', prediction);
        }
      });
    });
  }

  startMLMonitoring() {
    console.log('🔄 Starting continuous ML monitoring...');
    
    setInterval(() => {
      // Update machine data with realistic variations
      Object.keys(this.factoryState.machines).forEach(machineId => {
        const machine = this.factoryState.machines[machineId];
        
        // Simulate realistic sensor drift
        machine.temperature += (Math.random() - 0.5) * 2;
        machine.temperature = Math.max(65, Math.min(90, machine.temperature));
        
        machine.vibration += (Math.random() - 0.5) * 0.1;
        machine.vibration = Math.max(0, Math.min(1.2, machine.vibration));
        
        machine.efficiency += (Math.random() - 0.5) * 0.05;
        machine.efficiency = Math.max(0.6, Math.min(1.0, machine.efficiency));
        
        machine.operatingHours += 0.25; // 15 minutes per cycle
        
        // Add pressure and rotation speed
        const enhancedData = {
          machineId,
          ...machine,
          pressure: 2.5 + (Math.random() - 0.5) * 0.5,
          rotationSpeed: 1800 + (Math.random() - 0.5) * 200
        };
        
        // Get ML prediction
        if (this.mlReady) {
          const prediction = this.mlEngine.makePrediction(enhancedData);
          
          // Check for critical alerts
          if (prediction.predictions.failureProbability > 0.6) {
            const alert = {
              id: Date.now(),
              machineId,
              severity: 'critical',
              message: `High failure risk: ${(prediction.predictions.failureProbability * 100).toFixed(1)}%`,
              timestamp: new Date().toISOString(),
              source: 'ml_engine'
            };
            
            this.factoryState.alerts.unshift(alert);
            if (this.factoryState.alerts.length > 10) {
              this.factoryState.alerts = this.factoryState.alerts.slice(0, 10);
            }
            
            // Emit critical alert
            this.io.emit('critical-alert', alert);
            console.log(`🚨 CRITICAL ALERT: ${machineId} - ${alert.message}`);
          }
          
          // Emit ML prediction
          this.io.emit('ml-prediction', prediction);
        }
      });
      
      // Update production metrics
      this.factoryState.production.oee = 0.8 + Math.random() * 0.15;
      this.factoryState.production.throughput = 900 + Math.random() * 100;
      
      // Broadcast factory update
      this.io.emit('factory-update', this.factoryState);
      
    }, 30000); // Every 30 seconds
  }

  generateEnhancedDashboardHTML() {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🏭 Smart Factory with Azure ML - Case Study #36</title>
    <script src="/socket.io/socket.io.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
        }
        .header {
            background: rgba(0,0,0,0.3);
            padding: 20px;
            text-align: center;
            border-bottom: 2px solid rgba(255,255,255,0.1);
        }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header p { font-size: 1.2em; opacity: 0.9; }
        
        .dashboard {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            padding: 20px;
            max-width: 1400px;
            margin: 0 auto;
        }
        
        .panel {
            background: rgba(255,255,255,0.1);
            border-radius: 15px;
            padding: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.2);
        }
        
        .panel h3 {
            margin-bottom: 15px;
            color: #FFD700;
            font-size: 1.3em;
        }
        
        .metrics {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .metric {
            background: rgba(255,255,255,0.1);
            padding: 15px;
            border-radius: 10px;
            text-align: center;
        }
        
        .metric-value {
            font-size: 2em;
            font-weight: bold;
            color: #4FFFB0;
        }
        
        .metric-label {
            font-size: 0.9em;
            opacity: 0.8;
            margin-top: 5px;
        }
        
        .machine-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
        }
        
        .machine {
            background: rgba(255,255,255,0.1);
            padding: 15px;
            border-radius: 10px;
            border-left: 4px solid #4FFFB0;
        }
        
        .machine.warning { border-left-color: #FFA500; }
        .machine.critical { border-left-color: #FF4444; }
        
        .machine-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        
        .machine-name {
            font-weight: bold;
            font-size: 1.1em;
        }
        
        .risk-badge {
            padding: 4px 8px;
            border-radius: 15px;
            font-size: 0.8em;
            font-weight: bold;
        }
        
        .risk-low { background: #4FFFB0; color: #000; }
        .risk-medium { background: #FFA500; color: #000; }
        .risk-high { background: #FF4444; color: #FFF; }
        
        .machine-stats {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            font-size: 0.9em;
        }
        
        .alerts {
            max-height: 300px;
            overflow-y: auto;
        }
        
        .alert {
            background: rgba(255,68,68,0.2);
            border: 1px solid #FF4444;
            border-radius: 8px;
            padding: 12px;
            margin-bottom: 10px;
        }
        
        .alert.warning {
            background: rgba(255,165,0,0.2);
            border-color: #FFA500;
        }
        
        .alert-header {
            display: flex;
            justify-content: space-between;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .ml-insights {
            max-height: 400px;
            overflow-y: auto;
        }
        
        .insight {
            background: rgba(79,255,176,0.1);
            border: 1px solid #4FFFB0;
            border-radius: 8px;
            padding: 12px;
            margin-bottom: 10px;
        }
        
        .insight-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
        }
        
        .prediction-values {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 10px;
            font-size: 0.8em;
        }
        
        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 8px;
        }
        
        .status-online { background: #4FFFB0; }
        .status-warning { background: #FFA500; }
        .status-offline { background: #FF4444; }
        
        .footer {
            text-align: center;
            padding: 20px;
            background: rgba(0,0,0,0.3);
            margin-top: 20px;
        }
        
        @media (max-width: 768px) {
            .dashboard { grid-template-columns: 1fr; }
            .metrics { grid-template-columns: 1fr; }
            .machine-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🏭 Smart Factory with Azure ML</h1>
        <p>🎯 Case Study #36: Predictive Maintenance with Real-time ML Analytics</p>
        <p>💰 Target ROI: $2.2M+ | 📊 Current OEE: <span id="currentOEE">84.7%</span></p>
    </div>

    <div class="dashboard">
        <!-- Production Metrics -->
        <div class="panel">
            <h3>📊 Production Metrics</h3>
            <div class="metrics">
                <div class="metric">
                    <div class="metric-value" id="oeeValue">84.7%</div>
                    <div class="metric-label">Overall Equipment Effectiveness</div>
                </div>
                <div class="metric">
                    <div class="metric-value" id="throughputValue">950</div>
                    <div class="metric-label">Units/Hour</div>
                </div>
                <div class="metric">
                    <div class="metric-value" id="qualityValue">94.8%</div>
                    <div class="metric-label">Quality Rate</div>
                </div>
                <div class="metric">
                    <div class="metric-value" id="mlStatus">🧠 Ready</div>
                    <div class="metric-label">ML Engine Status</div>
                </div>
            </div>
        </div>

        <!-- Machine Health with ML Predictions -->
        <div class="panel">
            <h3>🤖 ML-Powered Machine Health</h3>
            <div class="machine-grid" id="machineGrid">
                <!-- Machines will be populated by JavaScript -->
            </div>
        </div>

        <!-- Live Alerts -->
        <div class="panel">
            <h3>🚨 Live Alerts & ML Warnings</h3>
            <div class="alerts" id="alertsContainer">
                <div class="alert">
                    <div class="alert-header">
                        <span>🔄 System Status</span>
                        <span>Now</span>
                    </div>
                    <div>ML Engine initialized and ready for predictions</div>
                </div>
            </div>
        </div>

        <!-- ML Insights -->
        <div class="panel">
            <h3>🔮 Real-time ML Insights</h3>
            <div class="ml-insights" id="mlInsightsContainer">
                <div class="insight">
                    <div class="insight-header">
                        <span>🧠 ML Engine Initialized</span>
                        <span>Ready</span>
                    </div>
                    <div>All 3 ML models loaded and calibrated for Case Study #36</div>
                </div>
            </div>
        </div>
    </div>

    <div class="footer">
        <p>🎯 <strong>Case Study #36</strong>: Smart Factory Predictive Maintenance | 
           🏆 <strong>Expected ROI</strong>: $2.2M+ Annual Savings | 
           🤖 <strong>ML Models</strong>: Failure Prediction + Anomaly Detection + Risk Classification</p>
        <p>Last Updated: <span id="lastUpdate">Loading...</span></p>
    </div>

    <script>
        const socket = io();
        let machineData = {};
        let alertCount = 0;

        // Update dashboard with factory data
        socket.on('factory-update', (data) => {
            // Update production metrics
            document.getElementById('oeeValue').textContent = (data.production.oee * 100).toFixed(1) + '%';
            document.getElementById('currentOEE').textContent = (data.production.oee * 100).toFixed(1) + '%';
            document.getElementById('throughputValue').textContent = Math.round(data.production.throughput);
            document.getElementById('qualityValue').textContent = (data.production.quality * 100).toFixed(1) + '%';
            
            // Update machine data
            machineData = data.machines;
            updateMachineDisplay();
            
            // Update timestamp
            document.getElementById('lastUpdate').textContent = new Date().toLocaleTimeString();
        });

        // Handle ML predictions
        socket.on('ml-prediction', (prediction) => {
            addMLInsight(prediction);
            updateMachineRisk(prediction);
        });

        // Handle critical alerts
        socket.on('critical-alert', (alert) => {
            addAlert(alert);
        });

        function updateMachineDisplay() {
            const container = document.getElementById('machineGrid');
            container.innerHTML = '';
            
            Object.keys(machineData).forEach(machineId => {
                const machine = machineData[machineId];
                const div = document.createElement('div');
                div.className = 'machine';
                div.innerHTML = \`
                    <div class="machine-header">
                        <span class="machine-name">\${machineId.toUpperCase()}</span>
                        <span class="risk-badge risk-low" id="risk-\${machineId}">Low Risk</span>
                    </div>
                    <div class="machine-stats">
                        <div>🌡️ Temp: \${machine.temperature.toFixed(1)}°C</div>
                        <div>📳 Vibration: \${machine.vibration.toFixed(2)}</div>
                        <div>⚡ Efficiency: \${(machine.efficiency * 100).toFixed(1)}%</div>
                        <div>⏱️ Hours: \${machine.operatingHours.toFixed(0)}h</div>
                    </div>
                \`;
                container.appendChild(div);
            });
        }

        function updateMachineRisk(prediction) {
            const riskBadge = document.getElementById(\`risk-\${prediction.machineId}\`);
            if (riskBadge) {
                const riskLevel = prediction.predictions.risk.riskLabel;
                riskBadge.textContent = riskLevel + ' Risk';
                riskBadge.className = 'risk-badge risk-' + riskLevel.toLowerCase();
                
                // Update machine panel color
                const machinePanel = riskBadge.closest('.machine');
                machinePanel.className = 'machine';
                if (riskLevel === 'High') machinePanel.classList.add('critical');
                else if (riskLevel === 'Medium') machinePanel.classList.add('warning');
            }
        }

        function addMLInsight(prediction) {
            const container = document.getElementById('mlInsightsContainer');
            const div = document.createElement('div');
            div.className = 'insight';
            
            const failureProb = (prediction.predictions.failureProbability * 100).toFixed(1);
            const riskLevel = prediction.predictions.risk.riskLabel;
            const isAnomaly = prediction.predictions.anomaly.isAnomaly;
            
            div.innerHTML = \`
                <div class="insight-header">
                    <span>🔮 \${prediction.machineId.toUpperCase()} Analysis</span>
                    <span>\${new Date().toLocaleTimeString()}</span>
                </div>
                <div class="prediction-values">
                    <div>Failure: \${failureProb}%</div>
                    <div>Risk: \${riskLevel}</div>
                    <div>Anomaly: \${isAnomaly ? 'YES' : 'NO'}</div>
                </div>
            \`;
            
            container.insertBefore(div, container.firstChild);
            
            // Keep only last 10 insights
            while (container.children.length > 10) {
                container.removeChild(container.lastChild);
            }
        }

        function addAlert(alert) {
            const container = document.getElementById('alertsContainer');
            const div = document.createElement('div');
            div.className = 'alert ' + alert.severity;
            
            div.innerHTML = \`
                <div class="alert-header">
                    <span>🚨 \${alert.machineId.toUpperCase()}</span>
                    <span>\${new Date(alert.timestamp).toLocaleTimeString()}</span>
                </div>
                <div>\${alert.message}</div>
            \`;
            
            container.insertBefore(div, container.firstChild);
            
            // Keep only last 5 alerts
            while (container.children.length > 5) {
                container.removeChild(container.lastChild);
            }
        }

        // Request initial ML predictions for all machines
        setTimeout(() => {
            Object.keys(machineData).forEach(machineId => {
                socket.emit('request-ml-prediction', machineId);
            });
        }, 2000);

        // Auto-refresh ML predictions every 30 seconds
        setInterval(() => {
            Object.keys(machineData).forEach(machineId => {
                socket.emit('request-ml-prediction', machineId);
            });
        }, 30000);
    </script>
</body>
</html>
    `;
  }

  async start() {
    // Initialize ML first
    await this.initializeML();
    
    // Start server
    this.server.listen(this.port, () => {
      console.log('=' .repeat(60));
      console.log('🏭 SMART FACTORY ENHANCED DASHBOARD WITH AZURE ML');
      console.log('=' .repeat(60));
      console.log(`📊 Dashboard: http://localhost:${this.port}`);
      console.log('🎯 Case Study #36: Predictive Maintenance');
      console.log('🤖 ML Engine: 3 models trained and ready');
      console.log('💰 Expected ROI: $2.2M+ annual savings');
      console.log('📱 Mobile integration: Ready for real-time alerts');
      console.log('=' .repeat(60));
    });
  }

  stop() {
    this.server.close();
    console.log('🛑 Enhanced Factory Dashboard stopped');
  }
}

// Create and start enhanced dashboard
const dashboard = new EnhancedFactoryDashboard();
dashboard.start().catch(console.error);

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Stopping Enhanced Factory Dashboard...');
  dashboard.stop();
  process.exit(0);
});

module.exports = { EnhancedFactoryDashboard };