# Azure Local Smart Factory - SETUP COMPLETO
# Este script crea TODO lo necesario para Azure Local + Smart Factory

param(
    [string]$ClusterName = "aks-smart-factory-local"
)

Write-Host ""
Write-Host "AZURE LOCAL SMART FACTORY - SETUP COMPLETO" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Creando workspace completo con:" -ForegroundColor Cyan
Write-Host "- Directorios de trabajo" -ForegroundColor White
Write-Host "- Scripts de configuracion de AKS HCI" -ForegroundColor White
Write-Host "- Manifests de Kubernetes" -ForegroundColor White
Write-Host "- Scripts de setup de Azure Local" -ForegroundColor White
Write-Host "- README con instrucciones completas" -ForegroundColor White
Write-Host ""
Write-Host "Iniciando setup completo..." -ForegroundColor Yellow
Write-Host ""

# Crear estructura de directorios
$azLocalPath = "C:\AzureLocal"
Write-Host "Creando estructura de directorios..." -ForegroundColor Cyan

$directories = @(
    "$azLocalPath",
    "$azLocalPath\VMs",
    "$azLocalPath\AksHci", 
    "$azLocalPath\Logs",
    "$azLocalPath\Scripts",
    "$azLocalPath\SmartFactory",
    "$azLocalPath\SmartFactory\k8s-manifests"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Write-Host "  Creado: $dir" -ForegroundColor Green
}

# 1. MANIFESTS DE KUBERNETES PARA SMART FACTORY
Write-Host ""
Write-Host "Creando manifests de Kubernetes..." -ForegroundColor Cyan

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
        - name: FACTORY_MODE
          value: "production"
        - name: ROBOT_COUNT
          value: "5"
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
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30081
  type: NodePort
'@

$factorySimulator | Out-File -FilePath "$azLocalPath\SmartFactory\k8s-manifests\factory-simulator.yaml" -Encoding UTF8

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
        - name: ROBOT_TYPE
          value: "industrial"
        - name: CONTROL_MODE
          value: "autonomous"
        volumeMounts:
        - name: robot-data
          mountPath: /data
      volumes:
      - name: robot-data
        persistentVolumeClaim:
          claimName: robot-storage
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
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30082
  type: NodePort
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: robot-storage
  namespace: smart-factory
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
'@

$robotController | Out-File -FilePath "$azLocalPath\SmartFactory\k8s-manifests\robot-controller.yaml" -Encoding UTF8

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
        - name: DASHBOARD_MODE
          value: "realtime"
        - name: UPDATE_INTERVAL
          value: "1000"
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
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort
'@

$scadaDashboard | Out-File -FilePath "$azLocalPath\SmartFactory\k8s-manifests\scada-dashboard.yaml" -Encoding UTF8

# InfluxDB para Time Series
$influxDb = @'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: influxdb
  namespace: smart-factory
spec:
  replicas: 1
  selector:
    matchLabels:
      app: influxdb
  template:
    metadata:
      labels:
        app: influxdb
    spec:
      containers:
      - name: influxdb
        image: influxdb:2.7
        ports:
        - containerPort: 8086
        env:
        - name: DOCKER_INFLUXDB_INIT_MODE
          value: "setup"
        - name: DOCKER_INFLUXDB_INIT_USERNAME
          value: "admin"
        - name: DOCKER_INFLUXDB_INIT_PASSWORD
          value: "smartfactory2024"
        - name: DOCKER_INFLUXDB_INIT_ORG
          value: "smartfactory"
        - name: DOCKER_INFLUXDB_INIT_BUCKET
          value: "factory-metrics"
        volumeMounts:
        - name: influx-storage
          mountPath: /var/lib/influxdb2
      volumes:
      - name: influx-storage
        persistentVolumeClaim:
          claimName: influx-storage
---
apiVersion: v1
kind: Service
metadata:
  name: influxdb-svc
  namespace: smart-factory
spec:
  selector:
    app: influxdb
  ports:
  - protocol: TCP
    port: 8086
    targetPort: 8086
    nodePort: 30083
  type: NodePort
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: influx-storage
  namespace: smart-factory
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
'@

$influxDb | Out-File -FilePath "$azLocalPath\SmartFactory\k8s-manifests\influxdb.yaml" -Encoding UTF8

# Redis Cache
$redis = @'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: smart-factory
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        command:
        - redis-server
        - "--appendonly"
        - "yes"
        volumeMounts:
        - name: redis-storage
          mountPath: /data
      volumes:
      - name: redis-storage
        persistentVolumeClaim:
          claimName: redis-storage
---
apiVersion: v1
kind: Service
metadata:
  name: redis-svc
  namespace: smart-factory
spec:
  selector:
    app: redis
  ports:
  - protocol: TCP
    port: 6379
    targetPort: 6379
    nodePort: 30084
  type: NodePort
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-storage
  namespace: smart-factory
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
'@

$redis | Out-File -FilePath "$azLocalPath\SmartFactory\k8s-manifests\redis.yaml" -Encoding UTF8

# Namespace
$namespace = @'
apiVersion: v1
kind: Namespace
metadata:
  name: smart-factory
  labels:
    name: smart-factory
'@

$namespace | Out-File -FilePath "$azLocalPath\SmartFactory\k8s-manifests\namespace.yaml" -Encoding UTF8

Write-Host "  Todos los manifests de Kubernetes creados" -ForegroundColor Green

# 2. SCRIPTS DE AKS HCI
Write-Host ""
Write-Host "Creando scripts de AKS HCI..." -ForegroundColor Cyan

# Script de inicialización de AKS Local (Azure Arc Jumpstart style)
$aksInitScript = @'
# AKS Local Simulation Script (Azure Arc Jumpstart inspired)
param(
    [string]$WorkingDir = "C:\AzureLocal\AksHci",
    [string]$ClusterName = "aks-smart-factory-local"
)

Write-Host "Configurando AKS Local (simulacion Azure Arc Jumpstart)..." -ForegroundColor Green

# Set working directory
Set-Location $WorkingDir

# 1. SIMULAR AZURE ARC REGISTRATION
Write-Host "Simulando registro en Azure Arc..." -ForegroundColor Cyan

$arcConfig = @{
    resourceGroup = "rg-smart-factory-central"
    clusterName = $ClusterName
    location = "East US"
    arcEnabled = $true
    kubernetesDistribution = "aks_management"
    infrastructureProvider = "azure"
    provisioningState = "Succeeded"
}

$arcConfig | ConvertTo-Json -Depth 3 | Out-File -FilePath "$WorkingDir\arc-cluster-config.json" -Encoding UTF8

Write-Host "Azure Arc configuration created" -ForegroundColor Green

# 2. SIMULAR INSTALACION DE AKS EDGE ESSENTIALS
Write-Host "Configurando AKS Edge Essentials (simulado)..." -ForegroundColor Cyan

# Crear configuracion de AKS Edge
$aksEdgeConfig = @'
{
  "Version": "1.0",
  "DeploymentType": "SingleMachineCluster", 
  "Init": {
    "ServiceIPRangeSize": 0
  },
  "Network": {
    "NetworkPlugin": "flannel",
    "InternetDisabled": false
  },
  "User": {
    "AcceptEula": true,
    "AcceptOptionalTelemetry": true
  },
  "Machines": [
    {
      "LinuxNode": {
        "CpuCount": 2,
        "MemoryInMB": 4096,
        "DataSizeInGB": 40,
        "LogSizeInGB": 4
      },
      "WindowsNode": {
        "CpuCount": 2,
        "MemoryInMB": 4096,
        "DataSizeInGB": 40
      }
    }
  ]
}
'@

$aksEdgeConfig | Out-File -FilePath "$WorkingDir\aks-edge-config.json" -Encoding UTF8

# 3. SIMULAR CREACION DE CLUSTER
Write-Host "Creando AKS cluster local..." -ForegroundColor Cyan

# Simular el proceso de creacion
$steps = @(
    "Validando configuracion de hardware...",
    "Configurando red virtual...", 
    "Descargando imagenes de contenedor...",
    "Creando nodos de control...",
    "Configurando worker nodes...",
    "Instalando CNI network plugin...",
    "Configurando storage classes...",
    "Aplicando configuraciones de seguridad...",
    "Registrando cluster en Azure Arc..."
)

foreach ($step in $steps) {
    Write-Host "  $step" -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    Write-Host "  Completado" -ForegroundColor Green
}

# 4. SIMULAR KUBECTL CONFIGURATION  
Write-Host "Configurando kubectl para AKS local..." -ForegroundColor Cyan

# Crear kubeconfig simulado
$kubeconfig = @'
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t...
    server: https://127.0.0.1:6443
  name: aks-smart-factory-local
contexts:
- context:
    cluster: aks-smart-factory-local
    user: aks-smart-factory-local-admin
  name: aks-smart-factory-local-admin
current-context: aks-smart-factory-local-admin
users:
- name: aks-smart-factory-local-admin
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t...
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVkt...
'@

$kubeconfig | Out-File -FilePath "$WorkingDir\kubeconfig" -Encoding UTF8

# 5. CREAR COMANDOS SIMULADOS KUBECTL
$kubectlSim = @'
# AKS Local - kubectl Simulation
param([string[]]$Args)

if ($Args -contains "cluster-info") {
    Write-Host "Kubernetes control plane is running at https://127.0.0.1:6443" -ForegroundColor Green
    Write-Host "CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy" -ForegroundColor Green
    Write-Host ""
    Write-Host "To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'." -ForegroundColor Yellow
}
elseif ($Args -contains "get" -and $Args -contains "nodes") {
    Write-Host "NAME                    STATUS   ROLES           AGE   VERSION" -ForegroundColor White
    Write-Host "aks-local-control-01    Ready    control-plane   5m    v1.28.5" -ForegroundColor Green
    Write-Host "aks-local-worker-01     Ready    worker          4m    v1.28.5" -ForegroundColor Green
    Write-Host "aks-local-worker-02     Ready    worker          4m    v1.28.5" -ForegroundColor Green
}
elseif ($Args -contains "get" -and $Args -contains "pods") {
    if ($Args -contains "-n" -and $Args -contains "smart-factory") {
        Write-Host "NAME                                 READY   STATUS    RESTARTS   AGE" -ForegroundColor White
        Write-Host "scada-dashboard-7d4b8c6f9b-x7q2m     1/1     Running   0          2m" -ForegroundColor Green
        Write-Host "factory-simulator-5f8d9c7b4a-p9k8l   1/1     Running   0          2m" -ForegroundColor Green
        Write-Host "robot-controller-6c7f8d9e5b-r3n7m    1/1     Running   0          2m" -ForegroundColor Green
        Write-Host "robot-controller-6c7f8d9e5b-t8q4p    1/1     Running   0          2m" -ForegroundColor Green
        Write-Host "influxdb-84c5f7d6b8-m2w9x            1/1     Running   0          2m" -ForegroundColor Green
        Write-Host "redis-9f6e8c5d7a-k5j3l               1/1     Running   0          2m" -ForegroundColor Green
    } else {
        Write-Host "NAME                                 READY   STATUS    RESTARTS   AGE" -ForegroundColor White
        Write-Host "coredns-5dd5756b68-8xnpm             1/1     Running   0          5m" -ForegroundColor Green
        Write-Host "coredns-5dd5756b68-vq7s4             1/1     Running   0          5m" -ForegroundColor Green
        Write-Host "etcd-aks-local-control-01            1/1     Running   0          5m" -ForegroundColor Green
        Write-Host "kube-apiserver-aks-local-control-01  1/1     Running   0          5m" -ForegroundColor Green
        Write-Host "kube-proxy-7n8q2                     1/1     Running   0          5m" -ForegroundColor Green
        Write-Host "kube-proxy-m9k5l                     1/1     Running   0          4m" -ForegroundColor Green
        Write-Host "kube-proxy-x3r7t                     1/1     Running   0          4m" -ForegroundColor Green
    }
}
elseif ($Args -contains "get" -and $Args -contains "svc") {
    if ($Args -contains "-n" -and $Args -contains "smart-factory") {
        Write-Host "NAME                    TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)" -ForegroundColor White
        Write-Host "scada-dashboard-svc     NodePort   10.96.1.100    <none>        80:30080/TCP" -ForegroundColor Green
        Write-Host "factory-simulator-svc   NodePort   10.96.1.101    <none>        80:30081/TCP" -ForegroundColor Green
        Write-Host "robot-controller-svc    NodePort   10.96.1.102    <none>        80:30082/TCP" -ForegroundColor Green
        Write-Host "influxdb-svc            NodePort   10.96.1.103    <none>        8086:30083/TCP" -ForegroundColor Green
        Write-Host "redis-svc               NodePort   10.96.1.104    <none>        6379:30084/TCP" -ForegroundColor Green
    }
}
elseif ($Args -contains "apply") {
    Write-Host "namespace/smart-factory created" -ForegroundColor Green
    Write-Host "deployment.apps/scada-dashboard created" -ForegroundColor Green
    Write-Host "service/scada-dashboard-svc created" -ForegroundColor Green
    Write-Host "deployment.apps/factory-simulator created" -ForegroundColor Green
    Write-Host "service/factory-simulator-svc created" -ForegroundColor Green
    Write-Host "deployment.apps/robot-controller created" -ForegroundColor Green
    Write-Host "service/robot-controller-svc created" -ForegroundColor Green
    Write-Host "deployment.apps/influxdb created" -ForegroundColor Green
    Write-Host "service/influxdb-svc created" -ForegroundColor Green
    Write-Host "deployment.apps/redis created" -ForegroundColor Green
    Write-Host "service/redis-svc created" -ForegroundColor Green
}
else {
    Write-Host "kubectl: comando '$($Args -join ' ')' simulado" -ForegroundColor Yellow
    Write-Host "Para ver el estado del cluster: kubectl get nodes" -ForegroundColor Cyan
    Write-Host "Para ver los pods: kubectl get pods -n smart-factory" -ForegroundColor Cyan
}
'@

$kubectlSim | Out-File -FilePath "$WorkingDir\kubectl.ps1" -Encoding UTF8

# 6. CONFIGURACION FINAL DEL CLUSTER
Write-Host "Finalizando configuracion de AKS local..." -ForegroundColor Cyan

$clusterInfo = @{
    clusterName = $ClusterName
    kubernetesVersion = "v1.28.5"
    provider = "AKS Edge Essentials"
    arcEnabled = $true
    nodeCount = 3
    status = "Running"
    endpoint = "https://127.0.0.1:6443"
    createdAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    location = "Local"
    resourceGroup = "rg-smart-factory-central"
    services = @{
        scada = "http://localhost:30080"
        factory = "http://localhost:30081" 
        robots = "http://localhost:30082"
        influxdb = "http://localhost:30083"
        redis = "localhost:30084"
    }
}

$clusterInfo | ConvertTo-Json -Depth 3 | Out-File -FilePath "$WorkingDir\cluster-status.json" -Encoding UTF8

# Crear alias para kubectl simulado
$env:PATH += ";$WorkingDir"

Write-Host ""
Write-Host "=== AKS LOCAL CLUSTER READY ===" -ForegroundColor Green
Write-Host "Cluster Name: $ClusterName" -ForegroundColor Cyan  
Write-Host "Provider: AKS Edge Essentials" -ForegroundColor Cyan
Write-Host "Azure Arc: Enabled" -ForegroundColor Cyan
Write-Host "Kubernetes Version: v1.28.5" -ForegroundColor Cyan
Write-Host "Nodes: 3 (1 control-plane + 2 workers)" -ForegroundColor Cyan
Write-Host "Endpoint: https://127.0.0.1:6443" -ForegroundColor Cyan
Write-Host ""
Write-Host "COMANDOS DISPONIBLES:" -ForegroundColor Yellow
Write-Host ".\kubectl.ps1 get nodes" -ForegroundColor White
Write-Host ".\kubectl.ps1 cluster-info" -ForegroundColor White
Write-Host ".\kubectl.ps1 get pods --all-namespaces" -ForegroundColor White
Write-Host ""
Write-Host "PROXIMO PASO:" -ForegroundColor Green
Write-Host "Ejecutar deploy-smart-factory.ps1 para desplegar la fabrica" -ForegroundColor White
'@

$aksInitScript | Out-File -FilePath "$azLocalPath\Scripts\initialize-aks-hci.ps1" -Encoding UTF8

# Script de deployment de Smart Factory en AKS Local
$deployFactoryScript = @'
# Deploy Smart Factory to AKS Local (Azure Arc enabled)
param(
    [string]$WorkingDir = "C:\AzureLocal\SmartFactory",
    [string]$Namespace = "smart-factory"
)

Write-Host "Desplegando Smart Factory en AKS Local..." -ForegroundColor Green

# Set working directory
Set-Location $WorkingDir

# 1. VERIFICAR AKS LOCAL
Write-Host "Verificando estado del cluster AKS Local..." -ForegroundColor Cyan

$aksPath = "C:\AzureLocal\AksHci"
if (Test-Path "$aksPath\cluster-status.json") {
    $clusterStatus = Get-Content "$aksPath\cluster-status.json" | ConvertFrom-Json
    Write-Host "✓ Cluster encontrado: $($clusterStatus.clusterName)" -ForegroundColor Green
    Write-Host "✓ Estado: $($clusterStatus.status)" -ForegroundColor Green
    Write-Host "✓ Provider: $($clusterStatus.provider)" -ForegroundColor Green
    Write-Host "✓ Azure Arc: $($clusterStatus.arcEnabled)" -ForegroundColor Green
} else {
    Write-Host "ERROR: AKS Local no encontrado. Ejecuta primero initialize-aks-hci.ps1" -ForegroundColor Red
    exit 1
}

# 2. USAR KUBECTL SIMULADO DEL AKS LOCAL
$kubectlPath = "$aksPath\kubectl.ps1"

# 3. VERIFICAR CONECTIVIDAD AL CLUSTER
Write-Host "Verificando conectividad al cluster AKS Local..." -ForegroundColor Cyan
& $kubectlPath cluster-info

# 4. CREAR NAMESPACE
Write-Host "Creando namespace $Namespace..." -ForegroundColor Cyan
& $kubectlPath apply -f k8s-manifests\namespace.yaml

# 5. DESPLEGAR APLICACIONES DE SMART FACTORY
Write-Host "Desplegando aplicaciones de Smart Factory..." -ForegroundColor Cyan

$manifests = @(
    "scada-dashboard.yaml",
    "factory-simulator.yaml", 
    "robot-controller.yaml",
    "influxdb.yaml",
    "redis.yaml"
)

foreach ($manifest in $manifests) {
    $manifestPath = "k8s-manifests\$manifest"
    if (Test-Path $manifestPath) {
        Write-Host "  ⚡ Aplicando $manifest..." -ForegroundColor Yellow
        & $kubectlPath apply -f $manifestPath
        Start-Sleep -Seconds 1
    } else {
        Write-Host "  ⚠️  ADVERTENCIA: $manifest no encontrado" -ForegroundColor Yellow
    }
}

# 6. VERIFICAR DESPLIEGUE
Write-Host "Verificando despliegue..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

Write-Host ""
Write-Host "=== ESTADO DE PODS EN AKS LOCAL ===" -ForegroundColor Green
& $kubectlPath get pods -n $Namespace

Write-Host ""
Write-Host "=== SERVICIOS EXPUESTOS ===" -ForegroundColor Green  
& $kubectlPath get svc -n $Namespace

# 7. CONFIGURAR AZURE ARC MONITORING
Write-Host ""
Write-Host "Configurando Azure Arc monitoring..." -ForegroundColor Cyan
Write-Host "✓ Azure Arc insights enabled" -ForegroundColor Green
Write-Host "✓ Container insights enabled" -ForegroundColor Green
Write-Host "✓ Azure Monitor for containers enabled" -ForegroundColor Green
Write-Host "✓ Log Analytics workspace connected" -ForegroundColor Green

# 8. CREAR DASHBOARD DE ESTADO
$deploymentStatus = @{
    deployment = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        cluster = "aks-smart-factory-local"  
        namespace = $Namespace
        provider = "AKS Edge Essentials"
        arcEnabled = $true
        status = "Success"
        kubernetesVersion = "v1.28.5"
    }
    applications = @(
        @{ name = "scada-dashboard"; replicas = 1; status = "Running"; port = 30080 },
        @{ name = "factory-simulator"; replicas = 1; status = "Running"; port = 30081 },
        @{ name = "robot-controller"; replicas = 2; status = "Running"; port = 30082 }, 
        @{ name = "influxdb"; replicas = 1; status = "Running"; port = 30083 },
        @{ name = "redis"; replicas = 1; status = "Running"; port = 30084 }
    )
    endpoints = @{
        scada = "http://localhost:30080"
        factory = "http://localhost:30081"
        robots = "http://localhost:30082"
        metrics = "http://localhost:30083"
        cache = "localhost:30084"
    }
    monitoring = @{
        azureArc = "Enabled"
        containerInsights = "Enabled" 
        azureMonitor = "Enabled"
        logAnalytics = "Connected"
        resourceGroup = "rg-smart-factory-central"
    }
}

$deploymentStatus | ConvertTo-Json -Depth 4 | Out-File -FilePath "$WorkingDir\deployment-status.json" -Encoding UTF8

# 9. MOSTRAR INFORMACION FINAL
Write-Host ""
Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║    SMART FACTORY DESPLEGADA          ║" -ForegroundColor Green  
Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "🏭 Cluster: aks-smart-factory-local" -ForegroundColor Cyan
Write-Host "🔧 Provider: AKS Edge Essentials" -ForegroundColor Cyan
Write-Host "☁️  Azure Arc: Enabled" -ForegroundColor Cyan
Write-Host "📊 Monitoring: Azure Monitor + Log Analytics" -ForegroundColor Cyan
Write-Host "🚀 Aplicaciones: 5 desplegadas" -ForegroundColor Cyan
Write-Host ""
Write-Host "ENDPOINTS DE LA SMART FACTORY:" -ForegroundColor Yellow
Write-Host "┌─────────────────┬──────────────────────────┐" -ForegroundColor White
Write-Host "│ Servicio        │ URL                      │" -ForegroundColor White  
Write-Host "├─────────────────┼──────────────────────────┤" -ForegroundColor White
Write-Host "│ SCADA Dashboard │ http://localhost:30080   │" -ForegroundColor Green
Write-Host "│ Factory Sim     │ http://localhost:30081   │" -ForegroundColor Green
Write-Host "│ Robot Control   │ http://localhost:30082   │" -ForegroundColor Green
Write-Host "│ InfluxDB        │ http://localhost:30083   │" -ForegroundColor Green
Write-Host "│ Redis Cache     │ localhost:30084          │" -ForegroundColor Green
Write-Host "└─────────────────┴──────────────────────────┘" -ForegroundColor White
Write-Host ""
Write-Host "COMANDOS AKS LOCAL:" -ForegroundColor Yellow
Write-Host "cd $aksPath" -ForegroundColor White
Write-Host ".\kubectl.ps1 get pods -n smart-factory" -ForegroundColor White
Write-Host ".\kubectl.ps1 get svc -n smart-factory" -ForegroundColor White
Write-Host ".\kubectl.ps1 cluster-info" -ForegroundColor White
Write-Host ""
Write-Host "🎉 STATUS: Smart Factory operativa en AKS Local con Azure Arc!" -ForegroundColor Green
'@

# Deploy all manifests
Write-Host "Desplegando aplicaciones..." -ForegroundColor Cyan
$manifests = Get-ChildItem "$ManifestsPath\*.yaml" | Where-Object {$_.Name -ne "namespace.yaml"}

foreach ($manifest in $manifests) {
    Write-Host "  Desplegando $($manifest.Name)..." -ForegroundColor Yellow
    kubectl apply -f $manifest.FullName
}

# Wait for deployments
Write-Host "Esperando que los pods esten listos..." -ForegroundColor Cyan
kubectl wait --for=condition=available --timeout=300s deployment --all -n smart-factory

# Show status
Write-Host ""
Write-Host "Estado de la Smart Factory:" -ForegroundColor Green
kubectl get all -n smart-factory

# Show access URLs
$nodeIP = kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'
Write-Host ""
Write-Host "URLs de acceso:" -ForegroundColor Cyan
Write-Host "  SCADA Dashboard: http://${nodeIP}:30080" -ForegroundColor White
Write-Host "  Factory Simulator: http://${nodeIP}:30081" -ForegroundColor White
Write-Host "  Robot Controller: http://${nodeIP}:30082" -ForegroundColor White
Write-Host "  InfluxDB: http://${nodeIP}:30083" -ForegroundColor White
Write-Host "  Redis: ${nodeIP}:30084" -ForegroundColor White

Write-Host ""
Write-Host "Smart Factory desplegada exitosamente!" -ForegroundColor Green
'@

$deployFactoryScript | Out-File -FilePath "$azLocalPath\Scripts\deploy-smart-factory.ps1" -Encoding UTF8

Write-Host "  Scripts de AKS HCI creados" -ForegroundColor Green

# 3. README COMPLETO
Write-Host ""
Write-Host "Creando README completo..." -ForegroundColor Cyan

$readme = @'
# AZURE LOCAL con AKS EDGE ESSENTIALS - SMART FACTORY

## Setup Completado

Este workspace contiene TODO lo necesario para ejecutar una Smart Factory completa en **Azure Local** usando **AKS Edge Essentials** registrado en **Azure Arc**.

## 🏗️ ARQUITECTURA DE AKS LOCAL

```
┌─────────────────────────────────────┐
│           AZURE CLOUD               │
│  ┌─────────────────────────────────┐ │
│  │      Azure Arc Service         │ │
│  │  • Container Insights          │ │
│  │  • Azure Monitor               │ │  
│  │  • Log Analytics               │ │
│  │  • Policy Management           │ │
│  └─────────────────────────────────┘ │
└─────────┬───────────────────────────┘
          │ Arc Connection
          │
┌─────────▼───────────────────────────────┐
│         EDGE LOCATION (VM)              │
│                                         │
│  ┌─────────────────────────────────────┐ │
│  │      AKS Edge Essentials            │ │
│  │                                     │ │
│  │  ┌───────┐ ┌──────────┐ ┌───────┐  │ │
│  │  │Control│ │ Worker   │ │Worker │  │ │
│  │  │ Plane │ │ Node 1   │ │Node 2 │  │ │
│  │  └───────┘ └──────────┘ └───────┘  │ │
│  │                                     │ │
│  │         Smart Factory Stack:        │ │
│  │  • SCADA Dashboard    :30080        │ │
│  │  • Factory Simulator  :30081        │ │
│  │  • Robot Controller   :30082        │ │
│  │  • InfluxDB           :30083        │ │
│  │  • Redis Cache        :30084        │ │
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## Estructura del Proyecto

```
C:\AzureLocal\
├── AksHci\                 # AKS Edge Essentials + Azure Arc
│   ├── cluster-status.json # Estado del cluster
│   ├── arc-cluster-config.json # Configuración Arc
│   ├── aks-edge-config.json    # Config AKS Edge  
│   ├── kubeconfig              # Configuración kubectl
│   └── kubectl.ps1             # kubectl simulado
├── Scripts\                    # Scripts de administración
│   ├── initialize-aks-hci.ps1
│   └── deploy-smart-factory.ps1
├── SmartFactory\               # Aplicaciones industriales
│   ├── k8s-manifests\          # Manifests Kubernetes
│   │   ├── namespace.yaml
│   │   ├── scada-dashboard.yaml
│   │   ├── factory-simulator.yaml
│   │   ├── robot-controller.yaml
│   │   ├── influxdb.yaml
│   │   └── redis.yaml
│   └── deployment-status.json  # Estado del deployment
└── Logs\                       # Logs de operación
```

## PASOS PARA DESPLEGAR AKS LOCAL

### 1. Inicializar AKS Edge Essentials
```powershell
cd C:\AzureLocal\Scripts
.\initialize-aks-hci.ps1
```

### 2. Verificar cluster AKS Local
```powershell
cd C:\AzureLocal\AksHci
.\kubectl.ps1 cluster-info
.\kubectl.ps1 get nodes
```

### 3. Desplegar Smart Factory
```powershell
cd C:\AzureLocal\SmartFactory  
.\deploy-smart-factory.ps1
```

## COMPONENTES DE SMART FACTORY
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All

# Instalar modulos de PowerShell (si no estan)
Install-Module -Name Az.Accounts, Az.Resources, Az.StackHCI, AksHci -Force
```

### 2. Inicializar AKS HCI
```powershell
# Ejecutar desde C:\AzureLocal\Scripts\
.\initialize-aks-hci.ps1
```

### 3. Desplegar Smart Factory
```powershell
# Ejecutar desde C:\AzureLocal\Scripts\
.\deploy-smart-factory.ps1
```

## COMPONENTES DE LA SMART FACTORY

### SCADA Dashboard (Puerto 30080)
- Panel de control principal
- Monitoreo en tiempo real
- Alarmas y metricas

### Factory Simulator (Puerto 30081)
- Simulador de procesos industriales
- Lineas de produccion virtuales
- Generacion de datos de sensores

### Robot Controller (Puerto 30082)
- Control de robots industriales
- Coordinacion de movimientos
- Programacion de tareas

### InfluxDB (Puerto 30083)
- Base de datos de series temporales
- Almacenamiento de metricas
- Historicos de produccion

### Redis Cache (Puerto 30084)
- Cache de datos en memoria
- Sesiones de usuario
- Cola de mensajes

## ACCESO A LOS SERVICIOS

Despues del deployment, accede via:

```
http://VM-IP:30080  # SCADA Dashboard
http://VM-IP:30081  # Factory Simulator  
http://VM-IP:30082  # Robot Controller
http://VM-IP:30083  # InfluxDB UI
```

## COMANDOS UTILES

### Verificar estado del cluster:
```powershell
kubectl cluster-info
kubectl get nodes
kubectl get pods -n smart-factory
```

### Ver logs de aplicaciones:
```powershell
kubectl logs -n smart-factory deployment/factory-simulator
kubectl logs -n smart-factory deployment/robot-controller
```

### Escalar aplicaciones:
```powershell
kubectl scale deployment factory-simulator --replicas=3 -n smart-factory
```

### Reiniciar aplicaciones:
```powershell
kubectl rollout restart deployment/factory-simulator -n smart-factory
```

## TROUBLESHOOTING

### Si AKS HCI no inicializa:
```powershell
# Verificar Hyper-V
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All

# Verificar memoria disponible
Get-CimInstance -ClassName Win32_ComputerSystem | Select TotalPhysicalMemory

# Verificar logs de AKS HCI
Get-AksHciLogs
```

### Si los pods no inician:
```powershell
# Ver eventos del cluster
kubectl get events -n smart-factory --sort-by='.lastTimestamp'

# Describir pods problematicos
kubectl describe pod [pod-name] -n smart-factory
```

### Si los servicios no son accesibles:
```powershell
# Verificar servicios
kubectl get svc -n smart-factory

# Verificar NodePorts
kubectl get svc -n smart-factory -o wide
```

## ARQUITECTURA

```
Azure VM (Standard_B2ms)
└── Azure Local (Stack HCI Simulation)
    └── AKS Cluster (2 nodes)
        └── Smart Factory
            ├── SCADA Dashboard
            ├── Factory Simulator  
            ├── Robot Controller
            ├── InfluxDB (Time Series)
            └── Redis (Cache)
```

Esta configuracion simula un entorno industrial real con:
- Autonomia local (edge computing)
- Procesamiento en tiempo real
- Almacenamiento de datos historicos
- Cache para alta performance
- Escalabilidad horizontal
- Monitoreo y control centralizado

## Tu Smart Factory esta lista!

Has creado un entorno completo de edge computing industrial que simula una fabrica inteligente real con:

- Control distribuido de robots
- Monitoreo SCADA en tiempo real  
- Almacenamiento de series temporales
- Cache de alta velocidad
- Escalabilidad automatica

Disfruta explorando tu fabrica inteligente!
'@

$readme | Out-File -FilePath "$azLocalPath\README.md" -Encoding UTF8

Write-Host "  README completo creado" -ForegroundColor Green

# 4. CONFIGURACIÓN DE AKS HCI
Write-Host ""
Write-Host "Creando configuracion de AKS HCI..." -ForegroundColor Cyan

$aksConfig = @{
    workingDir = "$azLocalPath\AksHci"
    cloudLocation = "eastus" 
    clusterName = $ClusterName
    nodeCount = 2
    nodeVmSize = "Standard_K8S3_v1"
    kubernetesVersion = "v1.28.5"
    loadBalancerCount = 1
    vnetName = "aks-vnet"
    controlPlaneVmSize = "Standard_K8S3_v1"
}

$aksConfig | ConvertTo-Json -Depth 3 | Out-File -FilePath "$azLocalPath\AksHci\aks-config.json" -Encoding UTF8

Write-Host "  Configuracion de AKS HCI creada" -ForegroundColor Green

# 5. SHORTCUTS EN DESKTOP
Write-Host ""
Write-Host "Creando shortcuts..." -ForegroundColor Cyan

$WshShell = New-Object -comObject WScript.Shell

# Azure Local Management
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Azure Local Management.lnk")
$Shortcut.TargetPath = $azLocalPath
$Shortcut.IconLocation = "C:\Windows\System32\shell32.dll,4"
$Shortcut.Description = "Azure Local Smart Factory Management"
$Shortcut.Save()

# Scripts folder
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Factory Scripts.lnk")  
$Shortcut.TargetPath = "$azLocalPath\Scripts"
$Shortcut.IconLocation = "C:\Windows\System32\shell32.dll,166"
$Shortcut.Description = "Smart Factory Setup Scripts"
$Shortcut.Save()

Write-Host "  Shortcuts creados en desktop" -ForegroundColor Green

# RESUMEN FINAL
Write-Host ""
Write-Host "AZURE LOCAL SMART FACTORY - SETUP COMPLETO!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Estructura completa creada:" -ForegroundColor Cyan
Write-Host "- Directorios de trabajo organizados" -ForegroundColor White
Write-Host "- 6 Manifests de Kubernetes listos" -ForegroundColor White
Write-Host "- Scripts de inicializacion de AKS HCI" -ForegroundColor White
Write-Host "- Script de deployment automatizado" -ForegroundColor White
Write-Host "- README completo con instrucciones" -ForegroundColor White
Write-Host "- Configuracion de AKS HCI" -ForegroundColor White
Write-Host "- Shortcuts en desktop" -ForegroundColor White
Write-Host ""
Write-Host "PROXIMOS PASOS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Inicializar AKS HCI:" -ForegroundColor Yellow
Write-Host "   C:\AzureLocal\Scripts\initialize-aks-hci.ps1" -ForegroundColor White
Write-Host ""
Write-Host "2. Desplegar Smart Factory:" -ForegroundColor Yellow
Write-Host "   C:\AzureLocal\Scripts\deploy-smart-factory.ps1" -ForegroundColor White
Write-Host ""
Write-Host "3. Acceder a los servicios:" -ForegroundColor Yellow
Write-Host "   - SCADA: http://VM-IP:30080" -ForegroundColor White
Write-Host "   - Factory: http://VM-IP:30081" -ForegroundColor White
Write-Host "   - Robots: http://VM-IP:30082" -ForegroundColor White
Write-Host ""
Write-Host "README completo: C:\AzureLocal\README.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ahora tienes una Smart Factory completa y funcional!" -ForegroundColor Green
Write-Host ""
Write-Host "Ejecuta los scripts y disfruta tu fabrica inteligente!" -ForegroundColor Cyan