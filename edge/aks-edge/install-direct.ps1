# Script de instalación directa para ejecutar en la VM Arc
# Ejecutar como Administrador en la VM 130.131.248.173

Write-Host "🏭 Smart Factory - AKS Edge Essentials Installation" -ForegroundColor Cyan
Write-Host "VM Arc: $env:COMPUTERNAME" -ForegroundColor Yellow

# Verificar que se ejecuta como administrador
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $IsAdmin) {
    Write-Error "⚠️  Este script debe ejecutarse como Administrador"
    Write-Host "Click derecho en PowerShell > Ejecutar como administrador" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ Ejecutándose como Administrador" -ForegroundColor Green

# Crear directorio de trabajo
$WorkDir = "C:\SmartFactory\aks-edge"
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
Set-Location $WorkDir

Write-Host "📁 Directorio de trabajo: $WorkDir" -ForegroundColor Yellow

# Paso 1: Habilitar características de Windows
Write-Host "📋 Habilitando características de Windows..." -ForegroundColor Yellow
try {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart
    Write-Host "✅ Características habilitadas" -ForegroundColor Green
} catch {
    Write-Warning "Error habilitando características: $_"
}

# Paso 2: Descargar AKS Edge Essentials
Write-Host "📦 Descargando AKS Edge Essentials..." -ForegroundColor Yellow
$AksEdgeUrl = "https://aka.ms/aks-edge/k3s-msi"
$Installer = "$WorkDir\AksEdgeEssentials.msi"

try {
    Invoke-WebRequest -Uri $AksEdgeUrl -OutFile $Installer -UseBasicParsing
    Write-Host "✅ Descarga completada: $(Get-Item $Installer | Select-Object -ExpandProperty Length) bytes" -ForegroundColor Green
} catch {
    Write-Error "❌ Error descargando AKS Edge: $_"
    Read-Host "Press Enter to exit"
    exit 1
}

# Paso 3: Instalar AKS Edge Essentials
Write-Host "🔧 Instalando AKS Edge Essentials..." -ForegroundColor Yellow
Write-Host "Esto puede tomar varios minutos..." -ForegroundColor Cyan

try {
    $Process = Start-Process msiexec.exe -ArgumentList "/i `"$Installer`" /quiet /norestart" -Wait -PassThru
    if ($Process.ExitCode -eq 0) {
        Write-Host "✅ AKS Edge Essentials instalado correctamente" -ForegroundColor Green
    } else {
        throw "MSI installer failed with exit code: $($Process.ExitCode)"
    }
} catch {
    Write-Error "❌ Error instalando AKS Edge: $_"
    Read-Host "Press Enter to exit"
    exit 1
}

# Paso 4: Verificar instalación
Write-Host "🔍 Verificando instalación..." -ForegroundColor Yellow
try {
    # Recargar PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine")
    
    # Verificar módulo AksEdge
    if (Get-Module -ListAvailable -Name AksEdge) {
        Write-Host "✅ Módulo AksEdge disponible" -ForegroundColor Green
        Import-Module AksEdge -Force
        Write-Host "✅ Módulo AksEdge importado" -ForegroundColor Green
    } else {
        Write-Warning "⚠️  Módulo AksEdge no encontrado, puede requerir reinicio"
    }
} catch {
    Write-Warning "Error verificando módulo: $_"
}

# Paso 5: Configurar cluster
Write-Host "⚙️  Configurando cluster AKS Edge..." -ForegroundColor Yellow

# Crear configuración del cluster
$ClusterConfig = @{
    SchemaVersion = "1.1"
    Version = "1.0" 
    AksEdgeProduct = "AKS Edge Essentials - K3s"
    AksEdgeConfigFile = "aksedge-config.json"
    Machines = @(
        @{
            LinuxNode = @{
                CpuCount = 4
                MemoryInMB = 6144
                DataSizeInGB = 20
                LogSizeInGB = 4
                TimeoutSeconds = 300
            }
        }
    )
}

$ConfigPath = "$WorkDir\aksedge-config.json"
$ClusterConfig | ConvertTo-Json -Depth 10 | Out-File $ConfigPath
Write-Host "✅ Configuración creada: $ConfigPath" -ForegroundColor Green

# Crear cluster
Write-Host "🏗️  Creando cluster AKS Edge..." -ForegroundColor Yellow
Write-Host "Esto puede tomar 10-15 minutos..." -ForegroundColor Cyan

try {
    New-AksEdgeDeployment -JsonConfigFilePath $ConfigPath
    Write-Host "✅ Cluster AKS Edge creado exitosamente" -ForegroundColor Green
} catch {
    Write-Error "❌ Error creando cluster: $_"
    Write-Host "Posible solución: Reinicie la VM y ejecute la segunda parte" -ForegroundColor Yellow
}

# Paso 6: Configurar kubectl
Write-Host "🔧 Configurando kubectl..." -ForegroundColor Yellow

# Crear directorio kubeconfig
$KubeConfigDir = "$env:USERPROFILE\.kube"
New-Item -ItemType Directory -Force -Path $KubeConfigDir | Out-Null

# Obtener kubeconfig
try {
    Get-AksEdgeKubeConfig -outFile "$KubeConfigDir\config"
    Write-Host "✅ Kubeconfig configurado" -ForegroundColor Green
} catch {
    Write-Warning "Error obteniendo kubeconfig: $_"
}

# Descargar kubectl
$KubectlDir = "C:\SmartFactory\kubectl"
$KubectlPath = "$KubectlDir\kubectl.exe"

if (!(Test-Path $KubectlPath)) {
    Write-Host "📥 Descargando kubectl..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $KubectlDir | Out-Null
    
    $KubectlUrl = "https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe"
    try {
        Invoke-WebRequest -Uri $KubectlUrl -OutFile $KubectlPath
        Write-Host "✅ kubectl descargado" -ForegroundColor Green
        
        # Agregar a PATH
        $CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($CurrentPath -notlike "*$KubectlDir*") {
            [Environment]::SetEnvironmentVariable("PATH", "$CurrentPath;$KubectlDir", "Machine")
            $env:PATH += ";$KubectlDir"
            Write-Host "✅ kubectl agregado al PATH" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Error descargando kubectl: $_"
    }
}

# Verificar cluster
Write-Host "✅ Verificando cluster..." -ForegroundColor Yellow
try {
    & $KubectlPath version --client --short
    & $KubectlPath get nodes
    Write-Host "✅ Cluster verificado" -ForegroundColor Green
} catch {
    Write-Warning "Error verificando cluster: $_"
}

Write-Host "🎉 Instalación completada!" -ForegroundColor Green
Write-Host "📋 Próximos pasos:" -ForegroundColor Cyan
Write-Host "1. Si hubo errores, reinicie la VM" -ForegroundColor White
Write-Host "2. Ejecute: kubectl get nodes" -ForegroundColor White  
Write-Host "3. Para desplegar servicios: ejecute el script de deploy" -ForegroundColor White

Write-Host "🌐 Acceso URLs (después del deploy):" -ForegroundColor Cyan
Write-Host "Grafana: http://130.131.248.173:30000" -ForegroundColor White
Write-Host "Factory API: http://130.131.248.173:30003" -ForegroundColor White

Read-Host "Presione Enter para finalizar"