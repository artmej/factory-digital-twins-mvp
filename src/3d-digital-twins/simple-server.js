// 🏭 Simple 3D Factory Viewer - Minimal Debug Version
const express = require('express');
const path = require('path');

const app = express();
const PORT = 3003;

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Main route
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Dashboard route
app.get('/dashboard', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

// Debug endpoint
app.get('/debug', (req, res) => {
    res.json({
        status: '✅ 3D Server Running',
        message: 'If you see this, the server works. Check browser console for 3D loading.',
        timestamp: new Date().toISOString(),
        uptime: Math.floor(process.uptime()) + ' seconds'
    });
});

// Factory data endpoint
app.get('/api/factory-data', (req, res) => {
    res.json({
        machines: [
            { id: 'machine-01', name: 'CNC Station', status: 'operational', health: 85 },
            { id: 'machine-02', name: 'Assembly Robot', status: 'operational', health: 92 },
            { id: 'machine-03', name: 'Quality Control', status: 'maintenance', health: 45 }
        ]
    });
});

app.listen(PORT, () => {
    console.log('🏭 Simple 3D Factory Server');
    console.log(`🌐 Running on http://localhost:${PORT}`);
    console.log(`🔍 Debug: http://localhost:${PORT}/debug`);
});

// Handle shutdown gracefully
process.on('SIGINT', () => {
    console.log('\\n🛑 Server shutting down...');
    process.exit(0);
});