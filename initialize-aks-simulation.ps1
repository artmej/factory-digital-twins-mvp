# AKS HCI Simulation Script (para VM normal de Azure)
# Usa minikube para simular un cluster local

param(
    [string]$WorkingDir = "C:\AzureLocal\AksHci",
    [string]$ClusterName = "aks-smart-factory-local"
)

Write-Host "Inicializando simulacion de AKS Local..." -ForegroundColor Green

# Set working directory
Set-Location $WorkingDir

# Verificar si Docker Desktop está disponible
$dockerRunning = $false
try {
    docker version | Out-Null
    $dockerRunning = $true
    Write-Host "Docker Desktop detectado" -ForegroundColor Green
} catch {
    Write-Host "Docker Desktop no disponible" -ForegroundColor Yellow
}

# Opción 1: Usar minikube si Docker está disponible
if ($dockerRunning) {
    Write-Host "Configurando cluster con minikube..." -ForegroundColor Cyan
    
    # Verificar si minikube está instalado
    $minikubeExists = $false
    try {
        minikube version | Out-Null
        $minikubeExists = $true
    } catch {
        Write-Host "Instalando minikube..." -ForegroundColor Yellow
        
        # Descargar e instalar minikube
        $minikubeUrl = "https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe"
        $minikubePath = "$env:USERPROFILE\minikube.exe"
        
        try {
            Invoke-WebRequest -Uri $minikubeUrl -OutFile $minikubePath
            Move-Item $minikubePath "C:\Windows\System32\minikube.exe" -Force
            Write-Host "Minikube instalado" -ForegroundColor Green
            $minikubeExists = $true
        } catch {
            Write-Host "Error descargando minikube: $_" -ForegroundColor Red
        }
    }
    
    if ($minikubeExists) {
        try {
            Write-Host "Iniciando cluster minikube..." -ForegroundColor Cyan
            minikube start --cpus=2 --memory=4096 --driver=docker
            
            Write-Host "Configurando kubectl para minikube..." -ForegroundColor Cyan
            kubectl config use-context minikube
            
            Write-Host "Cluster local creado exitosamente" -ForegroundColor Green
            kubectl cluster-info
            
            # Crear archivo de configuración simulada
            $config = @{
                provider = "minikube"
                clusterName = $ClusterName
                status = "running"
                nodes = 1
                kubernetesVersion = (kubectl version --client -o yaml | Select-String "gitVersion").Line
            }
            
            $config | ConvertTo-Json | Out-File -FilePath "$WorkingDir\cluster-config.json" -Encoding UTF8
            
        } catch {
            Write-Host "Error iniciando minikube: $_" -ForegroundColor Red
            exit 1
        }
    }
}

# Opción 2: Simulación básica sin cluster real
if (-not $dockerRunning -or -not $minikubeExists) {
    Write-Host ""
    Write-Host "SIMULACION DE AZURE LOCAL (sin cluster real)" -ForegroundColor Yellow
    Write-Host "=============================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Azure Stack HCI no disponible en VM regular." -ForegroundColor Cyan
    Write-Host "Creando configuracion simulada..." -ForegroundColor Cyan
    
    # Crear archivos de configuración simulada
    $simulatedConfig = @{
        provider = "simulated"
        clusterName = $ClusterName
        status = "simulated"
        message = "Cluster simulado - para demo purposes"
        nodes = 2
        kubernetesVersion = "v1.28.5"
        services = @{
            scada = "http://localhost:30080"
            factory = "http://localhost:30081"
            robots = "http://localhost:30082"
            influxdb = "http://localhost:30083"
            redis = "localhost:30084"
        }
    }
    
    $simulatedConfig | ConvertTo-Json -Depth 3 | Out-File -FilePath "$WorkingDir\simulated-cluster.json" -Encoding UTF8
    
    # Crear kubectl simulado para demos
    $kubectlSim = @'
# kubectl Simulado para Azure Local Demo
Write-Host "=== CLUSTER SIMULADO - SMART FACTORY ===" -ForegroundColor Green

Write-Host "Namespace: smart-factory" -ForegroundColor Cyan
Write-Host ""

Write-Host "DEPLOYMENTS:" -ForegroundColor Yellow
Write-Host "NAME                READY   UP-TO-DATE   AVAILABLE" -ForegroundColor White
Write-Host "scada-dashboard     1/1     1            1" -ForegroundColor Green
Write-Host "factory-simulator   1/1     1            1" -ForegroundColor Green  
Write-Host "robot-controller    2/2     2            2" -ForegroundColor Green
Write-Host "influxdb            1/1     1            1" -ForegroundColor Green
Write-Host "redis               1/1     1            1" -ForegroundColor Green

Write-Host ""
Write-Host "SERVICES:" -ForegroundColor Yellow
Write-Host "NAME                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)" -ForegroundColor White
Write-Host "scada-dashboard-svc   NodePort    10.96.1.100   <none>        80:30080/TCP" -ForegroundColor Green
Write-Host "factory-simulator-svc NodePort    10.96.1.101   <none>        80:30081/TCP" -ForegroundColor Green
Write-Host "robot-controller-svc  NodePort    10.96.1.102   <none>        80:30082/TCP" -ForegroundColor Green
Write-Host "influxdb-svc          NodePort    10.96.1.103   <none>        8086:30083/TCP" -ForegroundColor Green
Write-Host "redis-svc             NodePort    10.96.1.104   <none>        6379:30084/TCP" -ForegroundColor Green

Write-Host ""
Write-Host "ACCESO A SERVICIOS (Simulado):" -ForegroundColor Cyan
Write-Host "- SCADA Dashboard: http://localhost:30080" -ForegroundColor White
Write-Host "- Factory Simulator: http://localhost:30081" -ForegroundColor White  
Write-Host "- Robot Controller: http://localhost:30082" -ForegroundColor White
Write-Host "- InfluxDB: http://localhost:30083" -ForegroundColor White
Write-Host "- Redis: localhost:30084" -ForegroundColor White

Write-Host ""
Write-Host "NOTA: Cluster simulado para propositos de demo" -ForegroundColor Yellow
Write-Host "Para cluster real, usar Azure Stack HCI" -ForegroundColor Yellow
'@

    $kubectlSim | Out-File -FilePath "$WorkingDir\kubectl-sim.ps1" -Encoding UTF8
    
    Write-Host "Configuracion simulada creada" -ForegroundColor Green
    Write-Host ""
    Write-Host "PARA VER EL 'CLUSTER' SIMULADO:" -ForegroundColor Cyan
    Write-Host ".\kubectl-sim.ps1" -ForegroundColor White
}

Write-Host ""
Write-Host "=== AZURE LOCAL SETUP COMPLETADO ===" -ForegroundColor Green
Write-Host ""
Write-Host "PROXIMOS PASOS:" -ForegroundColor Cyan

if ($dockerRunning -and $minikubeExists) {
    Write-Host "1. Cluster real funcionando con minikube" -ForegroundColor Green
    Write-Host "2. Ejecutar: .\deploy-smart-factory.ps1" -ForegroundColor White
} else {
    Write-Host "1. Cluster simulado creado" -ForegroundColor Yellow
    Write-Host "2. Ver demo: .\kubectl-sim.ps1" -ForegroundColor White
    Write-Host "3. Para cluster real: instalar Docker Desktop + minikube" -ForegroundColor White
}

Write-Host ""
Write-Host "ARQUITECTURA ACTUAL:" -ForegroundColor Cyan
if ($dockerRunning) {
    Write-Host "Azure VM -> Docker -> minikube -> Smart Factory" -ForegroundColor White
} else {
    Write-Host "Azure VM -> Configuracion simulada -> Demo Smart Factory" -ForegroundColor White
}

Write-Host ""
Write-Host "Azure Local simulation listo!" -ForegroundColor Green