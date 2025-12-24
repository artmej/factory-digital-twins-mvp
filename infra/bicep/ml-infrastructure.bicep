@description('Location for all resources')
param location string = resourceGroup().location

@description('Prefix for all resources')
param resourcePrefix string = 'factory'

@description('Environment suffix')
param environment string = 'dev'

// Variables
var mlWorkspaceName = '${resourcePrefix}-ml-${environment}'
var keyVaultName = '${resourcePrefix}-kv-${environment}-${uniqueString(resourceGroup().id)}'
var storageAccountName = '${resourcePrefix}mlst${environment}${uniqueString(resourceGroup().id)}'
var applicationInsightsName = '${resourcePrefix}-ai-${environment}'
var containerRegistryName = '${resourcePrefix}cr${environment}${uniqueString(resourceGroup().id)}'

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'AppServiceEnablementCreate'
  }
}

// Storage Account for ML
resource mlStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: take(replace(storageAccountName, '-', ''), 24)
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: take(keyVaultName, 24)
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    accessPolicies: []
    enableRbacAuthorization: true
    publicNetworkAccess: 'Enabled'
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: false
  }
}

// Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: take(replace(containerRegistryName, '-', ''), 50)
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
  }
}

// Machine Learning Workspace
resource mlWorkspace 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: mlWorkspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'Smart Factory ML Workspace'
    description: 'ML workspace for smart factory predictive maintenance'
    storageAccount: mlStorageAccount.id
    keyVault: keyVault.id
    applicationInsights: applicationInsights.id
    containerRegistry: containerRegistry.id
    publicNetworkAccess: 'Enabled'
    allowPublicAccessWhenBehindVnet: true
  }
  dependsOn: [
    mlStorageAccount
    keyVault
    applicationInsights
    containerRegistry
  ]
}

// Outputs
output mlWorkspaceName string = mlWorkspace.name
output containerRegistryName string = containerRegistry.name
output keyVaultName string = keyVault.name
output applicationInsightsName string = applicationInsights.name
output mlStorageAccountName string = mlStorageAccount.name
