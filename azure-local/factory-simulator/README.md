# Smart Factory Simulator

Este simulador ejecuta en **Azure Local** (VM arc-simple) y genera telemetría industrial que se envía a **Azure Cloud**.

## 🏭 Funcionalidades

### Simulación de Máquinas
- **CNC Machine 1**: Máquina de control numérico
- **Assembly Robot**: Robot de ensamblaje  
- **Quality Scanner**: Escáner de calidad
- **Packaging Unit**: Unidad de empaque

### Simulación de Líneas de Producción
- **Main Production Line**: Widget A
- **Secondary Line**: Widget B

### Telemetría Generada
```javascript
{
  deviceId: 'machine-001',
  temperature: 23.4,     // °C
  pressure: 102.1,       // kPa  
  vibration: 0.45,       // Level
  oee: 87.3,            // Overall Equipment Effectiveness %
  status: 'running',     // running/idle/maintenance/error
  timestamp: '2024-01-15T10:30:00Z'
}
```

## 🚀 Uso

### Instalación
```bash
cd azure-local/factory-simulator
npm install
```

### Ejecución
```bash
# Ejecutar simulador
npm start

# Desarrollo con auto-reload
npm run dev
```

### Configuración
El simulador se conecta a Azure IoT Hub usando las credenciales configuradas en la VM arc-simple.

## 📡 Conectividad

### Azure Local → Cloud
```
Factory Simulator → Azure Arc → IoT Hub → Azure Functions → Digital Twins
```

### Estados de Máquinas
- **Running**: Operación normal
- **Idle**: Máquina parada temporalmente  
- **Maintenance**: En mantenimiento programado
- **Error**: Falla que requiere atención

### Métricas Simuladas
- **Temperatura**: 15°C - 30°C (operación normal)
- **Presión**: 100-103 kPa (rango industrial)
- **Vibración**: 0.1-1.0 (niveles aceptables)
- **OEE**: 70%-95% (eficiencia equipamiento)