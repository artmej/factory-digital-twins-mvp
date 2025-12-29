# Script de instalación remota de AKS Edge Essentials
# Ejecuta la instalación en la VM Arc usando PSRemoting

param(
    [string]$VMHost = "130.131.248.173",
    [string]$VMUser = "azureuser", 
    [string]$VMPassword = "SmartFactory2025!"
)

Write-Host "🏭 Iniciando instalación remota de AKS Edge Essentials..." -ForegroundColor Cyan

# Convertir contraseña a SecureString
$SecurePassword = ConvertTo-SecureString $VMPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($VMUser, $SecurePassword)

# Verificar conectividad
Write-Host "📡 Verificando conectividad a VM Arc..." -ForegroundColor Yellow
if (!(Test-NetConnection -ComputerName $VMHost -Port 3389 -InformationLevel Quiet)) {
    Write-Error "No se puede conectar a la VM Arc en $VMHost"
    exit 1
}

Write-Host "✅ Conectividad verificada" -ForegroundColor Green

try {
    # Crear sesión remota
    Write-Host "🔗 Creando sesión PowerShell remota..." -ForegroundColor Yellow
    
    # Habilitar PSRemoting en caso de que no esté habilitado (vía RDP)
    Write-Host "🚀 Conectándose via RDP para configurar PSRemoting..." -ForegroundColor Yellow
    Write-Host "Manual steps needed:" -ForegroundColor Cyan
    Write-Host "1. Connect to VM via RDP: mstsc /v:$VMHost" -ForegroundColor White
    Write-Host "2. Login with: $VMUser / $VMPassword" -ForegroundColor White
    Write-Host "3. Open PowerShell as Administrator" -ForegroundColor White
    Write-Host "4. Run: Enable-PSRemoting -Force" -ForegroundColor White
    Write-Host "5. Run: Set-Item wsman:\localhost\client\trustedhosts * -Force" -ForegroundColor White
    Write-Host "6. Return here and press Enter to continue" -ForegroundColor White
    
    Read-Host "Press Enter when PSRemoting is enabled on the VM"
    
    # Intentar conexión remota
    $Session = New-PSSession -ComputerName $VMHost -Credential $Credential -ErrorAction Stop
    Write-Host "✅ Sesión remota establecida" -ForegroundColor Green
    
    # Transferir y ejecutar script de instalación
    Write-Host "📤 Transfiriendo archivos de instalación..." -ForegroundColor Yellow
    
    # Crear directorio en VM remota
    Invoke-Command -Session $Session -ScriptBlock {
        New-Item -ItemType Directory -Force -Path "C:\SmartFactory\aks-edge" | Out-Null
        Write-Host "Directorio creado en VM remota"
    }
    
    # Ejecutar instalación remota
    Write-Host "🔧 Ejecutando instalación de AKS Edge Essentials..." -ForegroundColor Yellow
    
    $InstallScript = {
        Write-Host "🏭 Iniciando instalación en VM Arc..." -ForegroundColor Cyan
        
        # Verificar si se ejecuta como administrador
        $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        if (-not $IsAdmin) {
            Write-Error "El script debe ejecutarse como Administrador"
            return
        }
        
        Set-Location "C:\SmartFactory\aks-edge"
        
        # Habilitar características de Windows necesarias
        Write-Host "📋 Habilitando características de Windows..." -ForegroundColor Yellow
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart
        
        # Descargar AKS Edge Essentials
        Write-Host "📦 Descargando AKS Edge Essentials..." -ForegroundColor Yellow
        $AksEdgeUrl = "https://aka.ms/aks-edge/k3s-msi"
        $Installer = "C:\SmartFactory\aks-edge\AksEdgeEssentials.msi"
        
        try {
            Invoke-WebRequest -Uri $AksEdgeUrl -OutFile $Installer -UseBasicParsing
            Write-Host "✅ Descarga completada" -ForegroundColor Green
        } catch {
            Write-Error "Error descargando AKS Edge: $_"
            return
        }
        
        # Instalar AKS Edge Essentials
        Write-Host "🔧 Instalando AKS Edge Essentials..." -ForegroundColor Yellow
        Start-Process msiexec.exe -Wait -ArgumentList "/i `"$Installer`" /quiet /norestart"
        
        # Verificar instalación
        if (Get-Module -ListAvailable -Name AksEdge) {
            Write-Host "✅ AKS Edge Essentials instalado correctamente" -ForegroundColor Green
        } else {
            Write-Error "Error en la instalación de AKS Edge Essentials"
            return
        }
        
        Write-Host "🎉 Instalación base completada!" -ForegroundColor Green
        Write-Host "Reinicio requerido para completar la instalación" -ForegroundColor Yellow
    }
    
    # Ejecutar script en VM remota
    Invoke-Command -Session $Session -ScriptBlock $InstallScript
    
    # Cerrar sesión
    Remove-PSSession -Session $Session
    
    Write-Host "🔄 Reiniciando VM para completar instalación..." -ForegroundColor Yellow
    
    # Reiniciar VM remotamente
    Restart-Computer -ComputerName $VMHost -Credential $Credential -Force -Wait -For PowerShell -Timeout 300
    
    Write-Host "✅ Instalación fase 1 completada" -ForegroundColor Green
    Write-Host "Next: Run .\configure-aks-cluster.ps1 to deploy Kubernetes cluster" -ForegroundColor Cyan

} catch {
    Write-Error "Error durante la instalación remota: $_"
    
    # Manual fallback
    Write-Host "🚨 Fallback: Manual installation required" -ForegroundColor Red
    Write-Host "1. RDP to VM: mstsc /v:$VMHost" -ForegroundColor White
    Write-Host "2. Login: $VMUser / $VMPassword" -ForegroundColor White  
    Write-Host "3. Copy files to VM and run install-aks-edge.ps1 manually" -ForegroundColor White
}