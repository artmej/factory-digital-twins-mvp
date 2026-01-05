/**
 * 📱 Smart Factory PWA API Server
 * Progressive Web Application API for Smart Factory Dashboard
 * 
 * This is the main entry point for Azure Functions that power the Smart Factory
 * PWA dashboard, providing REST API endpoints for real-time metrics, 
 * machine status, and ML insights.
 * 
 * @author Smart Factory Team
 * @version 1.0.0
 * @since 2026-01-03
 */

// Azure Functions entry point
require('./dashboard');
require('./metrics');
require('./health');