# Configuración y despliegue del cluster AKS Edge después del reinicio
# Ejecutar después de la instalación base y reinicio

param(
    [string]$VMHost = "130.131.248.173",
    [string]$VMUser = "azureuser",
    [string]$VMPassword = "SmartFactory2025!"
)

Write-Host "🚀 Configurando cluster AKS Edge..." -ForegroundColor Cyan

$SecurePassword = ConvertTo-SecureString $VMPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($VMUser, $SecurePassword)

try {
    # Crear nueva sesión después del reinicio
    Write-Host "🔗 Reconectando a VM Arc..." -ForegroundColor Yellow
    Start-Sleep 30  # Esperar que la VM termine de iniciar
    
    $Session = New-PSSession -ComputerName $VMHost -Credential $Credential
    Write-Host "✅ Reconectado a VM Arc" -ForegroundColor Green
    
    # Configurar cluster AKS Edge
    $ClusterScript = {
        Write-Host "⚙️ Configurando cluster Kubernetes..." -ForegroundColor Yellow
        
        Set-Location "C:\SmartFactory\aks-edge"
        
        # Importar módulo AksEdge
        Import-Module AksEdge
        
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
                        MemoryInMB = 8192
                        DataSizeInGB = 20
                        LogSizeInGB = 8
                        TimeoutSeconds = 300
                        TpmPassthrough = $false
                        SecureBoot = $false
                    }
                }
            )
        }
        
        $ConfigPath = "C:\SmartFactory\aks-edge\aksedge-config.json"
        $ClusterConfig | ConvertTo-Json -Depth 10 | Out-File $ConfigPath
        
        # Crear cluster AKS Edge
        Write-Host "🏗️ Desplegando cluster AKS Edge..." -ForegroundColor Yellow
        try {
            New-AksEdgeDeployment -JsonConfigFilePath $ConfigPath
            Write-Host "✅ Cluster AKS Edge desplegado" -ForegroundColor Green
        } catch {
            Write-Error "Error desplegando cluster: $_"
            return
        }
        
        # Obtener kubeconfig
        Write-Host "🔧 Configurando kubectl..." -ForegroundColor Yellow
        $KubeConfigDir = "$env:USERPROFILE\.kube"
        if (!(Test-Path $KubeConfigDir)) {
            New-Item -ItemType Directory -Force -Path $KubeConfigDir | Out-Null
        }
        
        Get-AksEdgeKubeConfig -outFile "$KubeConfigDir\config"
        
        # Descargar kubectl si no existe
        $KubectlPath = "C:\SmartFactory\kubectl\kubectl.exe"
        if (!(Test-Path $KubectlPath)) {
            Write-Host "📥 Descargando kubectl..." -ForegroundColor Yellow
            New-Item -ItemType Directory -Force -Path (Split-Path $KubectlPath) | Out-Null
            $KubectlUrl = "https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe"
            Invoke-WebRequest -Uri $KubectlUrl -OutFile $KubectlPath
            
            # Agregar a PATH
            $CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
            $KubectlDir = Split-Path $KubectlPath
            if ($CurrentPath -notlike "*$KubectlDir*") {
                [Environment]::SetEnvironmentVariable("PATH", "$CurrentPath;$KubectlDir", "Machine")
                $env:PATH += ";$KubectlDir"
            }
        }
        
        # Verificar cluster
        Write-Host "✅ Verificando cluster..." -ForegroundColor Yellow
        Start-Sleep 30
        
        & $KubectlPath get nodes
        & $KubectlPath get pods -A
        
        Write-Host "🎉 Cluster AKS Edge listo!" -ForegroundColor Green
        Write-Host "Ejecutar .\deploy-data-services.ps1 para desplegar servicios" -ForegroundColor Cyan
    }
    
    # Ejecutar configuración en VM remota
    Invoke-Command -Session $Session -ScriptBlock $ClusterScript
    
    # Transferir manifests a la VM
    Write-Host "📤 Transfiriendo manifests de Kubernetes..." -ForegroundColor Yellow
    
    $ManifestsScript = {
        # Crear directorio para manifests
        New-Item -ItemType Directory -Force -Path "C:\SmartFactory\aks-edge\manifests" | Out-Null
        Write-Host "Directorio de manifests creado"
    }
    
    Invoke-Command -Session $Session -ScriptBlock $ManifestsScript
    
    Remove-PSSession -Session $Session
    
    Write-Host "✅ Configuración del cluster completada" -ForegroundColor Green
    Write-Host "Ahora ejecuta: .\deploy-services.ps1" -ForegroundColor Cyan

} catch {
    Write-Error "Error configurando cluster: $_"
    Write-Host "Manual deployment required via RDP" -ForegroundColor Red
}