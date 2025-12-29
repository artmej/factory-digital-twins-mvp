@description('Prefix for all resources')
param prefix string = 'smartfactory'

@description('Environment suffix')
param environment string = 'prod'

@description('Location for all resources')
param location string = resourceGroup().location

// Reference existing IoT Hub
resource iotHub 'Microsoft.Devices/IotHubs@2023-06-30' existing = {
  name: '${prefix}-iothub-${environment}'
}

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: '${prefix}kv${environment}'
}

// Azure OpenAI Service
resource openAI 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: '${prefix}-openai-${environment}'
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: '${prefix}-openai-${environment}'
    networkAcls: {
      defaultAction: 'Allow'
    }
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// OpenAI Model Deployments
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openAI
  name: 'gpt-4o'
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-08-06'
    }
  }
  sku: {
    name: 'Standard'
    capacity: 20
  }
}

// Storage account for Function App
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'sfaistorage${environment}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// Function App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${prefix}-ai-plan-${environment}'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}

// AI Processing Function App
resource aiProcessingFunction 'Microsoft.Web/sites@2022-09-01' = {
  name: '${prefix}-ai-func-${environment}'
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: appServicePlan.id
    reserved: true
    siteConfig: {
      linuxFxVersion: 'NODE|18'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${az.environment().suffixes.storage}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'OPENAI_API_KEY'
          value: openAI.listKeys().key1
        }
        {
          name: 'OPENAI_ENDPOINT'
          value: openAI.properties.endpoint
        }
        {
          name: 'IOT_HUB_EVENTS_CONNECTION'
          value: 'Endpoint=${iotHub.properties.eventHubEndpoints.events.endpoint};SharedAccessKeyName=iothubowner;SharedAccessKey=${iotHub.listkeys().value[0].primaryKey};EntityPath=${iotHub.properties.eventHubEndpoints.events.path}'
        }
        {
          name: 'DIGITAL_TWINS_ENDPOINT'
          value: 'https://${prefix}-dt-${environment}.api.centralus.digitaltwins.azure.net'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Grant Function App access to Key Vault (optional, for additional secrets)
resource functionAppKeyVaultAccess 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: aiProcessingFunction.identity.principalId
        permissions: {
          secrets: ['get', 'list']
        }
      }
    ]
  }
}

// Output values
output openAIEndpoint string = openAI.properties.endpoint
output aiProcessingFunctionName string = aiProcessingFunction.name
output storageAccountName string = storageAccount.name
output functionUrl string = 'https://${aiProcessingFunction.properties.defaultHostName}'