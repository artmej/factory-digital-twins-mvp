// Smart Factory Virtual Network Configuration
// Production VNet with service endpoints for PaaS integration

param location string = resourceGroup().location
param vnetName string = 'vnet-smartfactory-prod'
param addressPrefix string = '10.1.0.0/16'

// Subnet configuration
var subnets = [
  {
    name: 'snet-webapp'
    addressPrefix: '10.1.1.0/24'
    serviceEndpoints: [
      'Microsoft.Web'
      'Microsoft.KeyVault'
    ]
  }
  {
    name: 'snet-functions'
    addressPrefix: '10.1.2.0/24'
    serviceEndpoints: [
      'Microsoft.Web'
      'Microsoft.Storage'
      'Microsoft.EventHub'
    ]
    delegations: [
      {
        name: 'Microsoft.Web/serverFarms'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ]
  }
  {
    name: 'snet-data'
    addressPrefix: '10.1.3.0/24'
    serviceEndpoints: [
      'Microsoft.DocumentDB'
      'Microsoft.DigitalTwins'
      'Microsoft.Storage'
    ]
  }
  {
    name: 'snet-gateway'
    addressPrefix: '10.1.4.0/24'
    serviceEndpoints: [
      'Microsoft.Web'
    ]
  }
]

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        serviceEndpoints: subnet.serviceEndpoints
        delegations: contains(subnet, 'delegations') ? subnet.delegations : []
        networkSecurityGroup: {
          id: nsg.id
        }
      }
    }]
  }
}

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-smartfactory-prod'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVNetInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 1100
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output webAppSubnetId string = vnet.properties.subnets[0].id
output functionsSubnetId string = vnet.properties.subnets[1].id
output dataSubnetId string = vnet.properties.subnets[2].id
output gatewaySubnetId string = vnet.properties.subnets[3].id