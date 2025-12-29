# ArcBox Quick Start - Script simple para encendido rápido

param(
    [string]$ResourceGroup = "rg-smartfactory-arcbox"
)

Write-Host "🚀 Encendido rápido de ArcBox..." -ForegroundColor Green

# Encender todas las VMs en orden con esperas cortas
$vms = @(
    "ArcBox-ADDS",
    "ArcBox-K3s-Data-6c14", 
    "ArcBox-K3s-Data-6c14-Node-00",
    "ArcBox-K3s-Data-6c14-Node-01", 
    "ArcBox-K3s-Data-6c14-Node-02",
    "ArcBox-Client"
)

foreach ($vm in $vms) {
    Write-Host "▶️ Iniciando $vm..." -ForegroundColor Cyan
    az vm start --name $vm --resource-group $ResourceGroup --no-wait
    Start-Sleep 10
}

Write-Host "⏳ Esperando 3 minutos para que todas las VMs arranquen..." -ForegroundColor Yellow
Start-Sleep 180

Write-Host "📊 Estado de VMs:" -ForegroundColor Green
az vm list --resource-group $ResourceGroup --show-details --query "[].{Name:name,PowerState:powerState}" --output table

# Encender clusters AKS  
Write-Host "`n🚀 Iniciando clusters AKS..." -ForegroundColor Yellow
az aks start --name "ArcBox-AKS-Data-6c14" --resource-group $ResourceGroup --no-wait
az aks start --name "ArcBox-AKS-DR-Data-6c14" --resource-group $ResourceGroup --no-wait

Write-Host "⏳ Clusters AKS iniciándose en paralelo..." -ForegroundColor Cyan
Start-Sleep 60

# Verificar AKS
try {
    $aksState = az aks show --name "ArcBox-AKS-Data-6c14" --resource-group $ResourceGroup --query powerState.code -o tsv 2>$null
    Write-Host "📊 Cluster principal: $aksState" -ForegroundColor Cyan
} catch {
    Write-Host "📊 Cluster principal: Iniciando..." -ForegroundColor Yellow
}

Write-Host "`n🎉 ArcBox iniciado - AKS disponible para Arc Data Services" -ForegroundColor Green

Write-Host "✅ Proceso completado!" -ForegroundColor Green