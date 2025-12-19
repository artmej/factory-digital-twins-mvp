# DevOps Foundation Setup Guide

## 🎯 Objetivo
Establecer un pipeline de DevOps **sólido y confiable** para el proyecto Factory Digital Twins antes de implementar características del capstone.

## ⚡ Pipeline Implementado

### 📋 Características Principales
- ✅ **Build & Test** automatizado
- ✅ **Validación de infraestructura** existente
- ✅ **Deployment sin VNet conflicts** 
- ✅ **OIDC authentication** (más seguro)
- ✅ **Artifacts management**
- ✅ **Health checks** post-deployment

### 🛡️ Estrategia Anti-VNet
Para evitar los problemas de VNet que bloqueaban deployments:
1. **ZIP deployment** via Azure CLI (bypass network restrictions)
2. **REST API direct calls** instead of GitHub Actions Azure extensions
3. **Validation-first approach** (check existing infrastructure)
4. **Safe deployment methods** that work with existing setup

## 🔐 Configuración Requerida

### 1. GitHub OIDC Secrets
Necesitas configurar estos secretos en GitHub:

```
AZURE_CLIENT_ID       # App Registration Client ID
AZURE_TENANT_ID       # Azure AD Tenant ID  
AZURE_SUBSCRIPTION_ID # Azure Subscription ID
```

### 2. Azure App Registration Setup
```powershell
# Crear App Registration para GitHub OIDC
az ad app create --display-name "GitHub-Factory-DevOps" --sign-in-audience AzureADMyOrg

# Obtener Client ID
az ad app list --display-name "GitHub-Factory-DevOps" --query "[0].appId" -o tsv

# Configurar Federated Credentials
az ad app federated-credential create \
  --id <APP_ID> \
  --parameters @federated-credential.json
```

### 3. Federated Credential Configuration
```json
{
  "name": "GitHubActions",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:yourusername/amapv2:ref:refs/heads/main",
  "description": "GitHub Actions OIDC",
  "audiences": ["api://AzureADTokenExchange"]
}
```

## 🚀 Deployment Strategy

### Fase 0: DevOps Foundation (ACTUAL)
- [x] Pipeline creation ✅
- [ ] OIDC configuration ⏳
- [ ] Test deployment ⏳
- [ ] Automated testing setup ⏳

### Beneficios del Nuevo Pipeline:
1. **Sin Service Principal passwords** (más seguro)
2. **ZIP deployment** evita VNet issues
3. **Validation steps** previenen deployments rotos
4. **Build artifacts** para rollbacks
5. **Health checks** automáticos

## 📊 Pipeline Jobs

### 🔨 Build & Test
- Node.js setup y dependencies
- Unit tests (preparado para expansion)
- Code quality validation
- DTDL model validation
- Docker builds
- Artifact packaging

### 🏗️ Infrastructure Validation  
- Azure login via OIDC
- Resource existence checks
- Health status validation
- Pre-deployment verification

### 🚀 Deploy (Main branch only)
- Safe ZIP deployment method
- Post-deployment validation
- Health checks
- Deployment summary

## 🎯 Próximos Pasos

1. **Configurar OIDC** (15 min)
2. **Test deployment** (15 min) 
3. **Add unit tests** (30 min)
4. **Automated testing** (30 min)

**Total Phase 0: ~1.5 horas** ⏰

Una vez que tengamos **DevOps sólido**, procedemos con:
- Phase 1: Factory Worker Agents
- Phase 2: Showcase Features  
- Phase 3: Capstone Polish

## 💡 Notas Técnicas

- Pipeline usa **ubuntu-latest** (más estable)
- **Conditional deployment** solo en main branch
- **Artifact retention** de 7 días
- **Safe deployment** methods que funcionan con VNet
- **Comprehensive logging** para debugging

¿Configuramos OIDC ahora para activar el pipeline? 🚀