# Azure Digital Twins Projection Function

Esta Azure Function recibe telemetría desde IoT Hub y la proyecta a Azure Digital Twins.

## Configuración Requerida

### Variables de Entorno
- `DIGITAL_TWINS_URL`: URL del servicio Azure Digital Twins (ej: `https://youradt.api.wus2.digitaltwins.azure.net`)
- `IOTHUB_CONNECTION`: Connection string del endpoint EventHub-compatible de IoT Hub

### Permisos de Azure
La función requiere los siguientes permisos en Azure Digital Twins:
- Azure Digital Twins Data Owner (para leer/escribir twins y publicar telemetría)

## Desarrollo Local

1. Instalar dependencias:
```bash
npm install
```

2. Instalar Azure Functions Core Tools:
```bash
npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

3. Configurar `local.settings.json`:
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "DIGITAL_TWINS_URL": "https://youradt.api.region.digitaltwins.azure.net",
    "IOTHUB_CONNECTION": "your-iothub-eventhub-compatible-connection-string"
  }
}
```

4. Ejecutar localmente:
```bash
func start
```

## Despliegue

### Usar Azure CLI
```bash
# Crear Function App
az functionapp create --resource-group myResourceGroup --consumption-plan-location westus2 --runtime node --runtime-version 18 --functions-version 4 --name myFunctionApp --storage-account mystorageaccount

# Configurar app settings
az functionapp config appsettings set --name myFunctionApp --resource-group myResourceGroup --settings DIGITAL_TWINS_URL="https://youradt.api.region.digitaltwins.azure.net"
az functionapp config appsettings set --name myFunctionApp --resource-group myResourceGroup --settings IOTHUB_CONNECTION="your-connection-string"

# Habilitar identity y asignar permisos
az functionapp identity assign --name myFunctionApp --resource-group myResourceGroup
```

## Estructura de Mensaje

La función espera mensajes JSON con la siguiente estructura:
```json
{
  "lineId": "lineA",
  "machineId": "machineA", 
  "sensorId": "sensorA",
  "throughput": 120.5,
  "temperature": 78.2,
  "value": 78.2,
  "state": "running",
  "oee": 0.84,
  "health": "healthy",
  "ts": "2025-12-06T10:30:00.000Z"
}
```

## Funcionalidad

1. **Actualización de Propiedades**:
   - Line: `oee`, `state`
   - Machine: `health`

2. **Publicación de Telemetría**:
   - Line: `throughput`
   - Machine: `temperature` 
   - Sensor: `value`

3. **Manejo de Errores**:
   - Logs estructurados
   - Procesamiento individual de mensajes
   - Validación de datos de entrada