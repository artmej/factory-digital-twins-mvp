# GitHub Actions con Managed Identity / Federated Credentials

Debido a las políticas de tu organización que limitan la duración de las credenciales de service principal, podemos usar **OpenID Connect (OIDC)** con **Federated Identity Credentials** que es más seguro y no requiere secrets de larga duración.

## Opción 1: Federated Identity Credentials (Recomendado)

### 1. Crear la aplicación de Azure AD
```powershell
# Crear la aplicación
$app = az ad app create --display-name "factory-gh-actions-federated" --query "id" -o tsv

# Crear el service principal
$sp = az ad sp create --id $app --query "id" -o tsv

# Asignar el rol Contributor
az role assignment create --role contributor --scope "/subscriptions/ab9fac11-f205-4caa-a081-9f71b839c5c0" --assignee-object-id $sp --assignee-principal-type ServicePrincipal
```

### 2. Configurar Federated Identity Credential
```powershell
# Para el repositorio principal (reemplaza TU_USUARIO/TU_REPO)
az ad app federated-credential create --id $app --parameters '{
    "name": "factory-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:TU_USUARIO/TU_REPO:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
}'

# Para pull requests
az ad app federated-credential create --id $app --parameters '{
    "name": "factory-pr",
    "issuer": "https://token.actions.githubusercontent.com", 
    "subject": "repo:TU_USUARIO/TU_REPO:pull_request",
    "audiences": ["api://AzureADTokenExchange"]
}'
```

### 3. Obtener los IDs necesarios
```powershell
Write-Host "AZURE_CLIENT_ID: $app"
Write-Host "AZURE_TENANT_ID: $(az account show --query tenantId -o tsv)"
Write-Host "AZURE_SUBSCRIPTION_ID: ab9fac11-f205-4caa-a081-9f71b839c5c0"
```

## Opción 2: Usar Azure CLI desde GitHub Actions

Si no puedes crear service principals, podemos modificar el workflow para usar Azure CLI directamente con tu usuario.

### GitHub Secrets necesarios:
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID` 
- `AZURE_USERNAME` (tu email de Azure)
- `AZURE_PASSWORD` (tu contraseña de Azure)

## Opción 3: Resource Manager Template

Alternativamente, podemos usar ARM/Bicep templates que se pueden desplegar desde el portal de Azure sin necesidad de service principal.

¿Cuál opción prefieres probar primero?