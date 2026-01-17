#!/usr/bin/env pwsh
# Smart Factory Simple Deployment (without Function App due to storage restrictions)

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "smartfactory-v2-simple",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourcePrefix = "smartfactory",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "v2"
)

Write-Host "🚀 Smart Factory Simple Deployment (Core Services Only)" -ForegroundColor Green
Write-Host "📋 Configuration:" -ForegroundColor Yellow
Write-Host "   Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "   Location: $Location" -ForegroundColor White
Write-Host "   Prefix: $ResourcePrefix" -ForegroundColor White
Write-Host "   Environment: $Environment" -ForegroundColor White
Write-Host ""

# Check Azure CLI login
Write-Host "🔐 Checking Azure authentication..." -ForegroundColor Yellow
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if ($account) {
        Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
    } else {
        throw "Not authenticated"
    }
} catch {
    Write-Host "🔓 Please login to Azure..." -ForegroundColor Yellow
    az login
}

# Create resource group
Write-Host "📁 Creating resource group..." -ForegroundColor Yellow
try {
    az group create --name $ResourceGroup --location $Location
    Write-Host "✅ Resource group created" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Resource group may already exist" -ForegroundColor Yellow
}

# Deploy simple template
Write-Host "🏗️ Deploying core infrastructure..." -ForegroundColor Green
$deploymentName = "smartfactory-simple-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$bicepFile = "../bicep/simple-deploy.bicep"

try {
    Write-Host "⏳ Starting deployment..." -ForegroundColor Yellow
    
    az deployment group create `
        --resource-group $ResourceGroup `
        --name $deploymentName `
        --template-file $bicepFile `
        --parameters location=$Location resourcePrefix=$ResourcePrefix environment=$Environment

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Infrastructure deployment completed!" -ForegroundColor Green
    } else {
        throw "Deployment failed"
    }
} catch {
    Write-Error "❌ Deployment failed: $_"
    exit 1
}

# Get outputs
Write-Host "📋 Retrieving deployment outputs..." -ForegroundColor Yellow
try {
    $outputs = az deployment group show --resource-group $ResourceGroup --name $deploymentName --query "properties.outputs" --output json | ConvertFrom-Json

    Write-Host ""
    Write-Host "🎉 Deployment Successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Resources Created:" -ForegroundColor Cyan
    Write-Host "   Digital Twins: $($outputs.digitalTwinsName.value)" -ForegroundColor White
    Write-Host "   Digital Twins URL: $($outputs.digitalTwinsUrl.value)" -ForegroundColor White
    Write-Host "   IoT Hub: $($outputs.iotHubName.value)" -ForegroundColor White
    Write-Host ""
    
    # Update dashboard configurations with new endpoints
    Write-Host "🔄 Updating dashboard configurations..." -ForegroundColor Yellow
    
    $newConfig = @"
# New V2 Endpoints for Dashboard Configuration
NEW_DIGITAL_TWINS_URL=$($outputs.digitalTwinsUrl.value)
NEW_IOT_HUB_NAME=$($outputs.iotHubName.value)

# Update these in AZURE_ARCHITECTURE:
# digitalTwinsAPI: "$($outputs.digitalTwinsUrl.value)"
# iotAPI: "https://$($outputs.iotHubName.value)-api.azurewebsites.net"
"@

    $newConfig | Out-File -FilePath "v2-endpoints.txt" -Encoding UTF8
    Write-Host "💾 New endpoints saved to: v2-endpoints.txt" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. ✅ Core infrastructure deployed (Digital Twins + IoT Hub)" -ForegroundColor White
    Write-Host "   2. 🔄 Update dashboard URLs in AZURE_ARCHITECTURE configuration" -ForegroundColor White
    Write-Host "   3. 🚀 Deploy your ML API separately as WebApp" -ForegroundColor White
    Write-Host "   4. 🔗 Update Application Gateway to point to new endpoints" -ForegroundColor White
    
} catch {
    Write-Warning "⚠️ Could not retrieve outputs, but deployment may have succeeded"
}

Write-Host ""
Write-Host "✨ Simple deployment completed!" -ForegroundColor Green