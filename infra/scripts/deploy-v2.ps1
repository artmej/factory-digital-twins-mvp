#!/usr/bin/env pwsh
# Smart Factory Blue-Green Deployment Script
# Deploys new version while preserving existing infrastructure

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "smartfactory-rg-v2",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourcePrefix = "smartfactory",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "v2",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipExistingCheck
)

Write-Host "🚀 Smart Factory Blue-Green Deployment" -ForegroundColor Green
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
        Write-Host "📧 Subscription: $($account.name)" -ForegroundColor Green
    } else {
        throw "Not authenticated"
    }
} catch {
    Write-Host "🔓 Please login to Azure..." -ForegroundColor Yellow
    az login
}

# Check if resource group exists (don't create if it has existing resources)
Write-Host "📁 Checking resource group..." -ForegroundColor Yellow
try {
    $rgExists = az group show --name $ResourceGroup 2>$null
    if ($rgExists) {
        $existingResources = az resource list --resource-group $ResourceGroup --query "length([])" -o tsv
        if ($existingResources -gt 0 -and !$SkipExistingCheck) {
            Write-Warning "⚠️  Resource group $ResourceGroup already has $existingResources resources"
            $confirm = Read-Host "Do you want to continue? This may update existing resources (y/N)"
            if ($confirm -ne 'y' -and $confirm -ne 'Y') {
                Write-Host "❌ Deployment cancelled by user" -ForegroundColor Red
                exit 1
            }
        }
        Write-Host "✅ Resource group exists: $ResourceGroup" -ForegroundColor Green
    } else {
        Write-Host "📁 Creating resource group: $ResourceGroup" -ForegroundColor Yellow
        az group create --name $ResourceGroup --location $Location
        Write-Host "✅ Resource group created" -ForegroundColor Green
    }
} catch {
    Write-Error "❌ Failed to handle resource group: $_"
    exit 1
}

# Deploy Bicep template
Write-Host "🏗️ Deploying new infrastructure..." -ForegroundColor Green
$deploymentName = "smartfactory-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$bicepFile = "../bicep/main.bicep"

if (-not (Test-Path $bicepFile)) {
    Write-Error "❌ Bicep template not found: $bicepFile"
    exit 1
}

Write-Host "📋 Deployment name: $deploymentName" -ForegroundColor Blue

try {
    Write-Host "⏳ Starting deployment (this may take 5-10 minutes)..." -ForegroundColor Yellow
    
    $deployment = az deployment group create `
        --resource-group $ResourceGroup `
        --name $deploymentName `
        --template-file $bicepFile `
        --parameters location=$Location resourcePrefix=$ResourcePrefix environment=$Environment `
        --output json | ConvertFrom-Json

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Infrastructure deployment completed!" -ForegroundColor Green
    } else {
        throw "Deployment failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Error "❌ Deployment failed: $_"
    exit 1
}

# Get deployment outputs
Write-Host "📋 Retrieving deployment outputs..." -ForegroundColor Yellow
try {
    $outputs = az deployment group show --resource-group $ResourceGroup --name $deploymentName --query "properties.outputs" --output json | ConvertFrom-Json

    $digitalTwinsName = $outputs.digitalTwinsName.value
    $digitalTwinsUrl = $outputs.digitalTwinsUrl.value
    $iotHubName = $outputs.iotHubName.value
    $functionAppName = $outputs.functionAppName.value
    $deviceConnectionString = $outputs.deviceConnectionString.value
    $iotHubConnectionString = $outputs.iotHubConnectionString.value

    Write-Host "📊 Deployment Results:" -ForegroundColor Green
    Write-Host "   Digital Twins: $digitalTwinsName" -ForegroundColor White
    Write-Host "   Digital Twins URL: $digitalTwinsUrl" -ForegroundColor White
    Write-Host "   IoT Hub: $iotHubName" -ForegroundColor White
    Write-Host "   Function App: $functionAppName" -ForegroundColor White
    Write-Host ""

    # Create configuration file
    $configContent = @"
# Smart Factory V2 Configuration
# Generated on $(Get-Date)

# Resource Information
RESOURCE_GROUP=$ResourceGroup
LOCATION=$Location
DEPLOYMENT_NAME=$deploymentName

# Azure Resources V2
DIGITAL_TWINS_NAME_V2=$digitalTwinsName
DIGITAL_TWINS_URL_V2=$digitalTwinsUrl
IOT_HUB_NAME_V2=$iotHubName
FUNCTION_APP_NAME_V2=$functionAppName

# Connection Strings V2
DEVICE_CONNECTION_STRING_V2="$deviceConnectionString"
IOTHUB_CONNECTION_STRING_V2="$iotHubConnectionString"

# New API Endpoints (for Gateway remapping)
NEW_ML_API_URL=https://$functionAppName.azurewebsites.net
NEW_IOT_API_URL=https://$iotHubName-api.azurewebsites.net
NEW_DATA_API_URL=https://$functionAppName-data.azurewebsites.net

# Use these for Gateway/Front Door configuration
"@

    $configContent | Out-File -FilePath "smartfactory-v2-config.env" -Encoding UTF8
    Write-Host "💾 Configuration saved to: smartfactory-v2-config.env" -ForegroundColor Green

} catch {
    Write-Warning "⚠️ Could not retrieve all deployment outputs, but deployment was successful"
}

Write-Host ""
Write-Host "🎉 Blue-Green Deployment Completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Deploy your application code to the new Function App" -ForegroundColor White
Write-Host "   2. Update Application Gateway/Front Door to point to new endpoints" -ForegroundColor White
Write-Host "   3. Test the new version thoroughly" -ForegroundColor White
Write-Host "   4. Switch traffic gradually (blue-green strategy)" -ForegroundColor White
Write-Host "   5. Keep old resources as backup until confident" -ForegroundColor White
Write-Host ""
Write-Host "🔄 Rollback Strategy:" -ForegroundColor Cyan
Write-Host "   - Old resources remain untouched" -ForegroundColor White
Write-Host "   - Simply revert Gateway/Front Door configuration" -ForegroundColor White
Write-Host "   - Delete new resource group if needed: az group delete --name $ResourceGroup" -ForegroundColor White
Write-Host ""