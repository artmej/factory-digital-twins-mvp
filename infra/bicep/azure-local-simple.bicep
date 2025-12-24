@description('Location for all resources')
param location string = 'Central US'

@description('Admin username for the VM')
param adminUsername string = 'smartfactory'

@description('Admin password for the VM')
@secure()
param adminPassword string = 'SmartFactory2024!'

@description('VM size - needs nested virtualization support')
param vmSize string = 'Standard_B2s'

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-azure-local-simple'
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
        name: 'Factory-Ports'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRanges: ['8080', '8081', '8082']
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
  name: 'vnet-azure-local-simple'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'subnet-default'
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
  name: 'pip-azure-local-simple'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'azure-local-simple-${uniqueString(resourceGroup().id)}'
    }
  }
}

// Network Interface
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'nic-azure-local-simple'
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
    enableAcceleratedNetworking: false
  }
}

// Azure Local Host VM
resource azureLocalHost 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'vm-azure-local-simple'
  location: location
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
        name: 'osdisk-azure-local-simple'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: 256
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      dataDisks: [
        {
          name: 'datadisk-azure-local-simple'
          diskSizeGB: 512
          lun: 0
          createOption: 'Empty'
          caching: 'None'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
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

// Outputs
output vmPublicIP string = publicIP.properties.ipAddress
output vmFQDN string = publicIP.properties.dnsSettings.fqdn
output rdpConnection string = 'mstsc /v:${publicIP.properties.ipAddress}'
