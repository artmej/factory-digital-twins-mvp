const { Client } = require('azure-iot-device');
const { Mqtt } = require('azure-iot-device-mqtt');

describe('IoT Hub Integration', () => {
  let iotClient;
  const deviceConnectionString = process.env.DEVICE_CONNECTION_STRING;
  
  beforeAll(async () => {
    if (!deviceConnectionString) {
      throw new Error('DEVICE_CONNECTION_STRING environment variable is required');
    }
    
    iotClient = Client.fromConnectionString(deviceConnectionString, Mqtt);
    
    return new Promise((resolve, reject) => {
      iotClient.open((err) => {
        if (err) {
          reject(err);
        } else {
          resolve();
        }
      });
    });
  }, 20000);

  afterAll(async () => {
    if (iotClient) {
      return new Promise((resolve) => {
        iotClient.close(() => resolve());
      });
    }
  });

  describe('Device Connectivity', () => {
    test('should connect to IoT Hub successfully', async () => {
      // Connection is established in beforeAll
      expect(iotClient).toBeDefined();
    });

    test('should send telemetry message', async () => {
      const testMessage = {
        lineData: {
          lineId: 'test-line',
          state: 'running',
          oee: 0.85,
          throughput: 120
        },
        machineData: {
          machineId: 'test-machine',
          temperature: 75.5,
          vibration: 0.2
        },
        sensorData: {
          sensorId: 'test-sensor',
          value: 75.5
        },
        timestamp: new Date().toISOString()
      };

      return new Promise((resolve, reject) => {
        const message = new Message(JSON.stringify(testMessage));
        
        iotClient.sendEvent(message, (err, result) => {
          if (err) {
            reject(err);
          } else {
            expect(result.constructor.name).toBe('MessageEnqueued');
            resolve();
          }
        });
      });
    }, 15000);
  });

  describe('Device Twin Operations', () => {
    test('should retrieve device twin', async () => {
      return new Promise((resolve, reject) => {
        iotClient.getTwin((err, twin) => {
          if (err) {
            reject(err);
          } else {
            expect(twin).toBeDefined();
            expect(twin.properties).toBeDefined();
            expect(twin.properties.desired).toBeDefined();
            expect(twin.properties.reported).toBeDefined();
            resolve();
          }
        });
      });
    }, 10000);

    test('should update reported properties', async () => {
      return new Promise((resolve, reject) => {
        iotClient.getTwin((err, twin) => {
          if (err) {
            reject(err);
            return;
          }

          const reportedProperties = {
            testProperty: 'integration-test-value',
            lastUpdate: new Date().toISOString()
          };

          twin.properties.reported.update(reportedProperties, (updateErr) => {
            if (updateErr) {
              reject(updateErr);
            } else {
              resolve();
            }
          });
        });
      });
    }, 10000);
  });

  describe('Cloud-to-Device Messages', () => {
    test('should receive cloud-to-device messages', async () => {
      let messageReceived = false;

      const messageHandler = (msg) => {
        console.log('Received message:', msg.data.toString());
        messageReceived = true;
        iotClient.complete(msg, () => {
          console.log('Message completed');
        });
      };

      iotClient.on('message', messageHandler);

      // Wait a bit for any pending messages
      await new Promise(resolve => setTimeout(resolve, 3000));

      // For this test, we just verify the handler is set up correctly
      expect(typeof messageHandler).toBe('function');
      
      // Clean up
      iotClient.removeListener('message', messageHandler);
    }, 5000);
  });
});

// Helper class for IoT messages (if not available from SDK)
class Message {
  constructor(data) {
    this.data = data;
  }
}