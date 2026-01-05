# 📈 Smart Factory - Server Pulse Monitoring Configuration
# Real-time monitoring setup with professional tools

# Server Pulse Configuration for Smart Factory
# This PowerShell script configures comprehensive monitoring

param(
    [string]$SubscriptionId,
    [string]$ResourceGroupName = "smartfactory-blue-rg",
    [string]$WebAppName,
    [string]$FunctionAppName,
    [bool]$SetupAlerts = $true,
    [bool]$ConfigureMetrics = $true
)

Write-Host "🚀 Starting Server Pulse Monitoring Configuration..." -ForegroundColor Green

# 1. Install required monitoring extensions
Write-Host "📦 Installing Server Pulse and monitoring extensions..." -ForegroundColor Yellow

$extensions = @(
    "ms-vscode.vscode-server-pulse",
    "ms-vscode.azure-monitor",
    "ms-vscode.azure-appinsights",
    "humao.rest-client"
)

foreach ($ext in $extensions) {
    try {
        Write-Host "Installing $ext..." -ForegroundColor Cyan
        code --install-extension $ext --force
    }
    catch {
        Write-Host "Warning: Could not install $ext - may need manual installation" -ForegroundColor Yellow
    }
}

# 2. Generate Server Pulse configuration
$serverPulseConfig = @{
    "version" = "1.0.0"
    "name" = "Smart Factory Monitoring"
    "description" = "Real-time monitoring for Smart Factory IoT solution"
    "monitors" = @(
        @{
            "id" = "web-app-health"
            "name" = "Web App Health Check"
            "type" = "http"
            "enabled" = $true
            "interval" = 30
            "url" = "https://$WebAppName.azurewebsites.net/api/health"
            "method" = "GET"
            "headers" = @{
                "User-Agent" = "ServerPulse/1.0"
                "Accept" = "application/json"
            }
            "timeout" = 10
            "expectedStatus" = 200
            "healthChecks" = @{
                "responseTime" = 5000
                "statusCode" = @(200, 201)
                "contentType" = "application/json"
            }
            "alerts" = @{
                "responseTime" = @{
                    "threshold" = 5000
                    "action" = "notify"
                }
                "downtime" = @{
                    "consecutiveFailures" = 3
                    "action" = "escalate"
                }
            }
        },
        @{
            "id" = "function-app-health"
            "name" = "Function App Health Check"
            "type" = "http"
            "enabled" = $true
            "interval" = 60
            "url" = "https://$FunctionAppName.azurewebsites.net/api/health"
            "method" = "GET"
            "headers" = @{
                "User-Agent" = "ServerPulse/1.0"
                "Accept" = "application/json"
            }
            "timeout" = 15
            "expectedStatus" = 200
            "healthChecks" = @{
                "responseTime" = 10000
                "statusCode" = @(200)
                "contentType" = "application/json"
            }
            "alerts" = @{
                "responseTime" = @{
                    "threshold" = 10000
                    "action" = "notify"
                }
                "downtime" = @{
                    "consecutiveFailures" = 2
                    "action" = "escalate"
                }
            }
        },
        @{
            "id" = "web-app-metrics"
            "name" = "Web App Metrics"
            "type" = "http"
            "enabled" = $true
            "interval" = 120
            "url" = "https://$WebAppName.azurewebsites.net/api/metrics"
            "method" = "GET"
            "timeout" = 10
            "expectedStatus" = 200
        },
        @{
            "id" = "web-app-ready"
            "name" = "Web App Readiness"
            "type" = "http"
            "enabled" = $true
            "interval" = 30
            "url" = "https://$WebAppName.azurewebsites.net/api/ready"
            "method" = "GET"
            "timeout" = 5
            "expectedStatus" = 200
        },
        @{
            "id" = "web-app-live"
            "name" = "Web App Liveness"
            "type" = "http"
            "enabled" = $true
            "interval" = 15
            "url" = "https://$WebAppName.azurewebsites.net/api/live"
            "method" = "GET"
            "timeout" = 5
            "expectedStatus" = 200
        }
    )
    "notifications" = @{
        "email" = @{
            "enabled" = $true
            "recipients" = @("admin@smartfactory.local")
        }
        "webhook" = @{
            "enabled" = $true
            "url" = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
        }
    }
    "dashboard" = @{
        "enabled" = $true
        "refreshInterval" = 5
        "autoRefresh" = $true
        "theme" = "dark"
    }
    "reporting" = @{
        "enabled" = $true
        "interval" = "daily"
        "retention" = 30
        "metrics" = @("availability", "responseTime", "throughput", "errors")
    }
}

# 3. Save Server Pulse configuration
$configPath = "C:\amapv2\.vscode\serverpulse.json"
$serverPulseConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8

Write-Host "✅ Server Pulse configuration saved to: $configPath" -ForegroundColor Green

# 4. Create monitoring REST requests for testing
$restClientRequests = @"
### 🏥 Smart Factory Health Monitoring
### Collection of REST requests for monitoring all endpoints

@webappUrl = https://$WebAppName.azurewebsites.net
@functionappUrl = https://$FunctionAppName.azurewebsites.net

###
# 1. Web App Health Check
GET {{webappUrl}}/api/health
Accept: application/json
User-Agent: REST-Client/1.0

###
# 2. Function App Health Check  
GET {{functionappUrl}}/api/health
Accept: application/json
User-Agent: REST-Client/1.0

###
# 3. Web App Metrics
GET {{webappUrl}}/api/metrics
Accept: application/json

###
# 4. Web App Readiness Probe
GET {{webappUrl}}/api/ready
Accept: application/json

###
# 5. Web App Liveness Probe
GET {{webappUrl}}/api/live
Accept: application/json

###
# 6. Health Dashboard
GET {{webappUrl}}/
Accept: text/html

###
# 7. Load Test - Multiple Health Checks
GET {{webappUrl}}/api/health
Accept: application/json

###
GET {{webappUrl}}/api/health
Accept: application/json

###
GET {{webappUrl}}/api/health
Accept: application/json

###
# 8. Response Time Test
GET {{webappUrl}}/api/metrics
Accept: application/json
# @note This should complete in < 1 second

###
# 9. Error Handling Test
GET {{webappUrl}}/api/nonexistent
Accept: application/json
# @note This should return 404

###
# 10. Function App Load Test
GET {{functionappUrl}}/api/health
Accept: application/json

###
GET {{functionappUrl}}/api/health
Accept: application/json

###
GET {{functionappUrl}}/api/health
Accept: application/json

"@

$restClientPath = "C:\amapv2\monitoring\health-checks.http"
New-Item -Path (Split-Path $restClientPath -Parent) -ItemType Directory -Force | Out-Null
$restClientRequests | Out-File -FilePath $restClientPath -Encoding UTF8

Write-Host "✅ REST Client monitoring requests saved to: $restClientPath" -ForegroundColor Green

# 5. Create monitoring dashboard script
$dashboardScript = @'
# 📊 Smart Factory Monitoring Dashboard
# Real-time monitoring dashboard using PowerShell

param(
    [string]$WebAppUrl,
    [string]$FunctionAppUrl,
    [int]$RefreshInterval = 30
)

function Get-HealthStatus {
    param([string]$Url, [string]$Name)
    
    try {
        $response = Invoke-RestMethod -Uri "$Url/api/health" -Method GET -TimeoutSec 10
        return @{
            Name = $Name
            Status = $response.status
            ResponseTime = if($response.checks) { 
                ($response.checks.PSObject.Properties.Value | Measure-Object -Property responseTime -Average).Average 
            } else { 0 }
            Timestamp = $response.timestamp
            Summary = $response.summary
            Healthy = $response.status -eq "healthy"
        }
    }
    catch {
        return @{
            Name = $Name
            Status = "unhealthy"
            ResponseTime = -1
            Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            Summary = "Connection failed: $($_.Exception.Message)"
            Healthy = $false
        }
    }
}

function Show-MonitoringDashboard {
    param($WebAppStatus, $FunctionAppStatus)
    
    Clear-Host
    
    Write-Host "🏭 SMART FACTORY - REAL-TIME MONITORING DASHBOARD" -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Gray
    Write-Host "Last Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
    
    # Web App Status
    $webColor = if($WebAppStatus.Healthy) { "Green" } else { "Red" }
    Write-Host "🌐 WEB APP STATUS" -ForegroundColor $webColor
    Write-Host "   Status: $($WebAppStatus.Status.ToUpper())" -ForegroundColor $webColor
    Write-Host "   Response Time: $($WebAppStatus.ResponseTime)ms" -ForegroundColor $webColor
    Write-Host "   Summary: $($WebAppStatus.Summary)" -ForegroundColor $webColor
    Write-Host "   Last Check: $($WebAppStatus.Timestamp)" -ForegroundColor Gray
    Write-Host ""
    
    # Function App Status  
    $funcColor = if($FunctionAppStatus.Healthy) { "Green" } else { "Red" }
    Write-Host "⚡ FUNCTION APP STATUS" -ForegroundColor $funcColor
    Write-Host "   Status: $($FunctionAppStatus.Status.ToUpper())" -ForegroundColor $funcColor
    Write-Host "   Response Time: $($FunctionAppStatus.ResponseTime)ms" -ForegroundColor $funcColor
    Write-Host "   Summary: $($FunctionAppStatus.Summary)" -ForegroundColor $funcColor
    Write-Host "   Last Check: $($FunctionAppStatus.Timestamp)" -ForegroundColor Gray
    Write-Host ""
    
    # Overall System Health
    $overallHealthy = $WebAppStatus.Healthy -and $FunctionAppStatus.Healthy
    $overallColor = if($overallHealthy) { "Green" } else { "Red" }
    $overallStatus = if($overallHealthy) { "🟢 HEALTHY" } else { "🔴 DEGRADED" }
    
    Write-Host "🏥 OVERALL SYSTEM HEALTH: $overallStatus" -ForegroundColor $overallColor
    Write-Host ""
    
    Write-Host "Press Ctrl+C to exit, refreshing every $RefreshInterval seconds..." -ForegroundColor Yellow
    Write-Host "=" * 70 -ForegroundColor Gray
}

# Main monitoring loop
Write-Host "🚀 Starting Smart Factory monitoring dashboard..." -ForegroundColor Green
Write-Host "Web App URL: $WebAppUrl" -ForegroundColor Cyan
Write-Host "Function App URL: $FunctionAppUrl" -ForegroundColor Cyan
Write-Host ""

while ($true) {
    $webAppStatus = Get-HealthStatus -Url $WebAppUrl -Name "Web App"
    $functionAppStatus = Get-HealthStatus -Url $FunctionAppUrl -Name "Function App"
    
    Show-MonitoringDashboard -WebAppStatus $webAppStatus -FunctionAppStatus $functionAppStatus
    
    Start-Sleep -Seconds $RefreshInterval
}
'@

$dashboardScriptPath = "C:\amapv2\monitoring\dashboard.ps1"
$dashboardScript | Out-File -FilePath $dashboardScriptPath -Encoding UTF8

Write-Host "✅ Monitoring dashboard script saved to: $dashboardScriptPath" -ForegroundColor Green

# 6. Create VS Code workspace settings for monitoring
$workspaceSettings = @{
    "serverPulse.enabled" = $true
    "serverPulse.configFile" = "./.vscode/serverpulse.json"
    "serverPulse.autoStart" = $true
    "rest-client.environmentVariables" = @{
        "production" = @{
            "webappUrl" = "https://$WebAppName.azurewebsites.net"
            "functionappUrl" = "https://$FunctionAppName.azurewebsites.net"
        }
        "local" = @{
            "webappUrl" = "http://localhost:3000"
            "functionappUrl" = "http://localhost:7071"
        }
    }
    "azure.monitor.enabled" = $true
    "azure.monitor.resourceGroups" = @($ResourceGroupName)
}

$vsCodeSettingsPath = "C:\amapv2\.vscode\settings.json"
if (Test-Path $vsCodeSettingsPath) {
    $existingSettings = Get-Content $vsCodeSettingsPath | ConvertFrom-Json
    $workspaceSettings.PSObject.Properties | ForEach-Object {
        $existingSettings | Add-Member -NotePropertyName $_.Name -NotePropertyValue $_.Value -Force
    }
    $existingSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $vsCodeSettingsPath -Encoding UTF8
} else {
    New-Item -Path (Split-Path $vsCodeSettingsPath -Parent) -ItemType Directory -Force | Out-Null
    $workspaceSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $vsCodeSettingsPath -Encoding UTF8
}

Write-Host "✅ VS Code workspace settings updated" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 Server Pulse Monitoring Configuration Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Restart VS Code to load new extensions" -ForegroundColor White
Write-Host "2. Open the Command Palette (Ctrl+Shift+P)" -ForegroundColor White
Write-Host "3. Run 'Server Pulse: Start Monitoring'" -ForegroundColor White
Write-Host "4. Use monitoring/health-checks.http for manual testing" -ForegroundColor White
Write-Host "5. Run monitoring/dashboard.ps1 for real-time dashboard" -ForegroundColor White
Write-Host ""
Write-Host "Configuration files created:" -ForegroundColor Cyan
Write-Host "- $configPath" -ForegroundColor White
Write-Host "- $restClientPath" -ForegroundColor White  
Write-Host "- $dashboardScriptPath" -ForegroundColor White
Write-Host "- $vsCodeSettingsPath" -ForegroundColor White