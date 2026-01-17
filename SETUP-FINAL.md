# Configuración Final para GitHub Actions

## ✅ **Credenciales Creadas:**

- **Client ID**: `04587f2d-c127-4244-be11-a929d3c8a23d`
- **Tenant ID**: `16b3c013-d300-468d-ac64-7eda0820b6d3`
- **Subscription ID**: `ab9fac11-f205-4caa-a081-9f71b839c5c0`

## 🔧 **Siguiente Paso: Configurar Federated Identity**

**REEMPLAZA** `TU_USUARIO` y `TU_REPO` por el nombre real de tu repositorio de GitHub:

```powershell
# Para el repositorio principal (branch main)
az ad app federated-credential create --id "04587f2d-c127-4244-be11-a929d3c8a23d" --parameters '{
    "name": "factory-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:TU_USUARIO/TU_REPO:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
}'

# Para branch develop
az ad app federated-credential create --id "04587f2d-c127-4244-be11-a929d3c8a23d" --parameters '{
    "name": "factory-develop", 
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:TU_USUARIO/TU_REPO:ref:refs/heads/develop",
    "audiences": ["api://AzureADTokenExchange"]
}'

# Para pull requests
az ad app federated-credential create --id "04587f2d-c127-4244-be11-a929d3c8a23d" --parameters '{
    "name": "factory-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:TU_USUARIO/TU_REPO:pull_request", 
    "audiences": ["api://AzureADTokenExchange"]
}'
```

## 🔑 **GitHub Secrets a Configurar:**

En tu repositorio de GitHub, ve a **Settings** → **Secrets and variables** → **Actions** y agrega:

```
AZURE_CLIENT_ID = <your-client-id>
AZURE_TENANT_ID = <your-tenant-id>
AZURE_SUBSCRIPTION_ID = <your-subscription-id>
```

## 🎯 **GitHub Environments a Crear:**

1. Ve a **Settings** → **Environments** 
2. Crea estos environments:
   - `dev` 
   - `staging`
   - `production` (con required reviewers)

## 📋 **Archivos del Pipeline:**

- ✅ `/.github/workflows/ci-cd-oidc.yml` - Pipeline principal con OIDC
- ✅ `/.github/workflows/pr-environment.yml` - Entornos de PR (actualizado)
- ✅ `/tests/` - Suite completa de pruebas

**¡Una vez configures las federated credentials con el nombre real de tu repo, el pipeline estará listo! 🚀**