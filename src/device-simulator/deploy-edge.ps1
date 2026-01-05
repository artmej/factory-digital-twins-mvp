# 📦 Deploy Edge Simulator to Azure
param(
    [string]$ResourceGroupName = "smart-factory-v2-rg",
    [string]$AppName = "smart-factory-edge-simulator",
    [switch]$BuildDocker = $true
)

Write-Host "📦 Deploying Smart Factory Edge Simulator" -ForegroundColor Cyan

if ($BuildDocker) {
    Write-Host "🐳 Building Docker image..." -ForegroundColor Yellow
    docker build -f Dockerfile-enhanced -t smart-factory-simulator:latest .
}

# Deploy to Azure Container Instances
Write-Host "☁️ Deploying to Azure Container Instances..." -ForegroundColor Yellow
az container create \\
    --resource-group $ResourceGroupName \\
    --name $AppName \\
    --image smart-factory-simulator:latest \\
    --dns-name-label $AppName \\
    --ports 3000 \\
    --cpu 1 \\
    --memory 2 \\
    --environment-variables \\
        NODE_ENV=production \\
        AUTO_START=true \\
        DEVICE_COUNT=10

Write-Host "✅ Deployment completed!" -ForegroundColor Green
Write-Host "🌐 Access dashboard at: http://$AppName.$Location.azurecontainer.io:3000" -ForegroundColor Cyan
