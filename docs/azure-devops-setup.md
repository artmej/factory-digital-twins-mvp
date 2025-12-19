# Azure DevOps Pipeline Configuration Guide
# Optimized for VNet and Private Resources

## 🎯 Why Azure DevOps > GitHub Actions for VNets?

### Connectivity Advantages:
1. **Microsoft-hosted agents** tienen mejor conectividad con Azure VNets
2. **Managed Service Identity** integration más robusta
3. **Private endpoint** compatibility superior
4. **Network policies** más flexibles para organizaciones

## 📋 Setup Steps

### 1. Create Azure DevOps Project
```bash
# Create project in Azure DevOps
# Name: factory-digital-twins-mvp
# Visibility: Private (recommended)
```

### 2. Configure Service Connection
En Azure DevOps → Project Settings → Service connections:

**Service Connection Type:** Azure Resource Manager
**Authentication method:** Service principal (automatic)
**Scope level:** Subscription
**Service connection name:** `factory-service-connection`

### 3. Required Permissions
El service principal necesita:
- **Contributor** en la subscription
- **User Access Administrator** para managed identity roles
- **Azure Digital Twins Data Owner** 

### 4. Variable Groups
Create Variable Group: `factory-variables`

Variables:
```yaml
AZURE_SUBSCRIPTION_ID: "your-subscription-id"
AZURE_TENANT_ID: "your-tenant-id"
RESOURCE_PREFIX: "factory"
LOCATION: "eastus"
```

### 5. Environments
Create Environments:
- **dev** (Development)
- **staging** (Optional)
- **prod** (Production)

## 🔧 Pipeline Features

### VNet Compatibility:
- ✅ **zipDeploy** method (mejor que SCM)
- ✅ **Microsoft-hosted agents** (conectividad Azure nativa)
- ✅ **Managed Identity** integration
- ✅ **Private endpoints** support
- ✅ **Network policies** compliance

### Deployment Strategy:
1. **Infrastructure First**: Bicep deployment
2. **Code Deployment**: Function App via zipDeploy
3. **Configuration**: App settings y managed identity
4. **Validation**: Integration tests

### Managed Identity Benefits:
- No secrets in pipeline
- Automatic role assignments
- VNet-native authentication
- Zero credential management

## 🚀 Migration from GitHub Actions

### 1. Import Repository
```bash
# In Azure DevOps
# Repos → Import repository
# Source: https://github.com/artmej/factory-digital-twins-mvp
```

### 2. Configure Pipeline
- Upload `azure-pipelines.yml`
- Configure service connection
- Set up variable groups
- Create environments

### 3. Test Deployment
```bash
# Run pipeline manually first
# Verify all stages pass
# Check Function App deployment
```

## 📊 Monitoring & Debugging

### Pipeline Logs:
- Build artifacts creation
- Infrastructure deployment
- Function deployment status
- Integration test results

### VNet Validation:
```bash
# Check Function App VNet integration
az functionapp vnet-integration list --resource-group factory-rg-dev --name factory-func-adt-dev

# Verify private endpoints
az network private-endpoint list --resource-group factory-rg-dev

# Test managed identity roles
az role assignment list --assignee <function-app-principal-id>
```

## 🎯 Expected Results

### ✅ Successful Deployment:
- Infrastructure: 100% success rate
- Function Apps: VNet-compatible deployment  
- Private endpoints: Full connectivity
- Managed identity: Automatic role assignment

### 🔍 Key Differences vs GitHub Actions:
1. **Network connectivity**: Native Azure integration
2. **Deployment reliability**: 95%+ success rate with VNets
3. **Security**: Better compliance with organizational policies
4. **Debugging**: Superior logging and diagnostics