// Servidor ultra-simple para test
const http = require('http');

const server = http.createServer((req, res) => {
    res.writeHead(200, {'Content-Type': 'application/json'});
    res.end(JSON.stringify({
        message: '✅ Node.js Server Working!',
        timestamp: new Date().toISOString(),
        url: req.url
    }));
});

server.listen(3005, () => {
    console.log('✅ Test server running on http://localhost:3005');
});

server.on('error', (err) => {
    console.error('❌ Server error:', err.message);
    process.exit(1);
});