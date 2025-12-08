@description('Location for all resources')
param location string = resourceGroup().location

@description('Prefix for all resources')
param resourcePrefix string = 'factory'

@description('Environment suffix')
param environment string = 'dev'

// Variables
var digitalTwinsName = '${resourcePrefix}-adt-${environment}'
var iotHubName = '${resourcePrefix}-iothub-${environment}'
var functionAppName = '${resourcePrefix}-func-${environment}'
var storageAccountName = '${resourcePrefix}stor${environment}'
var appServicePlanName = '${resourcePrefix}-plan-${environment}'
// Temporarily disabling VNet for initial deployment
// var vnetName = '${resourcePrefix}-vnet-${environment}'
// var subnetName = 'default'
// var privateEndpointsSubnetName = 'private-endpoints'

// Virtual Network - Temporarily disabled for initial deployment
/*
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
    ]
  }
}
*/

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
    // Network restrictions disabled for initial deployment
  }
}

// App Service Plan for Function App
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
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
    publicNetworkAccess: 'Enabled' // Will be disabled after private endpoints are configured
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Private Endpoint for Digital Twins - Disabled for initial deployment
/*
resource digitalTwinsPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${digitalTwinsName}-pe'
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/${privateEndpointsSubnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${digitalTwinsName}-connection'
        properties: {
          privateLinkServiceId: digitalTwins.id
          groupIds: [
            'API'
          ]
        }
      }
    ]
  }
}
*/

// Function App
resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: appServicePlan.id
    reserved: true
    // virtualNetworkSubnetId: '${vnet.id}/subnets/${subnetName}' // Disabled for initial deployment
    siteConfig: {
      linuxFxVersion: 'NODE|18'
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
          name: 'IOTHUB_CONNECTION'
          value: 'Endpoint=${iotHub.properties.eventHubEndpoints.events.endpoint};SharedAccessKeyName=iothubowner;SharedAccessKey=${iotHub.listKeys().value[0].primaryKey};EntityPath=${iotHub.properties.eventHubEndpoints.events.path}'
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

// Private Endpoints for Storage Account - Disabled for initial deployment
/*
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
*/

// Create a device in IoT Hub for the simulator
resource factoryDevice 'Microsoft.Devices/IotHubs/devices@2023-06-30' = {
  parent: iotHub
  name: 'factory-device'
  properties: {
    deviceId: 'factory-device'
    status: 'Enabled'
    statusReason: 'DeviceCreatedForFactory'
    authMethod: {
      type: 'SharedAccessKey'
      symmetricKey: {
        primaryKey: base64(guid('primary-key-${iotHub.name}-factory-device'))
        secondaryKey: base64(guid('secondary-key-${iotHub.name}-factory-device'))
      }
    }
  }
}

// Outputs
output digitalTwinsName string = digitalTwins.name
output digitalTwinsUrl string = 'https://${digitalTwins.properties.hostName}'
output iotHubName string = iotHub.name
output functionAppName string = functionApp.name
output deviceConnectionString string = 'HostName=${iotHub.properties.hostName};DeviceId=factory-device;SharedAccessKey=${factoryDevice.properties.authMethod.symmetricKey.primaryKey}'
output iotHubConnectionString string = 'Endpoint=${iotHub.properties.eventHubEndpoints.events.endpoint};SharedAccessKeyName=iothubowner;SharedAccessKey=${iotHub.listKeys().value[0].primaryKey};EntityPath=${iotHub.properties.eventHubEndpoints.events.path}'