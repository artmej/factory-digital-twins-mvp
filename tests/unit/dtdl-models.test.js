const fs = require('fs');
const path = require('path');

describe('DTDL Models Validation', () => {
  const modelsDir = path.join(__dirname, '../../models');
  const modelFiles = fs.readdirSync(modelsDir).filter(file => file.endsWith('.dtdl.json'));

  describe('JSON Validity', () => {
    modelFiles.forEach(file => {
      test(`${file} should be valid JSON`, () => {
        const filePath = path.join(modelsDir, file);
        const content = fs.readFileSync(filePath, 'utf8');
        
        expect(() => JSON.parse(content)).not.toThrow();
      });
    });
  });

  describe('DTDL Schema Compliance', () => {
    modelFiles.forEach(file => {
      test(`${file} should have required DTDL properties`, () => {
        const filePath = path.join(modelsDir, file);
        const content = fs.readFileSync(filePath, 'utf8');
        const model = JSON.parse(content);

        // Check required DTDL v3 properties
        expect(model).toHaveProperty('@context');
        expect(model).toHaveProperty('@id');
        expect(model).toHaveProperty('@type');
        expect(model['@context']).toBe('dtmi:dtdl:context;3');
        expect(model['@type']).toBe('Interface');
      });
    });
  });

  describe('Model Relationships', () => {
    test('Factory model should have correct structure', () => {
      const factoryModel = JSON.parse(
        fs.readFileSync(path.join(modelsDir, 'factory.dtdl.json'), 'utf8')
      );

      expect(factoryModel['@id']).toBe('dtmi:mx:factory;1');
      expect(factoryModel.displayName).toBe('Factory');
      
      // Check for contains relationship
      const containsRelationship = factoryModel.contents.find(
        content => content['@type'] === 'Relationship' && content.name === 'contains'
      );
      expect(containsRelationship).toBeDefined();
      expect(containsRelationship.target).toBe('dtmi:mx:factory:line;1');
    });

    test('Line model should have correct properties', () => {
      const lineModel = JSON.parse(
        fs.readFileSync(path.join(modelsDir, 'line.dtdl.json'), 'utf8')
      );

      expect(lineModel['@id']).toBe('dtmi:mx:factory:line;1');
      
      // Check for required properties
      const properties = lineModel.contents.filter(content => content['@type'] === 'Property');
      const propertyNames = properties.map(p => p.name);
      
      expect(propertyNames).toContain('oee');
      expect(propertyNames).toContain('state');
    });

    test('Machine model should have telemetry definitions', () => {
      const machineModel = JSON.parse(
        fs.readFileSync(path.join(modelsDir, 'machine.dtdl.json'), 'utf8')
      );

      expect(machineModel['@id']).toBe('dtmi:mx:factory:machine;1');
      
      // Check for telemetry
      const telemetries = machineModel.contents.filter(content => content['@type'] === 'Telemetry');
      expect(telemetries.length).toBeGreaterThan(0);
      
      const telemetryNames = telemetries.map(t => t.name);
      expect(telemetryNames).toContain('temperature');
    });

    test('Sensor model should have value property', () => {
      const sensorModel = JSON.parse(
        fs.readFileSync(path.join(modelsDir, 'sensor.dtdl.json'), 'utf8')
      );

      expect(sensorModel['@id']).toBe('dtmi:mx:factory:sensor;1');
      
      // Check for value telemetry/property
      const contents = sensorModel.contents;
      const hasValue = contents.some(content => 
        content.name === 'value' && 
        (content['@type'] === 'Telemetry' || content['@type'] === 'Property')
      );
      expect(hasValue).toBe(true);
    });
  });
});