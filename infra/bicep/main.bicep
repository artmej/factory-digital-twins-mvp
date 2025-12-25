// Smart Factory Infrastructure - Azure Master Program
// Case Study #36 - Production Ready Template
// Version: 1.0.0 - Clean & Secure (No hardcoded secrets)
targetScope = 'resourceGroup'

@description('Environment name (prod, staging, dev)')
param environment string = 'prod'

@description('Resource prefix for naming convention')
param resourcePrefix string = 'smartfactory'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Admin username for VMs')
param adminUsername string

@description('VM Admin password - will be stored in Key Vault')
@secure()
param adminPassword string

@description('Your IP address for network access (format: x.x.x.x/32)')
param allowedIPAddress string = '0.0.0.0/32'

// 🏗️ VARIABLES & NAMING CONVENTION
var naming = {
  suffix: '${resourcePrefix}-${environment}'
  storageAccount: replace('${resourcePrefix}${environment}st', '-', '')
  keyVault: '${resourcePrefix}-${environment}-kv'
  iotHub: '${resourcePrefix}-${environment}-iot'
  digitalTwins: '${resourcePrefix}-${environment}-dt'
  functions: '${resourcePrefix}-${environment}-func'
  webApp: '${resourcePrefix}-${environment}-web'
  vm: '${resourcePrefix}-${environment}-vm'
  vnet: '${resourcePrefix}-${environment}-vnet'
  cosmos: '${resourcePrefix}-${environment}-cosmos'
}

// 🔐 1. KEY VAULT - Security Foundation (Deploy First)
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: naming.keyVault
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

// 📊 2. LOG ANALYTICS & MONITORING
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${naming.suffix}-logs'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${naming.suffix}-ai'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

// 💾 3. STORAGE ACCOUNT - Data Lake
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: naming.storageAccount
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
  }
}

// 🌐 4. VIRTUAL NETWORK - Secure Connectivity
resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: naming.vnet
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'functions'
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: [
            {
              name: 'Microsoft.Web.serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

// 🔧 5. IOT HUB - Device Connectivity (Simplified)
resource iotHub 'Microsoft.Devices/IotHubs@2023-06-30' = {
  name: naming.iotHub
  location: location
  sku: {
    name: 'S1'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: 4
      }
    }
    routing: {
      endpoints: {
        eventHubs: []
        serviceBusQueues: []
        serviceBusTopics: []
        storageContainers: []
      }
      routes: []
    }
  }
}

// 🏭 6. AZURE DIGITAL TWINS - Factory Model
resource digitalTwins 'Microsoft.DigitalTwins/digitalTwinsInstances@2023-01-31' = {
  name: naming.digitalTwins
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// ⚡ 7. AZURE FUNCTIONS - Serverless Processing
resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${naming.suffix}-plan'
  location: location
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
  properties: {
    reserved: false
  }
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: naming.functions
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: true
    virtualNetworkSubnetId: '${vnet.id}/subnets/functions'
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.name
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
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/appinsights-key/)'
        }
        {
          name: 'DIGITAL_TWINS_URL'
          value: 'https://${digitalTwins.name}.api.${location}.digitaltwins.azure.net'
        }
      ]
    }
  }
}

// 🗄️ 8. COSMOS DB - NoSQL Database (No Free Tier)
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: naming.cosmos
  location: location
  kind: 'GlobalDocumentDB'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
  }
}

resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  parent: cosmosAccount
  name: 'SmartFactory'
  properties: {
    resource: {
      id: 'SmartFactory'
    }
    options: {
      throughput: 400
    }
  }
}

// 🖥️ 9. VIRTUAL MACHINE - Edge Gateway
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  name: '${naming.vm}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${vnet.id}/subnets/default'
          }
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: '${naming.vm}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: '${naming.vm}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourceAddressPrefix: allowedIPAddress
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'HTTP'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '80'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: 'smart-vm'  // Nombre corto para Windows
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    osProfile: {
      computerName: 'smart-vm'  // Nombre corto para Windows
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        name: '${naming.vm}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}

// 🔐 10. STORE SECRETS IN KEY VAULT
resource appInsightsSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'appinsights-key'
  properties: {
    value: appInsights.properties.InstrumentationKey
  }
}

resource adminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'vm-admin-password'
  properties: {
    value: adminPassword
  }
}

// 🔑 11. RBAC ASSIGNMENTS - Managed Identity Permissions
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, iotHub.id, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: iotHub.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource functionAppDigitalTwinsRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: digitalTwins
  name: guid(digitalTwins.id, functionApp.id, 'bcd981a7-7f74-457b-83e1-cceb9e632ffe')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'bcd981a7-7f74-457b-83e1-cceb9e632ffe') // Azure Digital Twins Data Owner
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource functionAppStorageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, functionApp.id, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource functionAppKeyVaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, functionApp.id, '4633458b-17de-408a-b874-0445c86b69e6')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// 📤 OUTPUTS - No Secrets!
output resourceGroupName string = resourceGroup().name
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output iotHubName string = iotHub.name
output digitalTwinsName string = digitalTwins.name
output digitalTwinsUrl string = 'https://${digitalTwins.name}.api.${location}.digitaltwins.azure.net'
output functionAppName string = functionApp.name
output storageAccountName string = storageAccount.name
output cosmosAccountName string = cosmosAccount.name
output vmName string = 'smart-vm'
output vmPublicIP string = publicIP.properties.ipAddress
output deploymentComplete string = '✅ Smart Factory Infrastructure deployed successfully!'
