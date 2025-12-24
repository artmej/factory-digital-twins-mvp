# Azure Local Setup Troubleshooting Script
# Run this in PowerShell as Administrator on the VM

Write-Host "🔍 AZURE LOCAL SETUP TROUBLESHOOTING" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Check if AzureLocal folder exists
Write-Host "`n1. Checking C:\AzureLocal folder..." -ForegroundColor Yellow
$azLocalExists = Test-Path "C:\AzureLocal"
Write-Host "   C:\AzureLocal exists: $azLocalExists" -ForegroundColor $(if($azLocalExists){"Green"}else{"Red"})

# List all folders in C:\
Write-Host "`n2. Folders in C:\ drive:" -ForegroundColor Yellow
Get-ChildItem C:\ -Directory | Format-Table Name, CreationTime

# Check Custom Script Extension logs
Write-Host "`n3. Custom Script Extension Logs:" -ForegroundColor Yellow
$extensionPath = "C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension"
if (Test-Path $extensionPath) {
    Write-Host "   Extension logs found at: $extensionPath" -ForegroundColor Green
    
    # Get the latest version folder
    $latestVersion = Get-ChildItem $extensionPath | Sort-Object CreationTime -Descending | Select-Object -First 1
    if ($latestVersion) {
        Write-Host "   Latest version: $($latestVersion.Name)" -ForegroundColor Green
        
        # Check CommandExecution.log
        $commandLog = Join-Path $latestVersion.FullName "CommandExecution.log"
        if (Test-Path $commandLog) {
            Write-Host "`n4. Command Execution Log:" -ForegroundColor Yellow
            Get-Content $commandLog | Select-Object -Last 50
        } else {
            Write-Host "   CommandExecution.log not found" -ForegroundColor Red
        }
        
        # Check handler.log
        $handlerLog = Join-Path $latestVersion.FullName "handler.log"
        if (Test-Path $handlerLog) {
            Write-Host "`n5. Handler Log:" -ForegroundColor Yellow
            Get-Content $handlerLog | Select-Object -Last 20
        }
    }
} else {
    Write-Host "   Extension logs not found!" -ForegroundColor Red
}

# Check Windows Event Logs for errors
Write-Host "`n6. Recent Windows Events (last 10):" -ForegroundColor Yellow
Get-WinEvent -LogName Application -MaxEvents 10 | Where-Object {$_.LevelDisplayName -eq "Error"} | Format-Table TimeCreated, Id, LevelDisplayName, Message

# Check if Hyper-V is installed
Write-Host "`n7. Hyper-V Status:" -ForegroundColor Yellow
$hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
Write-Host "   Hyper-V State: $($hyperV.State)" -ForegroundColor $(if($hyperV.State -eq "Enabled"){"Green"}else{"Yellow"})

# Check PowerShell execution policy
Write-Host "`n8. PowerShell Execution Policy:" -ForegroundColor Yellow
$executionPolicy = Get-ExecutionPolicy
Write-Host "   Current policy: $executionPolicy" -ForegroundColor White

# Manual setup option
Write-Host "`n🔧 MANUAL SETUP OPTION:" -ForegroundColor Cyan
Write-Host "If auto-setup failed, run this to create manually:" -ForegroundColor Yellow
Write-Host @"
# Manual Azure Local Setup
New-Item -ItemType Directory -Force -Path "C:\AzureLocal"
New-Item -ItemType Directory -Force -Path "C:\AzureLocal\VMs"
New-Item -ItemType Directory -Force -Path "C:\AzureLocal\AksHci"
New-Item -ItemType Directory -Force -Path "C:\AzureLocal\Logs"
New-Item -ItemType Directory -Force -Path "C:\AzureLocal\Scripts"
New-Item -ItemType Directory -Force -Path "C:\AzureLocal\SmartFactory"

Write-Host "Manual directories created!" -ForegroundColor Green
"@ -ForegroundColor White

Write-Host "`n✅ Troubleshooting complete!" -ForegroundColor Green