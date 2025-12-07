# Device Simulator

Simulador de dispositivos IoT para generar telemetría de una línea de fábrica.

## Características

- **Simulación Realista**: Genera datos con variaciones naturales y tendencias
- **Múltiples Métricas**: OEE, throughput, temperatura, estado de salud
- **Escenarios de Incidentes**: Simula degradación de rendimiento automáticamente
- **Manejo Robusto**: Reconexión automática y manejo de errores

## Configuración

### Variables de Entorno Requeridas

```bash
# Connection string del dispositivo en IoT Hub
DEVICE_CONN_STRING="HostName=your-iothub.azure-devices.net;DeviceId=factory-device;SharedAccessKey=your-key"

# Intervalo de envío en milisegundos (opcional, default: 5000)
SEND_INTERVAL_MS=5000
```

### Obtener Connection String del Dispositivo

1. Crear dispositivo en IoT Hub:
```bash
az iot hub device-identity create --device-id factory-device --hub-name your-iothub
```

2. Obtener connection string:
```bash
az iot hub device-identity connection-string show --device-id factory-device --hub-name your-iothub
```

## Uso

### Instalación
```bash
cd src/device-simulator
npm install
```

### Ejecución
```bash
# Configurar variables de entorno
export DEVICE_CONN_STRING="your-connection-string"

# Ejecutar simulador
npm start

# O para desarrollo con auto-reload
npm run dev
```

### Ejecución con Docker
```bash
docker build -t factory-simulator .
docker run -e DEVICE_CONN_STRING="your-connection-string" factory-simulator
```

## Datos Simulados

El simulador genera mensajes con la siguiente estructura:

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

### Métricas Simuladas

1. **Line (Línea de Producción)**:
   - `oee`: 0.85 ± 0.1 (Overall Equipment Effectiveness)
   - `throughput`: 120 ± 20 units/min
   - `state`: running/degraded/stopped

2. **Machine (Máquina)**:
   - `temperature`: 75 ± 10°C
   - `health`: healthy/warning/critical
   - `serial`: MAC-001-2024

3. **Sensor**:
   - `value`: Similar a temperatura con variación
   - `kind`: temperature
   - `unit`: celsius

### Simulación de Incidentes

- **Automático**: Cada 2 minutos simula un incidente que reduce el rendimiento
- **Recuperación**: Después de 30 segundos se recupera automáticamente
- **Efectos**: Reduce OEE, throughput y aumenta temperatura

## Arquitectura

```
Simulator -> IoT Hub -> Event Hub Endpoint -> Azure Function -> Digital Twins
```

## Logs y Monitoreo

El simulador proporciona logs detallados:
- ✅ Conexión exitosa
- 📤 Telemetría enviada  
- ❌ Errores de conexión
- 🚨 Simulación de incidentes
- 🔧 Recuperación automática

## Troubleshooting

### Error de Conexión
- Verificar `DEVICE_CONN_STRING`
- Confirmar que el dispositivo existe en IoT Hub
- Revisar políticas de acceso

### Sin Datos en Digital Twins
- Verificar que la Azure Function esté ejecutándose
- Revisar logs de la Function App
- Confirmar que los modelos DTDL están importados
- Verificar que los twins existen en ADT