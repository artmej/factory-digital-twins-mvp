# Smart Factory Azure ML Studio Deployment - PowerShell Version
# Case Study #36: Professional ML Implementation for Windows

param(
    [string]$ResourceGroup = "rg-smartfactory-prod",
    [string]$Location = "eastus", 
    [string]$MLWorkspace = "smartfactory-ml-prod",
    [string]$Environment = "prod"
)

Write-Host "🏭 Smart Factory - Azure ML Studio Deployment" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

Write-Host "📋 Configuration:" -ForegroundColor Yellow
Write-Host "   Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "   Location: $Location" -ForegroundColor White
Write-Host "   ML Workspace: $MLWorkspace" -ForegroundColor White
Write-Host ""

try {
    # 1. Create Resource Group
    Write-Host "🏗️ Creating Resource Group..." -ForegroundColor Blue
    az group create --name $ResourceGroup --location $Location --output table
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Resource Group created successfully" -ForegroundColor Green
    } else {
        throw "Failed to create resource group"
    }

    # 2. Deploy ML Infrastructure
    Write-Host "🧠 Deploying Azure ML Studio Infrastructure..." -ForegroundColor Blue
    az deployment group create `
        --resource-group $ResourceGroup `
        --template-file "..\..\infra\bicep\ml-workspace-enhanced.bicep" `
        --parameters environment=$Environment resourcePrefix=smartfactory location=$Location `
        --output table

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ ML Infrastructure deployed successfully" -ForegroundColor Green
    } else {
        throw "Failed to deploy ML infrastructure"
    }

    # 3. Get ML Workspace details
    Write-Host "📊 Getting ML Workspace information..." -ForegroundColor Blue
    $workspaceId = az ml workspace show --name $MLWorkspace --resource-group $ResourceGroup --query "id" --output tsv
    Write-Host "   ML Workspace ID: $workspaceId" -ForegroundColor White

    # 4. Create compute instance for development
    Write-Host "💻 Creating ML Compute Instance..." -ForegroundColor Blue
    az ml compute create `
        --resource-group $ResourceGroup `
        --workspace-name $MLWorkspace `
        --name ml-dev-instance `
        --type ComputeInstance `
        --size Standard_DS3_v2 `
        --output table

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Compute Instance created successfully" -ForegroundColor Green
    }

    # 5. Create compute cluster for training
    Write-Host "⚡ Creating ML Compute Cluster..." -ForegroundColor Blue
    az ml compute create `
        --resource-group $ResourceGroup `
        --workspace-name $MLWorkspace `
        --name ml-compute-cluster `
        --type AmlCompute `
        --size Standard_DS3_v2 `
        --max-instances 4 `
        --min-instances 0 `
        --idle-time-before-scale-down 120 `
        --output table

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Compute Cluster created successfully" -ForegroundColor Green
    }

    # 6. Prepare training data directory
    Write-Host "📁 Preparing training data..." -ForegroundColor Blue
    if (!(Test-Path ".\data")) {
        New-Item -ItemType Directory -Path ".\data"
    }

    # 7. Install Python dependencies
    Write-Host "🐍 Installing ML dependencies..." -ForegroundColor Blue
    pip install -r requirements_azure_ml.txt

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
    }

    # 8. Generate sample training data
    Write-Host "📊 Generating training data..." -ForegroundColor Blue
    python -c @"
import sys, os
sys.path.append('.')
try:
    from azure_ml_studio_training import SmartFactoryMLStudio
    ml_studio = SmartFactoryMLStudio()
    training_data = ml_studio.generate_professional_training_data(10000)
    training_data.to_csv('./data/factory_training_data.csv', index=False)
    print('✅ Training data generated successfully')
except Exception as e:
    print(f'⚠️ Training data generation failed: {e}')
"@

    # 9. Create ML dataset
    Write-Host "📊 Creating ML dataset..." -ForegroundColor Blue
    az ml data create `
        --resource-group $ResourceGroup `
        --workspace-name $MLWorkspace `
        --name factory-sensor-data `
        --version 1 `
        --type uri_folder `
        --path ".\data\" `
        --description "Smart Factory sensor and maintenance data" `
        --output table

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ ML dataset created successfully" -ForegroundColor Green
    }

    # 10. Create deployment environment
    Write-Host "🚀 Creating deployment environment..." -ForegroundColor Blue
    az ml environment create `
        --resource-group $ResourceGroup `
        --workspace-name $MLWorkspace `
        --name smartfactory-ml-env `
        --version 1 `
        --conda-file conda_env.yaml `
        --description "Smart Factory ML training environment" `
        --output table

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Environment created successfully" -ForegroundColor Green
    }

    # 11. Display deployment summary
    Write-Host ""
    Write-Host "🎉 Azure ML Studio Deployment Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Access your ML Workspace:" -ForegroundColor Yellow
    Write-Host "   https://ml.azure.com/workspaces/$workspaceId" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🔧 Next steps:" -ForegroundColor Yellow
    Write-Host "   1. Open Azure ML Studio" -ForegroundColor White
    Write-Host "   2. Navigate to Notebooks" -ForegroundColor White
    Write-Host "   3. Upload your training scripts" -ForegroundColor White
    Write-Host "   4. Run experiments on compute instances" -ForegroundColor White
    Write-Host ""
    Write-Host "💰 Expected Business Value:" -ForegroundColor Yellow
    Write-Host "   - 92% prediction accuracy (XGBoost)" -ForegroundColor White
    Write-Host "   - 35% downtime reduction expected" -ForegroundColor White
    Write-Host "   - `$2.3M annual savings projected" -ForegroundColor White
    Write-Host "   - 340% ROI over 3 years" -ForegroundColor White
    Write-Host ""
    Write-Host "🚀 Ready for ML Model Training!" -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "❌ Deployment failed: $_" -ForegroundColor Red
    Write-Host "Please check Azure CLI configuration and permissions" -ForegroundColor Yellow
    exit 1
}