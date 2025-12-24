const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');

// Import AI Agents
const FactoryOperationsAgent = require('./factory-operations-agent');

// 📊 Smart Factory Monitoring Dashboard
class FactoryDashboard {
  constructor(port = 3000) {
    this.app = express();
    this.server = http.createServer(this.app);
    this.io = socketIo(this.server);
    this.port = port;
    
    this.factoryAgent = new FactoryOperationsAgent();
    this.dashboardData = {
      production: {
        oee: 0.87,
        throughput: 950,
        quality: 0.948,
        availability: 0.92
      },
      maintenance: {
        alerts: [],
        riskScores: {},
        nextMaintenance: 'Machine A: 2 days'
      },
      alerts: [],
      decisions: []
    };
    
    this.setupRoutes();
    this.setupSocketHandlers();
  }

  // 🌐 Setup Express Routes
  setupRoutes() {
    this.app.use(express.static(path.join(__dirname, 'public')));
    
    // Main dashboard
    this.app.get('/', (req, res) => {
      res.send(this.generateDashboardHTML());
    });
    
    // API endpoints
    this.app.get('/api/status', (req, res) => {
      res.json({
        status: 'operational',
        timestamp: new Date().toISOString(),
        data: this.dashboardData
      });
    });
    
    this.app.get('/api/production', (req, res) => {
      res.json(this.dashboardData.production);
    });
    
    this.app.get('/api/maintenance', (req, res) => {
      res.json(this.dashboardData.maintenance);
    });
  }

  // 🔌 Setup WebSocket Handlers
  setupSocketHandlers() {
    this.io.on('connection', (socket) => {
      console.log('📱 Dashboard client connected');
      
      // Send initial data
      socket.emit('initialData', this.dashboardData);
      
      socket.on('disconnect', () => {
        console.log('📱 Dashboard client disconnected');
      });
      
      socket.on('requestUpdate', () => {
        socket.emit('dataUpdate', this.dashboardData);
      });
    });
  }

  // 📊 Generate Dashboard HTML
  generateDashboardHTML() {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🏭 Smart Factory Predictive Maintenance Dashboard</title>
    <script src="https://cdn.socket.io/4.7.2/socket.io.min.js"></script>
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
            background: rgba(0,0,0,0.2); 
            padding: 20px; 
            text-align: center; 
            backdrop-filter: blur(10px);
        }
        .header h1 { font-size: 2.5rem; margin-bottom: 10px; }
        .header p { opacity: 0.9; font-size: 1.1rem; }
        .container { 
            max-width: 1400px; 
            margin: 0 auto; 
            padding: 20px; 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); 
            gap: 20px; 
        }
        .card { 
            background: rgba(255,255,255,0.1); 
            border-radius: 15px; 
            padding: 25px; 
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.2);
            transition: transform 0.3s ease;
        }
        .card:hover { transform: translateY(-5px); }
        .card h3 { 
            font-size: 1.4rem; 
            margin-bottom: 15px; 
            display: flex; 
            align-items: center; 
            gap: 10px; 
        }
        .metric { 
            display: flex; 
            justify-content: space-between; 
            align-items: center; 
            margin: 15px 0; 
            padding: 10px; 
            background: rgba(255,255,255,0.1); 
            border-radius: 8px; 
        }
        .metric-value { 
            font-size: 1.8rem; 
            font-weight: bold; 
        }
        .status-good { color: #4ade80; }
        .status-warning { color: #fbbf24; }
        .status-critical { color: #f87171; }
        .alert { 
            background: rgba(248, 113, 113, 0.2); 
            border-left: 4px solid #f87171; 
            padding: 15px; 
            margin: 10px 0; 
            border-radius: 5px; 
        }
        .decision { 
            background: rgba(74, 222, 128, 0.2); 
            border-left: 4px solid #4ade80; 
            padding: 15px; 
            margin: 10px 0; 
            border-radius: 5px; 
        }
        .progress-bar { 
            width: 100%; 
            height: 10px; 
            background: rgba(255,255,255,0.2); 
            border-radius: 5px; 
            overflow: hidden; 
            margin: 10px 0; 
        }
        .progress-fill { 
            height: 100%; 
            background: linear-gradient(90deg, #4ade80, #22d3ee); 
            transition: width 0.3s ease; 
        }
        .live-indicator { 
            display: inline-block; 
            width: 10px; 
            height: 10px; 
            background: #4ade80; 
            border-radius: 50%; 
            animation: pulse 2s infinite; 
        }
        @keyframes pulse { 
            0%, 100% { opacity: 1; } 
            50% { opacity: 0.5; } 
        }
        .connection-status {
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 10px 15px;
            border-radius: 25px;
            background: rgba(74, 222, 128, 0.9);
            font-weight: bold;
        }
        .chart-container {
            height: 300px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="connection-status" id="connectionStatus">
        🔴 Connecting...
    </div>

    <div class="header">
        <h1>🏭 Smart Factory Predictive Maintenance</h1>
        <p>🎯 Case Study #36: AI-Powered Equipment Monitoring & Autonomous Decision Making</p>
        <p><span class="live-indicator"></span> Live Dashboard - Real-time Factory Operations</p>
    </div>

    <div class="container">
        <!-- Production Metrics -->
        <div class="card">
            <h3>📈 Production Metrics</h3>
            <div class="metric">
                <span>Overall Equipment Effectiveness (OEE)</span>
                <span class="metric-value status-good" id="oee">87.3%</span>
            </div>
            <div class="progress-bar">
                <div class="progress-fill" id="oeeProgress" style="width: 87.3%"></div>
            </div>
            
            <div class="metric">
                <span>Throughput (units/hour)</span>
                <span class="metric-value status-good" id="throughput">950</span>
            </div>
            
            <div class="metric">
                <span>Quality Rate</span>
                <span class="metric-value status-good" id="quality">94.8%</span>
            </div>
            
            <div class="metric">
                <span>Availability</span>
                <span class="metric-value status-good" id="availability">92.1%</span>
            </div>
        </div>

        <!-- AI Predictions -->
        <div class="card">
            <h3>🔮 AI Maintenance Predictions</h3>
            <div class="metric">
                <span>Machine A Risk Score</span>
                <span class="metric-value status-warning" id="riskScoreA">42%</span>
            </div>
            <div class="metric">
                <span>Machine B Risk Score</span>
                <span class="metric-value status-good" id="riskScoreB">18%</span>
            </div>
            <div class="metric">
                <span>Machine C Risk Score</span>
                <span class="metric-value status-good" id="riskScoreC">12%</span>
            </div>
            
            <div style="margin-top: 20px;">
                <strong>🎯 Next Predicted Failure:</strong><br>
                <span id="nextFailure">Machine A: Bearing replacement needed in 2-3 days</span>
            </div>
        </div>

        <!-- Live Alerts -->
        <div class="card">
            <h3>🚨 Live Alerts & Decisions</h3>
            <div id="alertsContainer">
                <div class="alert">
                    <strong>⚠️ WARNING:</strong> Machine A showing early wear indicators. Preventive maintenance recommended within 48 hours.
                </div>
                <div class="decision">
                    <strong>🤖 AI DECISION:</strong> Optimizing production schedule to accommodate maintenance window during shift change.
                </div>
            </div>
        </div>

        <!-- Cost Impact -->
        <div class="card">
            <h3>💰 Business Impact</h3>
            <div class="metric">
                <span>Potential Cost Avoidance</span>
                <span class="metric-value status-good">$125,000</span>
            </div>
            <div class="metric">
                <span>Downtime Reduction</span>
                <span class="metric-value status-good">38%</span>
            </div>
            <div class="metric">
                <span>Monthly Savings</span>
                <span class="metric-value status-good">$185,000</span>
            </div>
            <div class="metric">
                <span>Annual ROI Projection</span>
                <span class="metric-value status-good">$2.2M</span>
            </div>
        </div>

        <!-- System Status -->
        <div class="card">
            <h3>🤖 AI Agent Status</h3>
            <div class="metric">
                <span>Predictive Maintenance Agent</span>
                <span class="metric-value status-good">🟢 Active</span>
            </div>
            <div class="metric">
                <span>Factory Operations Agent</span>
                <span class="metric-value status-good">🟢 Active</span>
            </div>
            <div class="metric">
                <span>Digital Twins Sync</span>
                <span class="metric-value status-good">🟢 Connected</span>
            </div>
            <div class="metric">
                <span>Real-time Processing</span>
                <span class="metric-value status-good">🟢 Online</span>
            </div>
        </div>

        <!-- Performance Chart -->
        <div class="card">
            <h3>📊 Performance Trend</h3>
            <div class="chart-container">
                <canvas id="performanceChart"></canvas>
            </div>
        </div>
    </div>

    <script>
        // WebSocket connection
        const socket = io();
        const connectionStatus = document.getElementById('connectionStatus');
        
        socket.on('connect', () => {
            connectionStatus.textContent = '🟢 Connected';
            connectionStatus.style.background = 'rgba(74, 222, 128, 0.9)';
        });
        
        socket.on('disconnect', () => {
            connectionStatus.textContent = '🔴 Disconnected';
            connectionStatus.style.background = 'rgba(248, 113, 113, 0.9)';
        });

        // Initialize Chart
        const ctx = document.getElementById('performanceChart').getContext('2d');
        const performanceChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['10:00', '10:15', '10:30', '10:45', '11:00', '11:15'],
                datasets: [{
                    label: 'OEE %',
                    data: [85, 87, 89, 86, 88, 87],
                    borderColor: '#4ade80',
                    backgroundColor: 'rgba(74, 222, 128, 0.1)',
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { labels: { color: 'white' } }
                },
                scales: {
                    y: { 
                        ticks: { color: 'white' },
                        grid: { color: 'rgba(255,255,255,0.2)' }
                    },
                    x: { 
                        ticks: { color: 'white' },
                        grid: { color: 'rgba(255,255,255,0.2)' }
                    }
                }
            }
        });

        // Update dashboard data
        socket.on('dataUpdate', (data) => {
            if (data.production) {
                document.getElementById('oee').textContent = (data.production.oee * 100).toFixed(1) + '%';
                document.getElementById('oeeProgress').style.width = (data.production.oee * 100).toFixed(1) + '%';
                document.getElementById('throughput').textContent = Math.round(data.production.throughput);
                document.getElementById('quality').textContent = (data.production.quality * 100).toFixed(1) + '%';
                document.getElementById('availability').textContent = (data.production.availability * 100).toFixed(1) + '%';
            }
        });

        // Simulate real-time updates
        setInterval(() => {
            socket.emit('requestUpdate');
        }, 5000);

        console.log('🏭 Smart Factory Dashboard loaded successfully');
        console.log('🎯 Case Study #36: Predictive Maintenance System');
        console.log('💰 Monitoring $2M+ annual ROI target');
    </script>
</body>
</html>`;
  }

  // 📊 Update Dashboard Data
  updateDashboardData() {
    // Simulate real-time data updates
    this.dashboardData.production = {
      oee: 0.80 + Math.random() * 0.15,
      throughput: 850 + Math.random() * 200,
      quality: 0.90 + Math.random() * 0.08,
      availability: 0.88 + Math.random() * 0.10
    };
    
    this.dashboardData.maintenance.riskScores = {
      machineA: Math.round(40 + Math.random() * 30),
      machineB: Math.round(10 + Math.random() * 25),
      machineC: Math.round(5 + Math.random() * 20)
    };
    
    // Broadcast updates to all connected clients
    this.io.emit('dataUpdate', this.dashboardData);
  }

  // 🚀 Start Dashboard Server
  start() {
    this.server.listen(this.port, () => {
      console.log('🏭 SMART FACTORY MONITORING DASHBOARD');
      console.log('══════════════════════════════════════════════════════════');
      console.log(`📊 Dashboard server running on http://localhost:${this.port}`);
      console.log('🎯 Case Study #36: Predictive Maintenance Monitoring');
      console.log('🤖 AI-Powered Factory Operations Dashboard');
      console.log('💰 ROI Tracking: $2M+ annual savings target');
      console.log('');
      console.log('📱 Open browser to view real-time factory status');
      console.log('');
    });
    
    // Start real-time data updates
    setInterval(() => {
      this.updateDashboardData();
    }, 3000);
    
    // Start factory agents
    this.factoryAgent.start().catch(console.error);
  }

  // 🛑 Stop Dashboard Server
  stop() {
    console.log('🛑 Stopping Smart Factory Dashboard...');
    this.factoryAgent.stop();
    this.server.close();
  }
}

// 🚀 Execute Dashboard
if (require.main === module) {
  const dashboard = new FactoryDashboard(3000);
  
  dashboard.start();
  
  // Graceful shutdown
  process.on('SIGINT', () => {
    dashboard.stop();
    process.exit(0);
  });
}

module.exports = FactoryDashboard;