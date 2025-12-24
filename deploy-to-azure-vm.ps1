# Script para desplegar Azure Local con AKS Edge Essentials EN LA VM DE AZURE
param(
    [string]$VMPublicIP = "132.196.12.45",
    [string]$VMUser = "azureuser",
    [string]$VMPassword = "SmartFactory2024!",
    [string]$LocalScriptPath = "C:\amapv2\complete-azure-local-setup-simple.ps1"
)

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  DEPLOYING TO AZURE VM - AKS LOCAL      ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 Target VM: $VMPublicIP" -ForegroundColor Cyan
Write-Host "👤 User: $VMUser" -ForegroundColor Cyan
Write-Host "📁 Script: $LocalScriptPath" -ForegroundColor Cyan
Write-Host ""

# 1. VERIFICAR CONECTIVIDAD A LA VM
Write-Host "1. Verificando conectividad a la VM..." -ForegroundColor Yellow
try {
    $result = Test-NetConnection -ComputerName $VMPublicIP -Port 3389 -InformationLevel Quiet
    if ($result) {
        Write-Host "✓ VM accesible en puerto RDP" -ForegroundColor Green
    } else {
        Write-Host "❌ No se puede conectar a la VM" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error verificando conectividad: $_" -ForegroundColor Red
    exit 1
}

# 2. CREAR CREDENCIALES
Write-Host "2. Preparando credenciales..." -ForegroundColor Yellow
$secpasswd = ConvertTo-SecureString $VMPassword -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential ($VMUser, $secpasswd)

# 3. CREAR SESSION REMOTA A LA VM
Write-Host "3. Estableciendo conexión remota..." -ForegroundColor Yellow
try {
    $session = New-PSSession -ComputerName $VMPublicIP -Credential $creds -ErrorAction Stop
    Write-Host "✓ Sesión remota establecida" -ForegroundColor Green
} catch {
    Write-Host "❌ Error conectando a la VM: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Alternativa - Conectarse manualmente:" -ForegroundColor Yellow
    Write-Host "   mstsc /v:$VMPublicIP" -ForegroundColor White
    Write-Host "   Usuario: $VMUser" -ForegroundColor White
    Write-Host "   Password: $VMPassword" -ForegroundColor White
    Write-Host ""
    Write-Host "   Luego copiar y ejecutar el script manualmente" -ForegroundColor White
    exit 1
}

# 4. VERIFICAR ESTADO DE LA VM
Write-Host "4. Verificando estado de la VM remota..." -ForegroundColor Yellow
$vmInfo = Invoke-Command -Session $session -ScriptBlock {
    return @{
        OS = (Get-CimInstance Win32_OperatingSystem).Caption
        Memory = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB, 2)
        Processor = (Get-CimInstance Win32_Processor).Name
        HyperV = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All).State
        PowerShell = $PSVersionTable.PSVersion.ToString()
    }
}

Write-Host "   OS: $($vmInfo.OS)" -ForegroundColor Cyan
Write-Host "   Memory: $($vmInfo.Memory) GB" -ForegroundColor Cyan  
Write-Host "   Processor: $($vmInfo.Processor)" -ForegroundColor Cyan
Write-Host "   Hyper-V: $($vmInfo.HyperV)" -ForegroundColor Cyan
Write-Host "   PowerShell: $($vmInfo.PowerShell)" -ForegroundColor Cyan

# 5. COPIAR SCRIPT A LA VM
Write-Host "5. Copiando script a la VM..." -ForegroundColor Yellow
try {
    Copy-Item -Path $LocalScriptPath -Destination "C:\azure-local-setup.ps1" -ToSession $session
    Write-Host "✓ Script copiado exitosamente" -ForegroundColor Green
} catch {
    Write-Host "❌ Error copiando script: $_" -ForegroundColor Red
    Remove-PSSession $session
    exit 1
}

# 6. EJECUTAR SCRIPT EN LA VM
Write-Host "6. Ejecutando script Azure Local en la VM..." -ForegroundColor Yellow
Write-Host ""
Write-Host "⚡ INICIANDO DEPLOYMENT DE AKS EDGE ESSENTIALS..." -ForegroundColor Green
Write-Host ""

try {
    Invoke-Command -Session $session -ScriptBlock {
        # Cambiar al directorio de trabajo
        Set-Location C:\
        
        # Ejecutar el script
        Write-Host "Ejecutando script Azure Local..." -ForegroundColor Green
        & .\azure-local-setup.ps1
    }
    
    Write-Host ""
    Write-Host "✅ Script ejecutado exitosamente en la VM" -ForegroundColor Green
} catch {
    Write-Host "❌ Error ejecutando script: $_" -ForegroundColor Red
} finally {
    Remove-PSSession $session
}

# 7. MOSTRAR INSTRUCCIONES FINALES
Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║           DEPLOYMENT COMPLETED          ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 PRÓXIMOS PASOS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Conectarse a la VM vía RDP:" -ForegroundColor White
Write-Host "   mstsc /v:$VMPublicIP" -ForegroundColor Cyan
Write-Host "   Usuario: $VMUser" -ForegroundColor Cyan
Write-Host "   Password: $VMPassword" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Verificar AKS Local:" -ForegroundColor White
Write-Host "   cd C:\AzureLocal\AksHci" -ForegroundColor Cyan
Write-Host "   .\kubectl.ps1 cluster-info" -ForegroundColor Cyan
Write-Host "   .\kubectl.ps1 get nodes" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Desplegar Smart Factory:" -ForegroundColor White
Write-Host "   cd C:\AzureLocal\SmartFactory" -ForegroundColor Cyan
Write-Host "   .\deploy-smart-factory.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Acceder a los servicios (desde dentro de la VM):" -ForegroundColor White
Write-Host "   SCADA Dashboard: http://localhost:30080" -ForegroundColor Cyan
Write-Host "   Factory Simulator: http://localhost:30081" -ForegroundColor Cyan
Write-Host "   Robot Controller: http://localhost:30082" -ForegroundColor Cyan
Write-Host "   InfluxDB: http://localhost:30083" -ForegroundColor Cyan
Write-Host ""
Write-Host "🚀 Azure Local con AKS Edge Essentials listo!" -ForegroundColor Green