targetScope = 'subscription'

@description('Resource group name')
param resourceGroupName string = 'rg-smart-factory-prod'

@description('Location for all resources')
param location string = 'East US'

@description('Resource prefix for naming')
param resourcePrefix string = 'factory'

@description('Environment suffix')
param environment string = 'prod'

// Create Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

// Deploy core infrastructure (Digital Twins, IoT Hub, Function App)
module coreInfrastructure 'core-infrastructure.bicep' = {
  scope: rg
  name: 'coreInfrastructure'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    environment: environment
  }
}

// Deploy ML infrastructure (ML Workspace, Container Registry, etc.)
module mlInfrastructure 'ml-infrastructure.bicep' = {
  scope: rg
  name: 'mlInfrastructure'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    environment: environment
  }
}

// Outputs
output digitalTwinsHostName string = coreInfrastructure.outputs.digitalTwinsHostName
output iotHubName string = coreInfrastructure.outputs.iotHubName
output functionAppName string = coreInfrastructure.outputs.functionAppName
output mlWorkspaceName string = mlInfrastructure.outputs.mlWorkspaceName
output containerRegistryName string = mlInfrastructure.outputs.containerRegistryName
