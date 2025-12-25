# Smart Factory - GitHub Actions CI/CD (OIDC)

## 🚀 **Automated Deployment Pipeline**

### **Workflows Configurados**
- **`azure-deploy.yml`** - Deploy completo de infraestructura Azure (OIDC)
- **`vm-setup.yml`** - Configuración automática del Edge Gateway (OIDC)

## 🔐 **Secrets Requeridos (Solo IDs - Sin Contraseñas!)**

Configurar en GitHub Repository → Settings → Secrets and Variables → Actions:

```bash
# OIDC Authentication (No passwords!)
AZURE_CLIENT_ID             # App Registration ID: 1582684b-9c2e-454a-b542-e6453b435bef
AZURE_TENANT_ID              # Tenant ID: 16b3c013-d300-468d-ac64-7eda0820b6d3
AZURE_SUBSCRIPTION_ID        # Subscription ID: ab9fac11-f205-4caa-a081-9f71b839c5c0

# Only VM password needed
VM_ADMIN_PASSWORD           # VM admin password
ALLOWED_IP_ADDRESS          # Tu IP pública (x.x.x.x/32)
```

### **✅ OIDC ya configurado:**
- **App Registration**: `smart-factory-github-oidc`
- **Federated Credentials**: Main branch + Pull Requests
- **Azure Role**: Contributor en subscription

## 🔄 **Pipeline Flow**

### **1. Infraestructura (azure-deploy.yml)**
```yaml
Trigger: Push to main (infra/bicep/**)
├── Validate → Bicep template validation
├── Deploy → Azure infrastructure
├── Configure → Upload models, setup services
└── Test → Smoke tests
```

### **2. Edge Gateway (vm-setup.yml)**
```yaml
Trigger: After azure-deploy success
├── Setup-Edge → Install tools, IoT Edge
├── Deploy-Modules → Edge deployment manifest
└── Verify → Test connectivity & telemetry
```

## 📋 **Manual Deployment**

### **Trigger Manual Deploy**
```bash
# Via GitHub Actions UI
Repository → Actions → Azure Smart Factory Deploy → Run workflow
- Environment: prod/staging/dev
```

### **Local Deploy (Emergency)**
```bash
cd infra/bicep
az deployment group create \
  --resource-group rg-smartfactory-prod \
  --template-file main.bicep \
  --parameters @main.parameters.json
```

## 🏗️ **Resources Deployed**

| Service | Purpose | Configuration |
|---------|---------|---------------|
| IoT Hub S1 | Device connectivity | Managed Identity |
| Digital Twins | Factory model | RBAC enabled |
| Functions Premium | Event processing | VNet integrated |
| Cosmos DB | Telemetry storage | Standard tier |
| Key Vault | Secrets management | RBAC enabled |
| VM Standard_B2s | Edge gateway | Auto-setup via script |
| Storage Account | Data Lake | HNS enabled |

## 🎯 **Best Practices Implementadas**

- ✅ **Infrastructure as Code** (Bicep)
- ✅ **GitOps workflow** (Git-based deployments)
- ✅ **Secrets management** (GitHub Secrets + Key Vault)
- ✅ **Multi-environment** (prod/staging/dev)
- ✅ **Automated testing** (Smoke tests)
- ✅ **Zero-downtime** (Blue/green capability)
- ✅ **Rollback capability** (Git revert)

## 🔍 **Monitoring & Logs**

### **GitHub Actions Logs**
- Repository → Actions → View workflow runs
- Real-time deployment progress
- Detailed error messages

### **Azure Monitoring**
- Application Insights for Functions
- IoT Hub monitoring dashboard
- VM performance metrics

## 🚨 **Troubleshooting**

### **Failed Deployment**
1. Check GitHub Actions logs
2. Verify Azure credentials
3. Check resource quotas
4. Review Bicep template errors

### **VM Setup Issues**
1. Verify VM is running
2. Check NSG rules (port 3389)
3. Validate Run Command execution
4. Review VM extension logs

## 🔄 **Rollback Strategy**

### **Infrastructure Rollback**
```bash
# Revert git commit
git revert <commit-hash>
git push origin main

# Or redeploy previous version
git checkout <previous-tag>
# Trigger manual deployment
```

### **Emergency Stop**
```bash
# Delete resource group (DANGER!)
az group delete --name rg-smartfactory-prod --yes --no-wait
```