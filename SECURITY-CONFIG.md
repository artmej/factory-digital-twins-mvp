# Smart Factory - Security Configuration Template

## 🔒 Environment Variables Setup

### For Local Development
Create a `.env.local` file (never commit this):

```bash
# Azure Authentication
AZURE_CLIENT_ID=your-actual-client-id-here
AZURE_TENANT_ID=your-actual-tenant-id-here
AZURE_SUBSCRIPTION_ID=your-actual-subscription-id-here

# Azure Services URLs  
AZURE_GATEWAY_URL=https://smartfactory-gw.azurefd.net
AZURE_ML_API_URL=https://smartfactoryml-api.azurewebsites.net
AZURE_MAIN_API_URL=https://smartfactory-prod-web.azurewebsites.net
```

### For GitHub Actions (Secrets)
Add these as GitHub Repository Secrets:

```
AZURE_CLIENT_ID = <your-client-id>
AZURE_TENANT_ID = <your-tenant-id>  
AZURE_SUBSCRIPTION_ID = <your-subscription-id>
```

### For Production Deployment
Set environment variables in your hosting environment:

```javascript
// For GitHub Pages (in deployment action)
window.ENV = {
  AZURE_CLIENT_ID: '${{ secrets.AZURE_CLIENT_ID }}',
  AZURE_ARCHITECTURE: {
    webApps: {
      mlAPI: 'https://smartfactoryml-api.azurewebsites.net'
    }
  }
};
```

## ⚠️ Security Guidelines

### ❌ NEVER Commit These:
- Client IDs, Tenant IDs, Subscription IDs
- Connection strings or access keys
- Any Azure secrets or tokens
- Local configuration files

### ✅ ALWAYS Use:
- Environment variables for sensitive data
- GitHub Secrets for CI/CD
- Managed Identity for Azure resources
- Configuration templates (like this file)

## 🔍 Security Checklist

Before committing code:

- [ ] Check that no hardcoded IDs are in source files
- [ ] Verify `.env*` files are in `.gitignore`
- [ ] Ensure connection strings use variables
- [ ] Test that application works with template values
- [ ] Run security scan: `git-secrets --scan`

## 🛡️ Subscription Security Note

This project uses a subscription with strict security policies:
- Public access is disabled on all storage accounts
- Only managed identity authentication is allowed
- Connection strings and access keys are blocked
- All network access requires private endpoints

## 📋 Quick Security Audit Commands

```bash
# Search for potential secrets in staged files
git diff --cached | grep -i "secret\|key\|password\|token"

# Check for hardcoded GUIDs
grep -r "[a-f0-9-]\{36\}" --include="*.js" --include="*.html" .

# Verify .gitignore coverage
git check-ignore *.env *.secrets local.settings.json
```