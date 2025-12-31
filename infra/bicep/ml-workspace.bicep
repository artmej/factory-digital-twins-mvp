@description('Smart Factory ML Components - Only missing pieces')
param prefix string = 'smartfactory'
param environment string = 'prod'
param location string = resourceGroup().location

// Reference existing Cosmos DB
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' existing = {
  name: '${prefix}-${environment}-cosmos'
}

// Reference existing IoT Hub  
resource iotHub 'Microsoft.Devices/IotHubs@2023-06-30' existing = {
  name: '${prefix}-${environment}-iot'
}

// Reference existing Storage Account (or create one for ML)
resource mlStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'sfmlstorage${environment}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

// Application Insights for ML monitoring
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${prefix}-ml-insights-${environment}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

// Key Vault for ML secrets
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'sfmlkv${environment}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    enableRbacAuthorization: true
  }
}

// Azure ML Workspace
resource mlWorkspace 'Microsoft.MachineLearningServices/workspaces@2023-10-01' = {
  name: '${prefix}-ml-${environment}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'Smart Factory ML Workspace'
    description: 'Machine Learning for Smart Factory predictive analytics'
    storageAccount: mlStorage.id
    keyVault: keyVault.id
    applicationInsights: appInsights.id
  }
}

// Compute Instance for ML development
resource mlCompute 'Microsoft.MachineLearningServices/workspaces/computes@2023-10-01' = {
  parent: mlWorkspace
  name: 'ml-compute-instance'
  properties: {
    computeType: 'ComputeInstance'
    properties: {
      vmSize: 'Standard_DS3_v2'
      applicationSharingPolicy: 'Personal'
      computeInstanceAuthorizationType: 'personal'
    }
  }
}

// Data Factory for automated ML pipeline
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: '${prefix}-ml-adf-${environment}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

// Outputs for integration
output mlWorkspaceName string = mlWorkspace.name
output mlWorkspaceId string = mlWorkspace.id
output dataFactoryName string = dataFactory.name
output storageAccountName string = mlStorage.name
