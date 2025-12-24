# Smart Factory on Azure Local (AKS) 🏭

Este directorio contiene los manifiestos de Kubernetes para deployar la **Smart Factory** sobre **AKS en Azure Local**.

## 🏗️ Arquitectura:
```
🌐 Azure VM (host)
└── 💿 Azure Local (Azure Stack HCI simulation)
    └── ⚙️ AKS Cluster
        ├── 🏭 Factory Simulation Namespace
        ├── 🤖 Robot Control System  
        ├── 📊 Local SCADA Dashboard
        ├── 📡 IoT Data Collector
        └── 🔄 Edge Processing Services
```

## 📋 Componentes:

### Core Services:
- **Factory Simulator**: Simula máquinas, líneas de producción y sensores
- **Robot Controller**: Control de brazos robóticos industriales  
- **SCADA Dashboard**: Interfaz de supervisión local
- **IoT Collector**: Recolección y procesamiento de telemetría
- **Edge AI**: Procesamiento local de ML models

### Storage:
- **Local Storage**: Persistencia en Azure Local
- **Cache Layer**: Redis para datos en tiempo real
- **Time Series DB**: InfluxDB para telemetría histórica

### Networking:
- **LoadBalancer**: Acceso externo a dashboards
- **Internal Services**: Comunicación entre pods
- **Edge Gateway**: Sincronización con cloud cuando disponible

## 🚀 Deployment Order:
1. `00-namespace.yaml` - Namespace base
2. `01-storage.yaml` - PVCs y storage
3. `02-configmaps.yaml` - Configuración
4. `03-secrets.yaml` - Credenciales
5. `04-services.yaml` - Servicios de red
6. `05-deployments.yaml` - Aplicaciones principales
7. `06-ingress.yaml` - Exposición externa

## 🌐 Access URLs (after deployment):
- **Factory Dashboard**: http://vm-ip:8081
- **SCADA Interface**: http://vm-ip:8080
- **Robot Control**: http://vm-ip:8082
- **Kubernetes Dashboard**: https://vm-ip:6443

## 💾 Local vs Cloud:
- **Local Processing**: Procesamiento en tiempo real, autonomía de red
- **Cloud Sync**: Sincronización cuando hay conectividad
- **Hybrid Mode**: Continua operación local + cloud analytics