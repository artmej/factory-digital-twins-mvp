# Factory Digital Twins MVP - Bicep Infrastructure

Esta carpeta contiene la infraestructura como código (IaC) para el MVP de Factory Digital Twins.

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