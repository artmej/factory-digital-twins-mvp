const { Client } = require('azure-iot-device');
const { Mqtt } = require('azure-iot-device-mqtt');

class FactorySimulator {
  constructor() {
    this.deviceConnectionString = process.env.DEVICE_CONN_STRING;
    this.intervalMs = parseInt(process.env.SEND_INTERVAL_MS) || 5000;
    
    if (!this.deviceConnectionString) {
      throw new Error('DEVICE_CONN_STRING environment variable is required');
    }
    
    this.client = null;
    this.intervalId = null;
    
    // Simulation state
    this.lineState = {
      lineId: 'lineA',
      state: 'running',
      baseOee: 0.85,
      baseThroughput: 120,
      oeeVariation: 0.1,
      throughputVariation: 20
    };
    
    this.machineState = {
      machineId: 'machineA',
      serial: 'MAC-001-2024',
      model: 'ProductionLine-X1',
      health: 'healthy',
      baseTemperature: 75,
      temperatureVariation: 10
    };
    
    this.sensorState = {
      sensorId: 'sensorA',
      kind: 'temperature',
      unit: 'celsius',
      baseValue: 75,
      valueVariation: 10
    };
    
    console.log('Factory Simulator initialized');
    console.log(`Send interval: ${this.intervalMs}ms`);
  }
  
  // Generate realistic sensor values with some variation
  generateSensorData() {
    const now = new Date().toISOString();
    
    // Add some randomness and trends
    const timeVariation = Math.sin(Date.now() / 60000) * 0.3; // 1-minute cycle
    const randomVariation = (Math.random() - 0.5) * 2;
    
    // Line metrics
    const oee = Math.max(0.1, Math.min(1.0, 
      this.lineState.baseOee + 
      (timeVariation + randomVariation) * this.lineState.oeeVariation
    ));
    
    const throughput = Math.max(0, 
      this.lineState.baseThroughput + 
      (timeVariation + randomVariation) * this.lineState.throughputVariation
    );
    
    // Machine metrics
    const temperature = this.machineState.baseTemperature + 
      (timeVariation + randomVariation) * this.machineState.temperatureVariation;
    
    // Sensor value (same as temperature for this simulation)
    const sensorValue = this.sensorState.baseValue + 
      (timeVariation + randomVariation) * this.sensorState.valueVariation;
    
    // Determine states based on values
    let lineState = 'running';
    let machineHealth = 'healthy';
    
    if (oee < 0.6) {
      lineState = 'degraded';
    } else if (oee < 0.3) {
      lineState = 'stopped';
    }
    
    if (temperature > 85) {
      machineHealth = 'warning';
    } else if (temperature > 90) {
      machineHealth = 'critical';
    }
    
    return {
      lineId: this.lineState.lineId,
      machineId: this.machineState.machineId,
      sensorId: this.sensorState.sensorId,
      throughput: Math.round(throughput * 10) / 10,
      temperature: Math.round(temperature * 10) / 10,
      value: Math.round(sensorValue * 10) / 10,
      state: lineState,
      oee: Math.round(oee * 100) / 100,
      health: machineHealth,
      ts: now
    };
  }
  
  async connect() {
    try {
      console.log('Connecting to IoT Hub...');
      this.client = Client.fromConnectionString(this.deviceConnectionString, Mqtt);
      
      // Set up connection event handlers
      this.client.on('connect', () => {
        console.log('✅ Connected to IoT Hub successfully');
      });
      
      this.client.on('error', (err) => {
        console.error('❌ IoT Hub connection error:', err.message);
      });
      
      this.client.on('disconnect', () => {
        console.log('🔌 Disconnected from IoT Hub');
      });
      
      await this.client.open();
      console.log('IoT Hub connection established');
      
    } catch (error) {
      console.error('Failed to connect to IoT Hub:', error.message);
      throw error;
    }
  }
  
  async sendTelemetry() {
    if (!this.client) {
      console.error('Client not connected');
      return;
    }
    
    try {
      const telemetryData = this.generateSensorData();
      const message = JSON.stringify(telemetryData);
      
      console.log('📤 Sending telemetry:', message);
      
      await new Promise((resolve, reject) => {
        this.client.sendEvent({ 
          data: message,
          properties: {
            contentType: 'application/json',
            contentEncoding: 'utf-8'
          }
        }, (err) => {
          if (err) {
            reject(err);
          } else {
            resolve();
          }
        });
      });
      
      console.log('✅ Telemetry sent successfully');
      
    } catch (error) {
      console.error('❌ Failed to send telemetry:', error.message);
    }
  }
  
  startSimulation() {
    console.log('🏭 Starting factory simulation...');
    
    // Send initial telemetry
    this.sendTelemetry();
    
    // Set up interval for continuous sending
    this.intervalId = setInterval(() => {
      this.sendTelemetry();
    }, this.intervalMs);
    
    console.log(`📡 Telemetry will be sent every ${this.intervalMs}ms`);
  }
  
  stopSimulation() {
    console.log('🛑 Stopping simulation...');
    
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    
    if (this.client) {
      this.client.close();
      this.client = null;
    }
    
    console.log('Simulation stopped');
  }
  
  // Simulate different scenarios
  simulateIncident() {
    console.log('🚨 Simulating incident - reducing performance');
    this.lineState.baseOee = 0.45;
    this.lineState.baseThroughput = 60;
    this.machineState.baseTemperature = 88;
    
    setTimeout(() => {
      this.recoverFromIncident();
    }, 30000); // Recover after 30 seconds
  }
  
  recoverFromIncident() {
    console.log('🔧 Recovering from incident');
    this.lineState.baseOee = 0.85;
    this.lineState.baseThroughput = 120;
    this.machineState.baseTemperature = 75;
  }
}

// Main execution
async function main() {
  const simulator = new FactorySimulator();
  
  // Handle graceful shutdown
  process.on('SIGINT', () => {
    console.log('\\n🛑 Received SIGINT, shutting down gracefully...');
    simulator.stopSimulation();
    process.exit(0);
  });
  
  process.on('SIGTERM', () => {
    console.log('\\n🛑 Received SIGTERM, shutting down gracefully...');
    simulator.stopSimulation();
    process.exit(0);
  });
  
  try {
    await simulator.connect();
    simulator.startSimulation();
    
    // Simulate an incident after 2 minutes (for demo purposes)
    setTimeout(() => {
      simulator.simulateIncident();
    }, 120000);
    
    console.log('\\n🏭 Factory simulator is running. Press Ctrl+C to stop.');
    console.log('📊 Monitor telemetry in Azure IoT Hub and Digital Twins Explorer');
    
  } catch (error) {
    console.error('Failed to start simulator:', error.message);
    process.exit(1);
  }
}

// Run the simulator
if (require.main === module) {
  main().catch(console.error);
}

module.exports = FactorySimulator;