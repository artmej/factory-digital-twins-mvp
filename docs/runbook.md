# Factory Digital Twins MVP - Runbook

## Quick Start Guide

Esta guía te permitirá tener el MVP funcionando en menos de 30 minutos.

## Prerequisites

### Required Tools
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (latest version)
- [Node.js 18+](https://nodejs.org/) 
- [Azure Functions Core Tools v4](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- [jq](https://stedolan.github.io/jq/) (para parsing de JSON en scripts)

### Azure Subscription
- Active Azure subscription with Contributor permissions
- Sufficient quota for:
  - IoT Hub (1 S1 unit)
  - Digital Twins (1 instance)
  - Function App (1 consumption plan)

## Step 1: Deploy Infrastructure

### 1.1 Clone and Setup
```bash
git clone <your-repo>
cd factory-digital-twins-mvp
```

### 1.2 Login to Azure
```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 1.3 Deploy Resources
```bash
cd infra/scripts
chmod +x deploy.sh
./deploy.sh --rg factory-rg --location eastus
```

**Expected Output:**
- Resource Group: `factory-rg`
- Digital Twins: `factory-adt-dev`
- IoT Hub: `factory-iothub-dev`
- Function App: `factory-func-dev`
- Configuration file: `factory_config.env`

### 1.4 Setup Digital Twins
```bash
chmod +x adt_setup.sh
./adt_setup.sh --rg factory-rg --adt factory-adt-dev
```

**Expected Output:**
- 4 DTDL models imported
- 4 digital twins created (factory1, lineA, machineA, sensorA)
- 3 relationships established

## Step 2: Deploy Azure Function

### 2.1 Build and Deploy
```bash
cd ../../src/function-adt-projection
npm install

# Deploy to Azure
func azure functionapp publish factory-func-dev --node
```

### 2.2 Verify Deployment
```bash
# Check function status
az functionapp show --name factory-func-dev --resource-group factory-rg --query "state"

# Check app settings
az functionapp config appsettings list --name factory-func-dev --resource-group factory-rg
```

## Step 3: Run Device Simulator

### 3.1 Setup Simulator
```bash
cd ../../src/device-simulator
npm install

# Load configuration
source ../../infra/scripts/factory_config.env

# Start simulator
npm start
```

### 3.2 Expected Output
```
🏭 Factory Simulator initialized
Send interval: 5000ms
✅ Connected to IoT Hub successfully
📤 Sending telemetry: {"lineId":"lineA",...}
✅ Telemetry sent successfully
```

## Step 4: Verify Data Flow

### 4.1 Check IoT Hub Messages
```bash
# Monitor IoT Hub messages (keep simulator running)
az iot hub monitor-events --hub-name factory-iothub-dev --device-id factory-device
```

### 4.2 Check Function Logs
```bash
# Stream function logs
func azure functionapp logstream factory-func-dev
```

### 4.3 Verify Digital Twins Updates
```bash
# Query twins
az dt twin query --dt-name factory-adt-dev --query-command "SELECT * FROM digitaltwins T WHERE T.\$dtId = 'lineA'"
```

## Step 5: Visualize in ADT Explorer

### 5.1 Access ADT Explorer
1. Open https://explorer.digitaltwins.azure.net
2. Sign in with your Azure account
3. Connect to: `https://factory-adt-dev.api.eastus.digitaltwins.azure.net`

### 5.2 Explore the Model
- **Models Tab**: View DTDL models
- **Twin Graph**: See factory hierarchy
- **Query Explorer**: Run DTDL queries

### 5.3 Monitor Live Data
- Watch property updates in real-time
- View telemetry streams
- Observe relationship graph

## Troubleshooting

### Common Issues

#### 1. Function Not Processing Messages
**Symptoms:** Simulator sends data but no updates in ADT

**Check:**
```bash
# Verify IoT Hub connection string
az functionapp config appsettings show --name factory-func-dev --resource-group factory-rg --setting-names IOTHUB_CONNECTION

# Check function permissions
az role assignment list --assignee $(az functionapp identity show --name factory-func-dev --resource-group factory-rg --query principalId -o tsv) --scope /subscriptions/<sub-id>/resourceGroups/factory-rg/providers/Microsoft.DigitalTwins/digitalTwinsInstances/factory-adt-dev
```

**Fix:**
```bash
# Restart function app
az functionapp restart --name factory-func-dev --resource-group factory-rg
```

#### 2. Simulator Connection Failed
**Symptoms:** `❌ IoT Hub connection error`

**Check:**
```bash
# Verify device exists
az iot hub device-identity show --hub-name factory-iothub-dev --device-id factory-device

# Test connection string
echo $DEVICE_CONN_STRING
```

**Fix:**
```bash
# Regenerate device key
az iot hub device-identity renew-key --hub-name factory-iothub-dev --device-id factory-device --key-type primary

# Update connection string
source ../../infra/scripts/factory_config.env
```

#### 3. Twins Not Found
**Symptoms:** `Twin 'lineA' not found` in function logs

**Check:**
```bash
# List all twins
az dt twin query --dt-name factory-adt-dev --query-command "SELECT * FROM digitaltwins"
```

**Fix:**
```bash
# Re-run ADT setup
./adt_setup.sh --rg factory-rg --adt factory-adt-dev
```

#### 4. Permission Denied
**Symptoms:** `403 Forbidden` in function logs

**Fix:**
```bash
# Assign Digital Twins Data Owner role
FUNCTION_PRINCIPAL_ID=$(az functionapp identity show --name factory-func-dev --resource-group factory-rg --query principalId -o tsv)
DIGITAL_TWINS_ID=$(az dt show --dt-name factory-adt-dev --resource-group factory-rg --query id -o tsv)

az role assignment create \
    --role "Azure Digital Twins Data Owner" \
    --assignee $FUNCTION_PRINCIPAL_ID \
    --scope $DIGITAL_TWINS_ID
```

### Monitoring Commands

#### Health Check Script
```bash
#!/bin/bash
echo "=== Factory MVP Health Check ==="

# 1. Check IoT Hub
echo "IoT Hub Status:"
az iot hub show --name factory-iothub-dev --resource-group factory-rg --query "properties.state"

# 2. Check Digital Twins
echo "Digital Twins Status:"  
az dt show --dt-name factory-adt-dev --resource-group factory-rg --query "properties.provisioningState"

# 3. Check Function App
echo "Function App Status:"
az functionapp show --name factory-func-dev --resource-group factory-rg --query "state"

# 4. Check recent telemetry
echo "Recent Twin Updates:"
az dt twin show --dt-name factory-adt-dev --twin-id lineA --query "{OEE: oee, State: state, LastUpdate: \$metadata.\$lastUpdateTime}"
```

## Performance Optimization

### 1. Function App Optimization
```bash
# Enable Application Insights
az functionapp config appsettings set --name factory-func-dev --resource-group factory-rg --settings APPINSIGHTS_INSTRUMENTATIONKEY="<key>"

# Optimize function timeout
az functionapp config set --name factory-func-dev --resource-group factory-rg --use-32bit-worker-process false --web-sockets-enabled true
```

### 2. Scaling Configuration
```bash
# Configure auto-scaling triggers
az monitor autoscale create \
    --resource-group factory-rg \
    --resource factory-func-dev \
    --resource-type Microsoft.Web/sites \
    --name factory-func-autoscale \
    --min-count 1 \
    --max-count 10 \
    --count 1
```

## Security Hardening

### 1. Network Security
```bash
# Restrict IoT Hub access
az iot hub update --name factory-iothub-dev --resource-group factory-rg --set properties.publicNetworkAccess=Disabled

# Configure private endpoints (optional)
az network private-endpoint create --name adt-private-endpoint --resource-group factory-rg --subnet mySubnet --private-connection-resource-id $DIGITAL_TWINS_ID --group-id API --connection-name adt-connection
```

### 2. Key Rotation
```bash
# Rotate IoT device keys (monthly)
az iot hub device-identity renew-key --hub-name factory-iothub-dev --device-id factory-device --key-type primary

# Update simulator configuration
./update_device_config.sh
```

## Clean Up Resources

### Remove Everything
```bash
# Delete resource group (removes all resources)
az group delete --name factory-rg --yes --no-wait
```

### Selective Cleanup
```bash
# Keep infrastructure, remove only twins
az dt twin delete-all --dt-name factory-adt-dev --yes
az dt model delete --dt-name factory-adt-dev --dtmi "dtmi:mx:factory:sensor;1"
az dt model delete --dt-name factory-adt-dev --dtmi "dtmi:mx:factory:machine;1"  
az dt model delete --dt-name factory-adt-dev --dtmi "dtmi:mx:factory:line;1"
az dt model delete --dt-name factory-adt-dev --dtmi "dtmi:mx:factory;1"
```

## Next Steps

### Production Readiness
1. **Monitoring**: Set up comprehensive monitoring with Application Insights
2. **Alerting**: Configure alerts for failures and performance issues
3. **Backup**: Implement backup strategy for Digital Twins models and data
4. **CI/CD**: Set up automated deployment pipelines
5. **Security**: Implement network isolation and advanced threat protection

### Feature Enhancements  
1. **Analytics**: Add Azure Data Explorer for historical analysis
2. **Visualization**: Implement Power BI dashboards
3. **ML Integration**: Add predictive maintenance with Azure ML
4. **Edge Computing**: Deploy IoT Edge for offline scenarios
5. **Multi-tenancy**: Support multiple factories and customers