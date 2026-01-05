# 🏥 Smart Factory Health Monitoring Test Suite
# Tests all health endpoints across the enterprise architecture

param(
    [string]$ResourceGroupName = "rg-smartfactory-prod",
    [string]$Location = "westus2",
    [switch]$Detailed = $false,
    [switch]$Continuous = $false,
    [int]$IntervalSeconds = 30
)

Write-Host "🏥 Smart Factory Health Monitoring Test Suite" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Global health summary
$healthSummary = @{
    TotalServices = 0
    HealthyServices = 0
    DegradedServices = 0
    UnhealthyServices = 0
    Services = @()
}

function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$HealthUrl,
        [hashtable]$Headers = @{},
        [int]$TimeoutSeconds = 30
    )
    
    $healthSummary.TotalServices++
    
    Write-Host "🔍 Testing $ServiceName..." -ForegroundColor Yellow
    
    $result = @{
        ServiceName = $ServiceName
        Url = $HealthUrl
        Status = "Unknown"
        ResponseTime = 0
        StatusCode = 0
        Details = @{}
        Error = $null
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        $response = Invoke-RestMethod -Uri $HealthUrl -Method GET -Headers $Headers -TimeoutSec $TimeoutSeconds -ErrorAction Stop
        
        $stopwatch.Stop()
        $result.ResponseTime = $stopwatch.ElapsedMilliseconds
        $result.StatusCode = 200
        
        # Parse health response
        if ($response.status) {
            $result.Status = $response.status
            $result.Details = $response
            
            switch ($response.status) {
                "healthy" { 
                    Write-Host "  ✅ $ServiceName is healthy (${result.ResponseTime}ms)" -ForegroundColor Green
                    $healthSummary.HealthyServices++
                }
                "degraded" { 
                    Write-Host "  ⚠️  $ServiceName is degraded (${result.ResponseTime}ms)" -ForegroundColor Yellow
                    $healthSummary.DegradedServices++
                }
                "unhealthy" { 
                    Write-Host "  ❌ $ServiceName is unhealthy (${result.ResponseTime}ms)" -ForegroundColor Red
                    $healthSummary.UnhealthyServices++
                }
                default {
                    Write-Host "  ❓ $ServiceName status unknown: $($response.status)" -ForegroundColor Magenta
                }
            }
            
            if ($Detailed -and $response.checks) {
                Write-Host "     Detailed checks:" -ForegroundColor Gray
                foreach ($check in $response.checks.PSObject.Properties) {
                    $checkStatus = switch ($check.Value.status) {
                        "healthy" { "✅" }
                        "warning" { "⚠️" }
                        "unhealthy" { "❌" }
                        default { "❓" }
                    }
                    Write-Host "       $checkStatus $($check.Name): $($check.Value.status)" -ForegroundColor Gray
                    if ($check.Value.message) {
                        Write-Host "         └─ $($check.Value.message)" -ForegroundColor DarkGray
                    }
                }
            }
        } else {
            $result.Status = "unknown"
            Write-Host "  ❓ $ServiceName responded but status unclear" -ForegroundColor Magenta
        }
        
    } catch {
        if ($stopwatch.IsRunning) { $stopwatch.Stop() }
        $result.ResponseTime = $stopwatch.ElapsedMilliseconds
        $result.Error = $_.Exception.Message
        $result.Status = "error"
        $result.StatusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { 0 }
        
        Write-Host "  ❌ $ServiceName failed: $($_.Exception.Message)" -ForegroundColor Red
        $healthSummary.UnhealthyServices++
    }
    
    $healthSummary.Services += $result
    return $result
}

function Get-AzureResourceEndpoints {
    param([string]$ResourceGroupName)
    
    Write-Host "🔍 Discovering Azure resources..." -ForegroundColor Cyan
    
    $endpoints = @{}
    
    try {
        # Get App Service URLs
        $webApps = az webapp list --resource-group $ResourceGroupName --query "[].{name:name,defaultHostName:defaultHostName}" | ConvertFrom-Json
        foreach ($app in $webApps) {
            if ($app.name -match "webapp") {
                $endpoints["WebApp"] = "https://$($app.defaultHostName)/api/health"
            }
            if ($app.name -match "simulator") {
                $endpoints["DeviceSimulator"] = "https://$($app.defaultHostName)/health"
            }
        }
        
        # Get Function App URLs
        $functionApps = az functionapp list --resource-group $ResourceGroupName --query "[].{name:name,defaultHostName:defaultHostName}" | ConvertFrom-Json
        foreach ($func in $functionApps) {
            $endpoints["FunctionApp"] = "https://$($func.defaultHostName)/api/health"
        }
        
        # Get Front Door endpoints
        $frontDoors = az network front-door list --resource-group $ResourceGroupName --query "[].{name:name,frontendEndpoints:frontendEndpoints}" | ConvertFrom-Json
        foreach ($fd in $frontDoors) {
            if ($fd.frontendEndpoints -and $fd.frontendEndpoints.Count -gt 0) {
                $frontEndUrl = "https://$($fd.frontendEndpoints[0].hostName)"
                $endpoints["FrontDoor-WebApp"] = "$frontEndUrl/api/health"
                $endpoints["FrontDoor-Simulator"] = "$frontEndUrl/simulator/health"
            }
        }
        
        # Get Application Gateway public IP
        $appGateways = az network application-gateway list --resource-group $ResourceGroupName --query "[].{name:name,frontendIPConfigurations:frontendIPConfigurations}" | ConvertFrom-Json
        foreach ($ag in $appGateways) {
            # This would require more complex logic to get the actual public IP
            # For now, we'll note that App Gateway health checks are internal
        }
        
    } catch {
        Write-Warning "Failed to discover some resources: $($_.Exception.Message)"
    }
    
    return $endpoints
}

function Show-HealthSummary {
    Write-Host "`n📊 Health Summary" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    
    $totalServices = $healthSummary.TotalServices
    $healthyServices = $healthSummary.HealthyServices
    $degradedServices = $healthSummary.DegradedServices
    $unhealthyServices = $healthSummary.UnhealthyServices
    
    Write-Host "Total Services: $totalServices" -ForegroundColor White
    Write-Host "✅ Healthy: $healthyServices" -ForegroundColor Green
    Write-Host "⚠️  Degraded: $degradedServices" -ForegroundColor Yellow
    Write-Host "❌ Unhealthy: $unhealthyServices" -ForegroundColor Red
    
    $healthPercentage = if ($totalServices -gt 0) { [math]::Round(($healthyServices / $totalServices) * 100, 1) } else { 0 }
    Write-Host "Health Score: $healthPercentage%" -ForegroundColor $(if ($healthPercentage -ge 80) { "Green" } elseif ($healthPercentage -ge 60) { "Yellow" } else { "Red" })
    
    # Show detailed service status
    if ($healthSummary.Services.Count -gt 0) {
        Write-Host "`n📋 Service Details:" -ForegroundColor Cyan
        $healthSummary.Services | Format-Table -Property ServiceName, Status, ResponseTime, StatusCode, Timestamp -AutoSize
    }
}

# Main execution
do {
    $startTime = Get-Date
    Write-Host "🚀 Starting health check at $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
    
    # Reset summary for this iteration
    $healthSummary = @{
        TotalServices = 0
        HealthyServices = 0
        DegradedServices = 0
        UnhealthyServices = 0
        Services = @()
    }
    
    # Discover Azure endpoints
    $endpoints = Get-AzureResourceEndpoints -ResourceGroupName $ResourceGroupName
    
    # Test discovered endpoints
    foreach ($endpoint in $endpoints.GetEnumerator()) {
        Test-ServiceHealth -ServiceName $endpoint.Key -HealthUrl $endpoint.Value
        Start-Sleep -Seconds 2  # Brief pause between tests
    }
    
    # Test local endpoints if no Azure endpoints found
    if ($endpoints.Count -eq 0) {
        Write-Host "⚠️  No Azure endpoints discovered, testing local endpoints..." -ForegroundColor Yellow
        
        # Test local development endpoints
        Test-ServiceHealth -ServiceName "Local-DeviceSimulator" -HealthUrl "http://localhost:3000/health"
        Test-ServiceHealth -ServiceName "Local-WebApp" -HealthUrl "http://localhost:7071/api/health"
        Test-ServiceHealth -ServiceName "Local-FunctionApp" -HealthUrl "http://localhost:7072/api/health"
    }
    
    # Show summary
    Show-HealthSummary
    
    # Export results if requested
    if ($Detailed) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $reportFile = "health-report-$timestamp.json"
        $healthSummary | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportFile
        Write-Host "📄 Detailed report saved to: $reportFile" -ForegroundColor Blue
    }
    
    if ($Continuous) {
        Write-Host "`n⏱️  Waiting $IntervalSeconds seconds for next check..." -ForegroundColor Gray
        Start-Sleep -Seconds $IntervalSeconds
        Clear-Host
    }
    
} while ($Continuous)

Write-Host "`n🎯 Health monitoring completed!" -ForegroundColor Green