const express = require('express');
const path = require('path');

const app = express();
const PORT = 8080;

// Serve static files
app.use(express.static(path.join(__dirname)));

// Main dashboard
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'dashboard.html'));
});

app.listen(PORT, () => {
    console.log('🎯 Smart Factory Dashboard');
    console.log(`🌐 Access: http://localhost:${PORT}`);
});