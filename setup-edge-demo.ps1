# 🏭 Smart Factory IoT Edge Demo - Completa
# Demostración de fábrica inteligente con procesamiento en el edge

param(
    [string]$EdgeMachineIP = "192.168.1.100",
    [int]$ProductionLines = 3,
    [switch]$SetupTunnel = $true
)

Write-Host "🏭 SMART FACTORY IoT EDGE DEMO" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# CONFIGURACIÓN DE LA DEMO
Write-Host "`n📋 CONFIGURACIÓN DE LA DEMO" -ForegroundColor Yellow
Write-Host "=============================" -ForegroundColor Yellow
Write-Host "🔧 Máquina Edge: $EdgeMachineIP"
Write-Host "🏭 Líneas de Producción: $ProductionLines"
Write-Host "📊 Componentes Edge:"
Write-Host "   • IoT Edge Runtime"
Write-Host "   • PostgreSQL local"
Write-Host "   • Grafana Dashboard"
Write-Host "   • ML Models (Edge)"
Write-Host "   • Device Simulator"

# PASO 1: LÍNEAS DE PRODUCCIÓN
Write-Host "`n🏭 PASO 1: Configurar Líneas de Producción" -ForegroundColor Yellow
Write-Host "===========================================" -ForegroundColor Yellow

$productionLines = @()
for ($i = 1; $i -le $ProductionLines; $i++) {
    $line = @{
        LineId = "LINE-$i"
        Name = "Línea de Producción $i"
        Devices = @(
            @{ Type="CNC"; Count=2; Status="Operational" },
            @{ Type="Robot"; Count=1; Status="Operational" },
            @{ Type="Conveyor"; Count=3; Status="Operational" },
            @{ Type="Quality"; Count=1; Status="Operational" },
            @{ Type="Environment"; Count=1; Status="Operational" }
        )
        TotalDevices = 8
        Production = @{
            Target = 100 * $i
            Current = [math]::Round((85 + (Get-Random -Maximum 15)) * $i)
            Efficiency = 85 + (Get-Random -Maximum 15)
        }
    }
    $productionLines += $line
}

foreach ($line in $productionLines) {
    Write-Host "`n🔧 $($line.Name) ($($line.LineId))" -ForegroundColor White
    Write-Host "   📊 Producción: $($line.Production.Current)/$($line.Production.Target) unidades"
    Write-Host "   ⚡ Eficiencia: $($line.Production.Efficiency)%"
    Write-Host "   🔌 Dispositivos: $($line.TotalDevices) total"
    
    foreach ($deviceType in $line.Devices) {
        $statusColor = if ($deviceType.Status -eq "Operational") { "Green" } else { "Red" }
        Write-Host "      • $($deviceType.Type): $($deviceType.Count) unidades - " -NoNewline
        Write-Host $deviceType.Status -ForegroundColor $statusColor
    }
}

Write-Host "`n📊 Resumen Total:"
Write-Host "   🏭 Total Líneas: $ProductionLines"
Write-Host "   🔌 Total Dispositivos: $(($productionLines | ForEach-Object { $_.TotalDevices } | Measure-Object -Sum).Sum)"
Write-Host "   🎯 Producción Total: $(($productionLines | ForEach-Object { $_.Production.Current } | Measure-Object -Sum).Sum) unidades"

# PASO 2: IoT EDGE SETUP
Write-Host "`n🔧 PASO 2: IoT Edge Runtime Setup" -ForegroundColor Yellow
Write-Host "==================================" -ForegroundColor Yellow

$edgeConfig = @"
# IoT Edge Device Configuration
# /etc/iotedge/config.yaml

device_hostname: edge-factory-01
provisioning:
  device_connection_string: "HostName=smartfactory-prod-iot.azure-devices.net;DeviceId=edge-factory-01;SharedAccessKey=..."

# Edge Runtime Modules
modules:
  edgeAgent:
    image: mcr.microsoft.com/azureiotedge-agent:1.4
  edgeHub:
    image: mcr.microsoft.com/azureiotedge-hub:1.4
  
  # Custom Modules
  deviceSimulator:
    image: smartfactory/device-simulator:edge
    ports: ["3000:3000"]
    environment:
      - PRODUCTION_LINES=$ProductionLines
      - EDGE_MODE=true
      
  dataProcessor:
    image: smartfactory/data-processor:edge
    environment:
      - POSTGRES_CONNECTION=postgresql://postgres:password@postgres:5432/factory
      
  mlInference:
    image: smartfactory/ml-inference:edge
    environment:
      - MODEL_PATH=/models/anomaly-detection.onnx
"@

Write-Host "📝 Configuración IoT Edge:" -ForegroundColor Cyan
Write-Host $edgeConfig -ForegroundColor Gray

# PASO 3: PostgreSQL Edge Setup
Write-Host "`n🗄️ PASO 3: PostgreSQL Edge Database" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow

$postgresSchema = @"
-- Smart Factory Edge Database Schema
CREATE DATABASE factory_edge;

CREATE TABLE production_lines (
    line_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100),
    status VARCHAR(20),
    target_production INT,
    current_production INT,
    efficiency DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE device_telemetry (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(50),
    line_id VARCHAR(20),
    device_type VARCHAR(20),
    sensor_type VARCHAR(20),
    value DECIMAL(10,2),
    unit VARCHAR(10),
    quality VARCHAR(10),
    anomaly BOOLEAN,
    timestamp TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (line_id) REFERENCES production_lines(line_id)
);

CREATE TABLE ml_predictions (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(50),
    prediction_type VARCHAR(50),
    confidence DECIMAL(5,2),
    alert_level VARCHAR(20),
    recommendations TEXT,
    timestamp TIMESTAMP DEFAULT NOW()
);

CREATE TABLE alerts (
    id SERIAL PRIMARY KEY,
    line_id VARCHAR(20),
    device_id VARCHAR(50),
    alert_type VARCHAR(50),
    severity VARCHAR(20),
    message TEXT,
    acknowledged BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Insert sample production lines
"@

for ($i = 1; $i -le $ProductionLines; $i++) {
    $postgresSchema += "INSERT INTO production_lines (line_id, name, status, target_production, current_production, efficiency) VALUES ('LINE-$i', 'Línea de Producción $i', 'ACTIVE', $($i * 100), $(($i * 85) + (Get-Random -Maximum 15)), $(85 + (Get-Random -Maximum 15)));"
}

Write-Host "📝 Schema PostgreSQL Edge:" -ForegroundColor Cyan
Write-Host $postgresSchema -ForegroundColor Gray

# PASO 4: Grafana Dashboard
Write-Host "`n📊 PASO 4: Grafana Edge Dashboard" -ForegroundColor Yellow
Write-Host "==================================" -ForegroundColor Yellow

$grafanaDashboard = @{
    dashboard = @{
        title = "Smart Factory Edge Monitor"
        panels = @(
            @{
                title = "Líneas de Producción - Vista General"
                type = "stat"
                targets = @(@{ rawSql = "SELECT line_id, current_production, efficiency FROM production_lines" })
                gridPos = @{ h=6; w=12; x=0; y=0 }
            },
            @{
                title = "Telemetría en Tiempo Real"
                type = "timeseries"
                targets = @(@{ rawSql = "SELECT timestamp, device_id, value FROM device_telemetry WHERE timestamp > NOW() - INTERVAL '1 hour'" })
                gridPos = @{ h=8; w=12; x=12; y=0 }
            },
            @{
                title = "Alertas ML"
                type = "table"
                targets = @(@{ rawSql = "SELECT device_id, prediction_type, confidence, alert_level FROM ml_predictions WHERE timestamp > NOW() - INTERVAL '1 hour'" })
                gridPos = @{ h=6; w=12; x=0; y=6 }
            },
            @{
                title = "Estado de Dispositivos por Línea"
                type = "heatmap"
                targets = @(@{ rawSql = "SELECT line_id, device_type, COUNT(*) as device_count FROM device_telemetry GROUP BY line_id, device_type" })
                gridPos = @{ h=8; w=12; x=12; y=8 }
            }
        )
    }
    datasource = @{
        name = "PostgreSQL Edge"
        type = "postgres"
        url = "postgres:5432"
        database = "factory_edge"
        user = "grafana"
    }
}

Write-Host "📝 Dashboard Grafana configurado para:" -ForegroundColor Cyan
Write-Host "   • Vista general de líneas de producción"
Write-Host "   • Telemetría en tiempo real"
Write-Host "   • Alertas de ML"
Write-Host "   • Estado de dispositivos por línea"

# PASO 5: ML en Edge
Write-Host "`n🤖 PASO 5: Machine Learning en Edge" -ForegroundColor Yellow
Write-Host "===================================" -ForegroundColor Yellow

$mlModels = @(
    @{ Name="Anomaly Detection"; Status="Active"; Accuracy=94.2; LastUpdate="2026-01-04" },
    @{ Name="Predictive Maintenance"; Status="Active"; Accuracy=89.7; LastUpdate="2026-01-04" },
    @{ Name="Quality Control"; Status="Active"; Accuracy=96.1; LastUpdate="2026-01-03" },
    @{ Name="Energy Optimization"; Status="Inactive"; Accuracy=0; LastUpdate="N/A" }
)

Write-Host "`n🧠 Modelos ML Edge desplegados:"
foreach ($model in $mlModels) {
    $statusColor = if ($model.Status -eq "Active") { "Green" } else { "Red" }
    Write-Host "   • $($model.Name): " -NoNewline
    Write-Host $model.Status -ForegroundColor $statusColor -NoNewline
    if ($model.Status -eq "Active") {
        Write-Host " (Precisión: $($model.Accuracy)%)" -ForegroundColor Gray
    } else {
        Write-Host " ⚠️ Requiere configuración" -ForegroundColor Yellow
    }
}

# PASO 6: Túnel para Cliente
if ($SetupTunnel) {
    Write-Host "`n🌐 PASO 6: Configuración de Túnel" -ForegroundColor Yellow
    Write-Host "==================================" -ForegroundColor Yellow
    
    Write-Host "`n📡 Configurando túnel SSH para acceso remoto:"
    Write-Host "   ssh -L 3000:localhost:3000 user@$EdgeMachineIP  # Grafana"
    Write-Host "   ssh -L 5432:localhost:5432 user@$EdgeMachineIP  # PostgreSQL"
    Write-Host "   ssh -L 8080:localhost:8080 user@$EdgeMachineIP  # Device Simulator"
    
    Write-Host "`n🔗 URLs de acceso local:"
    Write-Host "   📊 Grafana: http://localhost:3000"
    Write-Host "   🔧 Simulator: http://localhost:8080"
    Write-Host "   🗄️ PostgreSQL: localhost:5432"
}

# COMANDOS DE EJECUCIÓN
Write-Host "`n🚀 COMANDOS PARA EJECUTAR LA DEMO" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green

Write-Host "`n📋 En la máquina Edge ($EdgeMachineIP):" -ForegroundColor Cyan

$edgeCommands = @"
# 1. Iniciar servicios base
sudo systemctl start docker
sudo systemctl start iotedge

# 2. Verificar IoT Edge
sudo iotedge check
sudo iotedge list

# 3. Iniciar PostgreSQL Edge
docker run -d --name postgres-edge \
  -e POSTGRES_DB=factory_edge \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=factory123 \
  -p 5432:5432 \
  postgres:13

# 4. Iniciar Grafana Edge
docker run -d --name grafana-edge \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=factory123 \
  grafana/grafana:latest

# 5. Ejecutar Device Simulator
docker run -d --name device-simulator \
  -p 8080:3000 \
  -e PRODUCTION_LINES=$ProductionLines \
  -e EDGE_MODE=true \
  smartfactory/device-simulator:edge

# 6. Verificar servicios
docker ps
curl http://localhost:3000/api/health
curl http://localhost:8080/api/status
"@

Write-Host $edgeCommands -ForegroundColor Gray

Write-Host "`n📋 En la máquina cliente:" -ForegroundColor Cyan
Write-Host "   ssh -L 3000:localhost:3000 -L 8080:localhost:8080 user@$EdgeMachineIP"
Write-Host "   Abrir: http://localhost:3000 (Grafana)"
Write-Host "   Abrir: http://localhost:8080 (Simulator)"

Write-Host "`n✅ DEMO EDGE CONFIGURADA" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green
Write-Host "🏭 $ProductionLines líneas de producción simuladas"
Write-Host "📊 Dashboard Grafana con telemetría en tiempo real"
Write-Host "🤖 ML en edge para detección de anomalías"
Write-Host "🗄️ PostgreSQL edge para almacenamiento local"
Write-Host "🔧 Device simulator con múltiples dispositivos"