# 🚀 Quick Start Guide - Smart Factory Híbrida

## 📋 Resumen del Proyecto

**Smart Factory** con arquitectura híbrida Azure Cloud + Azure Local totalmente reorganizada:

```
📁 amapv2/
├── 🔷 azure-cloud/       # Servicios Azure Cloud
├── 🏭 azure-local/       # Componentes On-Premise 
├── 📱 applications/      # Apps Mobile & Web
├── 🔧 infrastructure/   # Bicep & Scripts
└── 📖 docs/             # Documentación
```

## ✅ Estado Actual

### **🏭 Azure Local (VM arc-simple)**
- **IP**: 130.131.248.173
- **Status**: ✅ Conectado vía Azure Arc
- **Simulator**: ✅ Funcionando
- **Telemetría**: Máquinas, líneas producción, fábrica

### **☁️ Azure Cloud**
- **Digital Twins**: 4 modelos DTDL listos
- **Functions**: Projection IoT → ADT configurada
- **IoT Hub**: Preparado para conexión
- **Mobile App**: React Native completa

## 🎯 Próximos Pasos

### 1. **Conectar VM → Cloud** (15 min)
```bash
# En VM arc-simple
cd azure-local/factory-simulator
npm install
npm start
```

### 2. **Deploy Azure Resources** (30 min)
```bash
# Deploy infraestructura
az deployment group create \
  --resource-group smart-factory-rg \
  --template-file infrastructure/bicep/main.bicep
```

### 3. **Validar End-to-End** (10 min)
- ✅ VM genera telemetría
- ✅ IoT Hub recibe datos  
- ✅ Functions procesa → Digital Twins
- ✅ Mobile App muestra estado

## 📱 Apps y Dashboards

### **Trabajadores** 
- **React Native App**: Estado máquinas en tiempo real
- **Notificaciones**: Mantenimiento predictivo

### **Ingenieros**
- **Web Dashboard**: KPIs y análisis
- **AI Insights**: Optimización procesos

### **Management**
- **Power BI**: Métricas ejecutivas
- **ROI Analytics**: Business intelligence

## 🔄 Flujo de Datos

```
🏭 Factory Simulator → 🔗 Azure Arc → ☁️ IoT Hub → ⚡ Functions → 🔷 Digital Twins → 📱 Apps
```

## 📖 Documentación Completa

- **[PROYECTO-HIBRIDO.md](PROYECTO-HIBRIDO.md)**: Overview arquitectura
- **[docs/ARQUITECTURA-HIBRIDA.md](docs/ARQUITECTURA-HIBRIDA.md)**: Diagramas detallados
- **[azure-cloud/README.md](azure-cloud/README.md)**: Componentes cloud
- **[azure-local/README.md](azure-local/README.md)**: Setup on-premise

## 🔧 Comandos Útiles

### **Verificar Status**
```powershell
# Status VM Azure Arc
azcmagent show

# Status Factory Simulator  
Get-Process node

# Logs en tiempo real
Get-EventLog -LogName Application -Newest 10
```

### **Troubleshooting**
```bash
# Test conectividad IoT Hub
az iot hub device-identity list --hub-name smartfactory-iothub

# Verify Digital Twins
az dt model list --dt-name smartfactory-adt
```

## 🏆 Casos de Uso Demonstrados

1. **📊 Monitoreo Real-time**: VM → Cloud → Mobile
2. **🔮 Mantenimiento Predictivo**: AI analysis de sensores  
3. **📈 Optimización Procesos**: Digital Twin insights
4. **👥 Multi-Usuario**: Workers, Engineers, Management
5. **🌐 Híbrido**: Cloud + On-premise integrados

¿Listo para probar la integración completa? 🚀