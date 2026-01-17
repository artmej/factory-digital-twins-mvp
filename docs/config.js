// Smart Factory Environment Configuration
// This file should be loaded before other scripts to set environment variables

window.ENV = window.ENV || {
    // Azure Authentication - Set these in your deployment environment
    AZURE_CLIENT_ID: process?.env?.AZURE_CLIENT_ID || 
                     localStorage.getItem('AZURE_CLIENT_ID') || 
                     'your-client-id-here',
    
    // Environment Detection
    ENVIRONMENT: window.location.hostname.includes('github.io') ? 'DEVELOPMENT' : 'PRODUCTION',
    
    // Deployment Configuration
    DEBUG_MODE: window.location.search.includes('debug=true'),
    
    // Azure Architecture URLs (populated from CI/CD or local config)
    AZURE_ARCHITECTURE: {
        gateway: process?.env?.AZURE_GATEWAY_URL,
        functions: {
            auth: process?.env?.AZURE_AUTH_FUNCTION_URL,
            data: process?.env?.AZURE_DATA_FUNCTION_URL,
            ml: process?.env?.AZURE_ML_FUNCTION_URL,
            iot: process?.env?.AZURE_IOT_FUNCTION_URL
        },
        webApps: {
            mlAPI: process?.env?.AZURE_ML_API_URL || 'https://smartfactoryml-api-v2.azurewebsites.net',
            mlAPIFallback: 'https://smartfactoryml-api.azurewebsites.net', // v1 fallback
            cosmosAPI: process?.env?.AZURE_COSMOS_API_URL,
            digitalTwinsAPI: process?.env?.AZURE_DT_API_URL,
            mainAPI: process?.env?.AZURE_MAIN_API_URL || 'https://smartfactory-prod-web.azurewebsites.net'
        }
    }
};

// Log configuration in debug mode
if (window.ENV.DEBUG_MODE) {
    console.log('🔧 Smart Factory Environment Configuration:', {
        environment: window.ENV.ENVIRONMENT,
        hasClientId: !!window.ENV.AZURE_CLIENT_ID && window.ENV.AZURE_CLIENT_ID !== 'your-client-id-here',
        architecture: window.ENV.AZURE_ARCHITECTURE
    });
}

// Environment-specific configuration validation
if (window.ENV.ENVIRONMENT === 'PRODUCTION' && window.ENV.AZURE_CLIENT_ID === 'your-client-id-here') {
    console.warn('⚠️ Production environment detected but AZURE_CLIENT_ID not configured');
}