# Smart Factory - Control System VM Setup Script
# PowerShell script for Windows Server with SCADA simulation

Write-Host "🏭 Starting Smart Factory Control System Setup..." -ForegroundColor Green

# Create application directory
$AppDir = "C:\SmartFactory"
New-Item -ItemType Directory -Force -Path $AppDir
New-Item -ItemType Directory -Force -Path "$AppDir\SCADA"
New-Item -ItemType Directory -Force -Path "$AppDir\HMI"
New-Item -ItemType Directory -Force -Path "$AppDir\Logs"

# Install required features
Write-Host "📦 Installing Windows features..." -ForegroundColor Yellow
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole, IIS-HttpRedirection, IIS-WebSockets -All -NoRestart

# Install Chocolatey
Write-Host "🍫 Installing Chocolatey..." -ForegroundColor Yellow
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install software via Chocolatey
Write-Host "📊 Installing development tools..." -ForegroundColor Yellow
choco install -y nodejs python3 git vscode dotnetcore-runtime

# Install .NET Framework (for SCADA simulation)
choco install -y dotnetfx

# Create SCADA Simulation Application
Write-Host "🖥️ Creating SCADA simulation..." -ForegroundColor Yellow

# Create a simple SCADA web interface
$SCADAHtml = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🏭 Smart Factory SCADA System</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            background: linear-gradient(135deg, #2c3e50, #34495e); 
            color: white; 
            overflow-x: auto;
        }
        .header { 
            background: rgba(0,0,0,0.3); 
            padding: 20px; 
            text-align: center; 
            border-bottom: 2px solid #3498db;
        }
        .container { 
            padding: 20px; 
            max-width: 1400px; 
            margin: 0 auto; 
        }
        .grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); 
            gap: 20px; 
            margin-top: 20px;
        }
        .panel { 
            background: rgba(255,255,255,0.1); 
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.2);
            border-radius: 15px; 
            padding: 20px; 
        }
        .panel h3 { 
            margin-top: 0; 
            color: #3498db; 
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .status-indicator { 
            width: 20px; 
            height: 20px; 
            border-radius: 50%; 
            display: inline-block;
            animation: pulse 2s infinite;
        }
        .status-running { background: #2ecc71; }
        .status-warning { background: #f39c12; }
        .status-critical { background: #e74c3c; }
        .status-offline { background: #95a5a6; }
        @keyframes pulse { 
            0% { opacity: 1; } 
            50% { opacity: 0.5; } 
            100% { opacity: 1; } 
        }
        .metric-row { 
            display: flex; 
            justify-content: space-between; 
            margin: 10px 0; 
            padding: 10px; 
            background: rgba(0,0,0,0.2);
            border-radius: 8px;
        }
        .metric-value { 
            font-weight: bold; 
            color: #2ecc71; 
        }
        .control-button { 
            background: linear-gradient(135deg, #3498db, #2980b9); 
            color: white; 
            border: none; 
            padding: 12px 24px; 
            border-radius: 25px; 
            cursor: pointer; 
            margin: 5px; 
            font-weight: bold;
            transition: transform 0.2s;
        }
        .control-button:hover { 
            transform: scale(1.05); 
        }
        .emergency-button { 
            background: linear-gradient(135deg, #e74c3c, #c0392b); 
        }
        .alarm-panel { 
            background: rgba(231, 76, 60, 0.2); 
            border: 2px solid #e74c3c;
        }
        .production-chart { 
            height: 200px; 
            background: rgba(0,0,0,0.3); 
            border-radius: 10px; 
            display: flex; 
            align-items: center; 
            justify-content: center;
            position: relative;
            overflow: hidden;
        }
        .chart-bar { 
            background: linear-gradient(0deg, #3498db, #2ecc71); 
            width: 30px; 
            margin: 2px; 
            border-radius: 3px 3px 0 0;
            animation: chartUpdate 3s infinite ease-in-out;
        }
        @keyframes chartUpdate {
            0% { transform: scaleY(1); }
            50% { transform: scaleY(1.2); }
            100% { transform: scaleY(1); }
        }
        .system-log { 
            background: rgba(0,0,0,0.5); 
            border-radius: 10px; 
            padding: 15px; 
            height: 200px; 
            overflow-y: scroll; 
            font-family: 'Courier New', monospace;
            font-size: 12px;
        }
        .log-entry { 
            margin: 3px 0; 
        }
        .log-info { color: #3498db; }
        .log-warning { color: #f39c12; }
        .log-error { color: #e74c3c; }
        .timestamp { 
            color: #bdc3c7; 
            font-size: 11px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🏭 Smart Factory SCADA Control System</h1>
        <p>Central Monitoring & Control Dashboard</p>
        <div>
            <span class="status-indicator status-running"></span>
            <span>System Online</span> | 
            <span id="current-time"></span> |
            <span id="system-uptime">Uptime: 00:00:00</span>
        </div>
    </div>

    <div class="container">
        <div class="grid">
            <!-- Production Overview -->
            <div class="panel">
                <h3>📊 Production Overview</h3>
                <div class="metric-row">
                    <span>Production Line A:</span>
                    <span class="metric-value" id="line-a-rate">1,250 units/hr</span>
                </div>
                <div class="metric-row">
                    <span>Production Line B:</span>
                    <span class="metric-value" id="line-b-rate">1,180 units/hr</span>
                </div>
                <div class="metric-row">
                    <span>Overall Equipment Effectiveness:</span>
                    <span class="metric-value" id="oee">94.2%</span>
                </div>
                <div class="metric-row">
                    <span>Quality Rate:</span>
                    <span class="metric-value" id="quality-rate">99.1%</span>
                </div>
                <div class="production-chart" id="production-chart">
                    <!-- Chart bars will be generated by JavaScript -->
                </div>
            </div>

            <!-- Machine Status -->
            <div class="panel">
                <h3>🤖 Machine Status</h3>
                <div id="machine-status">
                    <!-- Machine status will be populated by JavaScript -->
                </div>
                <div style="margin-top: 15px;">
                    <button class="control-button" onclick="startMaintenance()">🔧 Schedule Maintenance</button>
                    <button class="control-button emergency-button" onclick="emergencyStop()">🛑 Emergency Stop</button>
                </div>
            </div>

            <!-- Process Control -->
            <div class="panel">
                <h3>⚙️ Process Control</h3>
                <div class="metric-row">
                    <span>Temperature Zone 1:</span>
                    <span class="metric-value" id="temp-zone1">75°C</span>
                </div>
                <div class="metric-row">
                    <span>Temperature Zone 2:</span>
                    <span class="metric-value" id="temp-zone2">82°C</span>
                </div>
                <div class="metric-row">
                    <span>Pressure Main Line:</span>
                    <span class="metric-value" id="pressure-main">14.2 PSI</span>
                </div>
                <div class="metric-row">
                    <span>Flow Rate:</span>
                    <span class="metric-value" id="flow-rate">850 L/min</span>
                </div>
                <div>
                    <button class="control-button" onclick="adjustParameters()">📈 Optimize Parameters</button>
                    <button class="control-button" onclick="calibrateSensors()">🎯 Calibrate Sensors</button>
                </div>
            </div>

            <!-- Energy Management -->
            <div class="panel">
                <h3>⚡ Energy Management</h3>
                <div class="metric-row">
                    <span>Total Power Consumption:</span>
                    <span class="metric-value" id="power-consumption">285 kW</span>
                </div>
                <div class="metric-row">
                    <span>Energy Efficiency:</span>
                    <span class="metric-value" id="energy-efficiency">87%</span>
                </div>
                <div class="metric-row">
                    <span>Peak Demand Today:</span>
                    <span class="metric-value" id="peak-demand">320 kW</span>
                </div>
                <div class="metric-row">
                    <span>Cost per Hour:</span>
                    <span class="metric-value" id="energy-cost">$28.50</span>
                </div>
            </div>

            <!-- Alarms & Alerts -->
            <div class="panel alarm-panel" id="alarm-panel">
                <h3>🚨 Active Alarms</h3>
                <div id="alarm-list">
                    <div class="log-entry log-warning">⚠️ Machine CNC-001: Temperature slightly elevated</div>
                    <div class="log-entry log-info">ℹ️ Scheduled maintenance due: Assembly Robot 002</div>
                </div>
                <div style="margin-top: 15px;">
                    <button class="control-button" onclick="acknowledgeAlarms()">✅ Acknowledge All</button>
                    <button class="control-button emergency-button" onclick="soundAlarm()">🔊 Test Alarm</button>
                </div>
            </div>

            <!-- System Log -->
            <div class="panel">
                <h3>📝 System Log</h3>
                <div class="system-log" id="system-log">
                    <!-- Log entries will be populated by JavaScript -->
                </div>
                <div style="margin-top: 10px;">
                    <button class="control-button" onclick="clearLog()">🗑️ Clear Log</button>
                    <button class="control-button" onclick="exportLog()">💾 Export Log</button>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Global variables
        let systemStartTime = new Date();
        let machines = {
            'CNC_001': {name: 'CNC Machine 001', status: 'running', efficiency: 94.5, temp: 75},
            'ROBOT_001': {name: 'Assembly Robot 001', status: 'running', efficiency: 92.1, temp: 68},
            'PRESS_001': {name: 'Hydraulic Press 001', status: 'warning', efficiency: 87.3, temp: 85},
            'CONV_001': {name: 'Conveyor Belt 001', status: 'running', efficiency: 98.7, temp: 45},
            'QC_001': {name: 'Quality Control 001', status: 'running', efficiency: 96.2, temp: 22}
        };
        
        let logEntries = [];

        // Initialize system
        function initializeSystem() {
            updateClock();
            updateUptime();
            updateMachineStatus();
            updateProductionChart();
            addLogEntry('System initialized successfully', 'info');
            
            // Update every 3 seconds
            setInterval(updateSystemData, 3000);
            setInterval(updateClock, 1000);
            setInterval(updateUptime, 1000);
        }

        function updateClock() {
            document.getElementById('current-time').textContent = new Date().toLocaleTimeString();
        }

        function updateUptime() {
            const uptime = new Date() - systemStartTime;
            const hours = Math.floor(uptime / 3600000);
            const minutes = Math.floor((uptime % 3600000) / 60000);
            const seconds = Math.floor((uptime % 60000) / 1000);
            document.getElementById('system-uptime').textContent = 
                `Uptime: ${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        }

        function updateSystemData() {
            // Update production metrics
            document.getElementById('line-a-rate').textContent = (1200 + Math.random() * 100).toFixed(0) + ' units/hr';
            document.getElementById('line-b-rate').textContent = (1150 + Math.random() * 80).toFixed(0) + ' units/hr';
            document.getElementById('oee').textContent = (93 + Math.random() * 4).toFixed(1) + '%';
            document.getElementById('quality-rate').textContent = (98.5 + Math.random() * 1).toFixed(1) + '%';
            
            // Update process control
            document.getElementById('temp-zone1').textContent = (73 + Math.random() * 6).toFixed(0) + '°C';
            document.getElementById('temp-zone2').textContent = (80 + Math.random() * 6).toFixed(0) + '°C';
            document.getElementById('pressure-main').textContent = (14 + Math.random() * 1).toFixed(1) + ' PSI';
            document.getElementById('flow-rate').textContent = (840 + Math.random() * 30).toFixed(0) + ' L/min';
            
            // Update energy
            document.getElementById('power-consumption').textContent = (280 + Math.random() * 20).toFixed(0) + ' kW';
            document.getElementById('energy-efficiency').textContent = (85 + Math.random() * 5).toFixed(0) + '%';
            
            // Update machines
            updateMachineStatus();
            
            // Occasionally add log entries
            if (Math.random() < 0.1) {
                const events = [
                    'Production cycle completed on Line A',
                    'Quality inspection passed - Batch 001',
                    'Sensor calibration completed',
                    'Maintenance reminder: Scheduled for tomorrow',
                    'Energy optimization algorithm executed'
                ];
                addLogEntry(events[Math.floor(Math.random() * events.length)], 'info');
            }
        }

        function updateMachineStatus() {
            const statusDiv = document.getElementById('machine-status');
            statusDiv.innerHTML = '';
            
            for (const [id, machine] of Object.entries(machines)) {
                // Simulate status changes
                if (Math.random() < 0.05) { // 5% chance
                    const statuses = ['running', 'warning', 'running', 'running']; // Bias towards running
                    machine.status = statuses[Math.floor(Math.random() * statuses.length)];
                }
                
                // Update efficiency
                machine.efficiency += (Math.random() - 0.5) * 2;
                machine.efficiency = Math.max(70, Math.min(100, machine.efficiency));
                
                const statusClass = machine.status === 'running' ? 'status-running' : 
                                   machine.status === 'warning' ? 'status-warning' : 'status-critical';
                
                statusDiv.innerHTML += `
                    <div class="metric-row">
                        <span>
                            <span class="status-indicator ${statusClass}"></span>
                            ${machine.name}
                        </span>
                        <span class="metric-value">${machine.efficiency.toFixed(1)}%</span>
                    </div>
                `;
            }
        }

        function updateProductionChart() {
            const chartDiv = document.getElementById('production-chart');
            chartDiv.innerHTML = '';
            
            for (let i = 0; i < 12; i++) {
                const height = 50 + Math.random() * 120;
                const bar = document.createElement('div');
                bar.className = 'chart-bar';
                bar.style.height = height + 'px';
                bar.style.animationDelay = (i * 0.2) + 's';
                chartDiv.appendChild(bar);
            }
        }

        function addLogEntry(message, type = 'info') {
            const timestamp = new Date().toLocaleTimeString();
            const entry = {
                timestamp: timestamp,
                message: message,
                type: type
            };
            logEntries.unshift(entry);
            
            if (logEntries.length > 100) logEntries.pop();
            
            updateLogDisplay();
        }

        function updateLogDisplay() {
            const logDiv = document.getElementById('system-log');
            logDiv.innerHTML = '';
            
            logEntries.forEach(entry => {
                const logClass = `log-${entry.type}`;
                logDiv.innerHTML += `
                    <div class="log-entry ${logClass}">
                        <span class="timestamp">[${entry.timestamp}]</span> ${entry.message}
                    </div>
                `;
            });
        }

        // Control functions
        function startMaintenance() {
            addLogEntry('Maintenance mode activated', 'warning');
            alert('🔧 Maintenance mode activated. Selected machines will be taken offline.');
        }

        function emergencyStop() {
            addLogEntry('EMERGENCY STOP ACTIVATED', 'error');
            alert('🛑 EMERGENCY STOP ACTIVATED!\n\nAll production lines have been halted.\nSafety protocols engaged.');
        }

        function adjustParameters() {
            addLogEntry('Process parameters optimized automatically', 'info');
            alert('📈 Process parameters have been optimized for current conditions.');
        }

        function calibrateSensors() {
            addLogEntry('Sensor calibration initiated', 'info');
            alert('🎯 Sensor calibration started. This will take approximately 5 minutes.');
        }

        function acknowledgeAlarms() {
            addLogEntry('All active alarms acknowledged by operator', 'info');
            document.getElementById('alarm-list').innerHTML = '<div class="log-entry log-info">✅ No active alarms</div>';
        }

        function soundAlarm() {
            addLogEntry('Alarm test completed successfully', 'info');
            alert('🔊 Alarm test completed. All speakers and notification systems are operational.');
        }

        function clearLog() {
            logEntries = [];
            updateLogDisplay();
            addLogEntry('System log cleared by operator', 'info');
        }

        function exportLog() {
            const logData = logEntries.map(e => `[${e.timestamp}] ${e.message}`).join('\n');
            const blob = new Blob([logData], { type: 'text/plain' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `scada_log_${new Date().toISOString().slice(0, 10)}.txt`;
            a.click();
            addLogEntry('System log exported', 'info');
        }

        // Initialize when page loads
        window.onload = initializeSystem;
    </script>
</body>
</html>
'@

$SCADAHtml | Out-File -FilePath "$AppDir\SCADA\scada-dashboard.html" -Encoding UTF8

# Create a simple web server script
$WebServerScript = @'
# Simple Python HTTP Server for SCADA Dashboard
import http.server
import socketserver
import os
import webbrowser
from threading import Timer

class SCATDAHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=r"C:\SmartFactory\SCADA", **kwargs)

    def log_message(self, format, *args):
        print(f"SCADA Server: {format % args}")

def open_browser():
    webbrowser.open('http://localhost:8080')

if __name__ == "__main__":
    PORT = 8080
    
    with socketserver.TCPServer(("", PORT), SCATDAHandler) as httpd:
        print(f"🏭 SCADA Dashboard server running at http://localhost:{PORT}")
        print("Press Ctrl+C to stop the server")
        
        # Open browser after 2 seconds
        Timer(2, open_browser).start()
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 SCADA Server stopped")
            httpd.shutdown()
'@

$WebServerScript | Out-File -FilePath "$AppDir\SCADA\start-scada-server.py" -Encoding UTF8

# Create a PowerShell script to start the SCADA system
$StartScript = @'
# Start Smart Factory SCADA System
Write-Host "🏭 Starting Smart Factory SCADA System..." -ForegroundColor Green

# Change to SCADA directory
Set-Location "C:\SmartFactory\SCADA"

# Start Python web server
Write-Host "🌐 Starting SCADA web server on port 8080..." -ForegroundColor Yellow
python start-scada-server.py
'@

$StartScript | Out-File -FilePath "$AppDir\Start-SCADA.ps1" -Encoding UTF8

# Create scheduled task to start SCADA on boot
Write-Host "🔧 Creating scheduled task for auto-start..." -ForegroundColor Yellow

$TaskName = "SmartFactorySCADA"
$TaskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\SmartFactory\Start-SCADA.ps1"
$TaskTrigger = New-ScheduledTaskTrigger -AtStartup
$TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$TaskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Principal $TaskPrincipal -Force

# Create desktop shortcut
Write-Host "🖥️ Creating desktop shortcut..." -ForegroundColor Yellow
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Smart Factory SCADA.lnk")
$Shortcut.TargetPath = "http://localhost:8080"
$Shortcut.IconLocation = "C:\Windows\System32\shell32.dll,13"
$Shortcut.Save()

# Configure Windows Firewall
Write-Host "🔥 Configuring Windows Firewall..." -ForegroundColor Yellow
New-NetFirewallRule -DisplayName "Smart Factory SCADA" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow

# Install additional monitoring tools
Write-Host "📊 Installing monitoring tools..." -ForegroundColor Yellow
choco install -y perfview sysinternals

Write-Host "✅ Smart Factory Control System setup complete!" -ForegroundColor Green
Write-Host "🌐 SCADA Dashboard will be available at: http://localhost:8080" -ForegroundColor Cyan
Write-Host "🚀 System will auto-start on boot" -ForegroundColor Cyan
Write-Host "🖥️ Desktop shortcut created for easy access" -ForegroundColor Cyan

# Start the SCADA system immediately
Write-Host "🏭 Starting SCADA system now..." -ForegroundColor Yellow
Start-Process PowerShell -ArgumentList "-ExecutionPolicy Bypass -File C:\SmartFactory\Start-SCADA.ps1" -WindowStyle Minimized

Write-Host "📋 Setup Summary:" -ForegroundColor Green
Write-Host "- SCADA Dashboard: http://localhost:8080" -ForegroundColor White
Write-Host "- Application Directory: C:\SmartFactory" -ForegroundColor White  
Write-Host "- Auto-start: Configured" -ForegroundColor White
Write-Host "- Firewall: Configured" -ForegroundColor White

# Show system information
Write-Host "`n🖥️ System Information:" -ForegroundColor Green
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory | Format-List
'@

$WindowsSetupScript | Out-File -FilePath "C:\amapv2\scripts\setup-control-system.ps1" -Encoding UTF8

Write-Host "✅ Created Windows Control System setup script!" -ForegroundColor Green