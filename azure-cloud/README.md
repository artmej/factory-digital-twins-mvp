# Azure Cloud Components

Este directorio contiene todos los componentes que se ejecutan en **Azure Cloud**.

## 📁 Estructura

### `digital-twins/`
- **Modelos DTDL**: factory.dtdl.json, machine.dtdl.json, sensor.dtdl.json, line.dtdl.json
- **Definición**: Gemelos digitales de la fábrica
- **Conexión**: Recibe datos desde Azure Local vía IoT Hub

### `iot-hub/` 
- **Configuración**: Connection strings y device registry
- **Propósito**: Punto de entrada para telemetría desde edge
- **Conexión**: Conecta Azure Local simulator → Cloud processing

### `functions/`
- **Azure Functions**: Procesamiento serverless
- **ADT Projection**: Proyecta telemetría IoT → Digital Twins
- **Triggers**: IoT Hub events, TimerTrigger

## 🔄 Flujo de Datos

1. **Azure Local** (VM) envía telemetría → **IoT Hub**
2. **IoT Hub** trigger → **Azure Functions** 
3. **Functions** procesa y actualiza → **Digital Twins**
4. **Digital Twins** alimenta → **Aplicaciones & Dashboards**

## 🚀 Despliegue

Los recursos cloud se despliegan usando plantillas Bicep desde `infrastructure/`:

```bash
# Deploy Azure Cloud resources
az deployment group create \
  --resource-group smart-factory-rg \
  --template-file infrastructure/bicep/main.bicep
```