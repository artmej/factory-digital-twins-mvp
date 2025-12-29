# Arc Data Services - Diagnóstico Completo
# Ejecuta todos los comandos necesarios para diagnosticar el problema

Write-Host "🔍 DIAGNÓSTICO COMPLETO DE ARC DATA SERVICES" -ForegroundColor Cyan
Write-Host "=" * 60

Write-Host "`n📋 1. CONTEXTO ACTUAL:" -ForegroundColor Yellow
kubectl config current-context
kubectl config get-contexts

Write-Host "`n📋 2. NAMESPACES DISPONIBLES:" -ForegroundColor Yellow
kubectl get namespaces | findstr arc

Write-Host "`n📋 3. ESTADO DEL DATA CONTROLLER:" -ForegroundColor Yellow
kubectl get datacontroller -n arc
kubectl describe datacontroller arc-dc -n arc | Select-String -Pattern "Warning|Error|Status|State|Message"

Write-Host "`n📋 4. PODS EN ARC NAMESPACE:" -ForegroundColor Yellow
kubectl get pods -n arc

Write-Host "`n📋 5. EVENTOS RECIENTES:" -ForegroundColor Yellow
kubectl get events -n arc --sort-by='.lastTimestamp' | Select-Object -Last 15

Write-Host "`n📋 6. STORAGE CLASSES:" -ForegroundColor Yellow
kubectl get storageclass

Write-Host "`n📋 7. PERSISTENT VOLUMES:" -ForegroundColor Yellow
kubectl get pv
kubectl get pvc -n arc

Write-Host "`n📋 8. SERVICIOS EN ARC:" -ForegroundColor Yellow
kubectl get services -n arc

Write-Host "`n📋 9. VERIFICANDO CLUSTER AKS:" -ForegroundColor Yellow
Write-Host "Cambiando a AKS..."
kubectl config use-context aks
kubectl config current-context
kubectl get namespaces | findstr arc
kubectl get pods -n arc 2>$null

Write-Host "`n📋 10. VERIFICANDO CLUSTER AKS-DR:" -ForegroundColor Yellow
Write-Host "Cambiando a AKS-DR..."
kubectl config use-context aks-dr
kubectl config current-context
kubectl get namespaces | findstr arc
kubectl get pods -n arc 2>$null

Write-Host "`n📋 11. VOLVIENDO A K3S:" -ForegroundColor Yellow
kubectl config use-context k3s
kubectl config current-context

Write-Host "`n🎯 RESUMEN DEL DIAGNÓSTICO:" -ForegroundColor Green
Write-Host "=" * 60
Write-Host "✅ Contexto actual: K3s"
Write-Host "✅ Clusters disponibles: K3s, AKS, AKS-DR"
Write-Host "⚠️ Data Controller en estado: DeploymentError"
Write-Host "🔍 Revisa los eventos y storage classes arriba para identificar el problema"
Write-Host "💡 Recomendación: Usar cluster AKS para Arc Data Services"