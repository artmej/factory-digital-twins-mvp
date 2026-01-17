@description('Location for all resources')
param location string = resourceGroup().location

@description('Prefix for all resources')
param resourcePrefix string = 'smartfactory'

@description('Environment suffix')
param environment string = 'v2'

// Variables
var digitalTwinsName = '${resourcePrefix}-adt-${environment}'
var iotHubName = '${resourcePrefix}-iothub-${environment}'

// Digital Twins Instance
resource digitalTwins 'Microsoft.DigitalTwins/digitalTwinsInstances@2023-01-31' = {
  name: digitalTwinsName
  location: location
  properties: {
    publicNetworkAccess: 'Disabled'
  }
  identity: {
    type: 'SystemAssigned'
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
    publicNetworkAccess: 'Disabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

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
output deviceConnectionString string = 'HostName=${iotHub.properties.hostName};DeviceId=factory-device;SharedAccessKey=${factoryDevice.properties.authMethod.symmetricKey.primaryKey}'
output iotHubConnectionString string = 'Endpoint=${iotHub.properties.eventHubEndpoints.events.endpoint};SharedAccessKeyName=iothubowner;SharedAccessKey=${iotHub.listKeys().value[0].primaryKey};EntityPath=${iotHub.properties.eventHubEndpoints.events.path}'