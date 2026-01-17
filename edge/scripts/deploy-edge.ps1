#!/usr/bin/env pwsh
# Smart Factory Edge Deployment Script
# Deploys modules to IoT Edge devices

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$IoTHubName,
    
    [Parameter(Mandatory=$true)]
    [string]$EdgeDeviceId,
    
    [Parameter(Mandatory=$false)]
    [string]$DeploymentManifest = "../deployment-complete.json",
    
    [Parameter(Mandatory=$false)]
    [string]$RegistryName = "smartfactoryregistry"
)

Write-Host "🚀 Starting Smart Factory Edge Deployment" -ForegroundColor Green

# Validate prerequisites
Write-Host "📋 Validating prerequisites..." -ForegroundColor Yellow

# Check if Azure CLI is installed
try {
    az version | Out-Null
    Write-Host "✅ Azure CLI found" -ForegroundColor Green
} catch {
    Write-Error "❌ Azure CLI not found. Please install Azure CLI"
    exit 1
}

# Check if IoT extension is installed
try {
    az extension list --query "[?name=='azure-iot'].name" -o tsv | Out-Null
    if (-not $?) {
        Write-Host "📦 Installing Azure IoT CLI extension..." -ForegroundColor Yellow
        az extension add --name azure-iot
    }
    Write-Host "✅ Azure IoT CLI extension ready" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to install Azure IoT CLI extension"
    exit 1
}

# Login check
Write-Host "🔐 Checking Azure login status..." -ForegroundColor Yellow
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if ($account) {
        Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
    } else {
        Write-Host "🔓 Not logged in. Starting login process..." -ForegroundColor Yellow
        az login
    }
} catch {
    Write-Host "🔓 Login required. Starting login process..." -ForegroundColor Yellow
    az login
}

# Verify deployment manifest exists
if (-not (Test-Path $DeploymentManifest)) {
    Write-Error "❌ Deployment manifest not found: $DeploymentManifest"
    exit 1
}
Write-Host "✅ Deployment manifest found: $DeploymentManifest" -ForegroundColor Green

# Get IoT Hub connection string
Write-Host "🔗 Getting IoT Hub connection string..." -ForegroundColor Yellow
try {
    $iotHubConnString = az iot hub connection-string show --hub-name $IoTHubName --resource-group $ResourceGroup --query "connectionString" -o tsv
    if (-not $iotHubConnString) {
        throw "Failed to get connection string"
    }
    Write-Host "✅ IoT Hub connection string retrieved" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to get IoT Hub connection string. Check resource group and hub name."
    exit 1
}

# Check if Edge device exists
Write-Host "🎯 Checking Edge device: $EdgeDeviceId" -ForegroundColor Yellow
try {
    $device = az iot hub device-identity show --hub-name $IoTHubName --device-id $EdgeDeviceId 2>$null | ConvertFrom-Json
    if ($device) {
        Write-Host "✅ Edge device found: $EdgeDeviceId" -ForegroundColor Green
        if ($device.capabilities.iotEdge -ne $true) {
            Write-Warning "⚠️ Device $EdgeDeviceId is not configured as an IoT Edge device"
        }
    } else {
        Write-Host "➕ Creating Edge device: $EdgeDeviceId" -ForegroundColor Yellow
        az iot hub device-identity create --hub-name $IoTHubName --device-id $EdgeDeviceId --edge-enabled
        Write-Host "✅ Edge device created: $EdgeDeviceId" -ForegroundColor Green
    }
} catch {
    Write-Error "❌ Failed to check/create Edge device"
    exit 1
}

# Get container registry credentials
Write-Host "🗝️ Getting container registry credentials..." -ForegroundColor Yellow
try {
    $registryServer = az acr show --name $RegistryName --query "loginServer" -o tsv 2>$null
    if ($registryServer) {
        $registryUser = az acr credential show --name $RegistryName --query "username" -o tsv
        $registryPassword = az acr credential show --name $RegistryName --query "passwords[0].value" -o tsv
        Write-Host "✅ Container registry credentials retrieved" -ForegroundColor Green
    } else {
        Write-Warning "⚠️ Container registry $RegistryName not found. Using manifest as-is."
    }
} catch {
    Write-Warning "⚠️ Could not retrieve container registry credentials"
}

# Process deployment manifest
Write-Host "📝 Processing deployment manifest..." -ForegroundColor Yellow
$manifestContent = Get-Content $DeploymentManifest -Raw

# Replace environment variables if registry credentials are available
if ($registryUser -and $registryPassword) {
    $manifestContent = $manifestContent -replace '\$CONTAINER_REGISTRY_USERNAME', $registryUser
    $manifestContent = $manifestContent -replace '\$CONTAINER_REGISTRY_PASSWORD', $registryPassword
    Write-Host "✅ Manifest processed with registry credentials" -ForegroundColor Green
} else {
    Write-Host "ℹ️ Manifest processed without registry credentials" -ForegroundColor Blue
}

# Save processed manifest
$processedManifest = "deployment-processed.json"
$manifestContent | Out-File -FilePath $processedManifest -Encoding UTF8

# Deploy to Edge device
Write-Host "🚀 Deploying modules to Edge device..." -ForegroundColor Green
try {
    az iot edge set-modules --hub-name $IoTHubName --device-id $EdgeDeviceId --content $processedManifest
    Write-Host "✅ Deployment successful!" -ForegroundColor Green
} catch {
    Write-Error "❌ Deployment failed: $_"
    exit 1
} finally {
    # Clean up processed manifest
    if (Test-Path $processedManifest) {
        Remove-Item $processedManifest
    }
}

# Verify deployment
Write-Host "🔍 Verifying deployment..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

try {
    $modules = az iot hub module-identity list --hub-name $IoTHubName --device-id $EdgeDeviceId | ConvertFrom-Json
    Write-Host "📦 Deployed modules:" -ForegroundColor Cyan
    foreach ($module in $modules) {
        Write-Host "  - $($module.moduleId)" -ForegroundColor White
    }
} catch {
    Write-Warning "⚠️ Could not verify deployed modules"
}

Write-Host ""
Write-Host "🎉 Smart Factory Edge deployment completed!" -ForegroundColor Green
Write-Host "📊 Monitor deployment status with: az iot hub monitor-events --hub-name $IoTHubName --device-id $EdgeDeviceId" -ForegroundColor Blue