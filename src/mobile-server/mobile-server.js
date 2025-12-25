const express = require('express');
const path = require('path');
const app = express();
const PORT = 3002;

// 🛡️ Resilience: Health Check endpoint
app.get('/health', (req, res) => {
    const healthCheck = {
        uptime: process.uptime(),
        message: 'OK',
        timestamp: Date.now(),
        service: 'mobile-server',
        version: '1.0.0',
        checks: {
            memory: {
                status: process.memoryUsage().heapUsed < 100000000 ? 'healthy' : 'warning',
                usage: process.memoryUsage()
            },
            staticFiles: {
                status: 'healthy',
                path: path.join(__dirname, '../../deployment/mobile')
            }
        }
    };
    
    const statusCode = healthCheck.checks.memory.status === 'healthy' ? 200 : 503;
    res.status(statusCode).json(healthCheck);
});

// Serve static files from the mobile directory
app.use(express.static(path.join(__dirname, '../../deployment/mobile')));

// Handle all routes by serving the index.html file
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '../../deployment/mobile/index.html'));
});

app.listen(PORT, () => {
    console.log('📱 Smart Factory Mobile App Server started');
    console.log(`🌐 Mobile App running at: http://localhost:${PORT}`);
    console.log('🎯 Case Study #36: Predictive Maintenance Mobile Interface');
    console.log('================================================');
    console.log('🏭 Features Available:');
    console.log('   ✅ Real-time factory monitoring');
    console.log('   ✅ AI/ML predictions dashboard');
    console.log('   ✅ Mobile-optimized interface');
    console.log('   ✅ Export reports functionality');
    console.log('   ✅ Quick maintenance actions');
    console.log('   ✅ Integration with main dashboard');
    console.log('================================================');
});