#!/usr/bin/env pwsh
# Smart Factory Edge Monitoring Script
# Monitors Edge device status and module health

param(
    [Parameter(Mandatory=$true)]
    [string]$IoTHubName,
    
    [Parameter(Mandatory=$true)]
    [string]$EdgeDeviceId,
    
    [Parameter(Mandatory=$false)]
    [int]$MonitorDuration = 60,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowTelemetry,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowHealth
)

Write-Host "📊 Smart Factory Edge Monitor" -ForegroundColor Green
Write-Host "Device: $EdgeDeviceId" -ForegroundColor Cyan
Write-Host "Duration: $MonitorDuration seconds" -ForegroundColor Cyan
Write-Host "" 

function Get-EdgeDeviceStatus {
    param($HubName, $DeviceId)
    
    try {
        $device = az iot hub device-identity show --hub-name $HubName --device-id $DeviceId | ConvertFrom-Json
        $connectionState = $device.connectionState
        $lastActivity = $device.lastActivityTime
        
        Write-Host "🔌 Connection State: " -NoNewline -ForegroundColor Yellow
        if ($connectionState -eq "Connected") {
            Write-Host "Connected" -ForegroundColor Green
        } else {
            Write-Host "Disconnected" -ForegroundColor Red
        }
        
        Write-Host "🕒 Last Activity: $lastActivity" -ForegroundColor Blue
        
    } catch {
        Write-Host "❌ Failed to get device status" -ForegroundColor Red
    }
}

function Get-EdgeModuleStatus {
    param($HubName, $DeviceId)
    
    try {
        Write-Host "📦 Module Status:" -ForegroundColor Yellow
        
        $modules = az iot hub module-identity list --hub-name $HubName --device-id $DeviceId | ConvertFrom-Json
        
        foreach ($module in $modules) {
            $moduleName = $module.moduleId
            $connectionState = $module.connectionState
            $lastActivity = $module.lastActivityTime
            
            Write-Host "  • $moduleName" -NoNewline -ForegroundColor White
            if ($connectionState -eq "Connected") {
                Write-Host " [Connected]" -ForegroundColor Green
            } else {
                Write-Host " [Disconnected]" -ForegroundColor Red
            }
            Write-Host "    Last: $lastActivity" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "❌ Failed to get module status" -ForegroundColor Red
    }
}

function Start-TelemetryMonitoring {
    param($HubName, $DeviceId, $Duration)
    
    Write-Host "📡 Starting telemetry monitoring for $Duration seconds..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop early" -ForegroundColor Yellow
    Write-Host ""
    
    # Start monitoring in background job
    $job = Start-Job -ScriptBlock {
        param($hub, $device, $dur)
        $timeout = (Get-Date).AddSeconds($dur)
        
        & az iot hub monitor-events --hub-name $hub --device-id $device --timeout $dur
    } -ArgumentList $IoTHubName, $EdgeDeviceId, $Duration
    
    # Monitor job output
    do {
        Start-Sleep -Seconds 2
        Receive-Job -Job $job
    } while ($job.State -eq "Running" -and (Get-Date) -lt (Get-Date).AddSeconds($Duration))
    
    # Clean up
    Stop-Job -Job $job -ErrorAction SilentlyContinue
    Remove-Job -Job $job -ErrorAction SilentlyContinue
}

function Get-EdgeHealthMetrics {
    param($HubName, $DeviceId)
    
    Write-Host "🏥 Health Metrics:" -ForegroundColor Yellow
    
    try {
        # Get device twin
        $deviceTwin = az iot hub device-twin show --hub-name $HubName --device-id $DeviceId | ConvertFrom-Json
        
        if ($deviceTwin.properties.reported.'$edgeAgent') {
            $edgeAgent = $deviceTwin.properties.reported.'$edgeAgent'
            
            Write-Host "  🤖 Edge Agent:" -ForegroundColor Cyan
            Write-Host "    Runtime: $($edgeAgent.runtime.type)" -ForegroundColor White
            Write-Host "    Version: $($edgeAgent.schemaVersion)" -ForegroundColor White
            
            if ($edgeAgent.systemModules) {
                Write-Host "  📦 System Modules:" -ForegroundColor Cyan
                foreach ($module in $edgeAgent.systemModules.PSObject.Properties) {
                    $status = $module.Value.runtimeStatus
                    $exitCode = $module.Value.exitCode
                    
                    Write-Host "    • $($module.Name): " -NoNewline -ForegroundColor White
                    if ($status -eq "running") {
                        Write-Host "Running" -ForegroundColor Green
                    } else {
                        Write-Host "$status (Exit: $exitCode)" -ForegroundColor Red
                    }
                }
            }
            
            if ($edgeAgent.modules) {
                Write-Host "  🏭 Factory Modules:" -ForegroundColor Cyan
                foreach ($module in $edgeAgent.modules.PSObject.Properties) {
                    $status = $module.Value.runtimeStatus
                    $exitCode = $module.Value.exitCode
                    
                    Write-Host "    • $($module.Name): " -NoNewline -ForegroundColor White
                    if ($status -eq "running") {
                        Write-Host "Running" -ForegroundColor Green
                    } else {
                        Write-Host "$status (Exit: $exitCode)" -ForegroundColor Red
                    }
                }
            }
        }
        
    } catch {
        Write-Host "❌ Failed to get health metrics: $_" -ForegroundColor Red
    }
}

# Main monitoring loop
try {
    Write-Host "🔍 Getting initial device status..." -ForegroundColor Yellow
    Get-EdgeDeviceStatus -HubName $IoTHubName -DeviceId $EdgeDeviceId
    Write-Host ""
    
    Get-EdgeModuleStatus -HubName $IoTHubName -DeviceId $EdgeDeviceId
    Write-Host ""
    
    if ($ShowHealth) {
        Get-EdgeHealthMetrics -HubName $IoTHubName -DeviceId $EdgeDeviceId
        Write-Host ""
    }
    
    if ($ShowTelemetry) {
        Start-TelemetryMonitoring -HubName $IoTHubName -DeviceId $EdgeDeviceId -Duration $MonitorDuration
    } else {
        Write-Host "ℹ️ Use -ShowTelemetry to monitor real-time telemetry" -ForegroundColor Blue
        Write-Host "ℹ️ Use -ShowHealth to see detailed health metrics" -ForegroundColor Blue
    }
    
} catch {
    Write-Error "❌ Monitoring failed: $_"
} finally {
    Write-Host ""
    Write-Host "👋 Monitoring session ended" -ForegroundColor Green
}