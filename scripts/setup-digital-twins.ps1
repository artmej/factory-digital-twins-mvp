#!/usr/bin/env pwsh
<#
.SYNOPSIS
Configure Azure Digital Twins with Smart Factory models
#>

param(
    [string]$AdtName = "factory-adt-prod"
)

Write-Host "🔮 Configuring Azure Digital Twins for Smart Factory" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan

# 1. Upload DTDL models using REST API (avoiding extension issues)
Write-Host "`n📊 Uploading Smart Factory models..." -ForegroundColor Yellow

$endpoint = "https://$AdtName.api.eus.digitaltwins.azure.net"

# Get access token
Write-Host "   🔐 Getting authentication token..." -ForegroundColor Cyan
$token = az account get-access-token --resource https://digitaltwins.azure.net --query "accessToken" --output tsv

$headers = @{
    'Authorization' = "Bearer $token"
    'Content-Type' = 'application/json'
}

# Upload Factory model
Write-Host "   🏭 Uploading Factory model..." -ForegroundColor Cyan
$factoryModel = Get-Content "models/factory.dtdl.json" -Raw
try {
    Invoke-RestMethod -Uri "$endpoint/models" -Method Post -Headers $headers -Body $factoryModel
    Write-Host "      ✅ Factory model uploaded" -ForegroundColor Green
} catch {
    Write-Host "      ⚠️ Factory model already exists or error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Upload Line model  
Write-Host "   🔄 Uploading Line model..." -ForegroundColor Cyan
$lineModel = Get-Content "models/line.dtdl.json" -Raw
try {
    Invoke-RestMethod -Uri "$endpoint/models" -Method Post -Headers $headers -Body $lineModel
    Write-Host "      ✅ Line model uploaded" -ForegroundColor Green
} catch {
    Write-Host "      ⚠️ Line model already exists or error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Upload Machine model
Write-Host "   🤖 Uploading Machine model..." -ForegroundColor Cyan
$machineModel = Get-Content "models/machine.dtdl.json" -Raw
try {
    Invoke-RestMethod -Uri "$endpoint/models" -Method Post -Headers $headers -Body $machineModel
    Write-Host "      ✅ Machine model uploaded" -ForegroundColor Green
} catch {
    Write-Host "      ⚠️ Machine model already exists or error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Upload Sensor model
Write-Host "   📡 Uploading Sensor model..." -ForegroundColor Cyan
$sensorModel = Get-Content "models/sensor.dtdl.json" -Raw
try {
    Invoke-RestMethod -Uri "$endpoint/models" -Method Post -Headers $headers -Body $sensorModel
    Write-Host "      ✅ Sensor model uploaded" -ForegroundColor Green
} catch {
    Write-Host "      ⚠️ Sensor model already exists or error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 2. Create Digital Twin instances
Write-Host "`n🏭 Creating Digital Twin instances..." -ForegroundColor Yellow

# Create Factory twin
Write-Host "   🏭 Creating Factory twin..." -ForegroundColor Cyan
$factoryTwin = @{
    '$metadata' = @{
        '$model' = 'dtmi:smartfactory:Factory;1'
    }
    'name' = 'Smart Factory #1'
    'location' = 'Plant-East'
    'oee' = 87.3
    'status' = 'Running'
} | ConvertTo-Json -Depth 3

try {
    Invoke-RestMethod -Uri "$endpoint/digitaltwins/factory1" -Method Put -Headers $headers -Body $factoryTwin
    Write-Host "      ✅ Factory twin created" -ForegroundColor Green
} catch {
    Write-Host "      ⚠️ Factory twin exists or error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Create Line twin
Write-Host "   🔄 Creating Line twin..." -ForegroundColor Cyan
$lineTwin = @{
    '$metadata' = @{
        '$model' = 'dtmi:smartfactory:Line;1'
    }
    'name' = 'Production Line A'
    'status' = 'Running'
    'efficiency' = 94.2
    'speed' = 85
} | ConvertTo-Json -Depth 3

try {
    Invoke-RestMethod -Uri "$endpoint/digitaltwins/lineA" -Method Put -Headers $headers -Body $lineTwin
    Write-Host "      ✅ Line twin created" -ForegroundColor Green
} catch {
    Write-Host "      ⚠️ Line twin exists or error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Create Machine twin
Write-Host "   🤖 Creating Machine twin..." -ForegroundColor Cyan
$machineTwin = @{
    '$metadata' = @{
        '$model' = 'dtmi:smartfactory:Machine;1'
    }
    'name' = 'CNC Machine A1'
    'status' = 'Running'
    'temperature' = 24.5
    'vibration' = 0.3
    'efficiency' = 91.8
} | ConvertTo-Json -Depth 3

try {
    Invoke-RestMethod -Uri "$endpoint/digitaltwins/machineA1" -Method Put -Headers $headers -Body $machineTwin
    Write-Host "      ✅ Machine twin created" -ForegroundColor Green
} catch {
    Write-Host "      ⚠️ Machine twin exists or error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Create Sensor twin
Write-Host "   📡 Creating Sensor twin..." -ForegroundColor Cyan
$sensorTwin = @{
    '$metadata' = @{
        '$model' = 'dtmi:smartfactory:Sensor;1'
    }
    'name' = 'Temperature Sensor 1'
    'sensorType' = 'temperature'
    'value' = 24.5
    'unit' = 'celsius'
    'status' = 'active'
} | ConvertTo-Json -Depth 3

try {
    Invoke-RestMethod -Uri "$endpoint/digitaltwins/sensor1" -Method Put -Headers $headers -Body $sensorTwin
    Write-Host "      ✅ Sensor twin created" -ForegroundColor Green
} catch {
    Write-Host "      ⚠️ Sensor twin exists or error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 3. Create relationships
Write-Host "`n🔗 Creating relationships..." -ForegroundColor Yellow

# Factory contains Line
$relationship1 = @{
    '$targetId' = 'lineA'
    '$relationshipName' = 'contains'
} | ConvertTo-Json -Depth 2

try {
    Invoke-RestMethod -Uri "$endpoint/digitaltwins/factory1/relationships/factory-line-rel" -Method Put -Headers $headers -Body $relationship1
    Write-Host "   ✅ Factory->Line relationship created" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ Relationship exists or error" -ForegroundColor Yellow
}

# Line contains Machine
$relationship2 = @{
    '$targetId' = 'machineA1'
    '$relationshipName' = 'contains'
} | ConvertTo-Json -Depth 2

try {
    Invoke-RestMethod -Uri "$endpoint/digitaltwins/lineA/relationships/line-machine-rel" -Method Put -Headers $headers -Body $relationship2
    Write-Host "   ✅ Line->Machine relationship created" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ Relationship exists or error" -ForegroundColor Yellow
}

# Machine has Sensor
$relationship3 = @{
    '$targetId' = 'sensor1'
    '$relationshipName' = 'hasSensor'
} | ConvertTo-Json -Depth 2

try {
    Invoke-RestMethod -Uri "$endpoint/digitaltwins/machineA1/relationships/machine-sensor-rel" -Method Put -Headers $headers -Body $relationship3
    Write-Host "   ✅ Machine->Sensor relationship created" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ Relationship exists or error" -ForegroundColor Yellow
}

Write-Host "`n🎉 Azure Digital Twins configuration complete!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "🔗 Digital Twins Explorer: https://explorer.digitaltwins.azure.net" -ForegroundColor Cyan
Write-Host "🏭 Endpoint: $endpoint" -ForegroundColor Cyan
Write-Host "📊 Twin instances: factory1, lineA, machineA1, sensor1" -ForegroundColor Cyan
Write-Host "🔄 Relationships: Factory->Line->Machine->Sensor" -ForegroundColor Cyan