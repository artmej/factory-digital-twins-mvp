# Azure Local Complete Setup Script
# Ejecutar en el VM para instalar Arc Agent, IoT Edge y AKS Edge

Write-Host "=== AZURE LOCAL SETUP INICIADO ===" -ForegroundColor Green
Write-Host "Fecha: $(Get-Date)" -ForegroundColor Yellow

# Paso 1: Crear directorios
Write-Host "`n--- PASO 1: Creando directorios ---" -ForegroundColor Cyan
if (!(Test-Path "C:\AzureLocal")) {
    New-Item -Path "C:\AzureLocal" -ItemType Directory -Force
    Write-Host "✓ Directorio C:\AzureLocal creado" -ForegroundColor Green
} else {
    Write-Host "✓ Directorio C:\AzureLocal ya existe" -ForegroundColor Yellow
}

# Paso 2: Descargar Arc Agent
Write-Host "`n--- PASO 2: Descargando Azure Arc Agent ---" -ForegroundColor Cyan
$arcAgentPath = "C:\AzureLocal\AzureConnectedMachineAgent.msi"
try {
    if (!(Test-Path $arcAgentPath)) {
        Write-Host "Descargando Arc Agent..."
        Invoke-WebRequest -Uri "https://aka.ms/AzureConnectedMachineAgent" -OutFile $arcAgentPath
        Write-Host "✓ Arc Agent descargado: $(Get-ChildItem $arcAgentPath | Select-Object -ExpandProperty Length) bytes" -ForegroundColor Green
    } else {
        Write-Host "✓ Arc Agent ya existe" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Error descargando Arc Agent: $($_.Exception.Message)" -ForegroundColor Red
}

# Paso 3: Instalar Arc Agent
Write-Host "`n--- PASO 3: Instalando Azure Arc Agent ---" -ForegroundColor Cyan
if (Test-Path $arcAgentPath) {
    try {
        Write-Host "Instalando Arc Agent..."
        $installArgs = @("/i", $arcAgentPath, "/quiet", "/norestart")
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -PassThru
        Write-Host "Código de salida: $($process.ExitCode)"
        
        if ($process.ExitCode -eq 0) {
            Write-Host "✓ Arc Agent instalado correctamente" -ForegroundColor Green
            Start-Sleep 10
            
            # Verificar servicio
            $service = Get-Service -Name "himds" -ErrorAction SilentlyContinue
            if ($service) {
                Write-Host "✓ Servicio himds encontrado: $($service.Status)" -ForegroundColor Green
            } else {
                Write-Host "⚠ Servicio himds no encontrado, pero instalación completada" -ForegroundColor Yellow
            }
        } else {
            Write-Host "✗ Error en instalación Arc Agent. Código: $($process.ExitCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Excepción instalando Arc Agent: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "✗ No se puede instalar - archivo no encontrado" -ForegroundColor Red
}

# Paso 4: Descargar IoT Edge
Write-Host "`n--- PASO 4: Descargando IoT Edge Runtime ---" -ForegroundColor Cyan
try {
    Write-Host "Descargando IoT Edge..."
    Invoke-WebRequest -uri "https://aka.ms/iotedge-win" -outfile "C:\AzureLocal\Microsoft-Azure-IoTEdge.cab"
    Write-Host "✓ IoT Edge descargado" -ForegroundColor Green
} catch {
    Write-Host "✗ Error descargando IoT Edge: $($_.Exception.Message)" -ForegroundColor Red
}

# Paso 5: Estado final
Write-Host "`n--- ESTADO FINAL ---" -ForegroundColor Cyan
Write-Host "Archivos en C:\AzureLocal:"
Get-ChildItem "C:\AzureLocal" -ErrorAction SilentlyContinue | Format-Table Name, Length, LastWriteTime

Write-Host "`nServicios Azure relevantes:"
Get-Service -Name "*arc*", "*himds*", "*iot*" -ErrorAction SilentlyContinue | Format-Table Name, Status

Write-Host "`n=== SETUP COMPLETADO ===" -ForegroundColor Green
Write-Host "Para continuar, ejecutar scripts de configuración específicos." -ForegroundColor Yellow