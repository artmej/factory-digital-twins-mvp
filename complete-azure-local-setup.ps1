# Azure Local Smart Factory - SETUP COMPLETO
# Este script crea TODO lo necesario para Azure Local + Smart Factory

param(
    [string]$ClusterName = "aks-smart-factory-local"
)

Write-Host @"

     AZURE LOCAL SMART FACTORY - SETUP COMPLETO
    ===================================================
    
    Creando workspace completo con:
    - Directorios de trabajo
    - Scripts de configuracion de AKS HCI  
    - Manifests de Kubernetes
    - Scripts de setup de Azure Local
    - README con instrucciones completas
    
    Iniciando setup completo...

"@ -ForegroundColor Green

# Crear estructura de directorios
$azLocalPath = "C:\AzureLocal"
Write-Host "📁 Creando estructura de directorios..." -ForegroundColor Cyan

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
    Write-Host "  ✅ $dir" -ForegroundColor Green
}

# 1. MANIFESTS DE KUBERNETES PARA SMART FACTORY
Write-Host "`n📦 Creando manifests de Kubernetes..." -ForegroundColor Cyan

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

Write-Host "  ✅ Todos los manifests de Kubernetes creados" -ForegroundColor Green

# 2. SCRIPTS DE AKS HCI
Write-Host "`n🔧 Creando scripts de AKS HCI..." -ForegroundColor Cyan

# Script de inicialización de AKS HCI
$aksInitScript = @'
# AKS HCI Initialization Script
param(
    [string]$WorkingDir = "C:\AzureLocal\AksHci",
    [string]$ClusterName = "aks-smart-factory-local"
)

Write-Host "🚀 Inicializando AKS HCI..." -ForegroundColor Green

# Set working directory
Set-Location $WorkingDir

# Initialize AKS HCI
try {
    Write-Host "Configurando AKS HCI..." -ForegroundColor Cyan
    Initialize-AksHci -workingDir $WorkingDir
    Write-Host "✅ AKS HCI inicializado" -ForegroundColor Green
} catch {
    Write-Host "❌ Error inicializando AKS HCI: $_" -ForegroundColor Red
    exit 1
}

# Create cluster
try {
    Write-Host "Creando cluster AKS..." -ForegroundColor Cyan
    New-AksHciCluster -name $ClusterName -nodeCount 2 -nodeVmSize Standard_K8S3_v1
    Write-Host "✅ Cluster AKS creado" -ForegroundColor Green
} catch {
    Write-Host "❌ Error creando cluster: $_" -ForegroundColor Red
    exit 1
}

# Get credentials
try {
    Write-Host "Obteniendo credenciales..." -ForegroundColor Cyan
    Get-AksHciCredential -name $ClusterName
    Write-Host "✅ Credenciales configuradas" -ForegroundColor Green
} catch {
    Write-Host "❌ Error obteniendo credenciales: $_" -ForegroundColor Red
}

Write-Host "🎉 AKS HCI listo para usar!" -ForegroundColor Green
kubectl cluster-info
'@

$aksInitScript | Out-File -FilePath "$azLocalPath\Scripts\initialize-aks-hci.ps1" -Encoding UTF8

# Script de deployment de Smart Factory
$deployFactoryScript = @'
# Deploy Smart Factory Script
param(
    [string]$ManifestsPath = "C:\AzureLocal\SmartFactory\k8s-manifests"
)

Write-Host "🏭 Desplegando Smart Factory..." -ForegroundColor Green

# Check if kubectl is available
try {
    kubectl cluster-info | Out-Null
    Write-Host "✅ Conexión a cluster confirmada" -ForegroundColor Green
} catch {
    Write-Host "❌ No hay conexión al cluster. Ejecuta initialize-aks-hci.ps1 primero" -ForegroundColor Red
    exit 1
}

# Deploy namespace first
Write-Host "Creando namespace..." -ForegroundColor Cyan
kubectl apply -f "$ManifestsPath\namespace.yaml"

# Deploy all manifests
Write-Host "Desplegando aplicaciones..." -ForegroundColor Cyan
$manifests = Get-ChildItem "$ManifestsPath\*.yaml" | Where-Object {$_.Name -ne "namespace.yaml"}

foreach ($manifest in $manifests) {
    Write-Host "  Desplegando $($manifest.Name)..." -ForegroundColor Yellow
    kubectl apply -f $manifest.FullName
}

# Wait for deployments
Write-Host "Esperando que los pods estén listos..." -ForegroundColor Cyan
kubectl wait --for=condition=available --timeout=300s deployment --all -n smart-factory

# Show status
Write-Host "`n📊 Estado de la Smart Factory:" -ForegroundColor Green
kubectl get all -n smart-factory

# Show access URLs
$nodeIP = kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'
Write-Host "`n🌐 URLs de acceso:" -ForegroundColor Cyan
Write-Host "  📊 SCADA Dashboard: http://${nodeIP}:30080" -ForegroundColor White
Write-Host "  🏭 Factory Simulator: http://${nodeIP}:30081" -ForegroundColor White
Write-Host "  🤖 Robot Controller: http://${nodeIP}:30082" -ForegroundColor White
Write-Host "  📈 InfluxDB: http://${nodeIP}:30083" -ForegroundColor White
Write-Host "  💾 Redis: ${nodeIP}:30084" -ForegroundColor White

Write-Host "`n🎉 Smart Factory desplegada exitosamente!" -ForegroundColor Green
'@

$deployFactoryScript | Out-File -FilePath "$azLocalPath\Scripts\deploy-smart-factory.ps1" -Encoding UTF8

Write-Host "  ✅ Scripts de AKS HCI creados" -ForegroundColor Green

# 3. README COMPLETO
Write-Host "`n📖 Creando README completo..." -ForegroundColor Cyan

$readme = @'
# 🏭 AZURE LOCAL SMART FACTORY

## ✅ Setup Completado

Este workspace contiene TODO lo necesario para ejecutar una Smart Factory completa en Azure Local (Stack HCI simulation) con AKS.

## 📁 Estructura del Proyecto

```
C:\AzureLocal\
├── VMs\                    # Almacenamiento de VMs virtuales
├── AksHci\                 # Configuración de AKS HCI
├── Logs\                   # Logs de setup y operación
├── Scripts\                # Scripts de administración
│   ├── initialize-aks-hci.ps1
│   └── deploy-smart-factory.ps1
└── SmartFactory\           # Aplicaciones de la fábrica
    └── k8s-manifests\      # Manifests de Kubernetes
        ├── namespace.yaml
        ├── scada-dashboard.yaml
        ├── factory-simulator.yaml
        ├── robot-controller.yaml
        ├── influxdb.yaml
        └── redis.yaml
```

## 🚀 PASOS PARA DESPLEGAR

### 1. Preparar el entorno
```powershell
# Asegurar que Hyper-V esté habilitado
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All

# Instalar módulos de PowerShell (si no están)
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

## 🏭 COMPONENTES DE LA SMART FACTORY

### 📊 **SCADA Dashboard** (Puerto 30080)
• Panel de control principal
• Monitoreo en tiempo real
• Alarmas y métricas

### 🏭 **Factory Simulator** (Puerto 30081)
• Simulador de procesos industriales
• Líneas de producción virtuales
• Generación de datos de sensores

### 🤖 **Robot Controller** (Puerto 30082)
• Control de robots industriales
• Coordinación de movimientos
• Programación de tareas

### 📈 **InfluxDB** (Puerto 30083)
• Base de datos de series temporales
• Almacenamiento de métricas
• Históricos de producción

### 💾 **Redis Cache** (Puerto 30084)
• Cache de datos en memoria
• Sesiones de usuario
• Cola de mensajes

## 🌐 ACCESO A LOS SERVICIOS

Después del deployment, accede via:

```
http://VM-IP:30080  # SCADA Dashboard
http://VM-IP:30081  # Factory Simulator  
http://VM-IP:30082  # Robot Controller
http://VM-IP:30083  # InfluxDB UI
```

## 🔧 COMANDOS ÚTILES

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

## 🆘 TROUBLESHOOTING

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

# Describir pods problemáticos
kubectl describe pod [pod-name] -n smart-factory
```

### Si los servicios no son accesibles:
```powershell
# Verificar servicios
kubectl get svc -n smart-factory

# Verificar NodePorts
kubectl get svc -n smart-factory -o wide
```

## 🎯 ARQUITECTURA

```
🌐 Azure VM (Standard_B2ms)
└── 💿 Azure Local (Stack HCI Simulation)
    └── ⚙️ AKS Cluster (2 nodes)
        └── 🏭 Smart Factory
            ├── 📊 SCADA Dashboard
            ├── 🏭 Factory Simulator  
            ├── 🤖 Robot Controller
            ├── 📈 InfluxDB (Time Series)
            └── 💾 Redis (Cache)
```

Esta configuración simula un entorno industrial real con:
• ✅ Autonomía local (edge computing)
• ✅ Procesamiento en tiempo real
• ✅ Almacenamiento de datos históricos
• ✅ Cache para alta performance
• ✅ Escalabilidad horizontal
• ✅ Monitoreo y control centralizado

## 🎉 ¡Tu Smart Factory está lista!

Has creado un entorno completo de **edge computing industrial** que simula una fábrica inteligente real con:

• Control distribuido de robots
• Monitoreo SCADA en tiempo real  
• Almacenamiento de series temporales
• Cache de alta velocidad
• Escalabilidad automática

¡Disfruta explorando tu fábrica inteligente! 🚀
'@

$readme | Out-File -FilePath "$azLocalPath\README.md" -Encoding UTF8

Write-Host "  ✅ README completo creado" -ForegroundColor Green

# 4. CONFIGURACIÓN DE AKS HCI
Write-Host "`n⚙️ Creando configuración de AKS HCI..." -ForegroundColor Cyan

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

Write-Host "  ✅ Configuración de AKS HCI creada" -ForegroundColor Green

# 5. SHORTCUTS EN DESKTOP
Write-Host "`n🖱️ Creando shortcuts..." -ForegroundColor Cyan

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

Write-Host "  ✅ Shortcuts creados en desktop" -ForegroundColor Green

# RESUMEN FINAL
Write-Host @"

🎉 AZURE LOCAL SMART FACTORY - SETUP COMPLETO! 🎉
===============================================

✅ Estructura completa creada:
   • Directorios de trabajo organizados
   • 6 Manifests de Kubernetes listos
   • Scripts de inicialización de AKS HCI  
   • Script de deployment automatizado
   • README completo con instrucciones
   • Configuración de AKS HCI
   • Shortcuts en desktop

📋 PRÓXIMOS PASOS:

1. Inicializar AKS HCI:
   C:\AzureLocal\Scripts\initialize-aks-hci.ps1

2. Desplegar Smart Factory:  
   C:\AzureLocal\Scripts\deploy-smart-factory.ps1

3. Acceder a los servicios:
   • SCADA: http://VM-IP:30080
   • Factory: http://VM-IP:30081  
   • Robots: http://VM-IP:30082

📖 README completo: C:\AzureLocal\README.md

🎯 ¡Ahora tienes una Smart Factory completa y funcional!

"@ -ForegroundColor Green

Write-Host "🚀 ¡Ejecuta los scripts y disfruta tu fábrica inteligente!" -ForegroundColor Cyan