// AZURE LOCAL WORKING EDITION
// VM + IoT Hub + Post-Deploy Scripts for Azure Arc + AKS Edge + IoT Edge

@description('Location for all resources')
param location string = 'Central US'

@description('Admin username for the VM')
param adminUsername string = 'azlocal'

@description('Admin password for the VM')
@secure()
param adminPassword string = 'AzureLocal2024!'

@description('VM size for good performance')
param vmSize string = 'Standard_D4s_v3'

@description('Resource prefix for naming')
param resourcePrefix string = 'azlocal'

// IoT Hub for Smart Factory
resource iotHub 'Microsoft.Devices/IotHubs@2023-06-30' = {
  name: '${resourcePrefix}-iothub-${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'S1'
    capacity: 1
  }
  properties: {
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 7
        partitionCount: 2
      }
    }
    routing: {
      endpoints: {
        serviceBusQueues: []
        serviceBusTopics: []
        eventHubs: []
        storageContainers: []
      }
      routes: []
      fallbackRoute: {
        name: '$fallback'
        source: 'DeviceMessages'
        condition: 'true'
        endpointNames: ['events']
        isEnabled: true
      }
    }
  }
}

// Network Security Group with all required ports
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: '${resourcePrefix}-nsg'
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
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Smart-Factory-Web'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRanges: ['30080', '30081', '30082', '30083', '30084']
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'IoT-Edge-MQTT'
        properties: {
          priority: 1002
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRanges: ['8883', '443', '5671']
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'OPC-UA'
        properties: {
          priority: 1003
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '50000'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: '${resourcePrefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'azlocal-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// Public IP
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${resourcePrefix}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${resourcePrefix}-${uniqueString(resourceGroup().id)}'
    }
  }
}

// Network Interface
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: '${resourcePrefix}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
          subnet: {
            id: vnet.properties.subnets[0].id
          }
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
}

// Azure Local Host VM
resource azureLocalHost 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: '${resourcePrefix}-vm'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'azlocal01'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        name: '${resourcePrefix}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: 512
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: [
        {
          name: '${resourcePrefix}-datadisk'
          diskSizeGB: 1024
          lun: 0
          createOption: 'Empty'
          caching: 'None'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
      ]
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

// VM is ready - manual setup required via RDP
// Setup scripts will be provided for Azure Arc + AKS Edge + IoT Edge

// Outputs
output vmPublicIP string = publicIP.properties.ipAddress
output vmFQDN string = publicIP.properties.dnsSettings.fqdn
output vmName string = azureLocalHost.name
output iotHubName string = iotHub.name
output iotHubConnectionString string = 'HostName=${iotHub.name}.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=${iotHub.listKeys().value[0].primaryKey}'
output rdpConnection string = 'mstsc /v:${publicIP.properties.ipAddress}'
output resourceGroupName string = resourceGroup().name

output setupInstructions object = {
  step1: 'RDP to VM: ${publicIP.properties.ipAddress}'
  step2: 'Username: ${adminUsername}, Password: <provided>'
  step3: 'Run setup script manually in VM'
  step4: 'IoT Hub ready: ${iotHub.name}'
  nextSteps: [
    'Install Azure Arc Agent'
    'Install AKS Edge Essentials'
    'Install IoT Edge Runtime'
    'Configure Smart Factory modules'
  ]
}
