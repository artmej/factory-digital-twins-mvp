# Smart Factory IoT Edge Deployment

Este directorio contiene la configuración completa para desplegar la solución Smart Factory en IoT Edge con capacidades avanzadas de ML e inferencia local.

## 🏗️ Arquitectura Edge

### Módulos del Sistema
- **edgeAgent**: Administra el ciclo de vida de módulos
- **edgeHub**: Maneja comunicación y routing de mensajes  
- **Store & Forward**: Almacenamiento local con reenvío automático

### 🏭 Módulos Smart Factory

#### 1. Factory Simulator (`factory-simulator`)
- **Función**: Simulador realista de 9 dispositivos de fábrica
- **Características**:
  - Telemetría realista con patrones de desgaste
  - Anomalías simuladas (5% probabilidad)
  - Diferentes tipos: CNC, Robot, Conveyor
  - Intervalos configurables de envío
- **Dispositivos simulados**:
  ```
  LINE_1_CNC_01    - Máquina CNC Línea 1
  LINE_1_ROBOT_01  - Brazo robótico Línea 1  
  LINE_1_CONV_01   - Banda transportadora Línea 1
  LINE_2_CNC_02    - Máquina CNC Línea 2
  LINE_2_ROBOT_02  - Brazo robótico Línea 2
  LINE_2_CONV_02   - Banda transportadora Línea 2
  LINE_3_CNC_03    - Máquina CNC Línea 3
  LINE_3_ROBOT_03  - Brazo robótico Línea 3
  LINE_3_CONV_03   - Banda transportadora Línea 3
  ```

#### 2. Smart Factory ML (`smartFactoryML`)
- **Función**: Inferencia de ML en el edge para mantenimiento predictivo
- **Características**:
  - Modelo de ML con pesos entrenados reales
  - Predicciones de mantenimiento en tiempo real
  - API HTTP local para consultas directas
  - Confianza ajustable (65-95%)
  - Métricas de importancia de características

## 📁 Estructura de Archivos

```
edge/
├── deployment.json              # Configuración básica de Edge
├── deployment-complete.json     # Configuración completa con ML
├── README.md                   # Esta documentación
├── modules/                    # Módulos personalizados
│   ├── factory-simulator/      # Simulador de dispositivos
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── simulator.py
│   └── smart-factory-ml/       # Módulo de ML
│       ├── Dockerfile
│       ├── requirements.txt
│       └── main.py
└── scripts/                    # Scripts de gestión
    ├── build-containers.ps1    # Construcción de contenedores
    ├── deploy-edge.ps1         # Despliegue a dispositivos
    └── monitor-edge.ps1        # Monitoreo de dispositivos
```

## 🚀 Despliegue Rápido

### 1. Construir Contenedores
```powershell
cd edge/scripts
.\build-containers.ps1 -RegistryName "your-registry" -PushImages
```

### 2. Desplegar a Edge Device
```powershell
.\deploy-edge.ps1 -ResourceGroup "smart-factory-rg" -IoTHubName "smart-factory-hub" -EdgeDeviceId "factory-edge-01"
```

### 3. Monitorear Dispositivo
```powershell
.\monitor-edge.ps1 -IoTHubName "smart-factory-hub" -EdgeDeviceId "factory-edge-01" -ShowTelemetry -ShowHealth
```

## ⚙️ Configuración Detallada

### Variables de Entorno

#### Factory Simulator
- `TELEMETRY_INTERVAL`: Intervalo de envío en segundos (default: 30)
- `SIMULATION_MODE`: Modo de simulación (realistic/test)

#### Smart Factory ML
- `INFERENCE_MODE`: Modo de inferencia (edge/cloud)
- `MODEL_VERSION`: Versión del modelo ML
- `CONFIDENCE_THRESHOLD`: Umbral mínimo de confianza

### Rutas de Mensajes

```json
{
  "factorySimulatorToML": "FROM /messages/modules/factorySimulator/outputs/* INTO BrokeredEndpoint(\"/modules/smartFactoryML/inputs/input1\")",
  "mlToIoTHub": "FROM /messages/modules/smartFactoryML/outputs/* INTO $upstream",
  "factorySimulatorToIoTHub": "FROM /messages/modules/factorySimulator/outputs/* INTO $upstream"
}
```

### Configuración de Store & Forward
- **timeToLiveSecs**: 3600 (1 hora de almacenamiento local)
- Permite operación offline con reenvío automático al reconectar

## 🔧 Comandos de Gestión

### Verificar Estado de Módulos
```bash
az iot hub module-identity list --hub-name <hub-name> --device-id <edge-device-id>
```

### Obtener Logs de Módulos
```bash
az iot hub invoke-module-method --hub-name <hub-name> --device-id <edge-device-id> --module-id <module-name> --method-name "GetLogs"
```

### Reiniciar Módulo
```bash
az iot hub invoke-module-method --hub-name <hub-name> --device-id <edge-device-id> --module-id <module-name> --method-name "RestartModule"
```

## 📊 Monitoreo y Métricas

### Health Check Endpoints
- **Factory Simulator**: `http://localhost:5001/health`
- **Smart Factory ML**: `http://localhost:5000/health`

### Telemetría en Tiempo Real
```bash
az iot hub monitor-events --hub-name <hub-name> --device-id <edge-device-id>
```

### Predicciones ML Locales
```bash
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "LINE_1_CNC_01",
    "timestamp": "2026-01-16T10:00:00Z",
    "temperature": 75.5,
    "vibration": 0.45,
    "pressure": 32.1,
    "power": 78.3,
    "status": "Running"
  }'
```

## 🛡️ Seguridad y Mejores Prácticas

### Container Registry
- Usar Azure Container Registry con autenticación Managed Identity
- Imágenes firmadas y escaneadas por vulnerabilidades
- Credenciales seguras a través de variables de entorno

### Networking
- Comunicación cifrada entre módulos
- Acceso limitado a puertos expuestos
- VPN/firewall para administración remota

### Logs y Auditoría
- Logs centralizados en Azure Monitor
- Retención automática con rotación
- Alertas automáticas en fallos críticos

## 🔄 CI/CD para Edge

### GitHub Actions Pipeline
```yaml
- name: Build and Push Containers
  run: |
    edge/scripts/build-containers.ps1 -PushImages
    
- name: Deploy to Edge Fleet
  run: |
    edge/scripts/deploy-edge.ps1 -EdgeDeviceId ${{ matrix.device }}
```

### Actualizaciones OTA (Over-The-Air)
- Despliegues graduales por lotes de dispositivos
- Rollback automático en caso de fallas
- Validación de salud antes de continuar

## 🚨 Troubleshooting

### Problemas Comunes

1. **Módulo no inicia**
   - Verificar logs: `docker logs <container-id>`
   - Revisar configuración de recursos
   - Validar conectividad de red

2. **Sin telemetría**
   - Verificar rutas de mensajes
   - Comprobar estado de EdgeHub
   - Revisar configuración de dispositivo

3. **Predicciones ML fallan**
   - Verificar formato de datos de entrada
   - Comprobar modelo ML cargado
   - Revisar logs del módulo smartFactoryML

### Comandos de Diagnóstico
```bash
# Estado general del dispositivo
az iot hub device-identity show --hub-name <hub> --device-id <device>

# Logs específicos de módulo
docker logs -f <container-name>

# Métricas de recursos
docker stats

# Estado de conectividad
az iot hub monitor-feedback --hub-name <hub>
```

## 📈 Optimización de Performance

### Recursos Recomendados
- **CPU**: 2+ cores para inferencia ML
- **RAM**: 4GB+ para operación estable  
- **Storage**: 32GB+ para logs y cache
- **Network**: Conexión estable 1Mbps+

### Tuning de Parámetros
- Ajustar `TELEMETRY_INTERVAL` según necesidades
- Optimizar `MaxUpstreamBatchSize` para red
- Configurar `StoreAndForwardConfiguration` para disconnections

---

## 🎯 Próximos Pasos

1. **Escalar a múltiples dispositivos Edge**
2. **Implementar actualizaciones OTA automáticas**  
3. **Agregar más modelos ML especializados**
4. **Integrar con Azure Digital Twins**
5. **Configurar alertas avanzadas en Azure Monitor**
- `factorySimulatorToIoTHub`: Envía telemetría del simulador a IoT Hub
- `sensorToIoTHub`: Ruta general para sensores adicionales

## Despliegue

### Pre-requisitos
1. IoT Edge Runtime instalado en el dispositivo
2. Dispositivo IoT Edge registrado en IoT Hub
3. Connection strings configurados

### Comando de Despliegue
```bash
# Desplegar a un dispositivo específico
az iot edge set-modules --device-id myEdgeDevice --hub-name myIoTHub --content deployment.json

# Desplegar a múltiples dispositivos usando etiquetas
az iot edge set-modules --device-id myEdgeDevice --hub-name myIoTHub --content deployment.json --target-condition "tags.environment='production'"
```

### Variables de Entorno Requeridas
En el deployment, configurar:
- `DEVICE_CONN_STRING`: Connection string del dispositivo IoT Edge

### Configuración del Simulador como Módulo

Para usar el simulador como módulo de IoT Edge, necesitas:

1. **Crear imagen Docker**:
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY src/device-simulator/package*.json ./
RUN npm ci --only=production
COPY src/device-simulator/ ./
EXPOSE 8080
CMD ["node", "simulator.js"]
```

2. **Publicar en Container Registry**:
```bash
docker build -t myregistry.azurecr.io/factory-simulator:1.0 .
docker push myregistry.azurecr.io/factory-simulator:1.0
```

3. **Actualizar deployment.json** con la imagen personalizada:
```json
{
  "factorySimulator": {
    "settings": {
      "image": "myregistry.azurecr.io/factory-simulator:1.0"
    }
  }
}
```

## Ventajas de IoT Edge

### Store & Forward
- **Resiliencia**: Almacena datos localmente si hay problemas de conectividad
- **Batch Processing**: Agrupa mensajes para eficiencia de red
- **Automatic Retry**: Reintenta envíos fallidos automáticamente

### Edge Computing
- **Latencia Reducida**: Procesamiento local de datos críticos
- **Ancho de Banda Optimizado**: Filtra y agrega datos antes de enviar
- **Operación Offline**: Continúa funcionando sin conexión a la nube

### Gestión Centralizada
- **Despliegue Remoto**: Actualiza módulos desde la nube
- **Monitoreo**: Supervisa estado y salud de módulos
- **Configuración Dinámica**: Cambia parámetros sin reiniciar

## Monitoreo

### Logs de Módulos
```bash
# Ver logs del simulador
sudo iotedge logs factorySimulator

# Ver logs de edgeHub
sudo iotedge logs edgeHub

# Estado de módulos
sudo iotedge list
```

### Métricas
- Mensajes enviados/recibidos
- Uso de CPU y memoria de módulos
- Estado de conectividad
- Tamaño de cola de store & forward

## Troubleshooting

### Problemas Comunes
1. **Módulo no inicia**: Verificar imagen Docker y variables de entorno
2. **Sin conectividad**: Revisar configuración de red y certificates
3. **Mensajes no llegan**: Verificar rutas en edgeHub
4. **Store & Forward lleno**: Ajustar timeToLiveSecs o frecuencia de envío