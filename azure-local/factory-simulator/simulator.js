const { EventHubProducerClient } = require('@azure/event-hubs');
const { IoTHubConnectionString, EventHubConnectionString } = require('./config');

class FactorySimulator {
    constructor() {
        this.isRunning = false;
        this.interval = null;
        this.machines = [
            { id: 'machine-001', name: 'CNC Machine 1', type: 'CNC' },
            { id: 'machine-002', name: 'Assembly Robot', type: 'Robot' },
            { id: 'machine-003', name: 'Quality Scanner', type: 'Scanner' },
            { id: 'machine-004', name: 'Packaging Unit', type: 'Packaging' }
        ];
        
        this.productionLines = [
            { id: 'line-001', name: 'Main Production Line', productType: 'Widget A' },
            { id: 'line-002', name: 'Secondary Line', productType: 'Widget B' }
        ];
        
        this.factory = {
            id: 'factory-001',
            name: 'Smart Factory Demo',
            location: 'Azure Local VM - arc-simple'
        };
        
        console.log('Factory Simulator initialized');
        console.log(`Machines: ${this.machines.length}`);
        console.log(`Production Lines: ${this.productionLines.length}`);
    }
    
    generateMachineTelemetry(machine) {
        const baseTemp = 20;
        const tempVariation = Math.random() * 10 - 5; // ±5°C variation
        
        const basePressure = 101.3;
        const pressureVariation = Math.random() * 2 - 1; // ±1 kPa variation
        
        const baseVibration = 0.5;
        const vibrationVariation = Math.random() * 0.5;
        
        const baseOEE = 85;
        const oeeVariation = Math.random() * 20 - 10; // ±10% variation
        
        const statuses = ['running', 'idle', 'maintenance', 'error'];
        const status = statuses[Math.floor(Math.random() * statuses.length)];
        
        return {
            deviceId: machine.id,
            machineName: machine.name,
            machineType: machine.type,
            temperature: parseFloat((baseTemp + tempVariation).toFixed(2)),
            pressure: parseFloat((basePressure + pressureVariation).toFixed(2)),
            vibration: parseFloat((baseVibration + vibrationVariation).toFixed(3)),
            oee: parseFloat(Math.max(0, Math.min(100, baseOEE + oeeVariation)).toFixed(1)),
            status: status,
            timestamp: new Date().toISOString()
        };
    }
    
    generateLineTelemetry(line) {
        const baseThroughput = 100;
        const throughputVariation = Math.random() * 40 - 20; // ±20 units variation
        
        const baseQuality = 95;
        const qualityVariation = Math.random() * 10 - 5; // ±5% variation
        
        const baseEfficiency = 80;
        const efficiencyVariation = Math.random() * 30 - 15; // ±15% variation
        
        const statuses = ['active', 'stopped', 'setup', 'changeover'];
        const status = statuses[Math.floor(Math.random() * statuses.length)];
        
        return {
            deviceId: line.id,
            lineName: line.name,
            productType: line.productType,
            throughput: parseFloat(Math.max(0, baseThroughput + throughputVariation).toFixed(1)),
            quality: parseFloat(Math.max(0, Math.min(100, baseQuality + qualityVariation)).toFixed(2)),
            efficiency: parseFloat(Math.max(0, Math.min(100, baseEfficiency + efficiencyVariation)).toFixed(1)),
            status: status,
            timestamp: new Date().toISOString()
        };
    }
    
    generateFactoryTelemetry() {
        const baseEfficiency = 82;
        const efficiencyVariation = Math.random() * 20 - 10; // ±10% variation
        
        const baseEnergy = 1500;
        const energyVariation = Math.random() * 500 - 250; // ±250 kWh variation
        
        return {
            deviceId: this.factory.id,
            factoryName: this.factory.name,
            location: this.factory.location,
            overallEfficiency: parseFloat(Math.max(0, Math.min(100, baseEfficiency + efficiencyVariation)).toFixed(2)),
            energyConsumption: parseFloat(Math.max(0, baseEnergy + energyVariation).toFixed(1)),
            timestamp: new Date().toISOString()
        };
    }
    
    async sendTelemetry(telemetryData) {
        try {
            // Simulate sending to Azure IoT Hub
            console.log('📡 Sending telemetry:', JSON.stringify(telemetryData, null, 2));
            
            // In a real implementation, this would send to IoT Hub
            // For now, we'll log it and simulate the transmission
            
            return true;
        } catch (error) {
            console.error('❌ Error sending telemetry:', error.message);
            return false;
        }
    }
    
    async simulationCycle() {
        try {
            console.log('\\n🔄 Starting simulation cycle...');
            
            // Generate and send machine telemetry
            for (const machine of this.machines) {
                const telemetry = this.generateMachineTelemetry(machine);
                await this.sendTelemetry(telemetry);
                
                // Small delay between machine readings
                await new Promise(resolve => setTimeout(resolve, 100));
            }
            
            // Generate and send production line telemetry
            for (const line of this.productionLines) {
                const telemetry = this.generateLineTelemetry(line);
                await this.sendTelemetry(telemetry);
                
                await new Promise(resolve => setTimeout(resolve, 100));
            }
            
            // Generate and send factory-level telemetry
            const factoryTelemetry = this.generateFactoryTelemetry();
            await this.sendTelemetry(factoryTelemetry);
            
            console.log('✅ Simulation cycle completed');
            
        } catch (error) {
            console.error('❌ Error in simulation cycle:', error);
        }
    }
    
    start(intervalSeconds = 30) {
        if (this.isRunning) {
            console.log('⚠️ Simulator is already running');
            return;
        }
        
        console.log(`🚀 Starting Factory Simulator (${intervalSeconds}s intervals)`);
        console.log(`📍 Location: ${this.factory.location}`);
        console.log(`🏭 Factory: ${this.factory.name}`);
        
        this.isRunning = true;
        
        // Run initial cycle immediately
        this.simulationCycle();
        
        // Set up recurring cycles
        this.interval = setInterval(() => {
            this.simulationCycle();
        }, intervalSeconds * 1000);
        
        console.log('✅ Factory Simulator started successfully');
    }
    
    stop() {
        if (!this.isRunning) {
            console.log('⚠️ Simulator is not running');
            return;
        }
        
        console.log('🛑 Stopping Factory Simulator...');
        
        this.isRunning = false;
        
        if (this.interval) {
            clearInterval(this.interval);
            this.interval = null;
        }
        
        console.log('✅ Factory Simulator stopped');
    }
    
    getStatus() {
        return {
            isRunning: this.isRunning,
            factory: this.factory,
            machinesCount: this.machines.length,
            productionLinesCount: this.productionLines.length,
            uptime: this.interval ? 'Active' : 'Stopped'
        };
    }
}

// Export for use in other modules
module.exports = FactorySimulator;

// If running directly, start the simulator
if (require.main === module) {
    const simulator = new FactorySimulator();
    
    // Start with 30 second intervals
    simulator.start(30);
    
    // Graceful shutdown
    process.on('SIGINT', () => {
        console.log('\\n🛑 Received SIGINT, shutting down gracefully...');
        simulator.stop();
        process.exit(0);
    });
    
    process.on('SIGTERM', () => {
        console.log('\\n🛑 Received SIGTERM, shutting down gracefully...');
        simulator.stop();
        process.exit(0);
    });
}