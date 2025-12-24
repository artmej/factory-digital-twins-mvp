@description('Location for all resources')
param location string = resourceGroup().location

@description('AKS cluster name')
param aksClusterName string = 'aks-smart-factory-edge'

@description('Node count for AKS cluster')
param nodeCount int = 3

@description('VM size for AKS nodes')
param nodeVmSize string = 'Standard_DS2_v2'

@description('Kubernetes version')
param kubernetesVersion string = '1.28.5'

@description('Enable managed identity')
param enableSystemAssignedIdentity bool = true

// AKS Cluster
resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-11-01' = {
  name: aksClusterName
  location: location
  identity: {
    type: enableSystemAssignedIdentity ? 'SystemAssigned' : 'None'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: aksClusterName
    agentPoolProfiles: [
      {
        name: 'factory'
        count: nodeCount
        vmSize: nodeVmSize
        osType: 'Linux'
        mode: 'System'
        enableNodePublicIP: false
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        nodeLabels: {
          'factory-role': 'edge-simulation'
          'environment': 'demo'
        }
        nodeTaints: []
      }
      {
        name: 'robots'
        count: 2
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        mode: 'User'
        enableNodePublicIP: false
        nodeLabels: {
          'workload': 'robot-simulation'
          'factory-zone': 'production'
        }
        nodeTaints: [
          'factory-zone=production:NoSchedule'
        ]
      }
      {
        name: 'edge'
        count: 1
        vmSize: 'Standard_DS1_v2'
        osType: 'Linux'
        mode: 'User'
        enableNodePublicIP: false
        nodeLabels: {
          'workload': 'iot-edge'
          'autonomy': 'local'
        }
        nodeTaints: [
          'workload=iot-edge:NoSchedule'
        ]
      }
    ]
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    nodeResourceGroup: '${resourceGroup().name}-aks-nodes'
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      serviceCidr: '172.16.0.0/16'
      dnsServiceIP: '172.16.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
    }
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
        }
      }
      azurePolicy: {
        enabled: true
      }
      httpApplicationRouting: {
        enabled: true
      }
      ingressApplicationGateway: {
        enabled: false
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspace.id
        }
      }
    }
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
    }
    disableLocalAccounts: false
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
      imageCleaner: {
        enabled: true
        intervalHours: 24
      }
    }
  }
}

// Log Analytics Workspace for monitoring
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-smart-factory-edge'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Container Registry for custom images
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'acrsmartfactoryedge${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
  }
}

// Assign ACR Pull role to AKS
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aksCluster.id, 'acrpull')
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // ACR Pull
    principalId: aksCluster.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
}

// IoT Hub for edge connectivity (when cloud sync is available)
resource iotHub 'Microsoft.Devices/IotHubs@2023-06-30' = {
  name: 'iothub-smart-factory-edge-${uniqueString(resourceGroup().id)}'
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
        storageContainers: []
        serviceBusQueues: []
        serviceBusTopics: []
        eventHubs: []
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
    enableDataResidency: false
  }
}

// Storage Account for local data persistence (simulating edge storage)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stsmartfactoryedge${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

// Create blob containers for different data types
resource blobContainerTelemetry 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/telemetry'
  properties: {
    publicAccess: 'None'
  }
}

resource blobContainerLogs 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/logs'
  properties: {
    publicAccess: 'None'
  }
}

resource blobContainerModels 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/ml-models'
  properties: {
    publicAccess: 'None'
  }
}

// Public IP for ingress access (simulating factory network access)
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-smart-factory-edge'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'smart-factory-edge-${uniqueString(resourceGroup().id)}'
    }
  }
}

// Application Gateway for external access (simulating factory gateway)
resource applicationGateway 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: 'agw-smart-factory-edge'
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 1
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: vnet.properties.subnets[1].id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_8080'
        properties: {
          port: 8080
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'factory-dashboard-pool'
        properties: {}
      }
      {
        name: 'scada-pool'
        properties: {}
      }
      {
        name: 'robot-control-pool'
        properties: {}
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'http-setting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 30
        }
      }
      {
        name: 'scada-setting'
        properties: {
          port: 8080
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'factory-dashboard-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'agw-smart-factory-edge', 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'agw-smart-factory-edge', 'port_80')
          }
          protocol: 'Http'
        }
      }
      {
        name: 'scada-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'agw-smart-factory-edge', 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'agw-smart-factory-edge', 'port_8080')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'factory-dashboard-rule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'agw-smart-factory-edge', 'factory-dashboard-listener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'agw-smart-factory-edge', 'factory-dashboard-pool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'agw-smart-factory-edge', 'http-setting')
          }
        }
      }
      {
        name: 'scada-rule'
        properties: {
          ruleType: 'Basic'
          priority: 200
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'agw-smart-factory-edge', 'scada-listener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'agw-smart-factory-edge', 'scada-pool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'agw-smart-factory-edge', 'scada-setting')
          }
        }
      }
    ]
  }
  dependsOn: [
    vnet
  ]
}

// Virtual Network for AKS and Application Gateway
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-smart-factory-edge'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/8'
      ]
    }
    subnets: [
      {
        name: 'aks-subnet'
        properties: {
          addressPrefix: '10.1.0.0/16'
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.KeyVault'
            }
          ]
        }
      }
      {
        name: 'appgw-subnet'
        properties: {
          addressPrefix: '10.2.0.0/24'
        }
      }
    ]
  }
}

// Outputs
output aksClusterName string = aksCluster.name
output aksResourceGroup string = aksCluster.properties.nodeResourceGroup
output containerRegistryName string = containerRegistry.name
output containerRegistryLoginServer string = containerRegistry.properties.loginServer
output iotHubName string = iotHub.name
output iotHubHostName string = iotHub.properties.hostName
output storageAccountName string = storageAccount.name
output factoryDashboardUrl string = 'http://${publicIP.properties.dnsSettings.fqdn}'
output scadaUrl string = 'http://${publicIP.properties.dnsSettings.fqdn}:8080'
output kubeConfig string = 'az aks get-credentials --resource-group ${resourceGroup().name} --name ${aksCluster.name}'
