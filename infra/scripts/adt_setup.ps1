# Azure Digital Twins Setup - PowerShell Version (GA Services Only)
# Uses stable REST API calls without problematic extensions

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "factory-rg-dev",
    
    [Parameter(Mandatory=$false)]
    [string]$AdtName = "factory-adt-dev",
    
    [Parameter(Mandatory=$false)]
    [string]$ModelsPath = "models"
)

Write-Host "🏭 Azure Digital Twins Setup (GA Stable Version)" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""

# Verificar Azure CLI
Write-Host "🔍 Verificando Azure CLI..." -ForegroundColor Yellow
$account = az account show --query "name" -o tsv 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ No hay sesión activa de Azure CLI" -ForegroundColor Red
    Write-Host "💡 Ejecuta: az login" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Conectado a: $account" -ForegroundColor Green

# Verificar que ADT existe
Write-Host "🔍 Verificando Azure Digital Twins..." -ForegroundColor Yellow
$adtExists = az resource show --name $AdtName --resource-group $ResourceGroup --resource-type "Microsoft.DigitalTwins/digitalTwinsInstances" --query "name" -o tsv 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Azure Digital Twins '$AdtName' no encontrado" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Azure Digital Twins encontrado: $adtExists" -ForegroundColor Green

# Obtener URL de ADT
$adtUrl = az resource show --name $AdtName --resource-group $ResourceGroup --resource-type "Microsoft.DigitalTwins/digitalTwinsInstances" --query "properties.hostName" -o tsv
Write-Host "🔗 ADT URL: https://$adtUrl" -ForegroundColor Cyan

# Verificar permisos del usuario actual
Write-Host ""
Write-Host "🔑 Verificando permisos..." -ForegroundColor Yellow
$currentUser = az account show --query "user.name" -o tsv

# Obtener token de acceso para REST API
$accessToken = az account get-access-token --resource "https://digitaltwins.azure.net" --query "accessToken" -o tsv

# Función para hacer llamadas REST API a ADT
function Invoke-AdtRestApi {
    param(
        [string]$Method,
        [string]$Path,
        [string]$Body = $null
    )
    
    $headers = @{
        'Authorization' = "Bearer $accessToken"
        'Content-Type' = 'application/json'
    }
    
    $uri = "https://$adtUrl$Path"
    
    try {
        if ($Body) {
            $response = Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -Body $Body
        } else {
            $response = Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers
        }
        return $response
    } catch {
        Write-Host "❌ Error en REST API: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Listar modelos existentes
Write-Host ""
Write-Host "📋 Verificando modelos existentes..." -ForegroundColor Yellow
$existingModels = Invoke-AdtRestApi -Method "GET" -Path "/models?api-version=2023-10-31"
if ($existingModels -and $existingModels.value) {
    Write-Host "✅ Modelos existentes encontrados: $($existingModels.value.Count)" -ForegroundColor Green
    $existingModels.value | ForEach-Object {
        Write-Host "   - $($_.id)" -ForegroundColor Cyan
    }
} else {
    Write-Host "⚠️  No se encontraron modelos existentes" -ForegroundColor Yellow
}

# Cargar modelos DTDL
Write-Host ""
Write-Host "📁 Cargando modelos DTDL..." -ForegroundColor Yellow

$modelFiles = Get-ChildItem -Path $ModelsPath -Filter "*.dtdl.json"
$modelsToUpload = @()

foreach ($file in $modelFiles) {
    Write-Host "📄 Procesando: $($file.Name)" -ForegroundColor Cyan
    
    try {
        $modelContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        $modelsToUpload += $modelContent
        Write-Host "   ✅ Modelo validado: $($modelContent.'@id')" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Error validando modelo: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($modelsToUpload.Count -gt 0) {
    Write-Host ""
    Write-Host "⬆️  Subiendo $($modelsToUpload.Count) modelos a ADT..." -ForegroundColor Yellow
    
    $uploadBody = $modelsToUpload | ConvertTo-Json -Depth 10
    $uploadResult = Invoke-AdtRestApi -Method "POST" -Path "/models?api-version=2023-10-31" -Body $uploadBody
    
    if ($uploadResult) {
        Write-Host "✅ Modelos subidos exitosamente" -ForegroundColor Green
    } else {
        Write-Host "❌ Error subiendo modelos" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  No hay modelos válidos para subir" -ForegroundColor Yellow
}

# Crear twins básicos
Write-Host ""
Write-Host "🔧 Creando twins básicos..." -ForegroundColor Yellow

$twins = @(
    @{
        id = "factory1"
        model = "dtmi:factory:Factory;1"
        properties = @{
            name = "Main Factory"
            location = "Production Floor 1"
        }
    },
    @{
        id = "lineA" 
        model = "dtmi:factory:Line;1"
        properties = @{
            name = "Production Line A"
            oee = 0.85
            state = "running"
        }
    },
    @{
        id = "machineA"
        model = "dtmi:factory:Machine;1" 
        properties = @{
            name = "Machine A-001"
            serial = "MAC-001-2024"
            model = "ProductionLine-X1"
            health = "healthy"
        }
    },
    @{
        id = "sensorA"
        model = "dtmi:factory:Sensor;1"
        properties = @{
            name = "Temperature Sensor A"
            sensorType = "temperature"
            unit = "celsius"
        }
    }
)

foreach ($twin in $twins) {
    Write-Host "🔧 Creando twin: $($twin.id)" -ForegroundColor Cyan
    
    $twinBody = @{
        '$metadata' = @{
            '$model' = $twin.model
        }
    }
    
    # Agregar propiedades
    foreach ($prop in $twin.properties.GetEnumerator()) {
        $twinBody[$prop.Key] = $prop.Value
    }
    
    $twinJson = $twinBody | ConvertTo-Json -Depth 10
    $twinResult = Invoke-AdtRestApi -Method "PUT" -Path "/digitaltwins/$($twin.id)?api-version=2023-10-31" -Body $twinJson
    
    if ($twinResult) {
        Write-Host "   ✅ Twin creado: $($twin.id)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Twin ya existe o error: $($twin.id)" -ForegroundColor Yellow
    }
}

# Crear relaciones
Write-Host ""
Write-Host "🔗 Creando relaciones..." -ForegroundColor Yellow

$relationships = @(
    @{
        source = "factory1"
        target = "lineA"
        relationship = "contains"
        name = "factory-contains-line"
    },
    @{
        source = "lineA"
        target = "machineA" 
        relationship = "contains"
        name = "line-contains-machine"
    },
    @{
        source = "machineA"
        target = "sensorA"
        relationship = "contains"
        name = "machine-contains-sensor"
    }
)

foreach ($rel in $relationships) {
    Write-Host "🔗 Creando relación: $($rel.source) -> $($rel.target)" -ForegroundColor Cyan
    
    $relBody = @{
        '$targetId' = $rel.target
        '$relationshipName' = $rel.relationship
    } | ConvertTo-Json
    
    $relResult = Invoke-AdtRestApi -Method "PUT" -Path "/digitaltwins/$($rel.source)/relationships/$($rel.name)?api-version=2023-10-31" -Body $relBody
    
    if ($relResult) {
        Write-Host "   ✅ Relación creada: $($rel.name)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Relación ya existe o error: $($rel.name)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎉 Setup de Azure Digital Twins completado!" -ForegroundColor Green
Write-Host "🔍 Puedes verificar en ADT Explorer: https://explorer.digitaltwins.azure.net/" -ForegroundColor Cyan