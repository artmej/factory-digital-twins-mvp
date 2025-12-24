# DEPLOY AZURE LOCAL COMPLETE
# Automated deployment script for today's session

param(
    [string]$ResourceGroup = "rg-azlocal-working",
    [string]$Location = "Central US"
)

Write-Host "🚀 DEPLOYING AZURE LOCAL COMPLETE" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

# Check Azure CLI
try {
    $account = az account show | ConvertFrom-Json
    Write-Host "✅ Azure CLI logged in as: $($account.user.name)" -ForegroundColor Green
} catch {
    Write-Host "❌ Please login: az login" -ForegroundColor Red
    exit 1
}

# Check if resource group exists, create if not
Write-Host "📁 Checking resource group..." -ForegroundColor Yellow
$rg = az group show --name $ResourceGroup 2>$null | ConvertFrom-Json
if (-not $rg) {
    Write-Host "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
    az group create --name $ResourceGroup --location $Location | Out-Null
    Write-Host "✅ Resource group created" -ForegroundColor Green
} else {
    Write-Host "✅ Resource group exists: $ResourceGroup" -ForegroundColor Green
}

# Deploy template
Write-Host "🏗️ Deploying Azure Local infrastructure..." -ForegroundColor Yellow
Write-Host "   This will take 10-15 minutes..." -ForegroundColor Cyan

$deploymentName = "azlocal-deploy-$(Get-Date -Format 'yyyyMMddHHmm')"

try {
    $deployment = az deployment group create `
        --resource-group $ResourceGroup `
        --template-file "azure-local-working.bicep" `
        --parameters "azure-local-working.parameters.json" `
        --name $deploymentName `
        --output json | ConvertFrom-Json

    if ($deployment.properties.provisioningState -eq "Succeeded") {
        Write-Host ""
        Write-Host "🎯 DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
        Write-Host "=========================" -ForegroundColor Green
        
        $outputs = $deployment.properties.outputs
        
        Write-Host ""
        Write-Host "📋 CONNECTION INFO:" -ForegroundColor Cyan
        Write-Host "VM Public IP: $($outputs.vmPublicIP.value)" -ForegroundColor White
        Write-Host "VM FQDN: $($outputs.vmFQDN.value)" -ForegroundColor White
        Write-Host "RDP Command: $($outputs.rdpConnection.value)" -ForegroundColor White
        Write-Host "Username: azlocal" -ForegroundColor White
        Write-Host "Password: AzureLocal2024!" -ForegroundColor White
        
        Write-Host ""
        Write-Host "🌐 IOT HUB:" -ForegroundColor Cyan
        Write-Host "IoT Hub Name: $($outputs.iotHubName.value)" -ForegroundColor White
        Write-Host "Connection String: $($outputs.iotHubConnectionString.value)" -ForegroundColor Gray
        
        Write-Host ""
        Write-Host "📖 NEXT STEPS:" -ForegroundColor Yellow
        Write-Host "1. RDP to VM: $($outputs.vmPublicIP.value)" -ForegroundColor White
        Write-Host "2. Copy Setup-AzureLocalComplete.ps1 to VM" -ForegroundColor White
        Write-Host "3. Run setup script in VM with IoT Hub connection string" -ForegroundColor White
        Write-Host "4. Follow interactive prompts to install Arc/AKS/IoT Edge" -ForegroundColor White
        
        Write-Host ""
        Write-Host "🎮 DEMO READY!" -ForegroundColor Green
        Write-Host "Complete Azure Local simulation with:" -ForegroundColor Cyan
        Write-Host "  ✅ Azure VM (Windows Server 2022)" -ForegroundColor Green
        Write-Host "  ✅ Azure IoT Hub (ready for telemetry)" -ForegroundColor Green
        Write-Host "  ✅ Azure Arc Agent (optional)" -ForegroundColor Green
        Write-Host "  ✅ AKS Edge Essentials (kubernetes)" -ForegroundColor Green
        Write-Host "  ✅ IoT Edge Runtime (manufacturing)" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "🔗 Copy this command to connect:" -ForegroundColor Yellow
        Write-Host $outputs.rdpConnection.value -ForegroundColor White
        
    } else {
        Write-Host "❌ DEPLOYMENT FAILED!" -ForegroundColor Red
        Write-Host $deployment.properties.error -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ DEPLOYMENT ERROR: $($_.Exception.Message)" -ForegroundColor Red
    
    # Show deployment status
    Write-Host "Checking deployment status..." -ForegroundColor Yellow
    az deployment group show --resource-group $ResourceGroup --name $deploymentName --query "properties.error" --output json
}

Write-Host ""
Write-Host "🏁 Deployment script completed." -ForegroundColor Green