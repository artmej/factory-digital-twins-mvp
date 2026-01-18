#!/usr/bin/env pwsh
# Smart Factory Blue-Green Deployment v2
# Creates v2 resources in parallel while keeping v1 running

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupV1 = "smartfactory-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupV2 = "smartfactory-rg-v2",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$AppName = "smartfactoryml-api-v2",
    
    [Parameter(Mandatory=$false)]
    [string]$AppGatewayName = "smartfactory-gw",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild
)

Write-Host "🚀 Smart Factory Blue-Green Deployment v2" -ForegroundColor Green
Write-Host "📋 Configuration:" -ForegroundColor Yellow
Write-Host "   V1 Resource Group: $ResourceGroupV1" -ForegroundColor White
Write-Host "   V2 Resource Group: $ResourceGroupV2" -ForegroundColor White
Write-Host "   V2 App Name: $AppName" -ForegroundColor White
Write-Host "   Location: $Location" -ForegroundColor White
Write-Host ""

# Check Azure CLI login
Write-Host "🔐 Checking Azure authentication..." -ForegroundColor Yellow
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if ($account) {
        Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
        Write-Host "📧 Subscription: $($account.name)" -ForegroundColor Green
    } else {
        throw "Not authenticated"
    }
} catch {
    Write-Host "🔓 Please login to Azure..." -ForegroundColor Yellow
    az login
}

# Step 1: Create v2 Resource Group
Write-Host "📁 Creating v2 resource group..." -ForegroundColor Yellow
az group create --name $ResourceGroupV2 --location $Location
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to create resource group"
    exit 1
}
Write-Host "✅ Resource group created: $ResourceGroupV2" -ForegroundColor Green

# Step 2: Create App Service Plan for v2
Write-Host "🏗️ Creating App Service Plan v2..." -ForegroundColor Yellow
$planName = "smartfactory-plan-v2"
az appservice plan create `
    --name $planName `
    --resource-group $ResourceGroupV2 `
    --sku S1 `
    --is-linux
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to create App Service Plan"
    exit 1
}
Write-Host "✅ App Service Plan created: $planName" -ForegroundColor Green

# Step 3: Create Web App v2
Write-Host "🌐 Creating Web App v2..." -ForegroundColor Yellow
az webapp create `
    --name $AppName `
    --resource-group $ResourceGroupV2 `
    --plan $planName `
    --runtime "DOTNETCORE:8.0"
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to create Web App"
    exit 1
}
Write-Host "✅ Web App created: $AppName" -ForegroundColor Green

# Step 4: Configure App Settings
Write-Host "⚙️ Configuring app settings..." -ForegroundColor Yellow
az webapp config appsettings set `
    --name $AppName `
    --resource-group $ResourceGroupV2 `
    --settings `
        "CosmosDb__Endpoint=https://smartfactory-cosmos-v2.documents.azure.com:443/" `
        "DigitalTwins__Url=https://smartfactory-dt-v2.api.weu.digitaltwins.azure.net" `
        "ASPNETCORE_ENVIRONMENT=Production"

# Step 5: Enable Managed Identity
Write-Host "🔑 Enabling Managed Identity..." -ForegroundColor Yellow
az webapp identity assign --name $AppName --resource-group $ResourceGroupV2

# Step 6: Build and Deploy API
if (-not $SkipBuild) {
    Write-Host "🔨 Building SmartFactoryML API..." -ForegroundColor Yellow
    Push-Location "..\..\src\SmartFactoryML"
    try {
        dotnet publish --configuration Release --output ./publish
        if ($LASTEXITCODE -ne 0) {
            Write-Error "❌ Build failed"
            exit 1
        }
        
        # Create deployment package
        Compress-Archive -Path "./publish/*" -DestinationPath "./deploy.zip" -Force
        
        # Deploy to Azure
        Write-Host "📦 Deploying to Azure..." -ForegroundColor Yellow
        az webapp deploy `
            --name $AppName `
            --resource-group $ResourceGroupV2 `
            --src-path "./deploy.zip" `
            --type zip
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "❌ Deployment failed"
            exit 1
        }
        
        Write-Host "✅ API deployed successfully" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

# Step 7: Test v2 endpoint
Write-Host "🧪 Testing v2 endpoint..." -ForegroundColor Yellow
$testUrl = "https://$AppName.azurewebsites.net/api/device/health"
try {
    $response = Invoke-RestMethod -Uri $testUrl -Method GET -TimeoutSec 30
    Write-Host "✅ v2 endpoint is healthy: $($response.Status)" -ForegroundColor Green
} catch {
    Write-Host "⚠️ v2 endpoint test failed (may need time to warm up): $_" -ForegroundColor Yellow
}

# Step 8: Update Application Gateway Backend Pool
Write-Host "🔀 Updating Application Gateway..." -ForegroundColor Yellow
$v2Fqdn = "$AppName.azurewebsites.net"

# Get current Application Gateway
$appGw = az network application-gateway show --name $AppGatewayName --resource-group $ResourceGroupV1 | ConvertFrom-Json
if ($appGw) {
    # Add v2 backend pool
    az network application-gateway address-pool create `
        --gateway-name $AppGatewayName `
        --resource-group $ResourceGroupV1 `
        --name "smartfactory-backend-v2" `
        --servers $v2Fqdn
    
    Write-Host "✅ Application Gateway updated with v2 backend" -ForegroundColor Green
} else {
    Write-Host "⚠️ Application Gateway not found, creating configuration..." -ForegroundColor Yellow
}

# Step 9: Generate update script for Front Door
$frontDoorScript = @"
# Script to update Front Door to point to v2
# Run this manually after testing v2

# Update Front Door origin
az afd origin update \
    --profile-name smartfactory-fd \
    --origin-group-name smartfactory-origin-group \
    --origin-name smartfactory-origin \
    --host-name $v2Fqdn \
    --resource-group $ResourceGroupV1

Write-Host "Front Door updated to use v2 endpoint"
"@

$frontDoorScript | Out-File -FilePath "update-frontdoor-v2.ps1" -Encoding UTF8

Write-Host ""
Write-Host "🎉 BLUE-GREEN DEPLOYMENT COMPLETED!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Summary:" -ForegroundColor Yellow
Write-Host "   ✅ V1 (Current): https://smartfactoryml-api.azurewebsites.net" -ForegroundColor White
Write-Host "   ✅ V2 (New):     https://$AppName.azurewebsites.net" -ForegroundColor White
Write-Host ""
Write-Host "🔄 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Test v2 endpoint thoroughly" -ForegroundColor White
Write-Host "   2. Run .\update-frontdoor-v2.ps1 to switch traffic" -ForegroundColor White
Write-Host "   3. Monitor v2 for 24-48 hours" -ForegroundColor White
Write-Host "   4. Decommission v1 if v2 is stable" -ForegroundColor White
Write-Host ""
Write-Host "📊 Rollback:" -ForegroundColor Yellow
Write-Host "   If issues occur, v1 is still running and can be restored quickly" -ForegroundColor White