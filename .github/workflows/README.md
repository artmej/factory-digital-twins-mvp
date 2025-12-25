# Smart Factory - GitHub Actions CI/CD

## 🚀 **Automated Deployment Pipeline**

### **Workflows Configurados**
- **`azure-deploy.yml`** - Deploy completo de infraestructura Azure
- **`vm-setup.yml`** - Configuración automática del Edge Gateway

## 🔐 **Secrets Requeridos**

Configurar en GitHub Repository → Settings → Secrets and Variables → Actions:

```bash
AZURE_CREDENTIALS          # Service Principal JSON
ADMIN_USERNAME              # VM admin username  
ADMIN_PASSWORD              # VM admin password
ALLOWED_IP_ADDRESS          # Tu IP pública (x.x.x.x/32)
```

### **Crear Service Principal**
```bash
az ad sp create-for-rbac --name "smart-factory-deploy" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth
```

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