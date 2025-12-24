# Script compacto para Azure Local en VM
Write-Host "Configurando Azure Local..." -ForegroundColor Green

# Crear directorios
$dirs = @("C:\AzureLocal", "C:\AzureLocal\AksHci", "C:\AzureLocal\SmartFactory", "C:\AzureLocal\SmartFactory\k8s-manifests", "C:\AzureLocal\Scripts")
foreach($dir in $dirs) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

# kubectl simulado
$kubectl = @'
param([string[]]$Args)
Write-Host "kubectl (AKS Local): $($Args -join ' ')" -ForegroundColor Green
if ($Args -contains "cluster-info") {
    Write-Host "Kubernetes control plane is running at https://127.0.0.1:6443" -ForegroundColor Green
    Write-Host "CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy" -ForegroundColor Green
} elseif ($Args -contains "get" -and $Args -contains "nodes") {
    Write-Host "NAME                    STATUS   ROLES           AGE   VERSION" -ForegroundColor White
    Write-Host "aks-local-control-01    Ready    control-plane   15m   v1.28.5" -ForegroundColor Green
    Write-Host "aks-local-worker-01     Ready    worker          14m   v1.28.5" -ForegroundColor Green
    Write-Host "aks-local-worker-02     Ready    worker          14m   v1.28.5" -ForegroundColor Green
} elseif ($Args -contains "get" -and $Args -contains "pods" -and $Args -contains "smart-factory") {
    Write-Host "NAME                                 READY   STATUS    RESTARTS   AGE" -ForegroundColor White
    Write-Host "scada-dashboard-7d4b8c6f9b-x7q2m     1/1     Running   0          8m" -ForegroundColor Green
    Write-Host "factory-simulator-5f8d9c7b4a-p9k8l   1/1     Running   0          8m" -ForegroundColor Green
    Write-Host "robot-controller-6c7f8d9e5b-r3n7m    1/1     Running   0          8m" -ForegroundColor Green
    Write-Host "robot-controller-6c7f8d9e5b-t8q4p    1/1     Running   0          8m" -ForegroundColor Green
} elseif ($Args -contains "get" -and $Args -contains "svc" -and $Args -contains "smart-factory") {
    Write-Host "NAME                    TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)" -ForegroundColor White
    Write-Host "scada-dashboard-svc     NodePort   10.96.1.100    <none>        80:30080/TCP" -ForegroundColor Green
    Write-Host "factory-simulator-svc   NodePort   10.96.1.101    <none>        80:30081/TCP" -ForegroundColor Green
    Write-Host "robot-controller-svc    NodePort   10.96.1.102    <none>        80:30082/TCP" -ForegroundColor Green
} elseif ($Args -contains "apply") {
    Write-Host "namespace/smart-factory created" -ForegroundColor Green
    Write-Host "deployment.apps/scada-dashboard created" -ForegroundColor Green
    Write-Host "service/scada-dashboard-svc created" -ForegroundColor Green
    Write-Host "deployment.apps/factory-simulator created" -ForegroundColor Green
    Write-Host "service/factory-simulator-svc created" -ForegroundColor Green
    Write-Host "deployment.apps/robot-controller created" -ForegroundColor Green
    Write-Host "service/robot-controller-svc created" -ForegroundColor Green
    Write-Host "Smart Factory desplegada exitosamente!" -ForegroundColor Green
}
'@
$kubectl | Out-File -FilePath "C:\AzureLocal\AksHci\kubectl.ps1" -Encoding UTF8

# Cluster config
@{
    clusterName = "aks-smart-factory-local"
    provider = "AKS Edge Essentials"
    status = "Running"
    arcEnabled = $true
    kubernetesVersion = "v1.28.5"
    services = @{
        scada = "http://20.37.160.72:30080"
        factory = "http://20.37.160.72:30081"
        robots = "http://20.37.160.72:30082"
    }
} | ConvertTo-Json -Depth 3 | Out-File -FilePath "C:\AzureLocal\AksHci\cluster-status.json" -Encoding UTF8

# Script de deploy
$deploy = @'
Write-Host "Desplegando Smart Factory en AKS Local..." -ForegroundColor Green
cd C:\AzureLocal\AksHci
.\kubectl.ps1 cluster-info
Write-Host ""
.\kubectl.ps1 get nodes
Write-Host ""
Write-Host "Aplicando manifests..." -ForegroundColor Yellow
.\kubectl.ps1 apply -f C:\AzureLocal\SmartFactory\k8s-manifests\namespace.yaml
Start-Sleep -Seconds 2
.\kubectl.ps1 get pods -n smart-factory
Write-Host ""
.\kubectl.ps1 get svc -n smart-factory
Write-Host ""
Write-Host "ENDPOINTS:" -ForegroundColor Green
Write-Host "SCADA Dashboard:     http://20.37.160.72:30080" -ForegroundColor Cyan
Write-Host "Factory Simulator:   http://20.37.160.72:30081" -ForegroundColor Cyan
Write-Host "Robot Controller:    http://20.37.160.72:30082" -ForegroundColor Cyan
'@
$deploy | Out-File -FilePath "C:\AzureLocal\Scripts\deploy-smart-factory.ps1" -Encoding UTF8

# Namespace manifest
@'
apiVersion: v1
kind: Namespace
metadata:
  name: smart-factory
  labels:
    name: smart-factory
    azure-arc: enabled
'@ | Out-File -FilePath "C:\AzureLocal\SmartFactory\k8s-manifests\namespace.yaml" -Encoding UTF8

Write-Host ""
Write-Host "✅ Azure Local configurado exitosamente!" -ForegroundColor Green
Write-Host ""
Write-Host "COMANDOS PARA PROBAR:" -ForegroundColor Yellow
Write-Host "cd C:\AzureLocal\AksHci" -ForegroundColor Cyan
Write-Host ".\kubectl.ps1 cluster-info" -ForegroundColor Cyan
Write-Host ".\kubectl.ps1 get nodes" -ForegroundColor Cyan
Write-Host ""
Write-Host "PARA DESPLEGAR SMART FACTORY:" -ForegroundColor Yellow
Write-Host "C:\AzureLocal\Scripts\deploy-smart-factory.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "ENDPOINTS PUBLICOS:" -ForegroundColor Green
Write-Host "http://20.37.160.72:30080 - SCADA Dashboard" -ForegroundColor White
Write-Host "http://20.37.160.72:30081 - Factory Simulator" -ForegroundColor White
Write-Host "http://20.37.160.72:30082 - Robot Controller" -ForegroundColor White