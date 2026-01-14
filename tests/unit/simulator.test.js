// Mock FactorySimulator for testing
class FactorySimulator {
  constructor() {
    if (!process.env.DEVICE_CONN_STRING) {
      throw new Error('DEVICE_CONN_STRING environment variable is required');
    }
    this.deviceConnectionString = process.env.DEVICE_CONN_STRING;
    this.intervalMs = parseInt(process.env.SEND_INTERVAL_MS) || 5000;
    
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
  }
  
  generateSensorData() {
    return {
      timestamp: new Date().toISOString(),
      lineData: {
        lineId: 'lineA',
        state: 'running',
        oee: 0.85 + (Math.random() - 0.5) * 0.1,
        throughput: 120 + (Math.random() - 0.5) * 20
      },
      machineData: {
        machineId: 'machineA',
        temperature: 75 + (Math.random() - 0.5) * 10
      },
      sensorData: {
        sensorId: 'sensorA',
        value: 75 + (Math.random() - 0.5) * 10
      }
    };
  }
}

describe('FactorySimulator', () => {
  let simulator;
  
  beforeEach(() => {
    // Mock environment variables
    process.env.DEVICE_CONN_STRING = 'HostName=test.azure-devices.net;DeviceId=testDevice;SharedAccessKey=testkey';
    process.env.SEND_INTERVAL_MS = '1000';
    
    simulator = new FactorySimulator();
  });
  
  afterEach(() => {
    if (simulator && simulator.intervalId) {
      clearInterval(simulator.intervalId);
    }
  });

  describe('Constructor', () => {
    test('should initialize with environment variables', () => {
      expect(simulator.deviceConnectionString).toBe('HostName=test.azure-devices.net;DeviceId=testDevice;SharedAccessKey=testkey');
      expect(simulator.intervalMs).toBe(1000);
    });

    test('should throw error if DEVICE_CONN_STRING is missing', () => {
      delete process.env.DEVICE_CONN_STRING;
      expect(() => new FactorySimulator()).toThrow('DEVICE_CONN_STRING environment variable is required');
    });

    test('should use default interval if not specified', () => {
      delete process.env.SEND_INTERVAL_MS;
      const sim = new FactorySimulator();
      expect(sim.intervalMs).toBe(5000); // Default value
    });
  });

  describe('generateSensorData', () => {
    test('should generate realistic sensor data', () => {
      const data = simulator.generateSensorData();
      
      expect(data).toHaveProperty('timestamp');
      expect(data).toHaveProperty('lineData');
      expect(data).toHaveProperty('machineData');
      expect(data).toHaveProperty('sensorData');
      
      // Validate line data
      expect(data.lineData).toHaveProperty('lineId', 'lineA');
      expect(data.lineData).toHaveProperty('state');
      expect(data.lineData.oee).toBeGreaterThan(0);
      expect(data.lineData.oee).toBeLessThanOrEqual(1);
      
      // Validate machine data
      expect(data.machineData).toHaveProperty('machineId', 'machineA');
      expect(data.machineData).toHaveProperty('temperature');
      expect(typeof data.machineData.temperature).toBe('number');
      
      // Validate sensor data
      expect(data.sensorData).toHaveProperty('sensorId', 'sensorA');
      expect(data.sensorData).toHaveProperty('value');
      expect(typeof data.sensorData.value).toBe('number');
    });

    test('should generate different values on multiple calls', () => {
      const data1 = simulator.generateSensorData();
      const data2 = simulator.generateSensorData();
      
      // Values should be different due to randomization
      expect(data1.machineData.temperature).not.toBe(data2.machineData.temperature);
      expect(data1.sensorData.value).not.toBe(data2.sensorData.value);
    });
  });

  describe('State Management', () => {
    test('should have default line state', () => {
      expect(simulator.lineState).toEqual({
        lineId: 'lineA',
        state: 'running',
        baseOee: 0.85,
        baseThroughput: 120,
        oeeVariation: 0.1,
        throughputVariation: 20
      });
    });

    test('should have default machine state', () => {
      expect(simulator.machineState).toEqual({
        machineId: 'machineA',
        serial: 'MAC-001-2024',
        model: 'ProductionLine-X1',
        health: 'healthy',
        baseTemperature: 75,
        temperatureVariation: 10
      });
    });
  });
});