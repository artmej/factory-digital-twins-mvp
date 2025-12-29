@description('Prefix for all resources')
param prefix string = 'smartfactory'

@description('Environment suffix')
param environment string = 'prod'

@description('Location for all resources')
param location string = resourceGroup().location

@description('OpenAI model deployments configuration')
param openAIDeployments array = [
  {
    name: 'gpt-4o'
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-08-06'
    }
    capacity: 20
  }
  {
    name: 'text-embedding-3-large'
    model: {
      format: 'OpenAI'
      name: 'text-embedding-3-large'
      version: '1'
    }
    capacity: 10
  }
]

// Existing Smart Factory resources references
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: '${prefix}kv${environment}'
}

resource iotHub 'Microsoft.Devices/IotHubs@2023-06-30' existing = {
  name: '${prefix}-iothub-${environment}'
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
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// OpenAI Model Deployments
resource openAIDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = [for deployment in openAIDeployments: {
  parent: openAI
  name: deployment.name
  properties: {
    model: deployment.model
    raiPolicyName: contains(deployment, 'raiPolicyName') ? deployment.raiPolicyName : null
  }
  sku: contains(deployment, 'capacity') ? {
    name: 'Standard'
    capacity: deployment.capacity
  } : {
    name: 'Standard'
    capacity: 20
  }
}]

// AI Processing Function App
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
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=openai-api-key)'
        }
        {
          name: 'OPENAI_ENDPOINT'
          value: openAI.properties.endpoint
        }
        {
          name: 'IOT_HUB_CONNECTION_STRING'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=iothub-connection-string)'
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

// Event Hub for AI processing queue
resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' = {
  name: '${prefix}-ai-eventhub-${environment}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    minimumTlsVersion: '1.2'
  }
}

resource aiProcessingEventHub 'Microsoft.EventHub/namespaces/eventhubs@2024-01-01' = {
  parent: eventHubNamespace
  name: 'ai-processing'
  properties: {
    messageRetentionInDays: 1
    partitionCount: 2
  }
}

// Store OpenAI API key in Key Vault
resource openAIKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'openai-api-key'
  properties: {
    value: openAI.listKeys().key1
  }
}

// Grant Function App access to Key Vault
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
output eventHubNamespace string = eventHubNamespace.name
output storageAccountName string = storageAccount.name