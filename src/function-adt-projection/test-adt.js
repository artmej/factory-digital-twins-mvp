const { DigitalTwinsClient } = require('@azure/digital-twins-core');
const { DefaultAzureCredential } = require('@azure/identity');

async function testConnection() {
  try {
    console.log('🔗 Iniciando test de conexión ADT...');
    
    const digitalTwinsUrl = 'https://factory-adt-dev.api.eus.digitaltwins.azure.net';
    const credential = new DefaultAzureCredential();
    const dtClient = new DigitalTwinsClient(digitalTwinsUrl, credential);
    
    console.log('✅ Cliente ADT creado');
    
    // Test simple - listar modelos
    const models = dtClient.listModels();
    console.log('📋 Intentando listar modelos...');
    
    let count = 0;
    for await (const model of models) {
      console.log(`   📋 Modelo: ${model.id}`);
      count++;
    }
    
    console.log(`✅ Encontrados ${count} modelos`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

testConnection();
