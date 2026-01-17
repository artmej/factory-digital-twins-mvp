#!/usr/bin/env pwsh
# Smart Factory Edge Container Build Script
# Builds and pushes container images for Edge modules

param(
    [Parameter(Mandatory=$false)]
    [string]$RegistryName = "smartfactoryregistry",
    
    [Parameter(Mandatory=$false)]
    [string]$ImageTag = "1.0",
    
    [Parameter(Mandatory=$false)]
    [switch]$PushImages,
    
    [Parameter(Mandatory=$false)]
    [switch]$BuildAll
)

Write-Host "🏗️ Smart Factory Edge Container Builder" -ForegroundColor Green
Write-Host "Registry: $RegistryName" -ForegroundColor Cyan
Write-Host "Tag: $ImageTag" -ForegroundColor Cyan
Write-Host ""

# Container configurations
$containers = @(
    @{
        Name = "factory-simulator"
        Path = "../modules/factory-simulator"
        Description = "Factory device simulator with realistic telemetry"
    },
    @{
        Name = "smart-factory-ml"
        Path = "../modules/smart-factory-ml"
        Description = "ML inference module for predictive maintenance"
    }
)

function Test-Prerequisites {
    Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow
    
    # Check Docker
    try {
        docker version | Out-Null
        Write-Host "✅ Docker found" -ForegroundColor Green
    } catch {
        Write-Error "❌ Docker not found. Please install Docker"
        return $false
    }
    
    # Check Azure CLI
    try {
        az version | Out-Null
        Write-Host "✅ Azure CLI found" -ForegroundColor Green
    } catch {
        Write-Error "❌ Azure CLI not found. Please install Azure CLI"
        return $false
    }
    
    return $true
}

function Build-Container {
    param(
        [string]$Name,
        [string]$Path,
        [string]$Registry,
        [string]$Tag,
        [string]$Description
    )
    
    Write-Host "🔨 Building $Name..." -ForegroundColor Yellow
    Write-Host "  Description: $Description" -ForegroundColor Gray
    
    if (-not (Test-Path $Path)) {
        Write-Error "❌ Path not found: $Path"
        return $false
    }
    
    $imageName = "$Registry.azurecr.io/$Name`:$Tag"
    
    try {
        # Build the container
        Set-Location $Path
        docker build -t $imageName .
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully built: $imageName" -ForegroundColor Green
            return $true
        } else {
            Write-Error "❌ Build failed for: $Name"
            return $false
        }
        
    } catch {
        Write-Error "❌ Build error for $Name`: $_"
        return $false
    } finally {
        Set-Location $PSScriptRoot
    }
}

function Push-Container {
    param(
        [string]$Name,
        [string]$Registry,
        [string]$Tag
    )
    
    $imageName = "$Registry.azurecr.io/$Name`:$Tag"
    
    Write-Host "📤 Pushing $imageName..." -ForegroundColor Yellow
    
    try {
        # Login to registry
        az acr login --name $Registry
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "❌ Failed to login to registry: $Registry"
            return $false
        }
        
        # Push the image
        docker push $imageName
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully pushed: $imageName" -ForegroundColor Green
            return $true
        } else {
            Write-Error "❌ Push failed for: $imageName"
            return $false
        }
        
    } catch {
        Write-Error "❌ Push error for $imageName`: $_"
        return $false
    }
}

function Show-ContainerSizes {
    param([string]$Registry, [string]$Tag)
    
    Write-Host "📊 Container Sizes:" -ForegroundColor Cyan
    
    foreach ($container in $containers) {
        $imageName = "$Registry.azurecr.io/$($container.Name)`:$Tag"
        
        try {
            $size = docker images $imageName --format "table {{.Size}}" | Select-Object -Skip 1
            Write-Host "  • $($container.Name): $size" -ForegroundColor White
        } catch {
            Write-Host "  • $($container.Name): Unknown" -ForegroundColor Gray
        }
    }
}

# Main execution
try {
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    Write-Host "🚀 Starting container build process..." -ForegroundColor Green
    Write-Host ""
    
    $successfulBuilds = @()
    $failedBuilds = @()
    
    # Build containers
    foreach ($container in $containers) {
        if ($BuildAll -or $container.Name -eq "factory-simulator" -or $container.Name -eq "smart-factory-ml") {
            $success = Build-Container -Name $container.Name -Path $container.Path -Registry $RegistryName -Tag $ImageTag -Description $container.Description
            
            if ($success) {
                $successfulBuilds += $container.Name
            } else {
                $failedBuilds += $container.Name
            }
            
            Write-Host ""
        }
    }
    
    # Report build results
    Write-Host "📋 Build Summary:" -ForegroundColor Cyan
    
    if ($successfulBuilds.Count -gt 0) {
        Write-Host "  ✅ Successful builds ($($successfulBuilds.Count)):" -ForegroundColor Green
        foreach ($name in $successfulBuilds) {
            Write-Host "    • $name" -ForegroundColor White
        }
    }
    
    if ($failedBuilds.Count -gt 0) {
        Write-Host "  ❌ Failed builds ($($failedBuilds.Count)):" -ForegroundColor Red
        foreach ($name in $failedBuilds) {
            Write-Host "    • $name" -ForegroundColor White
        }
    }
    
    Write-Host ""
    
    # Push containers if requested
    if ($PushImages -and $successfulBuilds.Count -gt 0) {
        Write-Host "📤 Pushing containers to registry..." -ForegroundColor Green
        Write-Host ""
        
        $successfulPushes = @()
        $failedPushes = @()
        
        foreach ($name in $successfulBuilds) {
            $success = Push-Container -Name $name -Registry $RegistryName -Tag $ImageTag
            
            if ($success) {
                $successfulPushes += $name
            } else {
                $failedPushes += $name
            }
            
            Write-Host ""
        }
        
        # Report push results
        Write-Host "📋 Push Summary:" -ForegroundColor Cyan
        
        if ($successfulPushes.Count -gt 0) {
            Write-Host "  ✅ Successful pushes ($($successfulPushes.Count)):" -ForegroundColor Green
            foreach ($name in $successfulPushes) {
                Write-Host "    • $name" -ForegroundColor White
            }
        }
        
        if ($failedPushes.Count -gt 0) {
            Write-Host "  ❌ Failed pushes ($($failedPushes.Count)):" -ForegroundColor Red
            foreach ($name in $failedPushes) {
                Write-Host "    • $name" -ForegroundColor White
            }
        }
    }
    
    # Show container sizes
    Write-Host ""
    Show-ContainerSizes -Registry $RegistryName -Tag $ImageTag
    
    Write-Host ""
    Write-Host "🎉 Container build process completed!" -ForegroundColor Green
    
    if (-not $PushImages) {
        Write-Host "💡 Use -PushImages to push containers to registry" -ForegroundColor Blue
    }
    
} catch {
    Write-Error "❌ Build process failed: $_"
    exit 1
}