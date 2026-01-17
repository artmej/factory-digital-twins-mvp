// RBAC Configuration for Smart Factory Managed Identities
// Production security configuration with least privilege access

param principalIds object
param cosmosDbAccountId string
param digitalTwinsId string
param eventHubNamespaceId string
param storageAccountId string

// Cosmos DB Data Contributor for ML API
resource cosmosDbRoleAssignmentMlApi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('cosmosdb-contributor-mlapi')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00000000-0000-0000-0000-000000000002') // Cosmos DB Data Contributor
    principalId: principalIds.mlApi
    principalType: 'ServicePrincipal'
  }
}

// Digital Twins Data Owner for ML API
resource digitalTwinsRoleAssignmentMlApi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('digitaltwins-owner-mlapi')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'bcd981a7-7f74-457b-83e1-cceb9e632ffe') // Digital Twins Data Owner
    principalId: principalIds.mlApi
    principalType: 'ServicePrincipal'
  }
}

// Event Hubs Data Receiver for Logic App
resource eventHubRoleAssignmentLogicApp 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('eventhub-receiver-logicapp')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a638d3c7-ab3a-418d-83e6-5f17a39d4fde') // Event Hubs Data Receiver
    principalId: principalIds.logicApp
    principalType: 'ServicePrincipal'
  }
}

// Cosmos DB Data Contributor for Logic App
resource cosmosDbRoleAssignmentLogicApp 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('cosmosdb-contributor-logicapp')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00000000-0000-0000-0000-000000000002') // Cosmos DB Data Contributor
    principalId: principalIds.logicApp
    principalType: 'ServicePrincipal'
  }
}

// Digital Twins Data Owner for Logic App
resource digitalTwinsRoleAssignmentLogicApp 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('digitaltwins-owner-logicapp')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'bcd981a7-7f74-457b-83e1-cceb9e632ffe') // Digital Twins Data Owner
    principalId: principalIds.logicApp
    principalType: 'ServicePrincipal'
  }
}

// Storage Blob Data Contributor for all services
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('storage-contributor-all')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: principalIds.mlApi
    principalType: 'ServicePrincipal'
  }
}

output roleAssignments array = [
  {
    service: 'ML API'
    roles: [
      'Cosmos DB Data Contributor'
      'Digital Twins Data Owner'
      'Storage Blob Data Contributor'
    ]
  }
  {
    service: 'Logic App'
    roles: [
      'Event Hubs Data Receiver'
      'Cosmos DB Data Contributor'
      'Digital Twins Data Owner'
    ]
  }
]