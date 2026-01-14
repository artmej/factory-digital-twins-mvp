const { DigitalTwinsClient } = require('@azure/digital-twins-core');
const { DefaultAzureCredential } = require('@azure/identity');

describe('Azure Digital Twins Integration', () => {
  let dtClient;
  const testTwinId = 'test-factory-001';
  
  beforeAll(async () => {
    // Initialize Digital Twins client for integration testing
    const digitalTwinsUrl = process.env.DIGITAL_TWINS_URL;
    
    if (!digitalTwinsUrl) {
      throw new Error('DIGITAL_TWINS_URL environment variable is required for integration tests');
    }
    
    const credential = new DefaultAzureCredential();
    dtClient = new DigitalTwinsClient(digitalTwinsUrl, credential);
    
    // Wait a bit for Azure authentication
    await new Promise(resolve => setTimeout(resolve, 2000));
  }, 30000);

  afterAll(async () => {
    // Clean up test twins
    try {
      await dtClient.deleteDigitalTwin(testTwinId);
    } catch (error) {
      // Twin might not exist, that's OK
      console.log('Cleanup: Twin might not exist', error.message);
    }
  });

  describe('Digital Twins Operations', () => {
    test('should create factory twin successfully', async () => {
      const factoryTwin = {
        $metadata: {
          $model: 'dtmi:mx:factory;1'
        },
        name: 'Test Factory',
        location: 'Test Location'
      };

      await dtClient.upsertDigitalTwin(testTwinId, factoryTwin);
      
      const retrievedTwin = await dtClient.getDigitalTwin(testTwinId);
      expect(retrievedTwin.name).toBe('Test Factory');
      expect(retrievedTwin.location).toBe('Test Location');
    }, 15000);

    test('should update twin properties', async () => {
      const patch = [
        {
          op: 'replace',
          path: '/name',
          value: 'Updated Test Factory'
        }
      ];

      await dtClient.updateDigitalTwin(testTwinId, patch);
      
      const updatedTwin = await dtClient.getDigitalTwin(testTwinId);
      expect(updatedTwin.name).toBe('Updated Test Factory');
    }, 15000);

    test('should query twins successfully', async () => {
      const query = "SELECT * FROM DIGITALTWINS T WHERE T.name = 'Updated Test Factory'";
      
      const queryResult = dtClient.queryTwins(query);
      const twins = [];
      
      for await (const twin of queryResult) {
        twins.push(twin);
      }
      
      expect(twins.length).toBeGreaterThan(0);
      expect(twins[0].name).toBe('Updated Test Factory');
    }, 15000);
  });

  describe('Model Management', () => {
    test('should list available models', async () => {
      const models = [];
      
      for await (const model of dtClient.listModels()) {
        models.push(model);
      }
      
      expect(models.length).toBeGreaterThan(0);
      
      // Check if our factory models are deployed
      const modelIds = models.map(m => m.id);
      expect(modelIds).toContain('dtmi:mx:factory;1');
    }, 15000);

    test('should validate model relationships', async () => {
      const factoryModel = await dtClient.getModel('dtmi:mx:factory;1');
      
      expect(factoryModel).toBeDefined();
      expect(factoryModel.dtdlModel).toContain('dtmi:mx:factory:line;1');
    }, 10000);
  });

  describe('Telemetry Publishing', () => {
    test('should publish telemetry to twin', async () => {
      const telemetryData = {
        temperature: 75.5,
        timestamp: new Date().toISOString()
      };

      // This should not throw an error
      await expect(
        dtClient.publishTelemetry(testTwinId, 'temperatureReading', telemetryData)
      ).resolves.not.toThrow();
    }, 10000);
  });
});