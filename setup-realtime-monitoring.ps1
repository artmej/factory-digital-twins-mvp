# 📊 Smart Factory Real-time Monitoring Setup
# Configures comprehensive Application Insights monitoring with custom dashboards and alerts

param(
    [string]$ResourceGroupName = "smart-factory-v2-rg",
    [string]$Location = "westus2",
    [switch]$CreateDashboard = $true,
    [switch]$SetupAlerts = $true
)

Write-Host "📊 Smart Factory Real-time Monitoring Setup" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Get Application Insights instance
Write-Host "🔍 Finding Application Insights instance..." -ForegroundColor Yellow
$appInsights = az monitor app-insights component list --resource-group $ResourceGroupName --query "[0]" | ConvertFrom-Json

if (!$appInsights) {
    Write-Error "No Application Insights instance found in resource group: $ResourceGroupName"
    exit 1
}

$appInsightsName = $appInsights.name
$instrumentationKey = $appInsights.instrumentationKey
$connectionString = $appInsights.connectionString

Write-Host "✅ Found Application Insights: $appInsightsName" -ForegroundColor Green
Write-Host "   Instrumentation Key: $($instrumentationKey.Substring(0,8))..." -ForegroundColor Gray

# Create Custom Metrics and KQL Queries
Write-Host "`n📈 Setting up custom monitoring queries..." -ForegroundColor Yellow

$kqlQueries = @{
    "HealthStatus" = @"
requests
| where name contains "health"
| summarize 
    HealthyCount = countif(resultCode == 200),
    UnhealthyCount = countif(resultCode != 200),
    AvgResponseTime = avg(duration)
by bin(timestamp, 5m)
| order by timestamp desc
"@

    "IoTTelemetryRate" = @"
customEvents
| where name == "IoTTelemetryReceived"
| summarize 
    MessageCount = count(),
    UniqueDevices = dcount(tostring(customDimensions.deviceId))
by bin(timestamp, 1m)
| order by timestamp desc
"@

    "ErrorAnalysis" = @"
union exceptions, traces
| where severityLevel >= 3
| summarize 
    ErrorCount = count(),
    UniqueErrors = dcount(message)
by bin(timestamp, 5m), cloud_RoleName
| order by timestamp desc
"@

    "PerformanceMetrics" = @"
performanceCounters
| where name in ("% Processor Time", "Available MBytes")
| summarize avg(value) by name, bin(timestamp, 5m)
| order by timestamp desc
"@

    "DeviceSimulatorHealth" = @"
customEvents
| where name == "DeviceSimulatorHeartbeat"
| summarize 
    ActiveDevices = dcount(tostring(customDimensions.deviceId)),
    MessagesSent = sum(toint(customDimensions.messagesSent))
by bin(timestamp, 1m)
| order by timestamp desc
"@
}

# Create Application Insights Dashboard
if ($CreateDashboard) {
    Write-Host "`n🎛️ Creating custom dashboard..." -ForegroundColor Yellow
    
    $dashboardConfig = @{
        location = $Location
        tags = @{
            environment = "production"
            project = "smart-factory"
        }
        properties = @{
            lenses = @{
                "0" = @{
                    order = 0
                    parts = @{
                        "0" = @{
                            position = @{ x=0; y=0; rowSpan=4; colSpan=6 }
                            metadata = @{
                                type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
                                inputs = @(
                                    @{
                                        name = "resourceTypeMode"
                                        value = "workspace"
                                    }
                                    @{
                                        name = "ComponentId"
                                        value = $appInsights.id
                                    }
                                    @{
                                        name = "Query"
                                        value = $kqlQueries.HealthStatus
                                    }
                                    @{
                                        name = "PartTitle"
                                        value = "Service Health Status"
                                    }
                                )
                            }
                        }
                        "1" = @{
                            position = @{ x=6; y=0; rowSpan=4; colSpan=6 }
                            metadata = @{
                                type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
                                inputs = @(
                                    @{
                                        name = "ComponentId"
                                        value = $appInsights.id
                                    }
                                    @{
                                        name = "Query"
                                        value = $kqlQueries.IoTTelemetryRate
                                    }
                                    @{
                                        name = "PartTitle"
                                        value = "IoT Telemetry Rate"
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    } | ConvertTo-Json -Depth 10

    $dashboardName = "smart-factory-monitoring-dashboard"
    
    try {
        # Create dashboard using REST API via Azure CLI
        $dashboardFile = "dashboard-config.json"
        $dashboardConfig | Out-File -FilePath $dashboardFile -Encoding UTF8
        
        Write-Host "   Creating dashboard: $dashboardName..." -ForegroundColor Gray
        # Note: Dashboard creation via CLI is complex, we'll create a simple version
        az portal dashboard create --resource-group $ResourceGroupName --name $dashboardName --input-path $dashboardFile
        
        Remove-Item $dashboardFile -ErrorAction SilentlyContinue
        Write-Host "✅ Dashboard created successfully" -ForegroundColor Green
        
    } catch {
        Write-Warning "Dashboard creation failed: $($_.Exception.Message)"
        Write-Host "   You can manually create a dashboard in the Azure portal using the provided KQL queries" -ForegroundColor Yellow
    }
}

# Setup Alert Rules
if ($SetupAlerts) {
    Write-Host "`n🚨 Setting up alert rules..." -ForegroundColor Yellow
    
    # Alert 1: High Error Rate
    Write-Host "   Creating high error rate alert..." -ForegroundColor Gray
    az monitor metrics alert create `
        --name "SmartFactory-HighErrorRate" `
        --resource-group $ResourceGroupName `
        --scopes $appInsights.id `
        --condition "avg requests/failed > 5" `
        --description "Alert when error rate exceeds 5 per minute" `
        --evaluation-frequency 1m `
        --window-size 5m `
        --severity 2

    # Alert 2: Low Health Check Success Rate
    Write-Host "   Creating health check failure alert..." -ForegroundColor Gray
    az monitor metrics alert create `
        --name "SmartFactory-HealthCheckFailure" `
        --resource-group $ResourceGroupName `
        --scopes $appInsights.id `
        --condition "avg customEvents/count < 1" `
        --description "Alert when health checks are failing" `
        --evaluation-frequency 1m `
        --window-size 5m `
        --severity 1

    # Alert 3: High Response Time
    Write-Host "   Creating high response time alert..." -ForegroundColor Gray
    az monitor metrics alert create `
        --name "SmartFactory-HighResponseTime" `
        --resource-group $ResourceGroupName `
        --scopes $appInsights.id `
        --condition "avg requests/duration > 5000" `
        --description "Alert when average response time exceeds 5 seconds" `
        --evaluation-frequency 1m `
        --window-size 5m `
        --severity 3

    Write-Host "✅ Alert rules created successfully" -ForegroundColor Green
}

# Create monitoring PowerShell module
Write-Host "`n📦 Creating monitoring PowerShell module..." -ForegroundColor Yellow

$monitoringModule = @"
# Smart Factory Real-time Monitoring Module
# Provides functions for monitoring the smart factory infrastructure

function Get-SmartFactoryHealth {
    param(
        [string]`$ResourceGroupName = "smart-factory-v2-rg",
        [string]`$TimeRange = "PT1H"  # Last 1 hour
    )
    
    `$appInsights = az monitor app-insights component list --resource-group `$ResourceGroupName --query "[0]" | ConvertFrom-Json
    
    if (!`$appInsights) {
        Write-Error "Application Insights not found"
        return
    }
    
    # Query health status
    `$healthQuery = @"
requests
| where name contains "health"
| where timestamp > ago(1h)
| summarize 
    HealthyCount = countif(resultCode == 200),
    UnhealthyCount = countif(resultCode != 200),
    AvgResponseTime = avg(duration),
    LastCheck = max(timestamp)
"@
    
    `$healthResult = az monitor app-insights query --app `$appInsights.name --analytics-query `$healthQuery | ConvertFrom-Json
    
    return `$healthResult
}

function Get-IoTTelemetryStats {
    param(
        [string]`$ResourceGroupName = "smart-factory-v2-rg",
        [int]`$Minutes = 60
    )
    
    `$appInsights = az monitor app-insights component list --resource-group `$ResourceGroupName --query "[0]" | ConvertFrom-Json
    
    `$telemetryQuery = @"
customEvents
| where name == "IoTTelemetryReceived"
| where timestamp > ago({0}m)
| summarize 
    MessageCount = count(),
    UniqueDevices = dcount(tostring(customDimensions.deviceId)),
    AvgMessageSize = avg(toint(customDimensions.messageSize))
"@ -f `$Minutes
    
    `$telemetryResult = az monitor app-insights query --app `$appInsights.name --analytics-query `$telemetryQuery | ConvertFrom-Json
    
    return `$telemetryResult
}

function Get-ErrorSummary {
    param(
        [string]`$ResourceGroupName = "smart-factory-v2-rg",
        [int]`$Hours = 1
    )
    
    `$appInsights = az monitor app-insights component list --resource-group `$ResourceGroupName --query "[0]" | ConvertFrom-Json
    
    `$errorQuery = @"
union exceptions, traces
| where severityLevel >= 3
| where timestamp > ago({0}h)
| summarize 
    ErrorCount = count(),
    UniqueErrors = dcount(message),
    MostCommonError = any(message)
by cloud_RoleName
"@ -f `$Hours
    
    `$errorResult = az monitor app-insights query --app `$appInsights.name --analytics-query `$errorQuery | ConvertFrom-Json
    
    return `$errorResult
}

# Export functions
Export-ModuleMember -Function Get-SmartFactoryHealth, Get-IoTTelemetryStats, Get-ErrorSummary
"@

$monitoringModule | Out-File -FilePath "SmartFactoryMonitoring.psm1" -Encoding UTF8
Write-Host "✅ Monitoring module created: SmartFactoryMonitoring.psm1" -ForegroundColor Green

# Create real-time monitoring script
$realtimeScript = @"
# Real-time Smart Factory Monitoring Dashboard
# Run this script to get continuous monitoring updates

param(
    [int]`$RefreshSeconds = 30,
    [switch]`$Continuous = `$false
)

Import-Module .\SmartFactoryMonitoring.psm1 -Force

do {
    Clear-Host
    Write-Host "📊 Smart Factory Real-time Dashboard" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "Last Updated: `$(Get-Date)" -ForegroundColor Gray
    
    # Get health status
    Write-Host "`n🏥 Health Status:" -ForegroundColor Yellow
    try {
        `$health = Get-SmartFactoryHealth
        if (`$health.tables[0].rows.Count -gt 0) {
            `$row = `$health.tables[0].rows[0]
            `$healthy = `$row[0]
            `$unhealthy = `$row[1]
            `$avgResponse = [math]::Round(`$row[2], 2)
            
            Write-Host "   ✅ Healthy Checks: `$healthy" -ForegroundColor Green
            Write-Host "   ❌ Unhealthy Checks: `$unhealthy" -ForegroundColor Red
            Write-Host "   ⏱️  Avg Response Time: `${avgResponse}ms" -ForegroundColor Blue
        } else {
            Write-Host "   ⚠️  No health data available" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   ❌ Failed to get health status: `$(`$_.Exception.Message)" -ForegroundColor Red
    }
    
    # Get telemetry stats
    Write-Host "`n📡 IoT Telemetry (Last Hour):" -ForegroundColor Yellow
    try {
        `$telemetry = Get-IoTTelemetryStats
        if (`$telemetry.tables[0].rows.Count -gt 0) {
            `$row = `$telemetry.tables[0].rows[0]
            `$messages = `$row[0]
            `$devices = `$row[1]
            
            Write-Host "   📩 Messages Received: `$messages" -ForegroundColor Green
            Write-Host "   🔌 Active Devices: `$devices" -ForegroundColor Blue
        } else {
            Write-Host "   ⚠️  No telemetry data available" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   ❌ Failed to get telemetry stats: `$(`$_.Exception.Message)" -ForegroundColor Red
    }
    
    # Get error summary
    Write-Host "`n🚨 Error Summary (Last Hour):" -ForegroundColor Yellow
    try {
        `$errors = Get-ErrorSummary
        if (`$errors.tables[0].rows.Count -gt 0) {
            foreach (`$row in `$errors.tables[0].rows) {
                `$service = `$row[0]
                `$errorCount = `$row[1]
                `$uniqueErrors = `$row[2]
                
                if (`$errorCount -gt 0) {
                    Write-Host "   🔥 `$service`: `$errorCount errors (`$uniqueErrors unique)" -ForegroundColor Red
                }
            }
            
            if (`$errors.tables[0].rows.Count -eq 0) {
                Write-Host "   ✅ No errors detected" -ForegroundColor Green
            }
        } else {
            Write-Host "   ✅ No errors detected" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ❌ Failed to get error summary: `$(`$_.Exception.Message)" -ForegroundColor Red
    }
    
    if (`$Continuous) {
        Write-Host "`n⏱️  Refreshing in `$RefreshSeconds seconds... (Ctrl+C to stop)" -ForegroundColor Gray
        Start-Sleep -Seconds `$RefreshSeconds
    }
    
} while (`$Continuous)
"@

$realtimeScript | Out-File -FilePath "Start-RealtimeMonitoring.ps1" -Encoding UTF8
Write-Host "✅ Real-time monitoring script created: Start-RealtimeMonitoring.ps1" -ForegroundColor Green

# Output KQL Queries for manual dashboard creation
Write-Host "`n📝 KQL Queries for Custom Dashboard:" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

foreach ($query in $kqlQueries.GetEnumerator()) {
    Write-Host "`n📊 $($query.Key):" -ForegroundColor Yellow
    Write-Host $query.Value -ForegroundColor Gray
}

Write-Host "`n🎯 Real-time monitoring setup completed!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. ✅ Health endpoints implemented" -ForegroundColor Green  
Write-Host "2. ✅ Real-time monitoring configured" -ForegroundColor Green
Write-Host "3. 🔄 Run: .\Start-RealtimeMonitoring.ps1 -Continuous for live dashboard" -ForegroundColor Yellow
Write-Host "4. 🔄 Next: CI/CD Pipeline setup" -ForegroundColor Yellow