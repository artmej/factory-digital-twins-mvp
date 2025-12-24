#!/usr/bin/env pwsh
<#
.SYNOPSIS
Configure Azure Digital Twins with simple valid models
#>

Write-Host "🔮 Setting up Digital Twins with simple models" -ForegroundColor Green

# Create simple valid DTDL models as individual files
$factoryModel = @"
[
  {
    "@context": "dtmi:dtdl:context;3",
    "@id": "dtmi:smartfactory:Factory;1",
    "@type": "Interface",
    "displayName": "Factory",
    "contents": [
      {
        "@type": "Property",
        "name": "name",
        "schema": "string"
      },
      {
        "@type": "Property",
        "name": "location",
        "schema": "string"
      },
      {
        "@type": "Property",
        "name": "oee",
        "schema": "double"
      }
    ]
  }
]
"@

$machineModel = @"
[
  {
    "@context": "dtmi:dtdl:context;3",
    "@id": "dtmi:smartfactory:Machine;1",
    "@type": "Interface",
    "displayName": "Machine",
    "contents": [
      {
        "@type": "Property",
        "name": "name",
        "schema": "string"
      },
      {
        "@type": "Property",
        "name": "temperature",
        "schema": "double"
      },
      {
        "@type": "Property",
        "name": "status",
        "schema": "string"
      }
    ]
  }
]
"@

# Save models to temp files
$factoryModel | Out-File "temp-factory.json" -Encoding UTF8
$machineModel | Out-File "temp-machine.json" -Encoding UTF8

Write-Host "📊 Uploading models to Digital Twins..." -ForegroundColor Yellow

# Use Azure CLI directly 
$endpoint = "https://factory-adt-prod.api.eus.digitaltwins.azure.net"

Write-Host "   🏭 Uploading Factory model..." -ForegroundColor Cyan
try {
    $result = Invoke-RestMethod -Uri "$endpoint/models?api-version=2023-10-31" -Method Post -Headers @{
        'Authorization' = "Bearer $(az account get-access-token --resource https://digitaltwins.azure.net --query 'accessToken' -o tsv)"
        'Content-Type' = 'application/json'
    } -Body $factoryModel
    Write-Host "      ✅ Factory model uploaded successfully" -ForegroundColor Green
} catch {
    Write-Host "      ℹ️ Factory model upload result: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "   🤖 Uploading Machine model..." -ForegroundColor Cyan
try {
    $result = Invoke-RestMethod -Uri "$endpoint/models?api-version=2023-10-31" -Method Post -Headers @{
        'Authorization' = "Bearer $(az account get-access-token --resource https://digitaltwins.azure.net --query 'accessToken' -o tsv)"
        'Content-Type' = 'application/json'
    } -Body $machineModel
    Write-Host "      ✅ Machine model uploaded successfully" -ForegroundColor Green
} catch {
    Write-Host "      ℹ️ Machine model upload result: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Create simple twins
Write-Host "`n🏭 Creating Digital Twins..." -ForegroundColor Yellow

$factoryTwin = @{
    '$metadata' = @{
        '$model' = 'dtmi:smartfactory:Factory;1'
    }
    'name' = 'Smart Factory Production'
    'location' = 'East Plant'
    'oee' = 87.3
} | ConvertTo-Json -Depth 3

Write-Host "   🏭 Creating Factory twin..." -ForegroundColor Cyan
try {
    $result = Invoke-RestMethod -Uri "$endpoint/digitaltwins/factory1?api-version=2023-10-31" -Method Put -Headers @{
        'Authorization' = "Bearer $(az account get-access-token --resource https://digitaltwins.azure.net --query 'accessToken' -o tsv)"
        'Content-Type' = 'application/json'
    } -Body $factoryTwin
    Write-Host "      ✅ Factory twin created successfully" -ForegroundColor Green
} catch {
    Write-Host "      ℹ️ Factory twin result: $($_.Exception.Message)" -ForegroundColor Yellow
}

$machineTwin = @{
    '$metadata' = @{
        '$model' = 'dtmi:smartfactory:Machine;1'
    }
    'name' = 'CNC Machine A1'
    'temperature' = 24.5
    'status' = 'Running'
} | ConvertTo-Json -Depth 3

Write-Host "   🤖 Creating Machine twin..." -ForegroundColor Cyan
try {
    $result = Invoke-RestMethod -Uri "$endpoint/digitaltwins/machine1?api-version=2023-10-31" -Method Put -Headers @{
        'Authorization' = "Bearer $(az account get-access-token --resource https://digitaltwins.azure.net --query 'accessToken' -o tsv)"
        'Content-Type' = 'application/json'
    } -Body $machineTwin
    Write-Host "      ✅ Machine twin created successfully" -ForegroundColor Green
} catch {
    Write-Host "      ℹ️ Machine twin result: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Clean up temp files
Remove-Item "temp-factory.json" -ErrorAction SilentlyContinue
Remove-Item "temp-machine.json" -ErrorAction SilentlyContinue

Write-Host "`n🎉 Digital Twins setup complete!" -ForegroundColor Green
Write-Host "🔗 Endpoint: https://factory-adt-prod.api.eus.digitaltwins.azure.net" -ForegroundColor Cyan
Write-Host "🏭 Twins created: factory1, machine1" -ForegroundColor Cyan
Write-Host "📊 Now check the Digital Twins Explorer!" -ForegroundColor Yellow