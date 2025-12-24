# Smart Factory - Arquitectura Híbrida Azure Cloud + Azure Local

## 🏗️ Estructura del Proyecto

Este proyecto implementa una **Smart Factory** con arquitectura híbrida que conecta Azure Local (on-premise) con Azure Cloud.

```
amapv2/
├── azure-cloud/           # ☁️ COMPONENTES CLOUD
│   ├── digital-twins/     # Azure Digital Twins & DTDL Models
│   ├── iot-hub/          # Azure IoT Hub Configuration  
│   └── functions/        # Azure Functions (ADT Projection)
│
├── azure-local/          # 🏭 COMPONENTES ON-PREMISE
│   ├── factory-simulator/ # Factory Device Simulator
│   └── arc-simple-vm/    # Azure Arc VM (130.131.248.173)
│
├── applications/         # 📱 APLICACIONES
│   └── mobile-app/      # React Native Factory App
│
├── infrastructure/      # 🔧 INFRAESTRUCTURA
│   ├── bicep/          # Plantillas Bicep
│   └── scripts/        # Scripts de Deploy
│
└── docs/               # 📖 DOCUMENTACIÓN
    └── architecture/   # Diagramas & Runbooks
```

## 🔄 Flujo de Datos Híbrido

### 1. **Azure Local (On-Premise)**
- **VM Factory**: `130.131.248.173` (arc-simple)
- **Simulador**: Genera telemetría industrial (temperatura, presión, OEE)
- **Azure Arc**: Conecta VM on-premise con Azure Cloud

### 2. **Conectividad Híbrida**
- **Azure Arc** conecta la VM local con Azure Cloud
- **IoT Edge** (futuro) para procesamiento local
- **VPN/ExpressRoute** para conectividad segura

### 3. **Azure Cloud**
- **Azure Digital Twins**: Modelo digital de la fábrica
- **IoT Hub**: Ingesta de telemetría desde edge
- **Azure Functions**: Procesamiento y proyección a ADT
- **Power BI**: Dashboards ejecutivos

### 4. **Aplicaciones**
- **Mobile App**: React Native para trabajadores
- **Web Dashboard**: Control room operations
- **AI Agents**: Asistentes conversacionales

## 🚀 Estado Actual

### ✅ COMPLETADO
- [x] VM Azure Local funcionando (arc-simple)
- [x] Factory simulator generando datos
- [x] Modelos DTDL para Digital Twins
- [x] Azure Functions para ADT projection
- [x] React Native mobile app
- [x] Infraestructura Bicep limpia

### 🔄 EN PROGRESO  
- [ ] Conexión híbrida Arc → IoT Hub → ADT
- [ ] Dashboard web real-time
- [ ] AI agents integration

### 📋 PRÓXIMOS PASOS
1. **Conectar Simulator → IoT Hub**: Configurar device connection strings
2. **Deploy ADT Instance**: Subir modelos DTDL a Azure Digital Twins
3. **Configurar Functions**: Activar projection de telemetría
4. **Validar End-to-End**: Datos desde VM hasta Digital Twins

## 🎯 Casos de Uso

### **Trabajador de Planta**
- Usa mobile app React Native
- Ve estado real-time de máquinas
- Recibe notificaciones de mantenimiento

### **Ingeniero de Proceso** 
- Accede dashboard web
- Analiza KPIs y tendencias
- Optimiza procesos usando AI

### **Management**
- Power BI dashboards ejecutivos
- ROI y métricas business
- Predictive insights

## 🔧 Tech Stack

### **Cloud Native**
- Azure Digital Twins, IoT Hub, Functions
- Power BI, Storage, Cognitive Services

### **Edge/Local** 
- Azure Arc, Windows Server
- PowerShell automation, local dashboards

### **Applications**
- React Native (Mobile)
- React/TypeScript (Web)
- Azure OpenAI (AI Agents)

### **DevOps**
- Bicep Infrastructure as Code
- GitHub Actions CI/CD
- Azure DevOps pipelines