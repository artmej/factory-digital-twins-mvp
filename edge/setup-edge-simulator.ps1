# 🏭 Smart Factory Edge Device Simulator
# IoT device simulator running on Azure Arc-enabled VM

# This PowerShell script configures the Edge VM for IoT device simulation
param(
    [string]$IoTHubConnectionString,
    [string]$DeviceProvisioningServiceEndpoint,
    [string]$DeviceProvisioningServiceIdScope,
    [int]$NumberOfDevices = 5,
    [int]$TelemetryInterval = 30,
    [bool]$EnableRealTimeData = $true
)

Write-Host "🏭 Starting Smart Factory Edge Device Simulator Setup..." -ForegroundColor Green

# 1. Install required dependencies
Write-Host "📦 Installing required dependencies..." -ForegroundColor Yellow

# Install Node.js on the Arc VM (if not already installed)
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js already installed: $nodeVersion" -ForegroundColor Green
}
catch {
    Write-Host "📦 Installing Node.js..." -ForegroundColor Yellow
    
    # Download and install Node.js
    $nodeInstaller = "https://nodejs.org/dist/v18.17.1/node-v18.17.1-x64.msi"
    $installerPath = "$env:TEMP\nodejs-installer.msi"
    
    Invoke-WebRequest -Uri $nodeInstaller -OutFile $installerPath
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $installerPath, "/quiet" -Wait
    
    # Refresh environment variables
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
}

# 2. Create edge device simulator application
$edgeSimulatorCode = @'
// 🏭 Smart Factory Edge Device Simulator
// Simulates multiple IoT devices on an Azure Arc-enabled VM

const { Client } = require('azure-iot-device');
const { Message } = require('azure-iot-device');
const { Mqtt } = require('azure-iot-device-mqtt');
const { SymmetricKeySecurityClient } = require('azure-iot-security-symmetric-key');
const { ProvisioningDeviceClient } = require('azure-iot-provisioning-device');
const { ProvisioningTransport } = require('azure-iot-provisioning-device-mqtt');

class SmartFactoryDevice {
    constructor(deviceId, deviceKey, registrationId) {
        this.deviceId = deviceId;
        this.deviceKey = deviceKey;
        this.registrationId = registrationId;
        this.client = null;
        this.telemetryInterval = null;
        
        // Device state
        this.state = {
            temperature: 25.0,
            humidity: 60.0,
            pressure: 1013.25,
            vibration: 0.5,
            speed: 1500,
            power: 50000,
            efficiency: 85.0,
            status: 'running',
            lastMaintenance: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000),
            productionCount: 0,
            errorCount: 0
        };
        
        // Device configuration
        this.config = {
            deviceType: this.getDeviceType(deviceId),
            location: this.getLocation(deviceId),
            line: this.getProductionLine(deviceId),
            machineId: deviceId,
            firmwareVersion: '2.1.3',
            lastCalibration: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000)
        };
    }
    
    getDeviceType(deviceId) {
        const types = ['temperatureSensor', 'pressureSensor', 'vibrationSensor', 'powerMeter', 'conveyorBelt'];
        return types[Math.floor(Math.abs(this.hashCode(deviceId)) % types.length)];
    }
    
    getLocation(deviceId) {
        const locations = ['Assembly Line 1', 'Assembly Line 2', 'Quality Control', 'Packaging', 'Warehouse'];
        return locations[Math.floor(Math.abs(this.hashCode(deviceId)) % locations.length)];
    }
    
    getProductionLine(deviceId) {
        return `Line-${Math.floor(Math.abs(this.hashCode(deviceId)) % 5) + 1}`;
    }
    
    hashCode(str) {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            const char = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash;
        }
        return hash;
    }
    
    async provision() {
        console.log(`🔧 Provisioning device ${this.deviceId}...`);
        
        try {
            const provisioningHost = process.env.DPS_ENDPOINT || 'global.azure-devices-provisioning.net';
            const idScope = process.env.DPS_ID_SCOPE;
            
            const securityClient = new SymmetricKeySecurityClient(this.registrationId, this.deviceKey);
            const transport = new ProvisioningTransport();
            const provisioningClient = ProvisioningDeviceClient.create(
                provisioningHost,
                idScope,
                transport,
                securityClient
            );
            
            const result = await provisioningClient.register();
            
            if (result.status === 'assigned') {
                console.log(`✅ Device ${this.deviceId} provisioned to IoT Hub: ${result.registrationState.assignedHub}`);
                return result.registrationState.assignedHub;
            } else {
                throw new Error(`Provisioning failed with status: ${result.status}`);
            }
            
        } catch (error) {
            console.error(`❌ Failed to provision device ${this.deviceId}:`, error);
            throw error;
        }
    }
    
    async connect() {
        try {
            console.log(`🔌 Connecting device ${this.deviceId}...`);
            
            // Try provisioning first
            let hubHostname;
            try {
                hubHostname = await this.provision();
            } catch (provisionError) {
                console.warn(`⚠️  Provisioning failed, using direct connection for ${this.deviceId}`);
                hubHostname = process.env.IOT_HUB_HOSTNAME;
            }
            
            const connectionString = `HostName=${hubHostname};DeviceId=${this.deviceId};SharedAccessKey=${this.deviceKey}`;
            this.client = Client.fromConnectionString(connectionString, Mqtt);
            
            await this.client.open();
            console.log(`✅ Device ${this.deviceId} connected successfully`);
            
            // Set up device twin handlers
            this.setupDeviceTwin();
            
            // Set up direct method handlers
            this.setupDirectMethods();
            
        } catch (error) {
            console.error(`❌ Failed to connect device ${this.deviceId}:`, error);
            throw error;
        }
    }
    
    setupDeviceTwin() {
        this.client.getTwin((err, twin) => {
            if (err) {
                console.error(`❌ Failed to get device twin for ${this.deviceId}:`, err);
                return;
            }
            
            console.log(`📊 Device twin retrieved for ${this.deviceId}`);
            
            // Report device properties
            const reported = {
                deviceInfo: this.config,
                telemetryConfig: {
                    interval: process.env.TELEMETRY_INTERVAL || 30,
                    enabled: true
                },
                lastStartup: new Date().toISOString()
            };
            
            twin.properties.reported.update(reported, (err) => {
                if (err) console.error(`❌ Failed to update reported properties for ${this.deviceId}:`, err);
                else console.log(`✅ Reported properties updated for ${this.deviceId}`);
            });
            
            // Handle desired property changes
            twin.on('properties.desired', (desiredChange) => {
                console.log(`🔄 Received desired property change for ${this.deviceId}:`, desiredChange);
                
                if (desiredChange.telemetryConfig) {
                    this.updateTelemetryConfig(desiredChange.telemetryConfig);
                }
            });
        });
    }
    
    setupDirectMethods() {
        // Restart method
        this.client.onDeviceMethod('restart', (request, response) => {
            console.log(`🔄 Restart method called for ${this.deviceId}`);
            
            // Simulate restart
            this.state.status = 'restarting';
            this.state.lastMaintenance = new Date();
            
            setTimeout(() => {
                this.state.status = 'running';
                console.log(`✅ Device ${this.deviceId} restarted successfully`);
            }, 5000);
            
            response.send(200, 'Device restart initiated', (err) => {
                if (err) console.error(`❌ Failed to send restart response for ${this.deviceId}:`, err);
            });
        });
        
        // Maintenance method
        this.client.onDeviceMethod('maintenance', (request, response) => {
            console.log(`🔧 Maintenance method called for ${this.deviceId}`);
            
            this.state.status = 'maintenance';
            this.state.lastMaintenance = new Date();
            this.state.errorCount = 0;
            
            setTimeout(() => {
                this.state.status = 'running';
                this.state.efficiency = Math.min(95.0, this.state.efficiency + 5.0);
                console.log(`✅ Maintenance completed for ${this.deviceId}`);
            }, 10000);
            
            response.send(200, 'Maintenance mode activated', (err) => {
                if (err) console.error(`❌ Failed to send maintenance response for ${this.deviceId}:`, err);
            });
        });
        
        // Get device info method
        this.client.onDeviceMethod('getDeviceInfo', (request, response) => {
            const deviceInfo = {
                ...this.config,
                currentState: this.state,
                timestamp: new Date().toISOString()
            };
            
            response.send(200, deviceInfo, (err) => {
                if (err) console.error(`❌ Failed to send device info response for ${this.deviceId}:`, err);
            });
        });
    }
    
    updateTelemetryConfig(config) {
        if (config.interval && this.telemetryInterval) {
            clearInterval(this.telemetryInterval);
            this.startTelemetry(config.interval * 1000);
        }
    }
    
    generateTelemetryData() {
        // Simulate realistic device behavior
        this.simulateDeviceBehavior();
        
        const telemetry = {
            deviceId: this.deviceId,
            timestamp: new Date().toISOString(),
            deviceType: this.config.deviceType,
            location: this.config.location,
            line: this.config.line,
            
            // Sensor readings
            temperature: this.state.temperature,
            humidity: this.state.humidity,
            pressure: this.state.pressure,
            vibration: this.state.vibration,
            speed: this.state.speed,
            power: this.state.power,
            
            // Operational metrics
            efficiency: this.state.efficiency,
            status: this.state.status,
            productionCount: this.state.productionCount,
            errorCount: this.state.errorCount,
            
            // Quality metrics
            quality: this.calculateQualityScore(),
            oeeScore: this.calculateOEE(),
            
            // Predictive maintenance
            maintenanceScore: this.calculateMaintenanceScore(),
            nextMaintenanceDate: this.calculateNextMaintenance(),
            
            // Edge analytics
            anomalyScore: this.detectAnomalies(),
            trendAnalysis: this.analyzeTrends()
        };
        
        // Add device-specific telemetry
        switch (this.config.deviceType) {
            case 'temperatureSensor':
                telemetry.heatIndex = this.calculateHeatIndex();
                break;
            case 'pressureSensor':
                telemetry.pressureTrend = this.calculatePressureTrend();
                break;
            case 'vibrationSensor':
                telemetry.vibrationPattern = this.analyzeVibrationPattern();
                break;
            case 'powerMeter':
                telemetry.powerEfficiency = this.calculatePowerEfficiency();
                telemetry.energyCost = this.calculateEnergyCost();
                break;
            case 'conveyorBelt':
                telemetry.throughput = this.calculateThroughput();
                telemetry.jamDetection = this.detectJam();
                break;
        }
        
        return telemetry;
    }
    
    simulateDeviceBehavior() {
        // Simulate normal variations
        this.state.temperature += (Math.random() - 0.5) * 2;
        this.state.humidity += (Math.random() - 0.5) * 5;
        this.state.pressure += (Math.random() - 0.5) * 10;
        this.state.vibration += (Math.random() - 0.5) * 0.1;
        
        // Simulate production
        if (this.state.status === 'running') {
            this.state.productionCount += Math.floor(Math.random() * 3);
            this.state.speed = 1400 + Math.random() * 200;
            this.state.power = 45000 + Math.random() * 10000;
        }
        
        // Simulate efficiency degradation
        this.state.efficiency = Math.max(70, this.state.efficiency - Math.random() * 0.1);
        
        // Simulate occasional errors
        if (Math.random() < 0.05) {
            this.state.errorCount++;
            this.state.efficiency -= 1;
        }
        
        // Bounds checking
        this.state.temperature = Math.max(15, Math.min(45, this.state.temperature));
        this.state.humidity = Math.max(30, Math.min(90, this.state.humidity));
        this.state.pressure = Math.max(980, Math.min(1040, this.state.pressure));
        this.state.vibration = Math.max(0, Math.min(2, this.state.vibration));
    }
    
    calculateQualityScore() {
        // Simple quality calculation based on multiple factors
        let score = 100;
        
        // Temperature impact
        if (this.state.temperature > 35 || this.state.temperature < 20) score -= 10;
        
        // Vibration impact
        if (this.state.vibration > 1.5) score -= 15;
        
        // Efficiency impact
        score = score * (this.state.efficiency / 100);
        
        return Math.max(0, Math.round(score));
    }
    
    calculateOEE() {
        // Overall Equipment Effectiveness calculation
        const availability = this.state.status === 'running' ? 0.95 : 0.0;
        const performance = this.state.efficiency / 100;
        const quality = this.calculateQualityScore() / 100;
        
        return Math.round(availability * performance * quality * 100);
    }
    
    calculateMaintenanceScore() {
        const daysSinceLastMaintenance = (Date.now() - this.state.lastMaintenance.getTime()) / (1000 * 60 * 60 * 24);
        const vibrationFactor = this.state.vibration / 2;
        const efficiencyFactor = (100 - this.state.efficiency) / 100;
        
        return Math.min(100, Math.round((daysSinceLastMaintenance * 3) + (vibrationFactor * 20) + (efficiencyFactor * 30)));
    }
    
    calculateNextMaintenance() {
        const maintenanceScore = this.calculateMaintenanceScore();
        const daysUntilMaintenance = Math.max(1, 30 - Math.floor(maintenanceScore / 3));
        
        const nextDate = new Date();
        nextDate.setDate(nextDate.getDate() + daysUntilMaintenance);
        
        return nextDate.toISOString();
    }
    
    detectAnomalies() {
        let anomalyScore = 0;
        
        // Temperature anomaly
        if (this.state.temperature > 40 || this.state.temperature < 18) anomalyScore += 30;
        
        // Vibration anomaly
        if (this.state.vibration > 1.8) anomalyScore += 40;
        
        // Efficiency anomaly
        if (this.state.efficiency < 75) anomalyScore += 25;
        
        // Multiple errors
        if (this.state.errorCount > 5) anomalyScore += 20;
        
        return Math.min(100, anomalyScore);
    }
    
    analyzeTrends() {
        // Simplified trend analysis
        return {
            temperatureTrend: Math.random() > 0.5 ? 'increasing' : 'stable',
            efficiencyTrend: this.state.efficiency > 85 ? 'stable' : 'declining',
            vibrationTrend: this.state.vibration > 1.2 ? 'concerning' : 'normal',
            overallTrend: this.state.efficiency > 85 && this.state.vibration < 1.2 ? 'positive' : 'attention_needed'
        };
    }
    
    // Device-specific calculations
    calculateHeatIndex() {
        return this.state.temperature + (this.state.humidity / 10);
    }
    
    calculatePressureTrend() {
        return this.state.pressure > 1020 ? 'high_pressure' : this.state.pressure < 990 ? 'low_pressure' : 'normal';
    }
    
    analyzeVibrationPattern() {
        if (this.state.vibration > 1.5) return 'irregular';
        if (this.state.vibration > 1.0) return 'elevated';
        return 'normal';
    }
    
    calculatePowerEfficiency() {
        return Math.round((this.state.productionCount / this.state.power) * 1000000);
    }
    
    calculateEnergyCost() {
        const costPerKWh = 0.12;
        const powerInKW = this.state.power / 1000;
        const hoursRunning = 24; // Assume running 24/7
        return Math.round(powerInKW * hoursRunning * costPerKWh * 100) / 100;
    }
    
    calculateThroughput() {
        return this.state.status === 'running' ? Math.round(this.state.speed / 60) : 0;
    }
    
    detectJam() {
        return this.state.speed < 500 && this.state.status === 'running';
    }
    
    async sendTelemetry() {
        try {
            const telemetryData = this.generateTelemetryData();
            const message = new Message(JSON.stringify(telemetryData));
            
            // Add message properties
            message.properties.add('deviceType', this.config.deviceType);
            message.properties.add('location', this.config.location);
            message.properties.add('line', this.config.line);
            message.properties.add('criticalAlert', telemetryData.anomalyScore > 70 ? 'true' : 'false');
            
            await this.client.sendEvent(message);
            
            console.log(`📊 Telemetry sent from ${this.deviceId}: Status=${telemetryData.status}, Temp=${telemetryData.temperature.toFixed(1)}°C, Efficiency=${telemetryData.efficiency.toFixed(1)}%`);
            
        } catch (error) {
            console.error(`❌ Failed to send telemetry from ${this.deviceId}:`, error);
        }
    }
    
    startTelemetry(intervalMs = 30000) {
        console.log(`📡 Starting telemetry for ${this.deviceId} (interval: ${intervalMs}ms)`);
        
        this.telemetryInterval = setInterval(() => {
            this.sendTelemetry();
        }, intervalMs);
        
        // Send first telemetry immediately
        this.sendTelemetry();
    }
    
    async disconnect() {
        console.log(`🔌 Disconnecting device ${this.deviceId}...`);
        
        if (this.telemetryInterval) {
            clearInterval(this.telemetryInterval);
            this.telemetryInterval = null;
        }
        
        if (this.client) {
            await this.client.close();
            this.client = null;
        }
        
        console.log(`✅ Device ${this.deviceId} disconnected`);
    }
}

class EdgeDeviceManager {
    constructor() {
        this.devices = [];
        this.config = {
            numberOfDevices: parseInt(process.env.NUMBER_OF_DEVICES) || 5,
            telemetryInterval: parseInt(process.env.TELEMETRY_INTERVAL) * 1000 || 30000,
            enableRealTimeData: process.env.ENABLE_REAL_TIME_DATA === 'true'
        };
    }
    
    generateDeviceCredentials(deviceId) {
        // In a real implementation, these would come from a secure key store
        // For demo, we'll generate pseudo-random keys
        const crypto = require('crypto');
        const deviceKey = crypto.createHash('sha256').update(deviceId + 'shared-secret').digest('base64');
        
        return {
            deviceId: deviceId,
            deviceKey: deviceKey,
            registrationId: deviceId
        };
    }
    
    async startSimulation() {
        console.log(`🚀 Starting Smart Factory Edge Simulation with ${this.config.numberOfDevices} devices...`);
        
        // Create devices
        for (let i = 1; i <= this.config.numberOfDevices; i++) {
            const deviceId = `edge-device-${i.toString().padStart(3, '0')}`;
            const credentials = this.generateDeviceCredentials(deviceId);
            
            const device = new SmartFactoryDevice(
                credentials.deviceId,
                credentials.deviceKey,
                credentials.registrationId
            );
            
            this.devices.push(device);
        }
        
        // Connect all devices
        console.log(`🔌 Connecting ${this.devices.length} devices...`);
        
        for (const device of this.devices) {
            try {
                await device.connect();
                await new Promise(resolve => setTimeout(resolve, 1000)); // Stagger connections
            } catch (error) {
                console.error(`❌ Failed to connect device ${device.deviceId}:`, error);
            }
        }
        
        // Start telemetry for all connected devices
        console.log(`📡 Starting telemetry streams...`);
        
        for (const device of this.devices) {
            if (device.client) {
                device.startTelemetry(this.config.telemetryInterval);
                await new Promise(resolve => setTimeout(resolve, 500)); // Stagger telemetry start
            }
        }
        
        console.log(`✅ Edge simulation started successfully!`);
        console.log(`📊 Monitoring ${this.devices.filter(d => d.client).length} active devices`);
    }
    
    async stopSimulation() {
        console.log(`🛑 Stopping Smart Factory Edge Simulation...`);
        
        for (const device of this.devices) {
            try {
                await device.disconnect();
            } catch (error) {
                console.error(`❌ Error disconnecting device ${device.deviceId}:`, error);
            }
        }
        
        this.devices = [];
        console.log(`✅ Edge simulation stopped`);
    }
    
    getSimulationStatus() {
        const activeDevices = this.devices.filter(d => d.client).length;
        const totalTelemetry = this.devices.reduce((sum, d) => sum + (d.state?.productionCount || 0), 0);
        
        return {
            totalDevices: this.devices.length,
            activeDevices: activeDevices,
            telemetryInterval: this.config.telemetryInterval,
            totalProduction: totalTelemetry,
            uptime: process.uptime(),
            timestamp: new Date().toISOString()
        };
    }
}

// Main execution
async function main() {
    const manager = new EdgeDeviceManager();
    
    // Graceful shutdown handling
    process.on('SIGINT', async () => {
        console.log('\n🛑 Received SIGINT, shutting down gracefully...');
        await manager.stopSimulation();
        process.exit(0);
    });
    
    process.on('SIGTERM', async () => {
        console.log('\n🛑 Received SIGTERM, shutting down gracefully...');
        await manager.stopSimulation();
        process.exit(0);
    });
    
    // Start simulation
    try {
        await manager.startSimulation();
        
        // Status reporting
        setInterval(() => {
            const status = manager.getSimulationStatus();
            console.log(`📈 Status: ${status.activeDevices}/${status.totalDevices} devices active, ${status.totalProduction} total production`);
        }, 60000);
        
        console.log('🏭 Smart Factory Edge Simulation running. Press Ctrl+C to stop.');
        
    } catch (error) {
        console.error('❌ Failed to start edge simulation:', error);
        process.exit(1);
    }
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = { SmartFactoryDevice, EdgeDeviceManager };
'@

$edgeSimulatorPath = "C:\amapv2\edge\device-simulator.js"
New-Item -Path (Split-Path $edgeSimulatorPath -Parent) -ItemType Directory -Force | Out-Null
$edgeSimulatorCode | Out-File -FilePath $edgeSimulatorPath -Encoding UTF8

# 3. Create package.json for the edge simulator
$packageJson = @{
    "name" = "smart-factory-edge-simulator"
    "version" = "1.0.0"
    "description" = "IoT device simulator for Smart Factory running on Azure Arc VM"
    "main" = "device-simulator.js"
    "scripts" = @{
        "start" = "node device-simulator.js"
        "dev" = "nodemon device-simulator.js"
        "install-service" = "npm install -g node-windows && node install-service.js"
        "uninstall-service" = "node uninstall-service.js"
    }
    "dependencies" = @{
        "azure-iot-device" = "^1.18.1"
        "azure-iot-device-mqtt" = "^1.15.1"
        "azure-iot-security-symmetric-key" = "^1.5.1"
        "azure-iot-provisioning-device" = "^1.10.1"
        "azure-iot-provisioning-device-mqtt" = "^1.6.1"
    }
    "devDependencies" = @{
        "nodemon" = "^3.0.1"
        "node-windows" = "^1.0.0-beta.8"
    }
    "engines" = @{
        "node" = ">=18.0.0"
    }
    "keywords" = @("iot", "azure", "smart-factory", "edge", "telemetry")
    "author" = "Smart Factory Team"
    "license" = "MIT"
}

$packageJsonPath = "C:\amapv2\edge\package.json"
$packageJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $packageJsonPath -Encoding UTF8

# 4. Create Windows service installer
$serviceInstaller = @'
// Windows Service installer for Smart Factory Edge Simulator
const Service = require('node-windows').Service;

// Create a new service object
const svc = new Service({
    name: 'Smart Factory Edge Simulator',
    description: 'IoT device simulator for Smart Factory on Azure Arc VM',
    script: require('path').join(__dirname, 'device-simulator.js'),
    env: [
        {
            name: 'NODE_ENV',
            value: 'production'
        },
        {
            name: 'IOT_HUB_CONNECTION_STRING',
            value: process.env.IOT_HUB_CONNECTION_STRING || ''
        },
        {
            name: 'DPS_ENDPOINT',
            value: process.env.DPS_ENDPOINT || 'global.azure-devices-provisioning.net'
        },
        {
            name: 'DPS_ID_SCOPE',
            value: process.env.DPS_ID_SCOPE || ''
        },
        {
            name: 'NUMBER_OF_DEVICES',
            value: process.env.NUMBER_OF_DEVICES || '5'
        },
        {
            name: 'TELEMETRY_INTERVAL',
            value: process.env.TELEMETRY_INTERVAL || '30'
        },
        {
            name: 'ENABLE_REAL_TIME_DATA',
            value: process.env.ENABLE_REAL_TIME_DATA || 'true'
        }
    ]
});

// Listen for the "install" event
svc.on('install', () => {
    console.log('✅ Smart Factory Edge Simulator service installed successfully');
    svc.start();
});

// Install the service
svc.install();
'@

$serviceInstallerPath = "C:\amapv2\edge\install-service.js"
$serviceInstaller | Out-File -FilePath $serviceInstallerPath -Encoding UTF8

# 5. Create service uninstaller
$serviceUninstaller = @'
// Windows Service uninstaller for Smart Factory Edge Simulator
const Service = require('node-windows').Service;

// Create a new service object
const svc = new Service({
    name: 'Smart Factory Edge Simulator',
    script: require('path').join(__dirname, 'device-simulator.js')
});

// Listen for the "uninstall" event
svc.on('uninstall', () => {
    console.log('✅ Smart Factory Edge Simulator service uninstalled successfully');
});

// Uninstall the service
svc.uninstall();
'@

$serviceUninstallerPath = "C:\amapv2\edge\uninstall-service.js"
$serviceUninstaller | Out-File -FilePath $serviceUninstallerPath -Encoding UTF8

# 6. Create environment configuration script
$envConfig = @"
# 🔧 Smart Factory Edge Environment Configuration
# Set environment variables for the edge simulator

# IoT Hub Configuration
`$env:IOT_HUB_CONNECTION_STRING = "$IoTHubConnectionString"
`$env:IOT_HUB_HOSTNAME = "$((($IoTHubConnectionString -split ';')[0] -split '=')[1])"

# Device Provisioning Service Configuration
`$env:DPS_ENDPOINT = "$DeviceProvisioningServiceEndpoint"
`$env:DPS_ID_SCOPE = "$DeviceProvisioningServiceIdScope"

# Simulator Configuration
`$env:NUMBER_OF_DEVICES = "$NumberOfDevices"
`$env:TELEMETRY_INTERVAL = "$TelemetryInterval"
`$env:ENABLE_REAL_TIME_DATA = "$EnableRealTimeData"

# Edge Configuration
`$env:EDGE_VM_NAME = "`$env:COMPUTERNAME"
`$env:EDGE_LOCATION = "Factory Floor"
`$env:AZURE_ARC_ENABLED = "true"

Write-Host "✅ Environment variables configured for Smart Factory Edge Simulator" -ForegroundColor Green
Write-Host "IoT Hub: `$env:IOT_HUB_HOSTNAME" -ForegroundColor Cyan
Write-Host "DPS Scope: `$env:DPS_ID_SCOPE" -ForegroundColor Cyan
Write-Host "Devices: `$env:NUMBER_OF_DEVICES" -ForegroundColor Cyan
Write-Host "Interval: `$env:TELEMETRY_INTERVAL seconds" -ForegroundColor Cyan
"@

$envConfigPath = "C:\amapv2\edge\configure-environment.ps1"
$envConfig | Out-File -FilePath $envConfigPath -Encoding UTF8

# 7. Install dependencies and start the simulator
Write-Host "📦 Installing Node.js dependencies..." -ForegroundColor Yellow

Set-Location "C:\amapv2\edge"

try {
    npm install
    Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to install dependencies: $_" -ForegroundColor Red
    Write-Host "Please run 'npm install' manually in the C:\amapv2\edge directory" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Smart Factory Edge Device Simulator Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Files created in C:\amapv2\edge:" -ForegroundColor Cyan
Write-Host "- device-simulator.js (Main simulator application)" -ForegroundColor White
Write-Host "- package.json (Node.js dependencies)" -ForegroundColor White
Write-Host "- install-service.js (Windows service installer)" -ForegroundColor White
Write-Host "- uninstall-service.js (Windows service uninstaller)" -ForegroundColor White
Write-Host "- configure-environment.ps1 (Environment setup)" -ForegroundColor White
Write-Host ""
Write-Host "🚀 To start the simulator:" -ForegroundColor Yellow
Write-Host "1. Configure environment: .\configure-environment.ps1" -ForegroundColor White
Write-Host "2. Start simulator: npm start" -ForegroundColor White
Write-Host "3. Or install as service: npm run install-service" -ForegroundColor White
Write-Host ""
Write-Host "📊 The simulator will create $NumberOfDevices virtual devices" -ForegroundColor Green
Write-Host "📡 Sending telemetry every $TelemetryInterval seconds" -ForegroundColor Green