# IoT Edge Deployment

Este directorio contiene la configuración para desplegar la solución de fábrica digital en IoT Edge.

## Deployment Manifest

El archivo `deployment.json` define:

### Módulos del Sistema
- **edgeAgent**: Administra el ciclo de vida de módulos
- **edgeHub**: Maneja comunicación y routing de mensajes

### Módulos Personalizados
- **factorySimulator**: Simulador de telemetría de fábrica

### Configuración de Store & Forward
- **timeToLiveSecs**: 3600 (1 hora de almacenamiento local)
- Permite operación offline con reenvío automático al reconectar

### Rutas de Mensajes
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