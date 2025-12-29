# Smart Factory AKS Edge Essentials

Este directorio contiene la configuración completa para desplegar **AKS Edge Essentials** en la VM Arc con data services locales para autonomía en el edge.

## 🏗️ Arquitectura Edge

```
┌─────────────────────────────────────────────────────────────┐
│                    AKS Edge Essentials                     │
│                   (VM Arc: 130.131.248.173)               │
├─────────────────────────────────────────────────────────────┤
│  Data Services Layer                                       │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐ │
│  │ PostgreSQL  │  InfluxDB   │   Redis     │  Grafana    │ │
│  │   :30432    │   :30086    │   (cache)   │   :30000    │ │
│  └─────────────┴─────────────┴─────────────┴─────────────┘ │
├─────────────────────────────────────────────────────────────┤
│  ML & Analytics Layer                                      │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐ │
│  │ ML Inference│ Node-RED    │ Prometheus  │ Factory API │ │
│  │   :30002    │   :30001    │ (metrics)   │   :30003    │ │
│  └─────────────┴─────────────┴─────────────┴─────────────┘ │
├─────────────────────────────────────────────────────────────┤
│  Kubernetes Orchestration                                  │
│  • Auto-scaling • Health checks • Self-healing             │
│  • Persistent storage • Resource management                │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Instalación

### Paso 1: Instalar AKS Edge Essentials

```powershell
# En la VM Arc (130.131.248.173)
.\install-aks-edge.ps1
```

### Paso 2: Desplegar Data Services

```powershell
# Desplegar stack completo
.\deploy-data-services.ps1
```

## 📊 Servicios Desplegados

| Servicio | Puerto | URL | Propósito |
|----------|--------|-----|-----------|
| **Grafana** | 30000 | http://130.131.248.173:30000 | Dashboards y visualización |
| **Node-RED** | 30001 | http://130.131.248.173:30001 | Low-code automation |
| **ML Inference** | 30002 | http://130.131.248.173:30002 | Anomaly detection |
| **Factory API** | 30003 | http://130.131.248.173:30003 | REST API para datos |
| **PostgreSQL** | 30432 | 130.131.248.173:30432 | Base de datos relacional |
| **InfluxDB** | 30086 | http://130.131.248.173:30086 | Time-series database |

## 🔑 Credenciales

### Grafana
- **Usuario**: admin
- **Contraseña**: admin123

### PostgreSQL
- **Usuario**: factory_user
- **Contraseña**: SmartFactory2025!
- **Base de datos**: smart_factory

### InfluxDB
- **Usuario**: admin
- **Contraseña**: admin123
- **Base de datos**: smart_factory_metrics

## 🧠 Capacidades ML

### API de Anomaly Detection
```bash
POST http://130.131.248.173:30002/predict/anomaly
{
  "machine_id": "CNC-001",
  "sensor_values": [1.2, 1.5, 1.8, 2.1, 1.9, 1.7, 1.4, 1.6, 1.8, 2.0, 8.5]
}
```

### API de Predictive Maintenance
```bash
POST http://130.131.248.173:30002/predict/maintenance
{
  "machine_id": "CNC-001",
  "runtime_hours": 1200,
  "vibration": 6.5,
  "temperature": 85
}
```

## 📈 Factory Data API

### Máquinas
```bash
# Listar máquinas
GET http://130.131.248.173:30003/api/machines

# Obtener máquina específica
GET http://130.131.248.173:30003/api/machines/1

# Crear nueva máquina
POST http://130.131.248.173:30003/api/machines
{
  "name": "CNC-002",
  "type": "CNC Machine",
  "location": "Production Line 3"
}
```

### Sensores
```bash
# Sensores de una máquina
GET http://130.131.248.173:30003/api/machines/1/sensors
```

### Mantenimiento
```bash
# Historial de mantenimiento
GET http://130.131.248.173:30003/api/machines/1/maintenance

# Registrar mantenimiento
POST http://130.131.248.173:30003/api/machines/1/maintenance
{
  "maintenance_type": "Preventive",
  "description": "Routine calibration",
  "performed_by": "Tech Team",
  "cost": 150.00,
  "duration_hours": 2.5
}
```

## 🔄 Integración Híbrida

### Conexión con Azure Digital Twins
El stack edge se integra con la infraestructura cloud en `rg-smartfactory-prod`:

1. **Local**: Procesamiento en tiempo real, ML inference, cache
2. **Cloud**: Azure Digital Twins, almacenamiento histórico, analytics avanzados
3. **Sincronización**: Datos críticos se sincronizan cuando hay conectividad

### Flujo de Datos
```
Factory Floor → Edge Processing → Local DB/Cache → Cloud Sync
     ↓              ↓                ↓              ↓
  Sensores → ML Inference → PostgreSQL/Redis → Digital Twins
```

## 🛠️ Operaciones

### Verificar Estado
```powershell
kubectl get pods -n smart-factory
kubectl get services -n smart-factory
```

### Logs
```powershell
kubectl logs -n smart-factory deployment/ml-inference
kubectl logs -n smart-factory deployment/factory-api
```

### Escalamiento
```powershell
kubectl scale deployment ml-inference --replicas=2 -n smart-factory
```

## 🎯 Beneficios

- ✅ **Autonomía Local**: Funciona sin internet
- ✅ **Latencia Ultra-Baja**: ML inference < 100ms
- ✅ **Escalabilidad**: Auto-scaling basado en demanda  
- ✅ **Resilencia**: Auto-restart, health checks
- ✅ **Datos Seguros**: Datos críticos permanecen locales
- ✅ **Híbrido**: Sincronización con cloud cuando disponible