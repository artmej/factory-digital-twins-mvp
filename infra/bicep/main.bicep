@description('Location for all resources')
param location string = resourceGroup().location

@description('Prefix for all resources')
param resourcePrefix string = 'factory'

@description('Environment suffix')
param environment string = 'dev'

@description('Deployment phase: infrastructure, compute, or all')
param deploymentPhase string = 'all'

// Variables
var digitalTwinsName = '${resourcePrefix}-adt-${environment}'
var iotHubName = '${resourcePrefix}-iothub-${environment}'
var functionAppName = '${resourcePrefix}-func-adt-${environment}'
var storageAccountName = '${resourcePrefix}st${environment}${uniqueString(resourceGroup().id)}'
var appServicePlanName = '${resourcePrefix}-plan-${environment}'
var vnetName = '${resourcePrefix}-vnet-${environment}'
var subnetName = 'default'
var privateEndpointsSubnetName = 'private-endpoints'
var aciSubnetName = 'aci-agents'
var aciName = '${resourcePrefix}-aci-agent-${environment}'
var logAnalyticsName = '${resourcePrefix}-logs-${environment}'

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'Microsoft.Web.serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: privateEndpointsSubnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: aciSubnetName
        properties: {
          addressPrefix: '10.0.3.0/24'
          delegations: [
            {
              name: 'Microsoft.ContainerInstance.containerGroups'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
  }
}

// Storage Account for Function App
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
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
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// App Service Plan for Function App
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  properties: {
    reserved: true
  }
}

// IoT Hub
resource iotHub 'Microsoft.Devices/IotHubs@2023-06-30' = {
  name: iotHubName
  location: location
  sku: {
    name: 'S1'
    capacity: 1
  }
  properties: {
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: 2
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
      fallbackRoute: {
        name: '$fallback'
        source: 'DeviceMessages'
        condition: 'true'
        endpointNames: [
          'events'
        ]
        isEnabled: true
      }
    }
    messagingEndpoints: {
      fileNotifications: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
    enableFileUploadNotifications: false
    cloudToDevice: {
      maxDeliveryCount: 10
      defaultTtlAsIso8601: 'PT1H'
      feedback: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
  }
}

// Digital Twins Instance
resource digitalTwins 'Microsoft.DigitalTwins/digitalTwinsInstances@2023-01-31' = {
  name: digitalTwinsName
  location: location
  properties: {
    publicNetworkAccess: 'Enabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Note: Digital Twins Private Endpoint removed - using public access for better compatibility

// Function App
resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  dependsOn: [
    storagePrivateEndpoint
    storagePrivateEndpointFile
  ]
  properties: {
    serverFarmId: appServicePlan.id
    reserved: true
    virtualNetworkSubnetId: '${vnet.id}/subnets/${subnetName}'
    siteConfig: {
      linuxFxVersion: 'NODE|20'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
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
          name: 'DIGITAL_TWINS_URL'
          value: 'https://${digitalTwins.properties.hostName}'
        }
        {
          name: 'IOTHUB_EVENTHUB_PATH'
          value: iotHub.properties.eventHubEndpoints.events.path
        }
        {
          name: 'IOTHUB_EVENTHUB_ENDPOINT__fullyQualifiedNamespace'
          value: '${iotHub.name}.azure-devices.net'
        }
        {
          name: 'IOTHUB_NAME'
          value: iotHub.name
        }
      ]
    }
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Role Assignment: Function App as Digital Twins Data Owner
resource digitalTwinsDataOwnerRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'bcd981a7-7f74-457b-83e1-cceb9e632ffe' // Azure Digital Twins Data Owner
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: digitalTwins
  name: guid(digitalTwins.id, functionApp.id, digitalTwinsDataOwnerRole.id)
  properties: {
    roleDefinitionId: digitalTwinsDataOwnerRole.id
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Role Assignment: Function App as IoT Hub Data Contributor
resource iotHubDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '4fc6c259-987e-4a07-842e-c321cc9d413f' // IoT Hub Data Contributor
}

resource iotHubRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: iotHub
  name: guid(iotHub.id, functionApp.id, iotHubDataContributorRole.id)
  properties: {
    roleDefinitionId: iotHubDataContributorRole.id
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Role Assignment: Function App as Storage Blob Data Contributor
resource storageBlobDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
}

resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, functionApp.id, storageBlobDataContributorRole.id)
  properties: {
    roleDefinitionId: storageBlobDataContributorRole.id
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Private Endpoints for Storage Account
resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${storageAccount.name}-pe-blob'
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/${privateEndpointsSubnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${storageAccount.name}-connection-blob'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource storagePrivateEndpointFile 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${storageAccount.name}-pe-file'
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/${privateEndpointsSubnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${storageAccount.name}-connection-file'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

// Note: IoT Device creation moved to post-deployment script
// Creating devices via Bicep has compatibility issues

// Log Analytics for ACI monitoring
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Azure Container Instances for self-hosted DevOps agent
resource aciAgent 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: aciName
  location: location
  properties: {
    containers: [
      {
        name: 'devops-agent'
        properties: {
          image: 'ubuntu:22.04'
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 2
            }
          }
          command: [
            '/bin/bash'
            '-c'
            'apt-get update && apt-get install -y curl wget git && sleep infinity'
          ]
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Always'
    subnetIds: [
      {
        id: '${vnet.id}/subnets/${aciSubnetName}'
      }
    ]
    diagnostics: {
      logAnalytics: {
        workspaceId: logAnalytics.properties.customerId
        workspaceKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// Outputs
output digitalTwinsName string = digitalTwins.name
output digitalTwinsUrl string = 'https://${digitalTwins.properties.hostName}'
output iotHubName string = iotHub.name
output functionAppName string = functionApp.name
output iotHubConnectionString string = 'Endpoint=${iotHub.properties.eventHubEndpoints.events.endpoint};SharedAccessKeyName=iothubowner;SharedAccessKey=${iotHub.listKeys().value[0].primaryKey};EntityPath=${iotHub.properties.eventHubEndpoints.events.path}'
output aciName string = aciAgent.name
output logAnalyticsName string = logAnalytics.name
output aciSubnetId string = '${vnet.id}/subnets/${aciSubnetName}'