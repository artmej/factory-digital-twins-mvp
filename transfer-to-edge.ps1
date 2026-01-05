# 📦 Transferir archivos Edge a VM remota
# Script para copiar archivos de configuración y simulador a la VM Edge

param(
    [string]$EdgeVM_IP = "48.221.123.45",
    [string]$EdgeVM_User = "azureuser",
    [string]$SSHKey = "C:\Users\artmej\.ssh\cus-vm-arc-factory-1_key.pem"
)

Write-Host "📦 TRANSFERIR ARCHIVOS A VM EDGE" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "🎯 VM Edge: $EdgeVM_User@$EdgeVM_IP"
Write-Host "🔑 SSH Key: $SSHKey"

# Verificar conectividad SSH
Write-Host "`n🔍 Verificando conectividad SSH..." -ForegroundColor Yellow
try {
    $sshTest = ssh -i "$SSHKey" -o ConnectTimeout=10 -o BatchMode=yes $EdgeVM_User@$EdgeVM_IP "echo 'SSH_OK'"
    if ($sshTest -eq "SSH_OK") {
        Write-Host "✅ Conexión SSH exitosa" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Conexión SSH con advertencias" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error de conexión SSH: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Crear directorio remoto para la factory
Write-Host "`n📁 Creando directorios en VM Edge..." -ForegroundColor Yellow
ssh -i "$SSHKey" $EdgeVM_User@$EdgeVM_IP "mkdir -p /home/azureuser/smart-factory-edge"

# Transferir archivos de configuración
Write-Host "`n📋 Transferir configuración IoT Edge..." -ForegroundColor Yellow

$files = @(
    "setup-iot-edge-connection.ps1",
    "iot-edge-config.toml", 
    "edge-deployment-manifest.json",
    "edge-vm-commands.sh"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  📄 Copiando $file..."
        scp -i "$SSHKey" $file ${EdgeVM_User}@${EdgeVM_IP}:/home/azureuser/smart-factory-edge/
    } else {
        Write-Host "  ⚠️ Archivo no encontrado: $file" -ForegroundColor Yellow
    }
}

# Transferir simulador completo
Write-Host "`n🏭 Transferir simulador IoT..." -ForegroundColor Yellow
if (Test-Path "src\device-simulator") {
    Write-Host "  📦 Copiando device-simulator completo..."
    scp -i "$SSHKey" -r src\device-simulator ${EdgeVM_User}@${EdgeVM_IP}:/home/azureuser/smart-factory-edge/
} else {
    Write-Host "  ⚠️ Directorio device-simulator no encontrado" -ForegroundColor Yellow
}

Write-Host "`n✅ TRANSFERENCIA COMPLETADA" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

# Mostrar próximos pasos
Write-Host "`n📋 PRÓXIMOS PASOS:" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host "1. Conectar a la VM Edge:"
Write-Host "   ssh -i `"$SSHKey`" $EdgeVM_User@$EdgeVM_IP" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Navegar al directorio:"
Write-Host "   cd smart-factory-edge" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Verificar archivos:"
Write-Host "   ls -la" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Ejecutar setup IoT Edge:"
Write-Host "   sudo chmod +x edge-vm-commands.sh" -ForegroundColor Gray
Write-Host "   sudo ./edge-vm-commands.sh" -ForegroundColor Gray