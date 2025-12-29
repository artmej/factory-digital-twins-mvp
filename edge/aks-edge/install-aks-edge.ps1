# Smart Factory - AKS Edge Essentials Installation Script
# Installs and configures AKS Edge Essentials on Windows VM

param(
    [string]$ClusterName = "smart-factory-edge",
    [string]$VMUser = "azureuser",
    [string]$VMPassword = "SmartFactory2025!",
    [switch]$SkipPrerequisites = $false
)

Write-Host "🏭 Installing AKS Edge Essentials for Smart Factory..." -ForegroundColor Cyan

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

# Step 1: Install prerequisites
if (-not $SkipPrerequisites) {
    Write-Host "📋 Installing prerequisites..." -ForegroundColor Yellow
    
    # Enable Hyper-V and containers features
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart
    
    # Install Windows Subsystem for Linux if not present
    if (!(Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -eq "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    }
}

# Step 2: Download and install AKS Edge Essentials
Write-Host "📦 Downloading AKS Edge Essentials..." -ForegroundColor Yellow

$aksEdgeUrl = "https://aka.ms/aks-edge/k3s-msi"
$installer = "$env:TEMP\AksEdgeEssentials.msi"

try {
    Invoke-WebRequest -Uri $aksEdgeUrl -OutFile $installer -UseBasicParsing
    Write-Host "✅ Downloaded AKS Edge Essentials installer" -ForegroundColor Green
} catch {
    Write-Error "Failed to download AKS Edge Essentials: $_"
    exit 1
}

# Install AKS Edge Essentials
Write-Host "🔧 Installing AKS Edge Essentials..." -ForegroundColor Yellow
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$installer`" /quiet /norestart"

# Import AKS Edge module
Import-Module AksEdge

# Step 3: Create cluster configuration
Write-Host "⚙️  Creating cluster configuration..." -ForegroundColor Yellow

$clusterConfig = @{
    SchemaVersion = "1.1"
    Version = "1.0"
    AksEdgeProduct = "AKS Edge Essentials - K3s"
    AksEdgeProductUrl = ""
    Azure = @{
        SubscriptionName = ""
        SubscriptionId = ""
        TenantId = ""
        ResourceGroupName = "rg-arc-simple"
        ServicePrincipalName = ""
        Location = "centralus"
        Auth = @{
            ServicePrincipalId = ""
            Password = ""
        }
    }
    AksEdgeConfigFile = "aksedge-config.json"
    Machines = @(
        @{
            LinuxNode = @{
                CpuCount = 2
                MemoryInMB = 4096
                DataSizeInGB = 10
                LogSizeInGB = 4
                Ip4Address = ""
                Ip4GatewayAddress = ""
                Ip4PrefixLength = 24
                TimeoutSeconds = 300
                TpmPassthrough = $false
                SecureBoot = $false
            }
            WindowsNode = @{
                CpuCount = 1
                MemoryInMB = 2048
                Ip4Address = ""
                Ip4GatewayAddress = ""
                Ip4PrefixLength = 24
            }
        }
    )
}

$configPath = ".\aksedge-config.json"
$clusterConfig | ConvertTo-Json -Depth 10 | Out-File $configPath

# Step 4: Deploy AKS Edge cluster
Write-Host "🚀 Deploying AKS Edge cluster..." -ForegroundColor Yellow

try {
    New-AksEdgeDeployment -JsonConfigFilePath $configPath
    Write-Host "✅ AKS Edge cluster deployed successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to deploy AKS Edge cluster: $_"
    exit 1
}

# Step 5: Configure kubectl
Write-Host "🔧 Configuring kubectl..." -ForegroundColor Yellow

# Get kubeconfig
Get-AksEdgeKubeConfig -outFile "$env:USERPROFILE\.kube\config"

# Install kubectl if not present
if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    $kubectlUrl = "https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe"
    $kubectlPath = "$env:ProgramFiles\kubectl\kubectl.exe"
    
    New-Item -ItemType Directory -Force -Path (Split-Path $kubectlPath)
    Invoke-WebRequest -Uri $kubectlUrl -OutFile $kubectlPath
    
    # Add to PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    $kubectlDir = Split-Path $kubectlPath
    if ($currentPath -notlike "*$kubectlDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$kubectlDir", "Machine")
    }
}

# Step 6: Verify installation
Write-Host "✅ Verifying installation..." -ForegroundColor Yellow

kubectl get nodes
kubectl get pods -A

Write-Host "🏭 AKS Edge Essentials installation completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run: .\deploy-data-services.ps1" -ForegroundColor White
Write-Host "2. Access Grafana at: http://localhost:30000" -ForegroundColor White
Write-Host "3. Access PostgreSQL at: localhost:30432" -ForegroundColor White