# 🔌 Smart Factory IoT Flow Demonstration
# Muestra paso a paso cómo funciona el flujo de datos desde el simulador hasta IoT Hub

param(
    [switch]$ShowTelemetryFormat = $true,
    [switch]$TestConnection = $true,
    [switch]$ShowRealFlow = $true
)

Write-Host "🏭 SMART FACTORY IoT FLOW DEMONSTRATION" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# PASO 1: Configuración del Simulador
Write-Host "`n📋 PASO 1: Configuración del Simulador" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

Write-Host "`n🔧 Configuración detectada:" -ForegroundColor White
Write-Host "  • Device Count: " -NoNewline; Write-Host "5 dispositivos por defecto" -ForegroundColor Green
Write-Host "  • Simulation Interval: " -NoNewline; Write-Host "10 segundos" -ForegroundColor Green
Write-Host "  • Factory ID: " -NoNewline; Write-Host "FACTORY-001" -ForegroundColor Green
Write-Host "  • Connection String: " -NoNewline
if ($env:IOT_HUB_CONNECTION_STRING) {
    Write-Host "✅ Configurado" -ForegroundColor Green
} else {
    Write-Host "❌ NO configurado" -ForegroundColor Red
    Write-Host "     Para configurar: `$env:IOT_HUB_CONNECTION_STRING = 'HostName=...'" -ForegroundColor Gray
}

# PASO 2: Tipos de Dispositivos
Write-Host "`n📱 PASO 2: Tipos de Dispositivos IoT" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow

$deviceTypes = @(
    @{ Name="CNC Machine"; Sensors="temperature, vibration, power, speed, pressure"; Location="production-line-1"; Criticality="HIGH" },
    @{ Name="Conveyor Belt"; Sensors="speed, load, temperature, vibration"; Location="assembly-line-a"; Criticality="MEDIUM" },
    @{ Name="Robotic Arm"; Sensors="position, force, temperature, battery"; Location="assembly-station-3"; Criticality="HIGH" },
    @{ Name="Quality Sensor"; Sensors="defect-rate, throughput, accuracy"; Location="quality-gate-1"; Criticality="CRITICAL" },
    @{ Name="Environmental"; Sensors="temperature, humidity, air-quality, noise"; Location="facility-general"; Criticality="LOW" }
)

foreach ($device in $deviceTypes) {
    $criticalityColor = switch ($device.Criticality) {
        "CRITICAL" { "Red" }
        "HIGH" { "Magenta" }
        "MEDIUM" { "Yellow" }
        "LOW" { "Green" }
    }
    
    Write-Host "  🔌 $($device.Name)" -ForegroundColor White
    Write-Host "     └─ Sensores: $($device.Sensors)" -ForegroundColor Gray
    Write-Host "     └─ Ubicación: $($device.Location)" -ForegroundColor Gray
    Write-Host "     └─ Criticidad: " -NoNewline -ForegroundColor Gray
    Write-Host $device.Criticality -ForegroundColor $criticalityColor
    Write-Host ""
}

if ($ShowTelemetryFormat) {
    # PASO 3: Formato de Telemetría
    Write-Host "`n📊 PASO 3: Formato de Mensaje de Telemetría" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Yellow
    
    $sampleTelemetry = @{
        deviceId = "device-cnc-machine-001"
        deviceType = "cnc-machine"
        deviceName = "CNC Machine"
        location = "production-line-1"
        criticality = "high"
        factoryId = "FACTORY-001"
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        sensors = @{
            temperature = @{ value = 45.7; unit = "°C"; quality = "good"; anomaly = $false }
            vibration = @{ value = 0.15; unit = "mm/s²"; quality = "good"; anomaly = $false }
            power = @{ value = 2150; unit = "W"; quality = "good"; anomaly = $false }
            speed = @{ value = 1850; unit = "RPM"; quality = "good"; anomaly = $false }
            pressure = @{ value = 16.2; unit = "bar"; quality = "good"; anomaly = $false }
        }
        deviceState = @{
            operational = $true
            maintenanceMode = $false
            efficiency = 0.92
            runningHours = 1247
        }
        metadata = @{
            messageId = "msg-$(Get-Date -Format 'yyyyMMddHHmmss')-abc123"
            version = "2.0.0"
            schema = "smart-factory-telemetry-v2"
        }
    }
    
    Write-Host "`n📝 Ejemplo de mensaje JSON que se envía al IoT Hub:" -ForegroundColor Cyan
    $sampleTelemetry | ConvertTo-Json -Depth 4 | Write-Host -ForegroundColor White
}

# PASO 4: Proceso de Conexión
Write-Host "`n🔗 PASO 4: Proceso de Conexión IoT Hub" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow

Write-Host "`n📋 Secuencia de conexión:" -ForegroundColor White
Write-Host "  1. 🔧 Dispositivo lee IoT Hub connection string"
Write-Host "  2. 🤝 Establece conexión MQTT con Azure IoT Hub"
Write-Host "  3. 📝 Se registra con Device ID único"
Write-Host "  4. ✅ Confirma conexión establecida"
Write-Host "  5. 📡 Inicia envío de telemetría cada 10 segundos"

if ($TestConnection) {
    Write-Host "`n🧪 PASO 5: Test de Conectividad" -ForegroundColor Yellow
    Write-Host "===============================" -ForegroundColor Yellow
    
    # Verificar recursos en Azure
    Write-Host "`n🔍 Verificando recursos IoT en Azure..." -ForegroundColor Cyan
    
    try {
        $iotHubs = az iot hub list --query "[].{name:name,location:location,state:state}" | ConvertFrom-Json
        
        if ($iotHubs -and $iotHubs.Count -gt 0) {
            Write-Host "✅ IoT Hubs encontrados:" -ForegroundColor Green
            foreach ($hub in $iotHubs) {
                Write-Host "  📡 $($hub.name) - $($hub.location) - Estado: $($hub.state)" -ForegroundColor White
            }
            
            # Obtener connection string del primer hub
            $hubName = $iotHubs[0].name
            Write-Host "`n🔑 Obteniendo connection string para $hubName..." -ForegroundColor Cyan
            
            try {
                $connectionString = az iot hub connection-string show --hub-name $hubName --query "connectionString" -o tsv
                if ($connectionString) {
                    Write-Host "✅ Connection string obtenido exitosamente" -ForegroundColor Green
                    Write-Host "   Longitud: $($connectionString.Length) caracteres" -ForegroundColor Gray
                    
                    # Mostrar configuración
                    Write-Host "`n📋 Para configurar el simulador, ejecuta:" -ForegroundColor Yellow
                    Write-Host "`$env:IOT_HUB_CONNECTION_STRING = '$($connectionString.Substring(0,50))...'" -ForegroundColor Gray
                } else {
                    Write-Host "❌ No se pudo obtener connection string" -ForegroundColor Red
                }
            } catch {
                Write-Host "❌ Error obteniendo connection string: $($_.Exception.Message)" -ForegroundColor Red
            }
            
        } else {
            Write-Host "⚠️ No se encontraron IoT Hubs en la suscripción" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Error verificando recursos: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($ShowRealFlow) {
    # PASO 6: Flujo Real de Datos
    Write-Host "`n🌊 PASO 6: Flujo Real de Datos" -ForegroundColor Yellow
    Write-Host "==============================" -ForegroundColor Yellow
    
    Write-Host "`n📊 Arquitectura del flujo de datos:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "┌─────────────────┐    MQTT     ┌─────────────────┐" -ForegroundColor White
    Write-Host "│   📱 Device     │ ─────────► │  ☁️ IoT Hub      │" -ForegroundColor White  
    Write-Host "│   Simulator     │             │                 │" -ForegroundColor White
    Write-Host "└─────────────────┘             └─────────────────┘" -ForegroundColor White
    Write-Host "                                          │" -ForegroundColor White
    Write-Host "                                          ▼" -ForegroundColor White
    Write-Host "┌─────────────────┐             ┌─────────────────┐" -ForegroundColor White
    Write-Host "│  📊 Cosmos DB   │ ◄─────────  │  ⚡ Function     │" -ForegroundColor White
    Write-Host "│   (Telemetry)   │             │   ADT Projection│" -ForegroundColor White
    Write-Host "└─────────────────┘             └─────────────────┘" -ForegroundColor White
    Write-Host "                                          │" -ForegroundColor White
    Write-Host "                                          ▼" -ForegroundColor White
    Write-Host "                                ┌─────────────────┐" -ForegroundColor White
    Write-Host "                                │  🏭 Digital     │" -ForegroundColor White
    Write-Host "                                │   Twins (ADT)   │" -ForegroundColor White
    Write-Host "                                └─────────────────┘" -ForegroundColor White
    
    Write-Host "`n🔄 Proceso paso a paso:" -ForegroundColor White
    Write-Host "  1. 📱 Simulador genera datos de sensores realistas"
    Write-Host "  2. 📡 MQTT envía mensaje JSON al IoT Hub"
    Write-Host "  3. 🔧 IoT Hub routes el mensaje a Function App"
    Write-Host "  4. ⚡ Function procesa y almacena en Cosmos DB"
    Write-Host "  5. 🏭 Function actualiza Digital Twin en ADT"
    Write-Host "  6. 📊 Application Insights captura métricas"
    Write-Host "  7. 🎛️ Dashboard muestra datos en tiempo real"
}

# PASO 7: Comandos para Ejecutar
Write-Host "`n🚀 PASO 7: Comandos para Ejecutar la Demo" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Yellow

Write-Host "`n📋 Para ejecutar la demostración completa:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1️⃣ Configurar connection string:" -ForegroundColor White
Write-Host "   `$env:IOT_HUB_CONNECTION_STRING = 'tu-connection-string'" -ForegroundColor Gray
Write-Host ""
Write-Host "2️⃣ Navegar al directorio del simulador:" -ForegroundColor White
Write-Host "   cd src\device-simulator" -ForegroundColor Gray
Write-Host ""
Write-Host "3️⃣ Instalar dependencias (si es necesario):" -ForegroundColor White
Write-Host "   npm install azure-iot-device azure-iot-device-mqtt express" -ForegroundColor Gray
Write-Host ""
Write-Host "4️⃣ Ejecutar el simulador:" -ForegroundColor White
Write-Host "   node server.js" -ForegroundColor Gray
Write-Host ""
Write-Host "5️⃣ Abrir dashboard en navegador:" -ForegroundColor White
Write-Host "   http://localhost:3000" -ForegroundColor Gray
Write-Host ""
Write-Host "6️⃣ Monitorear en Azure Portal:" -ForegroundColor White
Write-Host "   - IoT Hub > Device-to-cloud messages" -ForegroundColor Gray
Write-Host "   - Application Insights > Live Metrics" -ForegroundColor Gray

Write-Host "`n✨ DEMOSTRACIÓN COMPLETADA" -ForegroundColor Green
Write-Host "==========================" -ForegroundColor Green
Write-Host "El flujo de datos está listo para funcionar con la configuración apropiada." -ForegroundColor Cyan