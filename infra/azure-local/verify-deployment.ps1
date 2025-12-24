# Smart Factory Azure Local - Deployment Verification Script
# Run this to check the complete deployment status

param(
    [string]$ResourceGroup = "rg-smart-factory-vms"
)

Clear-Host
Write-Host @"

🏭 SMART FACTORY AZURE LOCAL VERIFICATION 🏭
===========================================

"@ -ForegroundColor Green

# Check Azure connection
Write-Host "🔍 Checking Azure connection..." -ForegroundColor Cyan
try {
    $context = Get-AzContext
    if ($context) {
        Write-Host "✅ Connected to Azure as: $($context.Account.Id)" -ForegroundColor Green
        Write-Host "   Subscription: $($context.Subscription.Name)" -ForegroundColor Gray
    } else {
        Write-Host "❌ Not connected to Azure. Run Connect-AzAccount" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Azure PowerShell not available" -ForegroundColor Red
    exit 1
}

# Check Resource Group
Write-Host "`n🔍 Checking Resource Group..." -ForegroundColor Cyan
try {
    $rg = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction Stop
    Write-Host "✅ Resource Group: $($rg.ResourceGroupName)" -ForegroundColor Green
    Write-Host "   Location: $($rg.Location)" -ForegroundColor Gray
    Write-Host "   Status: $($rg.ProvisioningState)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Resource Group '$ResourceGroup' not found" -ForegroundColor Red
    exit 1
}

# Check VM Deployment
Write-Host "`n🔍 Checking VM Deployment..." -ForegroundColor Cyan
$deployment = Get-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup | 
    Where-Object {$_.DeploymentName -like "*azure-local*"} | 
    Sort-Object Timestamp -Descending | 
    Select-Object -First 1

if ($deployment) {
    Write-Host "📋 Latest Deployment: $($deployment.DeploymentName)" -ForegroundColor Yellow
    Write-Host "   Status: $($deployment.ProvisioningState)" -ForegroundColor $(if ($deployment.ProvisioningState -eq 'Succeeded') {'Green'} else {'Red'})
    Write-Host "   Timestamp: $($deployment.Timestamp)" -ForegroundColor Gray
    
    if ($deployment.ProvisioningState -eq 'Failed') {
        Write-Host "`n❌ Deployment failed. Error details:" -ForegroundColor Red
        $deployment | Format-List DeploymentName, ProvisioningState, Timestamp
        
        # Try to get error details
        try {
            $operations = Get-AzResourceGroupDeploymentOperation -ResourceGroupName $ResourceGroup -DeploymentName $deployment.DeploymentName
            $failedOps = $operations | Where-Object {$_.ProvisioningState -eq 'Failed'}
            foreach ($op in $failedOps) {
                Write-Host "   Error: $($op.StatusMessage)" -ForegroundColor Red
            }
        } catch {
            Write-Host "   Could not retrieve detailed error information" -ForegroundColor Yellow
        }
        
        # Show common solutions
        Write-Host "`n💡 Common Solutions:" -ForegroundColor Yellow
        Write-Host "   • Try different VM size (Standard_D2s_v3, Standard_B4ms)" -ForegroundColor Gray
        Write-Host "   • Try different region (West US 2, Central US)" -ForegroundColor Gray
        Write-Host "   • Check subscription quota limits" -ForegroundColor Gray
        exit 1
    }
} else {
    Write-Host "❌ No Azure Local deployments found" -ForegroundColor Red
    exit 1
}

# Check VM Resources
Write-Host "`n🔍 Checking VM Resources..." -ForegroundColor Cyan
$vm = Get-AzVM -ResourceGroupName $ResourceGroup | Where-Object {$_.Name -like "*azure-local*"}
if ($vm) {
    Write-Host "✅ VM Found: $($vm.Name)" -ForegroundColor Green
    Write-Host "   Size: $($vm.HardwareProfile.VmSize)" -ForegroundColor Gray
    Write-Host "   Location: $($vm.Location)" -ForegroundColor Gray
    Write-Host "   Status: $(if ($vm.PowerState -eq 'VM running') {'Running'} else {$vm.PowerState})" -ForegroundColor $(if ($vm.PowerState -eq 'VM running') {'Green'} else {'Yellow'})
    
    # Get public IP
    $nic = Get-AzNetworkInterface -ResourceGroupName $ResourceGroup | Where-Object {$_.VirtualMachine.Id -eq $vm.Id}
    if ($nic) {
        $publicIpId = $nic.IpConfigurations[0].PublicIpAddress.Id
        if ($publicIpId) {
            $publicIp = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroup | Where-Object {$_.Id -eq $publicIpId}
            if ($publicIp.IpAddress -and $publicIp.IpAddress -ne "Not Assigned") {
                Write-Host "🌐 Public IP: $($publicIp.IpAddress)" -ForegroundColor Green
                Write-Host "   DNS: $($publicIp.DnsSettings.Fqdn)" -ForegroundColor Gray
                
                # RDP connection string
                Write-Host "`n🖥️  RDP Connection:" -ForegroundColor Cyan
                Write-Host "   mstsc /v:$($publicIp.IpAddress)" -ForegroundColor Yellow
                Write-Host "   Username: smartfactory" -ForegroundColor Gray
                Write-Host "   Password: SmartFactory2024!" -ForegroundColor Gray
            } else {
                Write-Host "⚠️  Public IP not yet assigned" -ForegroundColor Yellow
            }
        }
    }
} else {
    Write-Host "❌ VM not found" -ForegroundColor Red
    exit 1
}

# Check Network Security Group
Write-Host "`n🔍 Checking Network Security..." -ForegroundColor Cyan
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup | Where-Object {$_.Name -like "*azure-local*"}
if ($nsg) {
    Write-Host "✅ NSG Found: $($nsg.Name)" -ForegroundColor Green
    $rdpRule = $nsg.SecurityRules | Where-Object {$_.Name -eq 'RDP'}
    if ($rdpRule) {
        Write-Host "   RDP Access: Enabled (Port 3389)" -ForegroundColor Green
    }
    
    $factoryRules = $nsg.SecurityRules | Where-Object {$_.DestinationPortRange -in @('8080','8081','8082')}
    if ($factoryRules) {
        Write-Host "   Factory Ports: Enabled (8080-8082)" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️  NSG not found" -ForegroundColor Yellow
}

# Show next steps
Write-Host "`n🚀 NEXT STEPS:" -ForegroundColor Green
Write-Host "==============" -ForegroundColor Green

if ($vm -and $deployment.ProvisioningState -eq 'Succeeded') {
    Write-Host "1. 🔐 RDP to the VM using the connection info above" -ForegroundColor Yellow
    Write-Host "2. 📁 Navigate to C:\AzureLocal\" -ForegroundColor Yellow
    Write-Host "3. 📋 Review README.md for detailed instructions" -ForegroundColor Yellow
    Write-Host "4. 🔧 Run setup-azure-local.ps1 to configure Azure Local" -ForegroundColor Yellow
    Write-Host "5. ⚙️  Initialize AKS HCI cluster" -ForegroundColor Yellow
    Write-Host "6. 🏭 Deploy Smart Factory using k8s-manifests/" -ForegroundColor Yellow
    
    Write-Host "`n📊 Expected Final URLs:" -ForegroundColor Cyan
    Write-Host "   SCADA Dashboard: http://$($publicIp.IpAddress):8080" -ForegroundColor Gray
    Write-Host "   Factory Simulator: http://$($publicIp.IpAddress):8081" -ForegroundColor Gray
    Write-Host "   Robot Controller: http://$($publicIp.IpAddress):8082" -ForegroundColor Gray
    
    Write-Host "`n🎯 You're ready to complete the Azure Local Smart Factory deployment!" -ForegroundColor Green
} else {
    Write-Host "❌ VM deployment must complete successfully first" -ForegroundColor Red
    Write-Host "   Check deployment errors above and retry" -ForegroundColor Yellow
}

Write-Host "`n📖 Documentation:" -ForegroundColor Cyan
Write-Host "   Architecture: .\ARCHITECTURE-OVERVIEW.md" -ForegroundColor Gray
Write-Host "   Deployment Guide: .\k8s-manifests\DEPLOYMENT.md" -ForegroundColor Gray
Write-Host "   Manifest Files: .\k8s-manifests\*.yaml" -ForegroundColor Gray

Write-Host "`n🏭 Smart Factory Azure Local Verification Complete! 🎉" -ForegroundColor Green