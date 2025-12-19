const { DigitalTwinsClient } = require('@azure/digital-twins-core');
const { DefaultAzureCredential } = require('@azure/identity');

class DirectFactorySimulator {
  constructor() {
    this.digitalTwinsUrl = 'https://factory-adt-dev.api.eus.digitaltwins.azure.net';
    this.credential = new DefaultAzureCredential();
    this.dtClient = new DigitalTwinsClient(this.digitalTwinsUrl, this.credential);
    
    this.isRunning = false;
  }

  generateFactoryData() {
    const now = new Date();
    
    return {
      lineId: 'lineA',
      machineId: 'machineA', 
      sensorId: 'sensorA',
      factoryId: 'factory1',
      
      // Line data
      oee: 0.75 + Math.random() * 0.2, // 0.75-0.95
      state: Math.random() > 0.1 ? 'running' : 'maintenance',
      throughput: 100 + Math.random() * 40, // 100-140 units/min
      
      // Machine data  
      health: Math.random() > 0.05 ? 'healthy' : 'warning',
      
      // Sensor data
      temperature: 65 + Math.random() * 15, // 65-80°C
      value: Math.random() * 100,
      
      timestamp: now.toISOString()
    };
  }

  async updateTwinProperty(twinId, propertyName, value) {
    try {
      const patch = [{ op: 'replace', path: `/${propertyName}`, value: value }];
      await this.dtClient.updateDigitalTwin(twinId, patch);
      console.log(`✅ Updated ${twinId}.${propertyName} = ${value}`);
    } catch (error) {
      console.error(`❌ Error updating ${twinId}.${propertyName}:`, error.message);
    }
  }

  async publishTelemetry(twinId, telemetryName, value, timestamp) {
    try {
      const telemetryData = { [telemetryName]: value };
      const messageId = `sim-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      await this.dtClient.publishTelemetry(twinId, telemetryData, messageId);
      console.log(`📡 Published ${twinId}.${telemetryName} = ${value}`);
    } catch (error) {
      console.error(`❌ Error publishing telemetry for ${twinId}:`, error.message);
    }
  }

  async simulateFactoryData() {
    console.log('🏭 Generando datos de fábrica simulados...');
    
    const data = this.generateFactoryData();
    console.log('📊 Datos generados:', JSON.stringify(data, null, 2));
    
    // Update properties
    await this.updateTwinProperty(data.lineId, 'oee', data.oee);
    await this.updateTwinProperty(data.lineId, 'state', data.state);
    await this.updateTwinProperty(data.machineId, 'health', data.health);
    
    // Publish telemetry
    await this.publishTelemetry(data.lineId, 'throughput', data.throughput, data.timestamp);
    await this.publishTelemetry(data.machineId, 'temperature', data.temperature, data.timestamp);  
    await this.publishTelemetry(data.sensorId, 'value', data.value, data.timestamp);
  }

  async start() {
    console.log('🚀 Iniciando simulador directo de Factory Digital Twins...');
    this.isRunning = true;
    
    while (this.isRunning) {
      await this.simulateFactoryData();
      console.log('⏸️  Esperando 10 segundos...\n');
      await new Promise(resolve => setTimeout(resolve, 10000));
    }
  }

  stop() {
    console.log('🛑 Deteniendo simulador...');
    this.isRunning = false;
  }
}

// Ejecutar simulador
const simulator = new DirectFactorySimulator();
simulator.start().catch(console.error);

// Manejo de Ctrl+C
process.on('SIGINT', () => {
  simulator.stop();
  process.exit(0);
});
