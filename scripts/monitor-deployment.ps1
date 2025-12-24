#!/usr/bin/env pwsh
<#
.SYNOPSIS
Monitor Smart Factory deployment status
.DESCRIPTION
Checks the status of Azure resources and deployment progress
#>

param(
    [string]$ResourceGroupName = "rg-smart-factory-prod"
)

Write-Host "🔍 Smart Factory Deployment Status Monitor" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Cyan

# Check resource group status
Write-Host "`n📁 Resource Group Status:" -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "true") {
    Write-Host "   ✅ Resource Group: $ResourceGroupName exists" -ForegroundColor Green
    
    # List resources in the group
    Write-Host "`n📊 Resources in group:" -ForegroundColor Cyan
    az resource list --resource-group $ResourceGroupName --output table
    
} else {
    Write-Host "   ❌ Resource Group: $ResourceGroupName does not exist" -ForegroundColor Red
}

# Check deployment status
Write-Host "`n🚀 Deployment Status:" -ForegroundColor Yellow
$deployments = az deployment group list --resource-group $ResourceGroupName --output json | ConvertFrom-Json

if ($deployments) {
    foreach ($deployment in $deployments) {
        $status = $deployment.properties.provisioningState
        $name = $deployment.name
        $timestamp = $deployment.properties.timestamp
        
        switch ($status) {
            "Running" { 
                Write-Host "   🔄 $name : $status (Started: $timestamp)" -ForegroundColor Yellow 
            }
            "Succeeded" { 
                Write-Host "   ✅ $name : $status (Completed: $timestamp)" -ForegroundColor Green 
            }
            "Failed" { 
                Write-Host "   ❌ $name : $status (Failed: $timestamp)" -ForegroundColor Red 
            }
            default { 
                Write-Host "   ⏳ $name : $status (Updated: $timestamp)" -ForegroundColor Cyan 
            }
        }
    }
} else {
    Write-Host "   ℹ️ No deployments found" -ForegroundColor Gray
}

# Check specific service status
Write-Host "`n🔍 Service Health Check:" -ForegroundColor Yellow

# Digital Twins
$adtName = "factory-adt-prod"
Write-Host "   🔮 Digital Twins ($adtName):" -ForegroundColor Cyan
try {
    $adt = az dt show --dt-name $adtName --query "{name:name, status:provisioningState, endpoint:hostName}" 2>$null
    if ($adt) {
        Write-Host "      ✅ Azure Digital Twins is running" -ForegroundColor Green
    }
} catch {
    Write-Host "      ⏳ Azure Digital Twins not ready yet" -ForegroundColor Yellow
}

# IoT Hub
$iotHubName = "factory-iothub-prod"
Write-Host "   🌐 IoT Hub ($iotHubName):" -ForegroundColor Cyan
try {
    $iot = az iot hub show --name $iotHubName --query "{name:name, state:state, tier:sku.tier}" 2>$null
    if ($iot) {
        Write-Host "      ✅ IoT Hub is active" -ForegroundColor Green
    }
} catch {
    Write-Host "      ⏳ IoT Hub not ready yet" -ForegroundColor Yellow
}

# Function App
$functionAppName = "factory-func-adt-prod"
Write-Host "   ⚡ Function App ($functionAppName):" -ForegroundColor Cyan
try {
    $func = az functionapp show --name $functionAppName --resource-group $ResourceGroupName --query "{name:name, state:state, defaultHostName:defaultHostName}" 2>$null
    if ($func) {
        Write-Host "      ✅ Function App is running" -ForegroundColor Green
    }
} catch {
    Write-Host "      ⏳ Function App not ready yet" -ForegroundColor Yellow
}

# Machine Learning Workspace
$mlWorkspaceName = "factory-ml-prod"
Write-Host "   🤖 ML Workspace ($mlWorkspaceName):" -ForegroundColor Cyan
try {
    $ml = az ml workspace show --name $mlWorkspaceName --resource-group $ResourceGroupName --query "{name:name, provisioningState:provisioningState}" 2>$null
    if ($ml) {
        Write-Host "      ✅ ML Workspace is provisioned" -ForegroundColor Green
    }
} catch {
    Write-Host "      ⏳ ML Workspace not ready yet" -ForegroundColor Yellow
}

Write-Host "`n📊 Overall Status Summary:" -ForegroundColor Yellow
Write-Host "   🏗️ Infrastructure deployment in progress..." -ForegroundColor Cyan
Write-Host "   ⏱️ Estimated completion time: 15-20 minutes" -ForegroundColor Cyan
Write-Host "   🔄 Run this script again to check updated status" -ForegroundColor Cyan

Write-Host "`n🎯 Next Steps after deployment completes:" -ForegroundColor Green
Write-Host "   1. Deploy Function App code" -ForegroundColor White
Write-Host "   2. Upload Digital Twins models" -ForegroundColor White
Write-Host "   3. Deploy mobile app" -ForegroundColor White
Write-Host "   4. Start real-time monitoring" -ForegroundColor White

Write-Host "`n🚀 Run .\scripts\deploy-mobile-app.ps1 when ready for mobile deployment" -ForegroundColor Cyan