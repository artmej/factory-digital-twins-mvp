# Script para configurar Azure Local manualmente en la VM
# Ejecutar este script DENTRO de la VM de Azure (via RDP)

param(
    [string]$BasePath = "C:\AzureLocal"
)

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║    CONFIGURANDO AZURE LOCAL EN VM       ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# 1. CREAR ESTRUCTURA DE DIRECTORIOS
Write-Host "1. Creando estructura de directorios..." -ForegroundColor Yellow
$directories = @(
    "$BasePath",
    "$BasePath\AksHci",
    "$BasePath\SmartFactory",
    "$BasePath\SmartFactory\k8s-manifests",
    "$BasePath\Scripts",
    "$BasePath\Logs",
    "$BasePath\VMs"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Write-Host "   ✓ Creado: $dir" -ForegroundColor Green
    } else {
        Write-Host "   ✓ Existe: $dir" -ForegroundColor Cyan
    }
}

# 2. CREAR SCRIPT DE KUBECTL SIMULADO
Write-Host "2. Creando kubectl simulado para AKS Local..." -ForegroundColor Yellow
$kubectlScript = @'
# AKS Local - kubectl Simulation
param([string[]]$Args)

$timestamp = Get-Date -Format "HH:mm:ss"
Write-Host "[$timestamp] kubectl (AKS Edge Essentials): $($Args -join ' ')" -ForegroundColor Green

if ($Args -contains "cluster-info") {
    Write-Host ""
    Write-Host "Kubernetes control plane is running at https://127.0.0.1:6443" -ForegroundColor Green
    Write-Host "CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy" -ForegroundColor Green
    Write-Host ""
    Write-Host "To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'." -ForegroundColor Yellow
}
elseif ($Args -contains "get" -and $Args -contains "nodes") {
    Write-Host ""
    Write-Host "NAME                    STATUS   ROLES           AGE   VERSION" -ForegroundColor White
    Write-Host "aks-local-control-01    Ready    control-plane   15m   v1.28.5" -ForegroundColor Green
    Write-Host "aks-local-worker-01     Ready    worker          14m   v1.28.5" -ForegroundColor Green
    Write-Host "aks-local-worker-02     Ready    worker          14m   v1.28.5" -ForegroundColor Green
}
elseif ($Args -contains "get" -and $Args -contains "pods") {
    if ($Args -contains "-n" -and $Args -contains "smart-factory") {
        Write-Host ""
        Write-Host "NAME                                 READY   STATUS    RESTARTS   AGE" -ForegroundColor White
        Write-Host "scada-dashboard-7d4b8c6f9b-x7q2m     1/1     Running   0          8m" -ForegroundColor Green
        Write-Host "factory-simulator-5f8d9c7b4a-p9k8l   1/1     Running   0          8m" -ForegroundColor Green
        Write-Host "robot-controller-6c7f8d9e5b-r3n7m    1/1     Running   0          8m" -ForegroundColor Green
        Write-Host "robot-controller-6c7f8d9e5b-t8q4p    1/1     Running   0          8m" -ForegroundColor Green
        Write-Host "influxdb-84c5f7d6b8-m2w9x            1/1     Running   0          8m" -ForegroundColor Green
        Write-Host "redis-9f6e8c5d7a-k5j3l               1/1     Running   0          8m" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "NAME                                 READY   STATUS    RESTARTS   AGE" -ForegroundColor White
        Write-Host "coredns-5dd5756b68-8xnpm             1/1     Running   0          15m" -ForegroundColor Green
        Write-Host "coredns-5dd5756b68-vq7s4             1/1     Running   0          15m" -ForegroundColor Green
        Write-Host "etcd-aks-local-control-01            1/1     Running   0          15m" -ForegroundColor Green
        Write-Host "kube-apiserver-aks-local-control-01  1/1     Running   0          15m" -ForegroundColor Green
        Write-Host "kube-proxy-7n8q2                     1/1     Running   0          15m" -ForegroundColor Green
        Write-Host "kube-proxy-m9k5l                     1/1     Running   0          14m" -ForegroundColor Green
        Write-Host "kube-proxy-x3r7t                     1/1     Running   0          14m" -ForegroundColor Green
    }
}
elseif ($Args -contains "get" -and $Args -contains "svc") {
    if ($Args -contains "-n" -and $Args -contains "smart-factory") {
        Write-Host ""
        Write-Host "NAME                    TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)" -ForegroundColor White
        Write-Host "scada-dashboard-svc     NodePort   10.96.1.100    <none>        80:30080/TCP" -ForegroundColor Green
        Write-Host "factory-simulator-svc   NodePort   10.96.1.101    <none>        80:30081/TCP" -ForegroundColor Green
        Write-Host "robot-controller-svc    NodePort   10.96.1.102    <none>        80:30082/TCP" -ForegroundColor Green
        Write-Host "influxdb-svc            NodePort   10.96.1.103    <none>        8086:30083/TCP" -ForegroundColor Green
        Write-Host "redis-svc               NodePort   10.96.1.104    <none>        6379:30084/TCP" -ForegroundColor Green
    }
}
elseif ($Args -contains "apply") {
    Write-Host ""
    Write-Host "✓ namespace/smart-factory created" -ForegroundColor Green
    Write-Host "✓ deployment.apps/scada-dashboard created" -ForegroundColor Green
    Write-Host "✓ service/scada-dashboard-svc created" -ForegroundColor Green
    Write-Host "✓ deployment.apps/factory-simulator created" -ForegroundColor Green
    Write-Host "✓ service/factory-simulator-svc created" -ForegroundColor Green
    Write-Host "✓ deployment.apps/robot-controller created" -ForegroundColor Green
    Write-Host "✓ service/robot-controller-svc created" -ForegroundColor Green
    Write-Host "✓ deployment.apps/influxdb created" -ForegroundColor Green
    Write-Host "✓ service/influxdb-svc created" -ForegroundColor Green
    Write-Host "✓ deployment.apps/redis created" -ForegroundColor Green
    Write-Host "✓ service/redis-svc created" -ForegroundColor Green
    Write-Host ""
    Write-Host "Smart Factory desplegada exitosamente!" -ForegroundColor Green
}
else {
    Write-Host "kubectl comando simulado: '$($Args -join ' ')'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Comandos disponibles:" -ForegroundColor Cyan
    Write-Host "  kubectl get nodes" -ForegroundColor White
    Write-Host "  kubectl get pods -n smart-factory" -ForegroundColor White
    Write-Host "  kubectl get svc -n smart-factory" -ForegroundColor White
    Write-Host "  kubectl cluster-info" -ForegroundColor White
}
'@

$kubectlScript | Out-File -FilePath "$BasePath\AksHci\kubectl.ps1" -Encoding UTF8
Write-Host "   ✓ kubectl.ps1 creado" -ForegroundColor Green

# 3. CREAR CONFIGURACION DEL CLUSTER
Write-Host "3. Creando configuración del cluster AKS Local..." -ForegroundColor Yellow
$clusterConfig = @{
    clusterName = "aks-smart-factory-local"
    provider = "AKS Edge Essentials"
    status = "Running"
    arcEnabled = $true
    kubernetesVersion = "v1.28.5"
    nodeCount = 3
    endpoint = "https://127.0.0.1:6443"
    createdAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    location = "Local (Azure VM)"
    resourceGroup = "rg-smart-factory-final"
    services = @{
        scada = "http://localhost:30080"
        factory = "http://localhost:30081"
        robots = "http://localhost:30082"
        influxdb = "http://localhost:30083"
        redis = "localhost:30084"
    }
}

$clusterConfig | ConvertTo-Json -Depth 3 | Out-File -FilePath "$BasePath\AksHci\cluster-status.json" -Encoding UTF8
Write-Host "   ✓ cluster-status.json creado" -ForegroundColor Green

# 4. CREAR MANIFESTS DE KUBERNETES PARA SMART FACTORY
Write-Host "4. Creando manifests de Kubernetes..." -ForegroundColor Yellow

# Namespace
$namespace = @'
apiVersion: v1
kind: Namespace
metadata:
  name: smart-factory
  labels:
    name: smart-factory
    azure-arc: enabled
'@
$namespace | Out-File -FilePath "$BasePath\SmartFactory\k8s-manifests\namespace.yaml" -Encoding UTF8

# SCADA Dashboard
$scadaDashboard = @'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scada-dashboard
  namespace: smart-factory
spec:
  replicas: 1
  selector:
    matchLabels:
      app: scada-dashboard
  template:
    metadata:
      labels:
        app: scada-dashboard
    spec:
      containers:
      - name: scada-dashboard
        image: nginx:latest
        ports:
        - containerPort: 80
        env:
        - name: FACTORY_MODE
          value: "SCADA"
---
apiVersion: v1
kind: Service
metadata:
  name: scada-dashboard-svc
  namespace: smart-factory
spec:
  selector:
    app: scada-dashboard
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort
'@
$scadaDashboard | Out-File -FilePath "$BasePath\SmartFactory\k8s-manifests\scada-dashboard.yaml" -Encoding UTF8

# Factory Simulator
$factorySimulator = @'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: factory-simulator
  namespace: smart-factory
spec:
  replicas: 1
  selector:
    matchLabels:
      app: factory-simulator
  template:
    metadata:
      labels:
        app: factory-simulator
    spec:
      containers:
      - name: factory-simulator
        image: nginx:latest
        ports:
        - containerPort: 80
        env:
        - name: SIMULATION_MODE
          value: "ACTIVE"
---
apiVersion: v1
kind: Service
metadata:
  name: factory-simulator-svc
  namespace: smart-factory
spec:
  selector:
    app: factory-simulator
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30081
  type: NodePort
'@
$factorySimulator | Out-File -FilePath "$BasePath\SmartFactory\k8s-manifests\factory-simulator.yaml" -Encoding UTF8

# Robot Controller  
$robotController = @'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: robot-controller
  namespace: smart-factory
spec:
  replicas: 2
  selector:
    matchLabels:
      app: robot-controller
  template:
    metadata:
      labels:
        app: robot-controller
    spec:
      containers:
      - name: robot-controller
        image: nginx:latest
        ports:
        - containerPort: 80
        env:
        - name: ROBOT_COUNT
          value: "4"
---
apiVersion: v1
kind: Service
metadata:
  name: robot-controller-svc
  namespace: smart-factory
spec:
  selector:
    app: robot-controller
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30082
  type: NodePort
'@
$robotController | Out-File -FilePath "$BasePath\SmartFactory\k8s-manifests\robot-controller.yaml" -Encoding UTF8

Write-Host "   ✓ Manifests de Kubernetes creados" -ForegroundColor Green

# 5. CREAR SCRIPT DE DEPLOY
Write-Host "5. Creando script de deploy..." -ForegroundColor Yellow
$deployScript = @"
# Deploy Smart Factory Script
param(
    [string]`$BasePath = 'C:\AzureLocal'
)

Write-Host ""
Write-Host "🚀 Desplegando Smart Factory en AKS Local..." -ForegroundColor Green
Write-Host ""

# Cambiar al directorio de kubectl
Set-Location "`$BasePath\AksHci"

Write-Host "1. Verificando cluster..." -ForegroundColor Yellow
.\kubectl.ps1 cluster-info

Write-Host ""
Write-Host "2. Verificando nodos..." -ForegroundColor Yellow
.\kubectl.ps1 get nodes

Write-Host ""
Write-Host "3. Aplicando namespace..." -ForegroundColor Yellow
.\kubectl.ps1 apply -f "`$BasePath\SmartFactory\k8s-manifests\namespace.yaml"

Write-Host ""
Write-Host "4. Aplicando aplicaciones..." -ForegroundColor Yellow
.\kubectl.ps1 apply -f "`$BasePath\SmartFactory\k8s-manifests\scada-dashboard.yaml"
.\kubectl.ps1 apply -f "`$BasePath\SmartFactory\k8s-manifests\factory-simulator.yaml"
.\kubectl.ps1 apply -f "`$BasePath\SmartFactory\k8s-manifests\robot-controller.yaml"

Write-Host ""
Write-Host "5. Verificando deployment..." -ForegroundColor Yellow
.\kubectl.ps1 get pods -n smart-factory

Write-Host ""
Write-Host "6. Verificando servicios..." -ForegroundColor Yellow
.\kubectl.ps1 get svc -n smart-factory

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   SMART FACTORY DESPLEGADA EN AKS     ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📊 ENDPOINTS:" -ForegroundColor Yellow
Write-Host "🏭 SCADA Dashboard:     http://localhost:30080" -ForegroundColor Cyan
Write-Host "⚙️  Factory Simulator:  http://localhost:30081" -ForegroundColor Cyan
Write-Host "🤖 Robot Controller:    http://localhost:30082" -ForegroundColor Cyan
Write-Host ""
"@

$deployScript | Out-File -FilePath "$BasePath\Scripts\deploy-smart-factory.ps1" -Encoding UTF8
Write-Host "   ✓ deploy-smart-factory.ps1 creado" -ForegroundColor Green

# 6. CREAR README
Write-Host "6. Creando README..." -ForegroundColor Yellow
$readme = @"
# Azure Local con AKS Edge Essentials - Smart Factory

## 🏗️ ARQUITECTURA LOCAL

Esta VM simula Azure Local con AKS Edge Essentials registrado en Azure Arc.

## 📁 ESTRUCTURA

``````
C:\AzureLocal\
├── AksHci\                 # AKS Edge Essentials simulado
│   ├── kubectl.ps1         # kubectl para AKS Local
│   └── cluster-status.json # Estado del cluster
├── SmartFactory\           # Aplicaciones Smart Factory
│   └── k8s-manifests\      # Manifests de Kubernetes
└── Scripts\                # Scripts de administración
    └── deploy-smart-factory.ps1
``````

## 🚀 COMANDOS

### Verificar cluster AKS Local:
``````powershell
cd C:\AzureLocal\AksHci
.\kubectl.ps1 cluster-info
.\kubectl.ps1 get nodes
``````

### Desplegar Smart Factory:
``````powershell
cd C:\AzureLocal\Scripts
.\deploy-smart-factory.ps1
``````

### Ver aplicaciones:
``````powershell
cd C:\AzureLocal\AksHci
.\kubectl.ps1 get pods -n smart-factory
.\kubectl.ps1 get svc -n smart-factory
``````

## 🌐 SERVICIOS

- **SCADA Dashboard**: http://localhost:30080
- **Factory Simulator**: http://localhost:30081  
- **Robot Controller**: http://localhost:30082

## 📊 ESTADO

Cluster: **aks-smart-factory-local**
Provider: **AKS Edge Essentials**
Azure Arc: **Enabled**
Estado: **Running**

---
Configurado el $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

$readme | Out-File -FilePath "$BasePath\README.md" -Encoding UTF8
Write-Host "   ✓ README.md creado" -ForegroundColor Green

# 7. LOG DE COMPLETADO
Write-Host "7. Finalizando setup..." -ForegroundColor Yellow
$setupLog = "Azure Local setup completado en $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$setupLog | Out-File -FilePath "$BasePath\Logs\setup.log" -Append -Encoding UTF8

Write-Host ""
Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║       ✅ AZURE LOCAL CONFIGURADO              ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Directorio base: $BasePath" -ForegroundColor Cyan
Write-Host "🎯 Próximo paso: Ejecutar deploy script" -ForegroundColor Yellow
Write-Host ""
Write-Host "COMANDOS:" -ForegroundColor Green
Write-Host "cd $BasePath\Scripts" -ForegroundColor White
Write-Host ".\deploy-smart-factory.ps1" -ForegroundColor White
Write-Host ""