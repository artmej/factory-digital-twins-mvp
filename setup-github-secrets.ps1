# Azure Credentials Setup for GitHub Actions
# Run this script to configure GitHub secrets for CI/CD

Write-Host "🔐 Setting up GitHub Secrets for CI/CD" -ForegroundColor Cyan

# Create Azure Service Principal
Write-Host "Creating Azure Service Principal..." -ForegroundColor Yellow
$subscriptionId = az account show --query id -o tsv
$spOutput = az ad sp create-for-rbac --name "smart-factory-github-actions" --role contributor --scopes /subscriptions/$subscriptionId/resourceGroups/smart-factory-v2-rg --sdk-auth

Write-Host "✅ Service Principal created" -ForegroundColor Green
Write-Host "
🔑 Add this as AZURE_CREDENTIALS secret in GitHub:" -ForegroundColor Yellow
Write-Host $spOutput

Write-Host "
📋 Additional secrets to add:" -ForegroundColor Yellow
Write-Host "AZURE_SUBSCRIPTION_ID: $subscriptionId"
Write-Host "AZURE_RESOURCE_GROUP: smart-factory-v2-rg"
Write-Host "AZURE_WEBAPP_NAME: smartfactory-prod-webapp-blue"
Write-Host "AZURE_FUNCTIONAPP_NAME: smartfactory-prod-func-blue"
