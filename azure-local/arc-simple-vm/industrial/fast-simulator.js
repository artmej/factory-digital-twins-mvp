const { DigitalTwinsClient } = require('@azure/digital-twins-core');
const { DefaultAzureCredential } = require('@azure/identity');

class FastFactorySimulator {
  constructor() {
    this.digitalTwinsUrl = 'https://factory-adt-dev.api.eus.digitaltwins.azure.net';
    this.credential = new DefaultAzureCredential();
    this.dtClient = new DigitalTwinsClient(this.digitalTwinsUrl, this.credential);
    
    this.isRunning = false;
    this.iteration = 0;
  }

  generateRealisticData() {
    this.iteration++;
    const time = Date.now() / 1000;
    
    // Simulación realista con patrones
    const baseOee = 0.85;
    const oeeVariation = Math.sin(time / 20) * 0.1; // Oscilación lenta
    const oee = Math.max(0.6, Math.min(0.98, baseOee + oeeVariation + (Math.random() - 0.5) * 0.15));
    
    // Estado basado en OEE
    const state = oee > 0.7 ? 'running' : (oee > 0.5 ? 'degraded' : 'maintenance');
    
    // Salud de máquina correlacionada
    const health = oee > 0.8 ? 'healthy' : (oee > 0.6 ? 'warning' : 'critical');
    
    // Temperatura realista
    const baseTemp = 70;
    const tempVariation = (1 - oee) * 20; // Más caliente cuando baja OEE
    const temperature = baseTemp + tempVariation + Math.random() * 5;
    
    return {
      lineId: 'lineA',
      machineId: 'machineA',
      sensorId: 'sensorA',
      oee: Math.round(oee * 1000) / 1000,
      state: state,
      health: health,
      temperature: Math.round(temperature * 10) / 10,
      throughput: Math.round((oee * 150) + Math.random() * 20),
      timestamp: new Date().toISOString(),
      iteration: this.iteration
    };
  }

  async updateTwinProperty(twinId, propertyName, value) {
    try {
      const patch = [{ op: 'replace', path: `/${propertyName}`, value: value }];
      await this.dtClient.updateDigitalTwin(twinId, patch);
      console.log(`✅ [${new Date().toLocaleTimeString()}] ${twinId}.${propertyName} = ${value}`);
    } catch (error) {
      console.error(`❌ Error updating ${twinId}.${propertyName}:`, error.message);
    }
  }

  async simulateRealtimeFactory() {
    const data = this.generateRealisticData();
    
    console.log(`🏭 [Iter ${data.iteration}] Factory Status: OEE=${data.oee} | State=${data.state} | Health=${data.health} | Temp=${data.temperature}°C`);
    
    // Actualizar propiedades
    await Promise.all([
      this.updateTwinProperty(data.lineId, 'oee', data.oee),
      this.updateTwinProperty(data.lineId, 'state', data.state),
      this.updateTwinProperty(data.machineId, 'health', data.health)
    ]);
    
    // Mostrar métricas
    this.showMetrics(data);
  }

  showMetrics(data) {
    const statusColor = data.oee > 0.8 ? '🟢' : (data.oee > 0.6 ? '🟡' : '🔴');
    console.log(`${statusColor} OEE: ${(data.oee * 100).toFixed(1)}% | Throughput: ${data.throughput} units/min | Temp: ${data.temperature}°C`);
    console.log(`📊 Trend: ${data.state.toUpperCase()} → Health: ${data.health.toUpperCase()}\n`);
  }

  async start() {
    console.log('🚀 Iniciando Factory Digital Twins FAST SIMULATOR...');
    console.log('⚡ Updates cada 3 segundos para demo en tiempo real');
    console.log('👁️  Ve a ADT Explorer y haz click en lineA para ver cambios\n');
    
    this.isRunning = true;
    
    while (this.isRunning) {
      await this.simulateRealtimeFactory();
      await new Promise(resolve => setTimeout(resolve, 3000)); // 3 segundos
    }
  }

  stop() {
    console.log('🛑 Deteniendo simulador...');
    this.isRunning = false;
  }
}

const simulator = new FastFactorySimulator();
simulator.start().catch(console.error);

process.on('SIGINT', () => {
  simulator.stop();
  process.exit(0);
});
