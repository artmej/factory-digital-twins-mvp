# Arc IoT Strategy - Smart Factory Edge Autónomo

## 🎯 Arquitectura Edge-First

### Opción 1: Azure IoT Edge + Arc (RECOMENDADO)
```
Smart Factory (Edge Autónomo)
├── IoT Edge Runtime (en AKS)
├── Module: MQTT Broker (local)
├── Module: TimescaleDB (ya tenemos)
├── Module: AI Inference (local)
└── Arc Agent (sync híbrido opcional)
```

### Opción 2: Arc-enabled Kubernetes + IoT Services
```
AKS Cluster (Arc-enabled)
├── MQTT Broker (Eclipse Mosquitto)
├── PostgreSQL + TimescaleDB ✅
├── Grafana Dashboard
├── ML Models (local inference)
└── Optional cloud sync
```

## 🚀 Ventajas Arc Approach

1. **Autonomía Total**: Factory funciona sin internet
2. **Latencia Mínima**: Todo procesamiento local
3. **Seguridad**: Datos no salen del factory floor
4. **Escalabilidad**: Cada factory es independiente
5. **Gestión Híbrida**: Arc permite administración central opcional

## 📊 Componentes Edge Stack

| Componente | Solución Arc | Beneficio |
|------------|--------------|-----------|
| Message Broker | MQTT (Mosquitto) | Comunicación local sensors |
| Database | PostgreSQL + TimescaleDB ✅ | Time-series data local |
| Visualization | Grafana | Real-time dashboards |
| ML Inference | TensorFlow Serving | AI predictions local |
| Device Management | IoT Edge | Device provisioning |

## 🔄 Smart Factory Data Flow

```
Sensors → MQTT Broker → PostgreSQL → Grafana
                    ↓
              ML Inference → Actuators
                    ↓
            Optional Arc Sync → Azure
```

## 🎯 Decisión: ¿Azure IoT Hub o Arc Services?

**RECOMENDACIÓN: Arc Services Edge-First**
- Autonomía completa
- Mejor para manufacturing
- Menos dependencia cloud
- Más control local