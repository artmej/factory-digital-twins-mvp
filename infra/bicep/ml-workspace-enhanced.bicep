// Smart Factory ML Workspace - Production Ready
// Case Study #36: Azure ML Studio for Predictive Maintenance
targetScope = 'resourceGroup'

@description('Environment name (prod, staging, dev)')
param environment string = 'prod'

@description('Resource prefix for naming convention')
param resourcePrefix string = 'smartfactory'

@description('Location for all resources')
param location string = resourceGroup().location

// 🏭 VARIABLES - Professional Naming
var naming = {
  mlWorkspace: '${resourcePrefix}-ml-${environment}'
  mlStorage: replace('${resourcePrefix}ml${environment}st', '-', '')
  mlKeyVault: '${resourcePrefix}-ml-kv-${environment}'
  containerRegistry: replace('${resourcePrefix}ml${environment}acr', '-', '')
  appInsights: '${resourcePrefix}-ml-ai-${environment}'
  databricks: '${resourcePrefix}-databricks-${environment}'
  computeCluster: 'ml-compute-cluster'
  computeInstance: 'ml-dev-instance'
}

// 💾 1. ML STORAGE ACCOUNT - Data Lake para ML
resource mlStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: take(naming.mlStorage, 24)
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// 🔐 2. KEY VAULT - ML Secrets
resource mlKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: take(naming.mlKeyVault, 24)
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    softDeleteRetentionInDays: 7
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// 📊 3. APPLICATION INSIGHTS - ML Monitoring
resource mlAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: naming.appInsights
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

// 🐳 4. CONTAINER REGISTRY - ML Images
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: take(replace(naming.containerRegistry, '-', ''), 50)
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
  }
}

// 🧠 5. AZURE ML WORKSPACE - Main ML Hub
resource mlWorkspace 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: naming.mlWorkspace
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'Smart Factory ML Studio'
    description: 'Azure ML workspace for predictive maintenance and factory analytics'
    storageAccount: mlStorageAccount.id
    keyVault: mlKeyVault.id
    applicationInsights: mlAppInsights.id
    containerRegistry: containerRegistry.id
    publicNetworkAccess: 'Enabled'
    allowPublicAccessWhenBehindVnet: true
    discoveryUrl: 'https://${location}.api.azureml.ms/discovery'
  }
  dependsOn: [
    mlStorageAccount
    mlKeyVault
    mlAppInsights
    containerRegistry
  ]
}

// 💻 6. COMPUTE INSTANCE - ML Development
resource mlComputeInstance 'Microsoft.MachineLearningServices/workspaces/computes@2024-04-01' = {
  parent: mlWorkspace
  name: naming.computeInstance
  properties: {
    computeType: 'ComputeInstance'
    properties: {
      vmSize: 'Standard_DS3_v2'
      applicationSharingPolicy: 'Personal'
      computeInstanceAuthorizationType: 'personal'
      personalComputeInstanceSettings: {
        assignedUser: {
          objectId: '00000000-0000-0000-0000-000000000000' // Will be set during deployment
          tenantId: subscription().tenantId
        }
      }
    }
  }
}

// ⚡ 7. COMPUTE CLUSTER - Model Training
resource mlComputeCluster 'Microsoft.MachineLearningServices/workspaces/computes@2024-04-01' = {
  parent: mlWorkspace
  name: naming.computeCluster
  properties: {
    computeType: 'AmlCompute'
    properties: {
      vmSize: 'Standard_DS3_v2'
      vmPriority: 'Dedicated'
      scaleSettings: {
        minNodeCount: 0
        maxNodeCount: 4
        nodeIdleTimeBeforeScaleDown: 'PT2M'
      }
      enableNodePublicIp: false
      isolatedNetwork: false
      osType: 'Linux'
    }
  }
}

// 🧪 8. AZURE DATABRICKS - Advanced Analytics
resource databricksWorkspace 'Microsoft.Databricks/workspaces@2024-05-01' = {
  name: naming.databricks
  location: location
  sku: {
    name: 'premium'
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', '${resourceGroup().name}-databricks-managed')
    parameters: {
      enableNoPublicIp: {
        value: false
      }
    }
  }
}

// 🔍 9. SEARCH SERVICE - AI Search for Data Discovery
resource cognitiveSearch 'Microsoft.Search/searchServices@2023-11-01' = {
  name: '${resourcePrefix}-search-${environment}'
  location: location
  sku: {
    name: 'basic'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'enabled'
    networkRuleSet: {
      ipRules: []
    }
  }
}

// 📤 OUTPUTS - Para integración con otros templates
output mlWorkspaceName string = mlWorkspace.name
output mlWorkspaceId string = mlWorkspace.id
output containerRegistryName string = containerRegistry.name
output containerRegistryId string = containerRegistry.id
output mlStorageAccountName string = mlStorageAccount.name
output mlStorageAccountId string = mlStorageAccount.id
output databricksWorkspaceName string = databricksWorkspace.name
output databricksWorkspaceId string = databricksWorkspace.id
output cognitiveSearchName string = cognitiveSearch.name
output mlKeyVaultName string = mlKeyVault.name

// 🚨 RBAC Assignments para ML Workspace
resource mlWorkspaceContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: mlWorkspace
  name: guid(mlWorkspace.id, 'contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: mlWorkspace.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Blob Data Contributor para ML Workspace
resource storageContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: mlStorageAccount
  name: guid(mlStorageAccount.id, 'contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: mlWorkspace.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
