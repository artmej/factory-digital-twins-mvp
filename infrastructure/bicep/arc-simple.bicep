@description('Virtual machine name')
param vmName string = 'arc-simple'

@description('Admin username for the VM')
param adminUsername string = 'arcadmin'

@description('Admin password for the VM')
@secure()
param adminPassword string = 'ArcSimple2024!'

@description('Size of the VM')
param vmSize string = 'Standard_D4s_v3'

@description('Location for all resources')
param location string = resourceGroup().location

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: '${vmName}-vnet'
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
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${vmName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
      {
        name: 'SSH'
        properties: {
          priority: 1001
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

// Public IP
resource pip 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${vmName}-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

// Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

// Virtual Machine with System Assigned Identity
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: false
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// Role assignment for Azure Connected Machine Resource Administrator
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, vm.id, 'Azure Connected Machine Resource Administrator')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'cd570a14-e51a-42ad-bac8-bafd67325302')
    principalId: vm.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Simple setup script
resource simpleSetup 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: vm
  name: 'SimpleSetup'
  location: location
  dependsOn: [roleAssignment]
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: []
    }
    protectedSettings: {
      commandToExecute: 'powershell.exe -Command "New-Item -Path C:\\ArcSimple -ItemType Directory -Force; [System.Environment]::SetEnvironmentVariable(\'MSFT_ARC_TEST\',\'true\',[System.EnvironmentVariableTarget]::Machine); Add-WindowsCapability -Online -Name OpenSSH.Server; Start-Service sshd; Set-Service sshd -StartupType Automatic; Invoke-WebRequest -Uri https://aka.ms/AzureConnectedMachineAgent -OutFile C:\\ArcSimple\\agent.msi; Write-Host \'Setup completed - VM ready for Arc connection\'"'
    }
  }
}

output vmName string = vm.name
output vmPublicIP string = pip.properties.ipAddress
output vmPrivateIP string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output resourceGroupName string = resourceGroup().name
output managedIdentityPrincipalId string = vm.identity.principalId
output rdpCommand string = 'mstsc /v:${pip.properties.ipAddress}'
output sshCommand string = 'ssh ${adminUsername}@${pip.properties.ipAddress}'
output nextSteps string = 'SSH to VM and run Arc connection with managed identity'