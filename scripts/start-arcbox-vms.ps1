# ArcBox DataOps - Script de Encendido Secuencial
# Enciende las VMs en el orden correcto con tiempos de espera

param(
    [string]$ResourceGroup = "rg-smartfactory-arcbox",
    [int]$WaitTime = 60  # Segundos entre cada grupo de VMs
)

Write-Host "🚀 Iniciando secuencia de encendido de ArcBox DataOps..." -ForegroundColor Green
Write-Host "📋 Resource Group: $ResourceGroup" -ForegroundColor Cyan
Write-Host "⏱️ Tiempo de espera: $WaitTime segundos entre grupos" -ForegroundColor Cyan
Write-Host "=" * 60

# Función para esperar que una VM esté corriendo
function Wait-ForVMRunning {
    param([string]$VMName, [string]$ResourceGroup)
    
    Write-Host "⏳ Esperando que $VMName esté corriendo..." -ForegroundColor Yellow
    do {
        $vmStatus = az vm get-instance-view --name $VMName --resource-group $ResourceGroup --query "instanceView.statuses[1].displayStatus" --output tsv
        if ($vmStatus -eq "VM running") {
            Write-Host "✅ $VMName está corriendo" -ForegroundColor Green
            return $true
        }
        Write-Host "   Estado actual: $vmStatus" -ForegroundColor Gray
        Start-Sleep 15
    } while ($vmStatus -ne "VM running")
}

# Función para verificar conectividad
function Test-VMConnectivity {
    param([string]$VMName, [string]$ResourceGroup)
    
    Write-Host "🔍 Verificando conectividad de $VMName..." -ForegroundColor Yellow
    $result = az vm run-command invoke --resource-group $ResourceGroup --name $VMName --command-id "RunPowerShellScript" --scripts "Write-Output 'VM Ready'" --query "value[0].message" --output tsv 2>$null
    
    if ($result -like "*VM Ready*") {
        Write-Host "✅ $VMName responde correctamente" -ForegroundColor Green
        return $true
    } else {
        Write-Host "⚠️ $VMName no responde aún" -ForegroundColor Yellow
        return $false
    }
}

try {
    # Paso 1: Encender Domain Controller (ADDS)
    Write-Host "`n🔷 PASO 1: Iniciando Domain Controller..." -ForegroundColor Blue
    az vm start --name "ArcBox-ADDS" --resource-group $ResourceGroup --no-wait
    
    Write-Host "⏳ Esperando $WaitTime segundos..." -ForegroundColor Gray
    Start-Sleep $WaitTime
    
    Wait-ForVMRunning -VMName "ArcBox-ADDS" -ResourceGroup $ResourceGroup
    
    # Paso 2: Encender K3s Master
    Write-Host "`n🔷 PASO 2: Iniciando K3s Master..." -ForegroundColor Blue
    az vm start --name "ArcBox-K3s-Data-6c14" --resource-group $ResourceGroup --no-wait
    
    Write-Host "⏳ Esperando $WaitTime segundos..." -ForegroundColor Gray
    Start-Sleep $WaitTime
    
    Wait-ForVMRunning -VMName "ArcBox-K3s-Data-6c14" -ResourceGroup $ResourceGroup
    
    # Paso 3: Encender K3s Workers en paralelo
    Write-Host "`n🔷 PASO 3: Iniciando K3s Workers..." -ForegroundColor Blue
    
    $workers = @("ArcBox-K3s-Data-6c14-Node-00", "ArcBox-K3s-Data-6c14-Node-01", "ArcBox-K3s-Data-6c14-Node-02")
    
    foreach ($worker in $workers) {
        Write-Host "   Iniciando $worker..." -ForegroundColor Cyan
        az vm start --name $worker --resource-group $ResourceGroup --no-wait
    }
    
    Write-Host "⏳ Esperando $WaitTime segundos para que los workers inicien..." -ForegroundColor Gray
    Start-Sleep $WaitTime
    
    # Verificar que todos los workers estén corriendo
    foreach ($worker in $workers) {
        Wait-ForVMRunning -VMName $worker -ResourceGroup $ResourceGroup
    }
    
    # Paso 4: Encender VM Cliente
    Write-Host "`n🔷 PASO 4: Iniciando VM Cliente..." -ForegroundColor Blue
    az vm start --name "ArcBox-Client" --resource-group $ResourceGroup --no-wait
    
    Write-Host "⏳ Esperando $WaitTime segundos..." -ForegroundColor Gray
    Start-Sleep $WaitTime
    
    Wait-ForVMRunning -VMName "ArcBox-Client" -ResourceGroup $ResourceGroup
    
    # Paso 5: Verificaciones finales
    Write-Host "`n🔷 PASO 5: Verificaciones finales..." -ForegroundColor Blue
    
    Write-Host "⏳ Esperando 2 minutos para que todos los servicios inicien..." -ForegroundColor Gray
    Start-Sleep 120
    
    # Verificar conectividad del cliente
    $clientReady = $false
    $attempts = 0
    while (-not $clientReady -and $attempts -lt 5) {
        $attempts++
        Write-Host "   Intento $attempts de verificación del cliente..." -ForegroundColor Gray
        $clientReady = Test-VMConnectivity -VMName "ArcBox-Client" -ResourceGroup $ResourceGroup
        if (-not $clientReady) {
            Start-Sleep 30
        }
    }
    
    # Resumen final
    Write-Host "`n" + "=" * 60 -ForegroundColor Green
    Write-Host "🎉 SECUENCIA DE ENCENDIDO COMPLETADA" -ForegroundColor Green
    Write-Host "=" * 60 -ForegroundColor Green
    
    # Encender clusters AKS
    Write-Host "`n🚀 INICIANDO CLUSTERS AKS..." -ForegroundColor Yellow
    
    $aksStartJobs = @()
    $aksClusters = @("ArcBox-AKS-Data-6c14", "ArcBox-AKS-DR-Data-6c14")
    
    foreach ($cluster in $aksClusters) {
        Write-Host "  ⚡ Iniciando cluster: $cluster" -ForegroundColor Cyan
        $job = Start-Job -ScriptBlock {
            param($clusterName, $resourceGroup)
            az aks start --name $clusterName --resource-group $resourceGroup 2>$null
        } -ArgumentList $cluster, $ResourceGroup
        $aksStartJobs += $job
    }
    
    # Esperar que los clusters estén listos
    Write-Host "  ⏳ Esperando clusters AKS..." -ForegroundColor Cyan
    $aksStartJobs | Wait-Job | Remove-Job
    
    # Verificar estado de clusters
    foreach ($cluster in $aksClusters) {
        try {
            $aksState = az aks show --name $cluster --resource-group $ResourceGroup --query powerState.code -o tsv 2>$null
            if ($aksState -eq "Running") {
                Write-Host "  ✅ $cluster: Running" -ForegroundColor Green
            } else {
                Write-Host "  ⚠️ $cluster: $aksState" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  ❌ $cluster: Error al verificar" -ForegroundColor Red
        }
    }

    Write-Host "`n📊 Estado de las VMs:" -ForegroundColor Cyan
    az vm list --resource-group $ResourceGroup --show-details --query "[].{Name:name,PowerState:powerState,PrivateIP:privateIps}" --output table
    
    Write-Host "`n🔗 Para conectar a la VM Cliente:" -ForegroundColor Yellow
    Write-Host "   1. Ve al Azure Portal" -ForegroundColor White
    Write-Host "   2. Navega a: $ResourceGroup > ArcBox-Client" -ForegroundColor White
    Write-Host "   3. Click 'Connect' > 'Bastion'" -ForegroundColor White
    Write-Host "   4. Usuario: arcdemo | Contraseña: SmartFactory2024!" -ForegroundColor White
    
    Write-Host "`n🎯 Arc Data Services:" -ForegroundColor Yellow
    Write-Host "   • Clusters AKS disponibles para deployment" -ForegroundColor White
    Write-Host "   • Desde Client VM: kubectl config use-context ArcBox-AKS-Data-6c14" -ForegroundColor White
    Write-Host "   • Recomendado usar AKS en lugar de K3s para Arc Data Services" -ForegroundColor White
    
    Write-Host "`n✅ ArcBox DataOps está listo para usar!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error durante el encendido: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Puedes reejecutar el script para reintentar" -ForegroundColor Yellow
}

Write-Host "`n🏁 Script completado - $(Get-Date)" -ForegroundColor Magenta