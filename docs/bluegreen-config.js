// Smart Factory V2 Configuration with Blue-Green Deployment
// Enhanced fetch with automatic v1 fallback

window.AZURE_ML_CONFIG_V2 = {
    // Primary v2 endpoint
    primaryEndpoint: 'https://smartfactoryml-api-v2.azurewebsites.net',
    
    // Fallback v1 endpoint
    fallbackEndpoint: 'https://smartfactoryml-api.azurewebsites.net',
    
    // Configuration
    useRealModels: true,
    fallbackEnabled: true,
    autoRetry: true,
    retryAttempts: 3,
    retryDelay: 1000,
    healthCheckInterval: 60000, // 1 minute
    
    // Health status
    primaryHealthy: true,
    fallbackHealthy: true,
    lastHealthCheck: null
};

// Enhanced fetch with blue-green failover
async function fetchWithBlueGreenFailover(endpoint, options = {}) {
    const config = window.AZURE_ML_CONFIG_V2;
    
    // Try primary endpoint (v2)
    if (config.primaryHealthy) {
        try {
            const response = await fetch(`${config.primaryEndpoint}${endpoint}`, {
                ...options,
                timeout: 8000
            });
            
            if (response.ok) {
                console.log(`✅ v2 API Success: ${endpoint}`);
                return await response.json();
            } else {
                throw new Error(`HTTP ${response.status} from v2`);
            }
        } catch (error) {
            console.warn(`⚠️ v2 API Failed (${endpoint}): ${error.message}`);
            config.primaryHealthy = false;
            
            // Fall through to v1 fallback
        }
    }
    
    // Try fallback endpoint (v1)
    try {
        const response = await fetch(`${config.fallbackEndpoint}${endpoint}`, {
            ...options,
            timeout: 8000
        });
        
        if (response.ok) {
            console.log(`🔄 v1 Fallback Success: ${endpoint}`);
            return await response.json();
        } else {
            throw new Error(`HTTP ${response.status} from v1`);
        }
    } catch (error) {
        console.error(`❌ Both v2 and v1 Failed (${endpoint}): ${error.message}`);
        config.fallbackHealthy = false;
        throw error;
    }
}

// Health check function
async function performHealthCheck() {
    const config = window.AZURE_ML_CONFIG_V2;
    config.lastHealthCheck = new Date();
    
    // Check v2 health
    try {
        const v2Response = await fetch(`${config.primaryEndpoint}/api/device/health`, {
            method: 'GET',
            timeout: 5000
        });
        config.primaryHealthy = v2Response.ok;
    } catch {
        config.primaryHealthy = false;
    }
    
    // Check v1 health
    try {
        const v1Response = await fetch(`${config.fallbackEndpoint}/api/device/health`, {
            method: 'GET',
            timeout: 5000
        });
        config.fallbackHealthy = v1Response.ok;
    } catch {
        config.fallbackHealthy = false;
    }
    
    console.log(`🏥 Health Check: v2=${config.primaryHealthy}, v1=${config.fallbackHealthy}`);
    
    // Update status indicator
    updateHealthStatus();
}

// Update health status in UI
function updateHealthStatus() {
    const config = window.AZURE_ML_CONFIG_V2;
    const statusElement = document.getElementById('api-version-status');
    
    if (statusElement) {
        let statusText = '';
        let statusClass = '';
        
        if (config.primaryHealthy && config.fallbackHealthy) {
            statusText = 'v2 Active (v1 Standby)';
            statusClass = 'status-optimal';
        } else if (config.primaryHealthy) {
            statusText = 'v2 Active';
            statusClass = 'status-good';
        } else if (config.fallbackHealthy) {
            statusText = 'v1 Active (v2 Down)';
            statusClass = 'status-fallback';
        } else {
            statusText = 'API Unavailable';
            statusClass = 'status-error';
        }
        
        statusElement.textContent = statusText;
        statusElement.className = `api-status ${statusClass}`;
    }
}

// Initialize health monitoring
if (typeof window !== 'undefined') {
    // Initial health check
    setTimeout(performHealthCheck, 1000);
    
    // Periodic health checks
    setInterval(performHealthCheck, window.AZURE_ML_CONFIG_V2.healthCheckInterval);
    
    // Override global fetchWithRetry to use blue-green failover
    window.fetchWithRetry = fetchWithBlueGreenFailover;
}