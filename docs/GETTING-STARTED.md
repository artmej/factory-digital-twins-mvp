# Smart Factory Hybrid - Technical Documentation

## Quick Start

### 1. Infrastructure Deployment (10 minutes)
```bash
cd infrastructure/bicep
az deployment group create \
  --resource-group smart-factory-rg \
  --template-file main.bicep \
  --parameters environmentName=production
```

### 2. Azure Local Setup (5 minutes)
```bash
# Start factory simulator on Azure Local VM
cd azure-local/factory-simulator
npm install
npm start
```

### 3. Verify Connection (2 minutes)
```bash
# Check telemetry flow
az iot hub device-identity list --hub-name smartfactory-iothub
az dt model list --dt-name smartfactory-adt
```

## Application Access

- **Factory Workers**: React Native mobile app
- **Process Engineers**: Web dashboard at `http://localhost:3000` 
- **Management**: Power BI dashboards in Azure portal

## Key Components

### Azure Cloud
- **Digital Twins**: Factory, machine, sensor, and production line models
- **IoT Hub**: Telemetry ingestion from Azure Local
- **Functions**: Real-time data projection to Digital Twins

### Azure Local  
- **arc-simple VM**: Windows Server with Azure Arc (IP: 130.131.248.173)
- **Factory Simulator**: Generates industrial telemetry data
- **Local Dashboard**: Real-time operations monitoring

### Applications
- **Mobile App**: React Native for iOS/Android
- **Web Dashboard**: Progressive Web App for engineers
- **Analytics**: Power BI for executive insights

## Support

For technical issues, refer to logs in the `logs/` directory or check the individual component README files in each subdirectory.