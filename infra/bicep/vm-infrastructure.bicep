@description('Location for all resources')
param location string = 'West US 2'

@description('Admin username for the VMs')
param adminUsername string = 'factoryadmin'

@description('Admin password for Windows VM')
@secure()
param adminPassword string

@description('SSH public key for Linux VM')
param sshPublicKey string

@description('VM size for factory floor VM')
param factoryVmSize string = 'Standard_DS1_v2'

@description('VM size for control system VM')
param controlVmSize string = 'Standard_DS1_v2'

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-smart-factory-plant'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-factory-floor'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsgFactory.id
          }
        }
      }
      {
        name: 'subnet-control-systems'
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: nsgControl.id
          }
        }
      }
      {
        name: 'subnet-iot-edge'
        properties: {
          addressPrefix: '10.0.3.0/24'
          networkSecurityGroup: {
            id: nsgIoTEdge.id
          }
        }
      }
    ]
  }
}

// Network Security Groups
resource nsgFactory 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-factory-floor'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'HTTP'
        properties: {
          priority: 1002
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '80'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'HTTPS'
        properties: {
          priority: 1003
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '443'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'IoTEdge'
        properties: {
          priority: 1004
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '8883'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nsgControl 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-control-system'
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          priority: 1001
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
        name: 'SCADA-Web'
        properties: {
          priority: 1002
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '8080'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nsgIoTEdge 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-iot-edge'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'IoTEdgeManagement'
        properties: {
          priority: 1002
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRanges: [
            '443'
            '5671'
            '8883'
          ]
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Public IPs
resource pipFactory 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-factory-floor'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'smart-factory-floor-${uniqueString(resourceGroup().id)}'
    }
  }
}

resource pipControl 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-control-system'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'smart-factory-control-${uniqueString(resourceGroup().id)}'
    }
  }
}

resource pipIoTEdge 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-iot-edge'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'smart-factory-iot-edge-${uniqueString(resourceGroup().id)}'
    }
  }
}

// Network Interfaces
resource nicFactory 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: 'nic-factory-floor'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipFactory.id
          }
          subnet: {
            id: vnet.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

resource nicControl 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: 'nic-control-system'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipControl.id
          }
          subnet: {
            id: vnet.properties.subnets[1].id
          }
        }
      }
    ]
  }
}

resource nicIoTEdge 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: 'nic-iot-edge'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipIoTEdge.id
          }
          subnet: {
            id: vnet.properties.subnets[2].id
          }
        }
      }
    ]
  }
}

// Factory Floor VM (Ubuntu + IoT simulation)
resource vmFactory 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'vm-factory-floor'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: factoryVmSize
    }
    osProfile: {
      computerName: 'factory-floor'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
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
          id: nicFactory.id
        }
      ]
    }
  }
}

// Control System VM (Windows + SCADA simulation)
resource vmControl 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'vm-control-system'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: controlVmSize
    }
    osProfile: {
      computerName: 'control-sys'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-core'
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
          id: nicControl.id
        }
      ]
    }
  }
}

// IoT Edge VM (Ubuntu + Azure IoT Edge)
resource vmIoTEdge 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'vm-iot-edge'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    osProfile: {
      computerName: 'iot-edge-gateway'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
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
          id: nicIoTEdge.id
        }
      ]
    }
  }
}

// VM Extensions for automatic setup

// Factory Floor VM Extension (Docker + Plant Simulator)
resource vmFactoryExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: vmFactory
  name: 'FactorySetup'
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: []
      commandToExecute: '''
        #!/bin/bash
        apt-get update
        apt-get install -y docker.io docker-compose nodejs npm python3 python3-pip
        systemctl enable docker
        systemctl start docker
        usermod -aG docker factoryadmin
        
        # Install Azure IoT Device SDK
        pip3 install azure-iot-device
        
        # Create factory simulation directory
        mkdir -p /opt/smart-factory
        cd /opt/smart-factory
        
        # Create simple factory simulator
        cat > factory_simulator.py << 'EOF'
import asyncio
import json
import random
import time
from azure.iot.device import IoTHubDeviceClient

class FactorySimulator:
    def __init__(self):
        self.machines = {
            "machine_001": {"status": "running", "temp": 75, "pressure": 14.2, "efficiency": 94.5},
            "machine_002": {"status": "running", "temp": 68, "pressure": 15.1, "efficiency": 92.1},
            "machine_003": {"status": "running", "temp": 82, "pressure": 13.8, "efficiency": 96.3}
        }
        self.production_line = {
            "line_001": {"rate": 1250, "quality": 99.2, "target": 1300},
            "line_002": {"rate": 1180, "quality": 98.8, "target": 1200}
        }
    
    def get_telemetry(self):
        # Simulate real factory data with variations
        for machine_id in self.machines:
            machine = self.machines[machine_id]
            machine["temp"] += random.uniform(-2, 2)
            machine["pressure"] += random.uniform(-0.5, 0.5)
            machine["efficiency"] += random.uniform(-1, 1)
            
            # Simulate occasional issues
            if random.random() < 0.05:  # 5% chance of issue
                machine["status"] = "warning"
                machine["efficiency"] -= 10
            else:
                machine["status"] = "running"
        
        for line_id in self.production_line:
            line = self.production_line[line_id]
            line["rate"] += random.randint(-50, 50)
            line["quality"] += random.uniform(-0.5, 0.5)
        
        return {
            "timestamp": time.time(),
            "machines": self.machines,
            "production_lines": self.production_line,
            "factory_status": "operational"
        }

if __name__ == "__main__":
    simulator = FactorySimulator()
    while True:
        telemetry = simulator.get_telemetry()
        print(json.dumps(telemetry, indent=2))
        time.sleep(5)
EOF
        
        # Create systemd service
        cat > /etc/systemd/system/factory-simulator.service << 'EOF'
[Unit]
Description=Smart Factory Simulator
After=network.target

[Service]
Type=simple
User=factoryadmin
WorkingDirectory=/opt/smart-factory
ExecStart=/usr/bin/python3 factory_simulator.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl enable factory-simulator
        systemctl start factory-simulator
        
        echo "Factory Floor VM setup complete"
      '''
    }
  }
}

// IoT Edge VM Extension
resource vmIoTEdgeExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: vmIoTEdge
  name: 'IoTEdgeSetup'
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: []
      commandToExecute: '''
        #!/bin/bash
        apt-get update
        apt-get install -y curl software-properties-common
        
        # Install Docker
        apt-get install -y docker.io
        systemctl enable docker
        systemctl start docker
        usermod -aG docker factoryadmin
        
        # Install Azure IoT Edge
        curl https://packages.microsoft.com/config/ubuntu/22.04/multiverse/prod.list > ./microsoft-prod.list
        cp ./microsoft-prod.list /etc/apt/sources.list.d/
        curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
        cp ./microsoft.gpg /etc/apt/trusted.gpg.d/
        
        apt-get update
        apt-get install -y aziot-edge
        
        echo "IoT Edge VM setup complete - manual configuration required"
      '''
    }
  }
}

// Outputs
output factoryFloorPublicIP string = pipFactory.properties.ipAddress
output factoryFloorFQDN string = pipFactory.properties.dnsSettings.fqdn
output controlSystemPublicIP string = pipControl.properties.ipAddress
output controlSystemFQDN string = pipControl.properties.dnsSettings.fqdn
output iotEdgePublicIP string = pipIoTEdge.properties.ipAddress
output iotEdgeFQDN string = pipIoTEdge.properties.dnsSettings.fqdn
