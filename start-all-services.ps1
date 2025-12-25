#!/usr/bin/env pwsh
# 🚀 Smart Factory - Complete System Startup
Write-Host "
🏭 SMART FACTORY COMPLETE STARTUP
================================
" -ForegroundColor Cyan

# Start services in background
Write-Host "🔄 Starting Digital Twins Connector..." -ForegroundColor Green
Start-Job -ScriptBlock {
    Set-Location "C:\amapv2\src\digital-twins-connector"
    node connector.js
} -Name "ADT-Service" | Out-Null

Start-Sleep 2

Write-Host "🔄 Starting Mobile Server..." -ForegroundColor Green  
Start-Job -ScriptBlock {
    Set-Location "C:\amapv2\src\mobile-server"
    node mobile-server.js
} -Name "Mobile-Service" | Out-Null

Start-Sleep 2

Write-Host "🔄 Starting 3D Factory Viewer..." -ForegroundColor Green
Start-Job -ScriptBlock {
    Set-Location "C:\amapv2\src\3d-digital-twins"
    node simple-server.js
} -Name "3D-Service" | Out-Null

Start-Sleep 5

# Check services
Write-Host "`n📊 SERVICE STATUS:" -ForegroundColor Yellow
$services = @(
    @{Name="Digital Twins API"; Port=3004; URL="http://localhost:3004/api/status"},
    @{Name="Mobile Interface"; Port=3002; URL="http://localhost:3002/health"},
    @{Name="3D Factory Viewer"; Port=3003; URL="http://localhost:3003/debug"}
)

foreach ($service in $services) {
    try {
        $response = Invoke-WebRequest $service.URL -TimeoutSec 3 -UseBasicParsing
        Write-Host "✅ $($service.Name): ONLINE (Port $($service.Port))" -ForegroundColor Green
    } catch {
        Write-Host "❌ $($service.Name): OFFLINE (Port $($service.Port))" -ForegroundColor Red
    }
}

Write-Host "`n🌐 ACCESS URLS:" -ForegroundColor Cyan
Write-Host "📊 Control Dashboard: http://localhost:3003/dashboard" -ForegroundColor White
Write-Host "🎮 3D Factory Viewer: http://localhost:3003" -ForegroundColor White
Write-Host "📡 Digital Twins API: http://localhost:3004/api/twins/factory" -ForegroundColor White
Write-Host "📱 Mobile Interface: http://localhost:3002" -ForegroundColor White

Write-Host "`n🎭 DEMO READY!" -ForegroundColor Green
Write-Host "Open http://localhost:3003/dashboard for complete system overview" -ForegroundColor Cyan
Write-Host "`nTo stop all: Get-Job | Stop-Job; Get-Job | Remove-Job" -ForegroundColor Gray