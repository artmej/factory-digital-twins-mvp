/**
 * 🏢 Smart Factory Infrastructure - Bicep Templates
 * Infrastructure as Code for Smart Factory Azure Deployment
 * 
 * This directory contains Azure Bicep templates for deploying the complete
 * Smart Factory infrastructure in a cost-optimized manner.
 * 
 * Current Architecture:
 * - Azure Arc VM: Standard_B2s ($30-50/month)
 * - K3s Kubernetes cluster for container orchestration
 * - Azure IoT Hub for device communication
 * - Azure ML Workspace for machine learning
 * - Cosmos DB for telemetry data storage
 * - Azure Functions for serverless processing
 * - Static Web Apps for PWA hosting
 * 
 * Cost Optimization:
 * - Replaced ArcBox ($800-1200/month) with simple Arc VM
 * - Uses lightweight K3s instead of full AKS
 * - Optimized resource SKUs for development/testing
 * - Regional deployment to minimize latency costs
 * 
 * @author Smart Factory Team
 * @version 1.0.0
 * @since 2026-01-03
 */

# Smart Factory Infrastructure - Infrastructure as Code

## 🏢 **Bicep Templates - Production Ready**

### **Core Infrastructure Components**
- **`main.bicep`** - Main entry point for complete deployment
- **`core-infrastructure.bicep`** - Azure Digital Twins + IoT Hub + Functions
- **`ml-infrastructure.bicep`** - Machine Learning services and workspace
- **`arc-simple.bicep`** - Azure Arc VM for edge computing

### **Cost-Optimized Architecture**
- **`arc-simple.bicep`** - VM para Azure Local simulation (ACTUAL)
- **`aks-edge-simulation.bicep`** - Kubernetes Edge deployment
- **`vm-infrastructure.bicep`** - VM infrastructure utilities

### **Legacy (Compatibility)**
- **`azure-local-simple.bicep`** - Basic Azure Local setup
- **`azure-local-simplified.bicep`** - Simplified deployment

## 🎯 **Current Deployment**
```bash
# Deploy main infrastructure
az deployment group create \
  --resource-group factory-rg \
  --template-file main.bicep

# Deploy edge computing demo (current)  
az deployment group create \
  --resource-group rg-arc-simple \
  --template-file arc-simple.bicep \
  --parameters @arc-simple.parameters.json
```

## ✅ **Cleaned Up**
Removed 20+ duplicate/experimental files:
- All arc-* attempts (jumpstart, win-ssh, automated, etc.)
- All azure-local-* duplicates (complete, auto, working, etc.)
- All setup/deploy scripts (consolidated in main deployment)

**Only production-ready templates remain.**

## Recursos Desplegados

El archivo `main.bicep` despliega los siguientes recursos de Azure:

### Core Services
- **Azure Digital Twins**: Instancia para el modelo de gemelo digital
- **IoT Hub**: Para ingesta de telemetría de dispositivos  
- **Azure Function App**: Para procesamiento de eventos y proyección a ADT
- **Storage Account**: Para almacenar archivos de la Function App
- **App Service Plan**: Plan de consumo para la Function App

### Security & Access
- **Managed Identity**: Identity del sistema para la Function App
- **Role Assignment**: Permisos "Digital Twins Data Owner" para la Function
- **Device Registration**: Dispositivo IoT preconfigurado para el simulador

## Parámetros

| Parámetro | Default | Descripción |
|-----------|---------|-------------|
| `location` | `resourceGroup().location` | Región para todos los recursos |
| `resourcePrefix` | `factory` | Prefijo para nombres de recursos |
| `environment` | `dev` | Sufijo de ambiente (dev/test/prod) |

## Outputs

El template proporciona los siguientes outputs:

```bicep
output digitalTwinsName string
output digitalTwinsUrl string  
output iotHubName string
output functionAppName string
output deviceConnectionString string
output iotHubConnectionString string
```

## Uso

### Deployment Manual
```bash
# Crear resource group
az group create --name factory-rg --location eastus

# Desplegar template
az deployment group create \
  --resource-group factory-rg \
  --template-file main.bicep \
  --parameters \
    resourcePrefix=factory \
    environment=dev
```

### Deployment con Script
```bash
# Usar el script automatizado
./scripts/deploy.sh --rg factory-rg --location eastus
```

## Configuración Posterior al Deployment

### 1. Configurar Digital Twins
```bash
# Importar modelos DTDL
az dt model create --dt-name <adt-name> --models "../models/factory.dtdl.json"
# ... otros modelos

# Crear twins
az dt twin create --dt-name <adt-name> --dtmi "dtmi:mx:factory;1" --twin-id "factory1"
# ... otros twins
```

### 2. Desplegar Function App
```bash
cd ../src/function-adt-projection
func azure functionapp publish <function-app-name>
```

## Customización

### Ambientes Múltiples
```bash
# Development
az deployment group create --template-file main.bicep --parameters environment=dev

# Staging  
az deployment group create --template-file main.bicep --parameters environment=staging

# Production
az deployment group create --template-file main.bicep --parameters environment=prod
```

### Escalamiento
Para ambiente de producción, considera estos ajustes:

```bicep
// IoT Hub con mayor capacidad
sku: {
  name: 'S2'  // En lugar de S1
  capacity: 2
}

// Function App con plan dedicado
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  sku: {
    name: 'P1V2'  // En lugar de Y1 (consumption)
    tier: 'PremiumV2'
  }
}
```

## Monitoreo de Costos

### Estimación Mensual (ambiente dev)
- **IoT Hub S1**: ~$25 USD
- **Digital Twins**: ~$15 USD (uso bajo)
- **Function App**: ~$5 USD (consumption plan)
- **Storage**: ~$2 USD
- **Total**: ~$47 USD/mes

### Optimización de Costos
1. **IoT Hub**: Usar S1 en dev, escalar en producción según necesidad
2. **Function App**: Mantener consumption plan para cargas variables
3. **Digital Twins**: Monitor operaciones para optimizar queries
4. **Storage**: Configurar lifecycle policies para archivos antiguos

## Troubleshooting

### Errores Comunes

#### 1. "Digital Twins instance already exists"
```bash
# Verificar si ya existe
az dt show --dt-name <name> --resource-group <rg>

# Usar nombre diferente o eliminar instancia existente
az dt delete --dt-name <name> --resource-group <rg>
```

#### 2. "Insufficient quota for IoT Hub"
```bash
# Verificar quota actual
az iot hub list --query "length([*])"

# Eliminar hubs no utilizados o solicitar aumento de quota
```

#### 3. "Function App deployment failed"
```bash
# Verificar logs de deployment
az deployment group show --name <deployment-name> --resource-group <rg>

# Revisar dependencias de recursos
```

## Security Best Practices

### 1. Network Isolation
Para producción, considera habilitar:
```bicep
properties: {
  publicNetworkAccess: 'Disabled'  // Para Digital Twins
  restrictOutboundNetworkAccess: true  // Para Function App
}
```

### 2. Key Management
```bicep
// Usar Key Vault para secrets sensibles
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  properties: {
    enableRbacAuthorization: true
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}
```

### 3. Monitoring & Alerting
```bicep
// Application Insights para monitoreo
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
  }
}
```