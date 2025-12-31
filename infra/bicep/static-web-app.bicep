@description('Prefix for all resources')
param prefix string = 'smartfactory'

@description('Environment name')
param environment string = 'prod'

@description('Azure region for resources')
param location string = resourceGroup().location

var staticWebAppName = '${prefix}-pwa-${environment}'

// Azure Static Web App
resource staticWebApp 'Microsoft.Web/staticSites@2022-09-01' = {
  name: staticWebAppName
  location: location
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    repositoryUrl: 'https://github.com/artmej/factory-digital-twins-mvp'
    branch: 'main'
    buildProperties: {
      appLocation: '/deployment/mobile'
      outputLocation: ''
    }
  }
}

output staticWebAppUrl string = 'https://${staticWebApp.properties.defaultHostname}'
output staticWebAppName string = staticWebApp.name
