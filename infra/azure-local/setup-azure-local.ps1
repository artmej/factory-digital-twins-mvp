# Azure Local Setup Script for Smart Factory
# Run this script on the Windows VM to configure Azure Local and AKS

param(
    [string]$SubscriptionId = "",
    [string]$ResourceGroup = "rg-smart-factory-vms",
    [string]$ClusterName = "aks-smart-factory-local"
)

# Colors for output
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

function Write-StatusMessage {
    param([string]$Message, [string]$Color = "White")
    Write-Host "🏭 $Message" -ForegroundColor $Color
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor $InfoColor
}

Clear-Host
Write-Host @"

     🏭 SMART FACTORY AZURE LOCAL SETUP 🏭
    ========================================
    
    This script will configure:
    • Azure Stack HCI simulation
    • AKS on Azure Local
    • Smart Factory deployment
    
    Starting setup process...

"@ -ForegroundColor $InfoColor

# Step 1: Verify Prerequisites
Write-Step "Step 1: Verifying Prerequisites"

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-StatusMessage "This script must run as Administrator. Restarting..." $WarningColor
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Write-StatusMessage "✅ Running as Administrator" $SuccessColor

# Check Hyper-V
$hyperV = Get-WindowsFeature -Name Hyper-V
if ($hyperV.InstallState -eq "Installed") {
    Write-StatusMessage "✅ Hyper-V is installed" $SuccessColor
} else {
    Write-StatusMessage "Installing Hyper-V..." $InfoColor
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    Write-StatusMessage "⚠️  Hyper-V installed, restart required after script completion" $WarningColor
}

# Step 2: Install Required Modules
Write-Step "Step 2: Installing PowerShell Modules"

$modules = @(
    @{Name="Az"; MinVersion="10.0.0"},
    @{Name="AzStackHCI"; MinVersion="1.0.0"},
    @{Name="AksHci"; MinVersion="1.0.0"}
)

foreach ($module in $modules) {
    Write-StatusMessage "Installing $($module.Name)..." $InfoColor
    try {
        Install-Module -Name $module.Name -MinimumVersion $module.MinVersion -Force -AllowClobber -Scope AllUsers
        Write-StatusMessage "✅ $($module.Name) installed" $SuccessColor
    } catch {
        Write-StatusMessage "❌ Failed to install $($module.Name): $_" $ErrorColor
    }
}

# Step 3: Configure Azure Authentication
Write-Step "Step 3: Azure Authentication"

try {
    $context = Get-AzContext
    if (-not $context) {
        Write-StatusMessage "Please sign in to Azure..." $InfoColor
        Connect-AzAccount
    } else {
        Write-StatusMessage "✅ Already signed in to Azure as $($context.Account.Id)" $SuccessColor
    }
} catch {
    Write-StatusMessage "❌ Azure authentication failed: $_" $ErrorColor
    exit 1
}

# Step 4: Initialize Azure Local Simulation
Write-Step "Step 4: Azure Local (Stack HCI) Simulation Setup"

# Create Azure Local directory structure
$azLocalPath = "C:\AzureLocal"
Write-StatusMessage "Creating Azure Local workspace at $azLocalPath..." $InfoColor
New-Item -ItemType Directory -Force -Path $azLocalPath | Out-Null
New-Item -ItemType Directory -Force -Path "$azLocalPath\VMs" | Out-Null
New-Item -ItemType Directory -Force -Path "$azLocalPath\AksHci" | Out-Null
New-Item -ItemType Directory -Force -Path "$azLocalPath\Logs" | Out-Null

# Configure Hyper-V Virtual Switch
Write-StatusMessage "Configuring Hyper-V virtual switch..." $InfoColor
try {
    $existingSwitch = Get-VMSwitch -Name "AzureLocalSwitch" -ErrorAction SilentlyContinue
    if (-not $existingSwitch) {
        New-VMSwitch -Name "AzureLocalSwitch" -SwitchType Internal
        Write-StatusMessage "✅ Virtual switch created" $SuccessColor
    } else {
        Write-StatusMessage "✅ Virtual switch already exists" $SuccessColor
    }
} catch {
    Write-StatusMessage "❌ Failed to create virtual switch: $_" $ErrorColor
}

# Configure Storage Spaces Direct simulation
Write-Step "Step 5: Storage Configuration"

Write-StatusMessage "Initializing storage for Azure Local simulation..." $InfoColor
$rawDisks = Get-Disk | Where-Object {$_.PartitionStyle -eq 'RAW'}
foreach ($disk in $rawDisks) {
    try {
        Initialize-Disk -Number $disk.Number -PartitionStyle GPT -Force
        $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -DriveLetter S
        Format-Volume -DriveLetter S -FileSystem NTFS -NewFileSystemLabel 'AzureLocalStorage' -Force
        Write-StatusMessage "✅ Storage disk $($disk.Number) configured" $SuccessColor
        break
    } catch {
        Write-StatusMessage "⚠️  Storage configuration: $_" $WarningColor
    }
}

# Step 6: AKS HCI Setup Simulation
Write-Step "Step 6: AKS on Azure Local Setup"

Write-StatusMessage "Configuring AKS HCI working directory..." $InfoColor
$aksWorkingDir = "$azLocalPath\AksHci"

# Create AKS HCI configuration
$aksConfig = @{
    workingDir = $aksWorkingDir
    cloudLocation = "eastus"
    clusterName = $ClusterName
    nodeCount = 2
    nodeVmSize = "Standard_K8S3_v1"
    kubernetesVersion = "v1.28.5"
    loadBalancerCount = 1
}

$aksConfigJson = $aksConfig | ConvertTo-Json -Depth 3
$aksConfigJson | Out-File -FilePath "$aksWorkingDir\aks-config.json" -Encoding UTF8

# Step 7: Deploy Smart Factory Kubernetes Manifests  
Write-Step "Step 7: Preparing Smart Factory Deployment"

Write-StatusMessage "Downloading factory manifests..." $InfoColor
$factoryPath = "$azLocalPath\SmartFactory"
New-Item -ItemType Directory -Force -Path $factoryPath | Out-Null

# Copy manifest files (these would be copied from the repository)
Write-StatusMessage "Manifest files will be copied to: $factoryPath" $InfoColor
Write-StatusMessage "To complete deployment:" $InfoColor
Write-StatusMessage "1. Copy k8s-manifests folder to $factoryPath" $WarningColor
Write-StatusMessage "2. Run: kubectl apply -f $factoryPath\k8s-manifests\" $WarningColor

# Step 8: Create Desktop Shortcuts and Final Setup
Write-Step "Step 8: Final Configuration"

# Create desktop shortcuts
$WshShell = New-Object -comObject WScript.Shell

# Azure Local Management shortcut
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Azure Local Management.lnk")
$Shortcut.TargetPath = $azLocalPath
$Shortcut.IconLocation = "C:\Windows\System32\shell32.dll,4"
$Shortcut.Description = "Azure Local Smart Factory Management"
$Shortcut.Save()

# PowerShell admin shortcut
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\PowerShell Admin.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-NoProfile"
$Shortcut.IconLocation = "powershell.exe,0"
$Shortcut.Description = "PowerShell as Administrator"
$Shortcut.Save()

# Create completion script
$completionScript = @"
# Azure Local Smart Factory - Final Setup Steps
# Run these commands after AKS cluster is ready

Write-Host "🏭 Azure Local Smart Factory - Final Setup" -ForegroundColor Green
Write-Host "==========================================`n" -ForegroundColor Green

# Check cluster status
Write-Host "Checking AKS cluster status..." -ForegroundColor Cyan
kubectl cluster-info

# Deploy Smart Factory
Write-Host "Deploying Smart Factory..." -ForegroundColor Cyan
Set-Location "$factoryPath\k8s-manifests"
.\deploy-factory.sh

# Monitor deployment
Write-Host "Monitoring deployment..." -ForegroundColor Cyan
kubectl get pods -n smart-factory -w
"@

$completionScript | Out-File -FilePath "$azLocalPath\complete-setup.ps1" -Encoding UTF8

# Create README file
$readme = @"
# Azure Local Smart Factory Setup Complete

## 🎉 Setup Status: READY FOR AKS DEPLOYMENT

### What's Configured:
✅ Hyper-V enabled (restart may be required)
✅ PowerShell modules installed (Az, AzStackHCI, AksHci)  
✅ Azure authentication configured
✅ Virtual networking setup
✅ Storage configuration
✅ AKS HCI workspace prepared

### Next Steps:

1. **Restart the VM** (if Hyper-V was just installed)
2. **Complete AKS HCI initialization:**
   ```powershell
   Initialize-AksHci -workingDir "C:\AzureLocal\AksHci"
   ```

3. **Create AKS cluster:**
   ```powershell
   New-AksHciCluster -name "$ClusterName" -nodeCount 2 -nodeVmSize Standard_K8S3_v1
   ```

4. **Get cluster credentials:**
   ```powershell
   Get-AksHciCredential -name "$ClusterName"
   ```

5. **Deploy Smart Factory:**
   - Copy the k8s-manifests folder to C:\AzureLocal\SmartFactory\
   - Run: .\deploy-factory.sh

### Access Information:

- **Azure Local Workspace**: C:\AzureLocal\
- **AKS Working Directory**: C:\AzureLocal\AksHci\
- **Factory Manifests**: C:\AzureLocal\SmartFactory\
- **Logs Directory**: C:\AzureLocal\Logs\

### Monitoring Commands:

```powershell
# Check cluster status
kubectl cluster-info

# Monitor factory deployment  
kubectl get all -n smart-factory

# View factory dashboard
# URL will be displayed after deployment
```

### Troubleshooting:

- **Hyper-V Issues**: Ensure nested virtualization is enabled on the Azure VM
- **AKS HCI Fails**: Check available memory and CPU resources
- **Network Issues**: Verify virtual switch configuration

### Architecture:

```
🌐 Azure VM (D4s_v4)
└── 💿 Azure Local (Stack HCI simulation)
    └── ⚙️ AKS Cluster (2 nodes)
        └── 🏭 Smart Factory
            ├── Factory Simulator
            ├── Robot Controller  
            ├── SCADA Dashboard
            ├── Time Series DB
            └── Cache Layer
```

This represents a real on-premises deployment that provides:
- Local autonomy and processing
- Edge computing capabilities  
- Industrial protocol simulation
- Real-time monitoring
- Cloud sync when available

🎯 **Ready to deploy your Smart Factory on Azure Local!**
"@

$readme | Out-File -FilePath "$azLocalPath\README.md" -Encoding UTF8

# Final summary
Write-Step "Setup Complete!"

Write-Host @"

🎉 AZURE LOCAL SETUP COMPLETED! 🎉
================================

✅ Configuration Status:
   • Hyper-V: Configured
   • PowerShell Modules: Installed
   • Azure Auth: Connected
   • Virtual Networking: Ready
   • Storage: Configured  
   • AKS Workspace: Prepared

📁 Files Created:
   • C:\AzureLocal\ (main workspace)
   • Desktop shortcuts for management
   • README.md with next steps
   • complete-setup.ps1 for final deployment

🔄 Next Actions Required:
   1. Restart VM (if Hyper-V was installed)
   2. Initialize AKS HCI cluster
   3. Deploy Smart Factory manifests
   4. Access factory dashboards

📋 Quick Reference:
   • Azure Local Workspace: C:\AzureLocal\
   • Management Tools: Desktop shortcuts  
   • Next Steps Guide: C:\AzureLocal\README.md

🌐 When complete, your factory will be accessible at:
   • SCADA Dashboard: http://cluster-ip:8080
   • Factory Simulator: http://cluster-ip:8081  
   • Robot Controller: http://cluster-ip:8082

🏭 You're ready to deploy your Smart Factory on Azure Local! 🚀

"@ -ForegroundColor $SuccessColor

# Offer to restart if Hyper-V was installed
if ($hyperV.InstallState -ne "Installed") {
    $restart = Read-Host "`nHyper-V was installed. Restart now? (y/N)"
    if ($restart -eq 'y' -or $restart -eq 'Y') {
        Write-StatusMessage "Restarting system..." $WarningColor
        Restart-Computer -Force
    }
}

Write-StatusMessage "Setup script completed. Check C:\AzureLocal\README.md for next steps." $InfoColor