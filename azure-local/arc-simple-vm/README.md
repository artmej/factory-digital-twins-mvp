# Azure Local Arc VM Configuration

## 📟 VM Information

- **VM Name**: arc-simple  
- **IP Address**: 130.131.248.173
- **OS**: Windows Server 2022
- **Azure Arc**: ✅ Connected to Azure Cloud
- **Location**: On-Premise (Azure Local)

## 🔗 Azure Arc Connection

### Status
```powershell
# Check Arc agent status
azcmagent show
```

### Resource Details
- **Resource Group**: smart-factory-rg
- **Subscription**: Azure Local subscription  
- **Arc Agent**: Connected and reporting

## 🏭 Factory Simulator Deployment

### Current Status
The VM runs our **Smart Factory Simulator** that generates:

- **Machine telemetry**: Temperature, pressure, vibration, OEE
- **Production line data**: Throughput, quality, efficiency  
- **Factory metrics**: Overall efficiency, energy consumption

### Services Running
```powershell
# Factory simulator service
Get-Service FactorySimulator

# Azure Arc agent
Get-Service azcmagent
```

## 📡 Connectivity to Azure Cloud

### Data Flow
```
arc-simple VM → Azure Arc → IoT Hub → Functions → Digital Twins
```

### Network Configuration
- **Outbound HTTPS**: 443 (Azure services)
- **Azure Arc endpoints**: Enabled
- **IoT Hub connection**: Device connection strings configured

## 🔧 Management

### Remote Access
```bash
# SSH connection (if enabled)
ssh azureuser@130.131.248.173

# RDP connection (Windows)  
mstsc /v:130.131.248.173
```

### Monitoring
- **Azure Arc**: VM metrics in Azure portal
- **Factory logs**: Local logging + Azure Monitor
- **Performance**: CPU, Memory, Disk usage tracked

## 🚀 Next Steps

1. **Deploy IoT Edge**: Install IoT Edge Runtime
2. **Edge Modules**: Local processing modules
3. **Offline Scenarios**: Local storage when disconnected
4. **Security**: Device certificates and TPM integration
