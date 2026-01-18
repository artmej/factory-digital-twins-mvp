# Configure RBAC permissions for Smart Factory ML API v2
# This script assigns required permissions to the Managed Identity

param(
    [string]$ResourceGroupV1 = "smartfactory-rg",
    [string]$ResourceGroupV2 = "smartfactory-v2-rg",
    [string]$WebAppName = "smartfactoryml-api-v2"
)

Write-Host "🔑 Configuring RBAC permissions for $WebAppName..." -ForegroundColor Yellow

# Get Managed Identity Principal ID
Write-Host "Getting Managed Identity Principal ID..." -ForegroundColor Cyan
$principalId = az webapp identity show --name $WebAppName --resource-group $ResourceGroupV2 --query principalId -o tsv
if (-not $principalId) {
    Write-Error "❌ Failed to get Managed Identity Principal ID"
    exit 1
}
Write-Host "✅ Principal ID: $principalId" -ForegroundColor Green

# Get Cosmos DB Account resource ID (from v1 resources)
Write-Host "Getting Cosmos DB resource ID..." -ForegroundColor Cyan
$cosmosAccountName = az cosmosdb list --resource-group $ResourceGroupV1 --query "[0].name" -o tsv
$cosmosResourceId = "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$ResourceGroupV1/providers/Microsoft.DocumentDB/databaseAccounts/$cosmosAccountName"
Write-Host "✅ Cosmos DB: $cosmosAccountName" -ForegroundColor Green

# Get Digital Twins resource ID (from v1 resources)
Write-Host "Getting Digital Twins resource ID..." -ForegroundColor Cyan
$dtInstanceName = az dt list --resource-group $ResourceGroupV1 --query "[0].name" -o tsv
$dtResourceId = "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$ResourceGroupV1/providers/Microsoft.DigitalTwins/digitalTwinsInstances/$dtInstanceName"
Write-Host "✅ Digital Twins: $dtInstanceName" -ForegroundColor Green

# Assign Cosmos DB Data Contributor role
Write-Host "Assigning Cosmos DB Data Contributor role..." -ForegroundColor Cyan
$cosmosRoleId = "00000000-0000-0000-0000-000000000002"
$subscriptionId = az account show --query id -o tsv

az role assignment create `
    --assignee $principalId `
    --role $cosmosRoleId `
    --scope $cosmosResourceId

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Cosmos DB Data Contributor role assigned" -ForegroundColor Green
} else {
    Write-Warning "⚠️ Cosmos DB role assignment may have failed (could already exist)"
}

# Assign Digital Twins Data Owner role
Write-Host "Assigning Digital Twins Data Owner role..." -ForegroundColor Cyan
$dtRoleId = "bcd981a7-7f74-457b-83e1-cceb9e632ffe"

az role assignment create `
    --assignee $principalId `
    --role $dtRoleId `
    --scope $dtResourceId

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Digital Twins Data Owner role assigned" -ForegroundColor Green
} else {
    Write-Warning "⚠️ Digital Twins role assignment may have failed (could already exist)"
}

# Verify role assignments
Write-Host "🔍 Verifying role assignments..." -ForegroundColor Cyan
$assignments = az role assignment list --assignee $principalId --query "[].{Role:roleDefinitionName, Scope:scope}" -o table
Write-Host $assignments

Write-Host "✅ RBAC configuration completed for $WebAppName" -ForegroundColor Green
Write-Host "📝 Note: It may take a few minutes for permissions to propagate" -ForegroundColor Yellow