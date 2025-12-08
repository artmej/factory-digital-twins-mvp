// Mock Azure SDK modules
const mockDigitalTwinsClient = {
  updateDigitalTwin: jest.fn(),
  publishTelemetry: jest.fn()
};

const mockDefaultAzureCredential = jest.fn();

jest.mock('@azure/digital-twins-core', () => ({
  DigitalTwinsClient: jest.fn().mockImplementation(() => mockDigitalTwinsClient)
}));

jest.mock('@azure/identity', () => ({
  DefaultAzureCredential: jest.fn().mockImplementation(() => mockDefaultAzureCredential)
}));

describe('Azure Function - ADT Projection', () => {
  let functionHandler;
  
  beforeEach(() => {
    // Reset mocks
    jest.clearAllMocks();
    
    // Set environment variables
    process.env.DIGITAL_TWINS_URL = 'https://test-adt.api.wcus.digitaltwins.azure.net';
    
    // Import the function after setting up mocks
    delete require.cache[require.resolve('../../src/function-adt-projection/index.js')];
    functionHandler = require('../../src/function-adt-projection/index.js');
  });

  describe('updateTwinProperty', () => {
    test('should update twin property successfully', async () => {
      const mockContext = {
        log: {
          info: jest.fn(),
          warn: jest.fn(),
          error: jest.fn()
        }
      };

      mockDigitalTwinsClient.updateDigitalTwin.mockResolvedValue();

      // Test the function (assuming it exports the helper function)
      // This would need to be adjusted based on actual function structure
      const testValue = 85.5;
      const twinId = 'testTwin';
      const propertyName = 'temperature';

      // Since the function is not directly exported, we'll test via the main handler
      // with a mock IoT Hub message
      const mockIoTMessage = {
        body: JSON.stringify({
          machineData: {
            machineId: 'machineA',
            temperature: testValue
          }
        }),
        enqueuedTimeUtc: new Date().toISOString()
      };

      await functionHandler(mockContext, mockIoTMessage);

      // Verify the Digital Twins client was called
      expect(mockDigitalTwinsClient.updateDigitalTwin).toHaveBeenCalled();
    });

    test('should handle null/undefined values gracefully', async () => {
      const mockContext = {
        log: {
          info: jest.fn(),
          warn: jest.fn(),
          error: jest.fn()
        }
      };

      const mockIoTMessage = {
        body: JSON.stringify({
          machineData: {
            machineId: 'machineA',
            temperature: null
          }
        }),
        enqueuedTimeUtc: new Date().toISOString()
      };

      await functionHandler(mockContext, mockIoTMessage);

      // Should log warning about null value
      expect(mockContext.log.warn).toHaveBeenCalled();
    });
  });

  describe('IoT Message Processing', () => {
    test('should process valid IoT Hub message', async () => {
      const mockContext = {
        log: {
          info: jest.fn(),
          warn: jest.fn(),
          error: jest.fn()
        }
      };

      const mockIoTMessage = {
        body: JSON.stringify({
          lineData: {
            lineId: 'lineA',
            state: 'running',
            oee: 0.85,
            throughput: 120
          },
          machineData: {
            machineId: 'machineA',
            temperature: 75.5,
            vibration: 0.2
          },
          sensorData: {
            sensorId: 'sensorA',
            value: 75.5
          }
        }),
        enqueuedTimeUtc: new Date().toISOString()
      };

      mockDigitalTwinsClient.updateDigitalTwin.mockResolvedValue();
      mockDigitalTwinsClient.publishTelemetry.mockResolvedValue();

      await functionHandler(mockContext, mockIoTMessage);

      // Verify successful processing
      expect(mockContext.log.info).toHaveBeenCalled();
      expect(mockDigitalTwinsClient.updateDigitalTwin).toHaveBeenCalled();
    });

    test('should handle malformed JSON gracefully', async () => {
      const mockContext = {
        log: {
          info: jest.fn(),
          warn: jest.fn(),
          error: jest.fn()
        }
      };

      const mockIoTMessage = {
        body: 'invalid json{',
        enqueuedTimeUtc: new Date().toISOString()
      };

      await functionHandler(mockContext, mockIoTMessage);

      // Should log error about invalid JSON
      expect(mockContext.log.error).toHaveBeenCalled();
    });

    test('should handle missing environment variables', () => {
      delete process.env.DIGITAL_TWINS_URL;
      
      expect(() => {
        delete require.cache[require.resolve('../../src/function-adt-projection/index.js')];
        require('../../src/function-adt-projection/index.js');
      }).toThrow('DIGITAL_TWINS_URL environment variable is not set');
    });
  });
});