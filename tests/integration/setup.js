// Integration test setup
const { DefaultAzureCredential } = require('@azure/identity');

// Global test configuration
beforeAll(async () => {
  // Validate required environment variables
  const requiredEnvVars = [
    'AZURE_RESOURCE_GROUP',
    'RESOURCE_PREFIX', 
    'ENVIRONMENT'
  ];

  const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
  
  if (missingVars.length > 0) {
    throw new Error(`Missing required environment variables: ${missingVars.join(', ')}`);
  }

  // Set derived environment variables if not set
  if (!process.env.DIGITAL_TWINS_URL) {
    const adtName = `${process.env.RESOURCE_PREFIX}-adt-${process.env.ENVIRONMENT}`;
    process.env.DIGITAL_TWINS_URL = `https://${adtName}.api.wcus.digitaltwins.azure.net`;
  }

  if (!process.env.FUNCTION_APP_URL) {
    const funcName = `${process.env.RESOURCE_PREFIX}-func-${process.env.ENVIRONMENT}`;
    process.env.FUNCTION_APP_URL = `https://${funcName}.azurewebsites.net`;
  }

  // Test Azure authentication
  try {
    const credential = new DefaultAzureCredential();
    await credential.getToken(['https://digitaltwins.azure.net/.default']);
    console.log('✅ Azure authentication successful');
  } catch (error) {
    console.warn('⚠️ Azure authentication failed:', error.message);
    console.warn('Some integration tests may fail');
  }
}, 30000);

// Global test cleanup
afterAll(async () => {
  // Any global cleanup if needed
  console.log('🧹 Integration tests completed');
});