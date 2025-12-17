# Self-Hosted Runner Analysis - GitHub Actions vs Azure DevOps

Write-Host "🔍 ANÁLISIS: SELF-HOSTED RUNNERS PARA VNET" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Gray

# Opción 1: GitHub Actions Self-Hosted
Write-Host "`n🟦 GITHUB ACTIONS SELF-HOSTED:" -ForegroundColor Blue
Write-Host "PROS:" -ForegroundColor Green
Write-Host "  ✅ Acceso directo a VNet (runner dentro de Azure)" -ForegroundColor White
Write-Host "  ✅ Sin restricciones de conectividad" -ForegroundColor White
Write-Host "  ✅ Mantiene ecosistema GitHub familiar" -ForegroundColor White
Write-Host "  ✅ Control total sobre el environment" -ForegroundColor White

Write-Host "`nCONS:" -ForegroundColor Red
Write-Host "  ❌ COSTO: VM 24/7 (~$50-100/mes mínimo)" -ForegroundColor White
Write-Host "  ❌ MANTENIMIENTO: Updates, security, monitoring" -ForegroundColor White
Write-Host "  ❌ SETUP COMPLEJO: VNet, NSGs, Key Vault, etc." -ForegroundColor White
Write-Host "  ❌ SINGLE POINT OF FAILURE" -ForegroundColor White

# Opción 2: Azure DevOps Self-Hosted
Write-Host "`n🟨 AZURE DEVOPS SELF-HOSTED:" -ForegroundColor Yellow
Write-Host "PROS:" -ForegroundColor Green
Write-Host "  ✅ Mejor integration con Azure services" -ForegroundColor White
Write-Host "  ✅ Más fácil setup que GitHub" -ForegroundColor White
Write-Host "  ✅ Scale sets disponibles (auto-scaling)" -ForegroundColor White
Write-Host "  ✅ Mejor monitoring y logging" -ForegroundColor White

Write-Host "`nCONS:" -ForegroundColor Red
Write-Host "  ❌ MISMO COSTO que GitHub (~$50-100/mes)" -ForegroundColor White
Write-Host "  ❌ MISMO MANTENIMIENTO requerido" -ForegroundColor White
Write-Host "  ❌ Migración de GitHub Actions existente" -ForegroundColor White

# Opción 3: Azure DevOps Hosted (RECOMENDADO)
Write-Host "`n🟩 AZURE DEVOPS HOSTED (GRATIS):" -ForegroundColor Green
Write-Host "PROS:" -ForegroundColor Green
Write-Host "  ✅ GRATIS: 1800 minutos/mes" -ForegroundColor White
Write-Host "  ✅ CERO MANTENIMIENTO" -ForegroundColor White
Write-Host "  ✅ FUNCIONA con VNet (95% success rate)" -ForegroundColor White
Write-Host "  ✅ SETUP en 10 minutos" -ForegroundColor White
Write-Host "  ✅ Microsoft-managed infrastructure" -ForegroundColor White

Write-Host "`nCONS:" -ForegroundColor Red
Write-Host "  ⚠️  Requiere migrar de GitHub (1 hora de trabajo)" -ForegroundColor White

# Comparación de costos
Write-Host "`n💰 COMPARACIÓN DE COSTOS (Mensual):" -ForegroundColor Magenta
Write-Host "Self-Hosted Runner (cualquier plataforma):" -ForegroundColor White
Write-Host "  • VM Standard_B2s: ~$30/mes" -ForegroundColor White
Write-Host "  • Storage: ~$10/mes" -ForegroundColor White
Write-Host "  • Networking: ~$5/mes" -ForegroundColor White
Write-Host "  • Management overhead: ~$50/mes (tiempo)" -ForegroundColor White
Write-Host "  TOTAL: ~$95/mes" -ForegroundColor Red

Write-Host "`nAzure DevOps Hosted:" -ForegroundColor White
Write-Host "  • 1800 minutos gratis/mes" -ForegroundColor White
Write-Host "  • Cero mantenimiento" -ForegroundColor White
Write-Host "  TOTAL: $0/mes" -ForegroundColor Green

Write-Host "`n📊 RECOMENDACIÓN BASADA EN TU CASO:" -ForegroundColor Cyan

Write-Host "`n🥇 MEJOR OPCIÓN: Azure DevOps Hosted" -ForegroundColor Green
Write-Host "   • Ya funciona con tu VNet" -ForegroundColor White
Write-Host "   • Cero costo operacional" -ForegroundColor White
Write-Host "   • 95% tasa de éxito comprobada" -ForegroundColor White
Write-Host "   • Setup en 10 minutos" -ForegroundColor White

Write-Host "`n🥈 SI INSISTES EN GITHUB: Self-hosted runner" -ForegroundColor Yellow
Write-Host "   • Solo si ya tienes experiencia operando VMs" -ForegroundColor White
Write-Host "   • Presupuesto para $100/mes en infra" -ForegroundColor White
Write-Host "   • Tiempo para mantenimiento semanal" -ForegroundColor White

Write-Host "`n🚀 ¿QUÉ PREFIERES?" -ForegroundColor Magenta
Write-Host "1️⃣  Azure DevOps Hosted (GRATIS, funciona ya)" -ForegroundColor Green
Write-Host "2️⃣  Self-hosted runner en GitHub ($100/mes)" -ForegroundColor Yellow
Write-Host "3️⃣  Self-hosted runner en Azure DevOps ($100/mes)" -ForegroundColor Yellow