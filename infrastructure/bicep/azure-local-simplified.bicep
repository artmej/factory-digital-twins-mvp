// AZURE LOCAL SIMPLIFIED - NO CUSTOM SCRIPT
// Basic VM for manual Azure Local setup

@description('Location for all resources')
param location string = 'Central US'

@description('Admin username for the VM')
param adminUsername string = 'azlocal'

@description('Admin password for the VM')
@secure()
param adminPassword string = 'AzureLocal2024!'

@description('VM size - needs good performance')
param vmSize string = 'Standard_D4s_v3'

@description('Resource group prefix')
param resourcePrefix string = 'azlocal'

// IoT Hub for manufacturing
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
        retentionTimeInDays: 1
        partitionCount: 2
      }
    }
  }
}

// Network Security Group
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
        name: 'Smart-Factory-Ports'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRanges: ['30080', '30081', '30082', '30083', '30084', '8883', '443', '50000']
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

// Minimal setup script via CustomScriptExtension
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: 'QuickSetup'
  parent: azureLocalHost
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'powershell.exe -Command "New-Item -ItemType Directory -Force -Path C:\\AzureLocal\\Setup; \'READY_FOR_AZURE_LOCAL_SETUP\' | Out-File C:\\AzureLocal\\Setup\\ready.txt"'
    }
  }
}

// Outputs
output vmPublicIP string = publicIP.properties.ipAddress
output vmFQDN string = publicIP.properties.dnsSettings.fqdn
output iotHubName string = iotHub.name
output iotHubConnectionString string = 'HostName=${iotHub.name}.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=${iotHub.listKeys().value[0].primaryKey}'
output rdpConnection string = 'mstsc /v:${publicIP.properties.ipAddress}'
output setupInstructions object = {
  step1: 'RDP to VM using: mstsc /v:${publicIP.properties.ipAddress}'
  step2: 'Username: ${adminUsername}, Password: <provided>'
  step3: 'VM is ready at C:\\AzureLocal\\Setup\\'
  step4: 'Download and run Azure Local setup manually'
  iotHub: 'IoT Hub created: ${iotHub.name}'
}
