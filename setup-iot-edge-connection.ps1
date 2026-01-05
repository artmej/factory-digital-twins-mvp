# 🔧 Configuración IoT Edge Device - Conexión al IoT Hub
# Script para conectar el edge device al IoT Hub existente

param(
    [string]$EdgeDeviceName = "edge-factory-01",
    [string]$ResourceGroupName = "smart-factory-v2-rg",
    [string]$IoTHubName = "smartfactory-prod-iot-ncy666q5uv3bo"
)

Write-Host "🔧 CONFIGURACIÓN IoT EDGE DEVICE" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# PASO 1: Verificar IoT Hub existente
Write-Host "`n📡 PASO 1: Verificar IoT Hub" -ForegroundColor Yellow
Write-Host "============================" -ForegroundColor Yellow

$iotHub = az iot hub show --name $IoTHubName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json

if ($iotHub) {
    Write-Host "✅ IoT Hub encontrado: $IoTHubName" -ForegroundColor Green
    Write-Host "   📍 Ubicación: $($iotHub.location)"
    Write-Host "   📊 SKU: $($iotHub.sku.name)"
    Write-Host "   🔗 HostName: $($iotHub.properties.hostName)"
} else {
    Write-Host "❌ IoT Hub no encontrado: $IoTHubName" -ForegroundColor Red
    exit 1
}

# PASO 2: Registrar Edge Device
Write-Host "`n🔌 PASO 2: Registrar Edge Device" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Yellow

Write-Host "🔍 Verificando si el device $EdgeDeviceName ya existe..."
$existingDevice = az iot hub device-identity show --device-id $EdgeDeviceName --hub-name $IoTHubName 2>$null | ConvertFrom-Json

if ($existingDevice) {
    Write-Host "⚠️ Device $EdgeDeviceName ya existe" -ForegroundColor Yellow
    $useExisting = Read-Host "¿Usar device existente? (y/n)"
    if ($useExisting -eq 'n') {
        Write-Host "🗑️ Eliminando device existente..."
        az iot hub device-identity delete --device-id $EdgeDeviceName --hub-name $IoTHubName
        $existingDevice = $null
    }
}

if (!$existingDevice) {
    Write-Host "📝 Creando nuevo Edge Device: $EdgeDeviceName"
    az iot hub device-identity create --device-id $EdgeDeviceName --hub-name $IoTHubName --edge-enabled true
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Edge Device creado exitosamente" -ForegroundColor Green
    } else {
        Write-Host "❌ Error creando Edge Device" -ForegroundColor Red
        exit 1
    }
}

# PASO 3: Obtener Connection String
Write-Host "`n🔑 PASO 3: Obtener Connection String" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow

Write-Host "🔍 Obteniendo connection string para $EdgeDeviceName..."
$deviceConnectionString = az iot hub device-identity connection-string show --device-id $EdgeDeviceName --hub-name $IoTHubName --query "connectionString" -o tsv

if ($deviceConnectionString) {
    Write-Host "✅ Connection string obtenido exitosamente" -ForegroundColor Green
    Write-Host "📋 Connection String (truncado): $($deviceConnectionString.Substring(0,80))..." -ForegroundColor Gray
} else {
    Write-Host "❌ Error obteniendo connection string" -ForegroundColor Red
    exit 1
}

# PASO 4: Generar configuración para Edge VM
Write-Host "`n⚙️ PASO 4: Configuración Edge VM" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Yellow

$edgeConfig = @"
# IoT Edge Configuration for Azure VM
# File: /etc/aziot/config.toml

[provisioning]
source = "manual"
connection_string = "$deviceConnectionString"

[agent]
name = "edgeAgent"
type = "docker"

[agent.config]
image = "mcr.microsoft.com/azureiotedge-agent:1.4"

[connect]
workload_uri = "unix:///var/run/iotedge/workload.sock"
management_uri = "unix:///var/run/iotedge/mgmt.sock"

[listen]
workload_uri = "fd://aziot-edged.workload.socket"
management_uri = "fd://aziot-edged.mgmt.socket"

[watchdog]
max_retries = 2
"@

Write-Host "📝 Configuración generada para Edge VM:"
Write-Host $edgeConfig -ForegroundColor Gray

# Guardar configuración en archivo
$configFile = "iot-edge-config.toml"
$edgeConfig | Out-File -FilePath $configFile -Encoding UTF8
Write-Host "💾 Configuración guardada en: $configFile" -ForegroundColor Cyan

# PASO 5: Comandos para Edge VM
Write-Host "`n🖥️ PASO 5: Comandos para Edge VM" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Yellow

$vmCommands = @"
# Ejecutar estos comandos en la Azure VM Edge:

# 1. Instalar IoT Edge Runtime (si no está instalado)
curl https://packages.microsoft.com/config/ubuntu/20.04/multiarch/prod.list > ./microsoft-prod.list
sudo cp ./microsoft-prod.list /etc/apt/sources.list.d/
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo cp ./microsoft.gpg /etc/apt/trusted.gpg.d/
sudo apt-get update
sudo apt-get install aziot-edge defender-iot-micro-agent-edge

# 2. Aplicar configuración
sudo cp $configFile /etc/aziot/config.toml
sudo chown aziotcs:aziotcs /etc/aziot/config.toml
sudo chmod 600 /etc/aziot/config.toml

# 3. Aplicar configuración y reiniciar
sudo iotedge config apply

# 4. Verificar estado
sudo iotedge system status
sudo iotedge check

# 5. Ver módulos
sudo iotedge list

# 6. Ver logs
sudo iotedge logs edgeAgent
"@

Write-Host "📋 Comandos para ejecutar en la Edge VM:" -ForegroundColor Cyan
Write-Host $vmCommands -ForegroundColor Gray

# Guardar comandos en archivo
$commandsFile = "edge-vm-commands.sh"
$vmCommands | Out-File -FilePath $commandsFile -Encoding UTF8
Write-Host "💾 Comandos guardados en: $commandsFile" -ForegroundColor Cyan

# PASO 6: Deployment Manifest para módulos
Write-Host "`n📦 PASO 6: Deployment Manifest" -ForegroundColor Yellow
Write-Host "===============================" -ForegroundColor Yellow

$deploymentManifest = @{
    content = @{
        modulesContent = @{
            '$edgeAgent' = @{
                'properties.desired' = @{
                    schemaVersion = "1.1"
                    runtime = @{
                        type = "docker"
                        settings = @{
                            minDockerVersion = "v1.25"
                        }
                    }
                    systemModules = @{
                        edgeAgent = @{
                            type = "docker"
                            settings = @{
                                image = "mcr.microsoft.com/azureiotedge-agent:1.4"
                                createOptions = "{}"
                            }
                        }
                        edgeHub = @{
                            type = "docker"
                            status = "running"
                            restartPolicy = "always"
                            settings = @{
                                image = "mcr.microsoft.com/azureiotedge-hub:1.4"
                                createOptions = @'
{
  "HostConfig": {
    "PortBindings": {
      "5671/tcp": [{"HostPort": "5671"}],
      "8883/tcp": [{"HostPort": "8883"}],
      "443/tcp": [{"HostPort": "443"}]
    }
  }
}
'@
                            }
                        }
                    }
                    modules = @{
                        deviceSimulator = @{
                            type = "docker"
                            status = "running"
                            restartPolicy = "always"
                            settings = @{
                                image = "smartfactory/device-simulator:edge"
                                createOptions = @'
{
  "HostConfig": {
    "PortBindings": {
      "3000/tcp": [{"HostPort": "8080"}]
    }
  },
  "Env": [
    "PRODUCTION_LINES=3",
    "EDGE_MODE=true",
    "FACTORY_ID=EDGE-FACTORY-001"
  ]
}
'@
                            }
                        }
                        postgresEdge = @{
                            type = "docker"
                            status = "running"
                            restartPolicy = "always"
                            settings = @{
                                image = "postgres:13"
                                createOptions = @'
{
  "HostConfig": {
    "PortBindings": {
      "5432/tcp": [{"HostPort": "5432"}]
    }
  },
  "Env": [
    "POSTGRES_DB=factory_edge",
    "POSTGRES_USER=postgres",
    "POSTGRES_PASSWORD=factory123"
  ]
}
'@
                            }
                        }
                        grafanaEdge = @{
                            type = "docker"
                            status = "running"
                            restartPolicy = "always"
                            settings = @{
                                image = "grafana/grafana:latest"
                                createOptions = @'
{
  "HostConfig": {
    "PortBindings": {
      "3000/tcp": [{"HostPort": "3000"}]
    }
  },
  "Env": [
    "GF_SECURITY_ADMIN_PASSWORD=factory123"
  ]
}
'@
                            }
                        }
                    }
                }
            }
            '$edgeHub' = @{
                'properties.desired' = @{
                    schemaVersion = "1.2"
                    routes = @{
                        telemetryToCloud = "FROM /messages/modules/deviceSimulator/outputs/* INTO `$upstream"
                        postgresLocal = "FROM /messages/modules/deviceSimulator/outputs/* INTO BrokeredEndpoint(`"/modules/postgresEdge/inputs/telemetry`")"
                    }
                    storeAndForwardConfiguration = @{
                        timeToLiveSecs = 7200
                    }
                }
            }
        }
    }
} | ConvertTo-Json -Depth 10

$manifestFile = "edge-deployment-manifest.json"
$deploymentManifest | Out-File -FilePath $manifestFile -Encoding UTF8
Write-Host "📦 Deployment manifest creado: $manifestFile" -ForegroundColor Cyan

# PASO 7: Aplicar deployment
Write-Host "`n🚀 PASO 7: Aplicar Deployment" -ForegroundColor Yellow
Write-Host "==============================" -ForegroundColor Yellow

Write-Host "📋 Para aplicar el deployment manifest:"
Write-Host "az iot edge set-modules --device-id $EdgeDeviceName --hub-name $IoTHubName --content $manifestFile" -ForegroundColor Gray

$applyNow = Read-Host "`n¿Aplicar deployment ahora? (y/n)"
if ($applyNow -eq 'y') {
    Write-Host "🚀 Aplicando deployment..."
    az iot edge set-modules --device-id $EdgeDeviceName --hub-name $IoTHubName --content $manifestFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Deployment aplicado exitosamente" -ForegroundColor Green
    } else {
        Write-Host "❌ Error aplicando deployment" -ForegroundColor Red
    }
}

# PASO 8: Verificación y monitoreo
Write-Host "`n📊 PASO 8: Verificación y Monitoreo" -ForegroundColor Yellow
Write-Host "===================================" -ForegroundColor Yellow

Write-Host "📋 Comandos de verificación:"
Write-Host "1. Estado del device: az iot hub device-identity show --device-id $EdgeDeviceName --hub-name $IoTHubName" -ForegroundColor Gray
Write-Host "2. Monitoreo de mensajes: az iot hub monitor-events --hub-name $IoTHubName --device-id $EdgeDeviceName" -ForegroundColor Gray
Write-Host "3. Estado de módulos: sudo iotedge list (en la VM edge)" -ForegroundColor Gray

Write-Host "`n✅ CONFIGURACIÓN COMPLETADA" -ForegroundColor Green
Write-Host "===========================" -ForegroundColor Green
Write-Host "🔧 Edge Device: $EdgeDeviceName registrado"
Write-Host "📡 IoT Hub: $IoTHubName conectado"
Write-Host "📦 Deployment manifest: Listo para aplicar"
Write-Host "🖥️ VM Commands: Guardados en $commandsFile"
Write-Host "`n🎯 Siguiente paso: Ejecutar comandos en la Azure VM Edge"