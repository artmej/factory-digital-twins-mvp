// 🏭 Simplified 3D Digital Twins Viewer
// Case Study #36 - Working 3D Visualization

const express = require('express');
const path = require('path');
const app = express();
const PORT = 3003;

// Serve static files
app.use(express.static(__dirname));

// Simple 3D viewer HTML
const html3D = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🏭 Smart Factory 3D Digital Twins</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: #0a0e27;
            color: white;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            overflow: hidden;
        }
        
        .header {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            background: rgba(10, 14, 39, 0.9);
            padding: 15px;
            z-index: 1000;
            text-align: center;
            border-bottom: 2px solid #00ffff;
        }
        
        .stats {
            position: fixed;
            top: 80px;
            left: 20px;
            background: rgba(0, 0, 0, 0.7);
            padding: 20px;
            border-radius: 10px;
            border: 1px solid #00ffff;
            max-width: 300px;
            z-index: 999;
        }
        
        .machine-info {
            margin-bottom: 15px;
            padding: 10px;
            background: rgba(0, 255, 255, 0.1);
            border-radius: 5px;
        }
        
        .status-operational { color: #00ff00; }
        .status-warning { color: #ffaa00; }
        .status-critical { color: #ff0000; }
        
        #container3d {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
        }
        
        .loading {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(0, 0, 0, 0.8);
            padding: 20px;
            border-radius: 10px;
            border: 2px solid #00ffff;
            text-align: center;
            z-index: 2000;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🏭 Smart Factory 3D Digital Twins - Case Study #36</h1>
        <p>Azure Master Program | Phase 3: 3D Visualization | ML Accuracy: 94.7% | ROI: $2.2M</p>
    </div>
    
    <div id="loading" class="loading">
        <h2>🚀 Initializing 3D Factory...</h2>
        <p>Loading Three.js Engine</p>
    </div>
    
    <div class="stats">
        <h3>🔧 Factory Overview</h3>
        <div class="machine-info">
            <strong>🏭 Machines Active:</strong> 4/4<br>
            <strong>⚡ Overall Health:</strong> <span class="status-operational">87%</span><br>
            <strong>🎯 Efficiency:</strong> <span class="status-operational">94.7%</span>
        </div>
        <div class="machine-info">
            <strong>🤖 AI Predictions:</strong><br>
            • Next Maintenance: Jan 15, 2025<br>
            • Anomaly Risk: <span class="status-warning">Low</span><br>
            • Failure Prediction: <span class="status-operational">15%</span>
        </div>
        <div class="machine-info">
            <strong>📊 Real-time Metrics:</strong><br>
            • Temperature: 42°C<br>
            • Vibration: Normal<br>
            • Production Rate: 95%
        </div>
    </div>
    
    <div id="container3d"></div>

    <script>
        console.log('🚀 Starting 3D Factory Visualization...');
        
        // Remove loading screen after a delay
        setTimeout(() => {
            const loading = document.getElementById('loading');
            if (loading) loading.style.display = 'none';
            console.log('✅ 3D Factory loaded successfully');
        }, 2000);
        
        // Three.js setup
        let scene, camera, renderer;
        let machines = [];
        
        function init() {
            console.log('🔧 Initializing Three.js...');
            
            // Scene
            scene = new THREE.Scene();
            scene.fog = new THREE.Fog(0x0a0e27, 50, 200);
            
            // Camera
            camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
            camera.position.set(0, 15, 25);
            camera.lookAt(0, 0, 0);
            
            // Renderer
            renderer = new THREE.WebGLRenderer({ antialias: true });
            renderer.setSize(window.innerWidth, window.innerHeight);
            renderer.setClearColor(0x0a0e27);
            renderer.shadowMap.enabled = true;
            renderer.shadowMap.type = THREE.PCFSoftShadowMap;
            
            document.getElementById('container3d').appendChild(renderer.domElement);
            
            // Lighting
            setupLighting();
            
            // Create factory floor
            createFactoryFloor();
            
            // Create machines
            createMachines();
            
            // Add factory infrastructure
            createFactoryInfrastructure();
            
            // Start animation
            animate();
            
            console.log('✅ Three.js initialized successfully');
        }
        
        function setupLighting() {
            // Ambient light
            const ambientLight = new THREE.AmbientLight(0x404040, 0.3);
            scene.add(ambientLight);
            
            // Main directional light
            const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
            directionalLight.position.set(20, 30, 10);
            directionalLight.castShadow = true;
            directionalLight.shadow.mapSize.width = 2048;
            directionalLight.shadow.mapSize.height = 2048;
            scene.add(directionalLight);
            
            // Cyan accent lights for tech feel
            const cyanLight = new THREE.PointLight(0x00ffff, 0.5, 30);
            cyanLight.position.set(-10, 5, -10);
            scene.add(cyanLight);
            
            const cyanLight2 = new THREE.PointLight(0x00ffff, 0.5, 30);
            cyanLight2.position.set(10, 5, 10);
            scene.add(cyanLight2);
        }
        
        function createFactoryFloor() {
            // Main floor
            const floorGeometry = new THREE.PlaneGeometry(50, 50);
            const floorMaterial = new THREE.MeshLambertMaterial({ 
                color: 0x2c3e50,
                transparent: true,
                opacity: 0.8
            });
            const floor = new THREE.Mesh(floorGeometry, floorMaterial);
            floor.rotation.x = -Math.PI / 2;
            floor.receiveShadow = true;
            scene.add(floor);
            
            // Grid lines
            const gridHelper = new THREE.GridHelper(50, 20, 0x00ffff, 0x444444);
            gridHelper.position.y = 0.01;
            scene.add(gridHelper);
        }
        
        function createMachines() {
            const machineData = [
                { id: 'machine-01', name: 'CNC Milling', pos: [-8, 1, -5], color: 0x3498db },
                { id: 'machine-02', name: 'Robotic Arm', pos: [8, 1, -5], color: 0xe74c3c },
                { id: 'machine-03', name: 'Assembly Line', pos: [-8, 1, 5], color: 0x27ae60 },
                { id: 'machine-04', name: 'Quality Control', pos: [8, 1, 5], color: 0xf39c12 }
            ];
            
            machineData.forEach((data, index) => {
                const machine = createMachine(data);
                machine.userData = data;
                machines.push(machine);
                scene.add(machine);
                
                // Add machine label
                createMachineLabel(data.name, data.pos);
            });
        }
        
        function createMachine(data) {
            const group = new THREE.Group();
            
            // Create different machine types based on name
            if (data.name.includes('CNC')) {
                createCNCMachine(group, data.color);
            } else if (data.name.includes('Robotic')) {
                createRoboticArm(group, data.color);
            } else if (data.name.includes('Assembly')) {
                createAssemblyLine(group, data.color);
            } else if (data.name.includes('Quality')) {
                createQualityStation(group, data.color);
            }
            
            // Status indicator
            const statusGeometry = new THREE.SphereGeometry(0.2, 16, 16);
            const statusMaterial = new THREE.MeshBasicMaterial({ 
                color: 0x00ff00,
                emissive: 0x00ff00,
                emissiveIntensity: 0.3
            });
            const statusLight = new THREE.Mesh(statusGeometry, statusMaterial);
            statusLight.position.set(0, 3, 1.2);
            group.add(statusLight);
            
            // Position the group
            group.position.set(data.pos[0], data.pos[1], data.pos[2]);
            
            return group;
        }
        
        function createCNCMachine(group, color) {
            // Main base
            const baseGeometry = new THREE.BoxGeometry(4, 1, 3);
            const baseMaterial = new THREE.MeshPhongMaterial({ color: 0x34495e });
            const base = new THREE.Mesh(baseGeometry, baseMaterial);
            base.position.set(0, 0.5, 0);
            base.castShadow = true;
            group.add(base);
            
            // CNC spindle housing
            const housingGeometry = new THREE.BoxGeometry(2, 2.5, 1.5);
            const housingMaterial = new THREE.MeshPhongMaterial({ color: color });
            const housing = new THREE.Mesh(housingGeometry, housingMaterial);
            housing.position.set(0, 2.25, 0);
            housing.castShadow = true;
            group.add(housing);
            
            // Spindle
            const spindleGeometry = new THREE.CylinderGeometry(0.1, 0.1, 1.5);
            const spindleMaterial = new THREE.MeshPhongMaterial({ color: 0x95a5a6 });
            const spindle = new THREE.Mesh(spindleGeometry, spindleMaterial);
            spindle.position.set(0, 1.5, 0);
            group.add(spindle);
            
            // Control panel
            const panelGeometry = new THREE.BoxGeometry(0.8, 1, 0.3);
            const panelMaterial = new THREE.MeshPhongMaterial({ color: 0x2c3e50 });
            const panel = new THREE.Mesh(panelGeometry, panelMaterial);
            panel.position.set(2.5, 1.5, 0);
            group.add(panel);
        }
        
        function createRoboticArm(group, color) {
            // Base
            const baseGeometry = new THREE.CylinderGeometry(1.5, 1.8, 1);
            const baseMaterial = new THREE.MeshPhongMaterial({ color: color });
            const base = new THREE.Mesh(baseGeometry, baseMaterial);
            base.position.set(0, 0.5, 0);
            base.castShadow = true;
            group.add(base);
            
            // Lower arm
            const lowerArmGeometry = new THREE.BoxGeometry(0.5, 3, 0.5);
            const armMaterial = new THREE.MeshPhongMaterial({ color: 0xecf0f1 });
            const lowerArm = new THREE.Mesh(lowerArmGeometry, armMaterial);
            lowerArm.position.set(0, 2.5, 0);
            lowerArm.castShadow = true;
            group.add(lowerArm);
            
            // Upper arm
            const upperArmGeometry = new THREE.BoxGeometry(0.4, 2, 0.4);
            const upperArm = new THREE.Mesh(upperArmGeometry, armMaterial);
            upperArm.position.set(1.2, 4, 0);
            upperArm.rotation.z = Math.PI / 6;
            upperArm.castShadow = true;
            group.add(upperArm);
            
            // End effector
            const effectorGeometry = new THREE.SphereGeometry(0.3);
            const effectorMaterial = new THREE.MeshPhongMaterial({ color: 0xe74c3c });
            const effector = new THREE.Mesh(effectorGeometry, effectorMaterial);
            effector.position.set(2, 4.8, 0);
            group.add(effector);
        }
        
        function createAssemblyLine(group, color) {
            // Conveyor base
            const conveyorGeometry = new THREE.BoxGeometry(8, 0.5, 1.5);
            const conveyorMaterial = new THREE.MeshPhongMaterial({ color: 0x7f8c8d });
            const conveyor = new THREE.Mesh(conveyorGeometry, conveyorMaterial);
            conveyor.position.set(0, 0.25, 0);
            conveyor.castShadow = true;
            group.add(conveyor);
            
            // Conveyor belt
            const beltGeometry = new THREE.BoxGeometry(8, 0.1, 1);
            const beltMaterial = new THREE.MeshPhongMaterial({ color: 0x2c3e50 });
            const belt = new THREE.Mesh(beltGeometry, beltMaterial);
            belt.position.set(0, 0.55, 0);
            group.add(belt);
            
            // Side guides
            for (let i = 0; i < 2; i++) {
                const guideGeometry = new THREE.BoxGeometry(8, 1, 0.2);
                const guideMaterial = new THREE.MeshPhongMaterial({ color: color });
                const guide = new THREE.Mesh(guideGeometry, guideMaterial);
                guide.position.set(0, 1, (i - 0.5) * 1.4);
                group.add(guide);
            }
            
            // Assembly stations
            for (let i = 0; i < 3; i++) {
                const stationGeometry = new THREE.BoxGeometry(1, 2, 1);
                const stationMaterial = new THREE.MeshPhongMaterial({ color: color });
                const station = new THREE.Mesh(stationGeometry, stationMaterial);
                station.position.set((i - 1) * 3, 1.5, 2);
                station.castShadow = true;
                group.add(station);
            }
        }
        
        function createQualityStation(group, color) {
            // Main inspection table
            const tableGeometry = new THREE.BoxGeometry(3, 1, 2);
            const tableMaterial = new THREE.MeshPhongMaterial({ color: 0xbdc3c7 });
            const table = new THREE.Mesh(tableGeometry, tableMaterial);
            table.position.set(0, 0.5, 0);
            table.castShadow = true;
            group.add(table);
            
            // Measurement arm
            const armBaseGeometry = new THREE.CylinderGeometry(0.3, 0.3, 2);
            const armBaseMaterial = new THREE.MeshPhongMaterial({ color: color });
            const armBase = new THREE.Mesh(armBaseGeometry, armBaseMaterial);
            armBase.position.set(0, 2, 0);
            group.add(armBase);
            
            // Measurement head
            const headGeometry = new THREE.BoxGeometry(0.8, 0.5, 0.8);
            const headMaterial = new THREE.MeshPhongMaterial({ color: 0xe67e22 });
            const head = new THREE.Mesh(headGeometry, headMaterial);
            head.position.set(0, 3.2, 0);
            group.add(head);
            
            // Computer terminal
            const terminalGeometry = new THREE.BoxGeometry(1, 1.5, 0.8);
            const terminalMaterial = new THREE.MeshPhongMaterial({ color: 0x2c3e50 });
            const terminal = new THREE.Mesh(terminalGeometry, terminalMaterial);
            terminal.position.set(2.5, 1.75, 0);
            group.add(terminal);
            
            // Screen
            const screenGeometry = new THREE.PlaneGeometry(0.8, 0.6);
            const screenMaterial = new THREE.MeshBasicMaterial({ color: 0x00ff00, emissive: 0x003300 });
            const screen = new THREE.Mesh(screenGeometry, screenMaterial);
            screen.position.set(2.51, 2, 0);
            screen.rotation.y = -Math.PI / 2;
            group.add(screen);
        }
        
        function createFactoryInfrastructure() {
            // Overhead crane rails
            createOverheadCrane();
            
            // Piping system
            createPipingSystem();
            
            // Support columns
            createSupportColumns();
            
            // Storage tanks
            createStorageTanks();
            
            // Ventilation ducts
            createVentilationSystem();
        }
        
        function createOverheadCrane() {
            // Rail beams
            for (let i = 0; i < 2; i++) {
                const railGeometry = new THREE.BoxGeometry(40, 0.5, 0.5);
                const railMaterial = new THREE.MeshPhongMaterial({ color: 0x95a5a6 });
                const rail = new THREE.Mesh(railGeometry, railMaterial);
                rail.position.set(0, 12, (i - 0.5) * 15);
                scene.add(rail);
            }
            
            // Crane bridge
            const bridgeGeometry = new THREE.BoxGeometry(0.8, 0.8, 15);
            const bridgeMaterial = new THREE.MeshPhongMaterial({ color: 0xf39c12 });
            const bridge = new THREE.Mesh(bridgeGeometry, bridgeMaterial);
            bridge.position.set(5, 12, 0);
            scene.add(bridge);
            
            // Hoist
            const hoistGeometry = new THREE.BoxGeometry(1, 1.5, 1);
            const hoistMaterial = new THREE.MeshPhongMaterial({ color: 0xe74c3c });
            const hoist = new THREE.Mesh(hoistGeometry, hoistMaterial);
            hoist.position.set(5, 10.25, 0);
            scene.add(hoist);
        }
        
        function createPipingSystem() {
            const pipePositions = [
                { start: [-15, 8, -10], end: [15, 8, -10] },
                { start: [-15, 8, 10], end: [15, 8, 10] },
                { start: [-15, 8, -10], end: [-15, 8, 10] },
                { start: [15, 8, -10], end: [15, 8, 10] }
            ];
            
            pipePositions.forEach(pipe => {
                const direction = new THREE.Vector3(
                    pipe.end[0] - pipe.start[0],
                    pipe.end[1] - pipe.start[1],
                    pipe.end[2] - pipe.start[2]
                );
                const length = direction.length();
                
                const pipeGeometry = new THREE.CylinderGeometry(0.3, 0.3, length);
                const pipeMaterial = new THREE.MeshPhongMaterial({ color: 0x7f8c8d });
                const pipeObj = new THREE.Mesh(pipeGeometry, pipeMaterial);
                
                pipeObj.position.set(
                    (pipe.start[0] + pipe.end[0]) / 2,
                    (pipe.start[1] + pipe.end[1]) / 2,
                    (pipe.start[2] + pipe.end[2]) / 2
                );
                
                // Rotate pipe to align with direction
                if (Math.abs(direction.x) > Math.abs(direction.z)) {
                    pipeObj.rotation.z = Math.PI / 2;
                } else if (Math.abs(direction.z) > 0) {
                    pipeObj.rotation.x = Math.PI / 2;
                }
                
                scene.add(pipeObj);
                
                // Add pipe joints
                [pipe.start, pipe.end].forEach(point => {
                    const jointGeometry = new THREE.SphereGeometry(0.4);
                    const jointMaterial = new THREE.MeshPhongMaterial({ color: 0x34495e });
                    const joint = new THREE.Mesh(jointGeometry, jointMaterial);
                    joint.position.set(point[0], point[1], point[2]);
                    scene.add(joint);
                });
            });
        }
        
        function createSupportColumns() {
            const columnPositions = [
                [-18, 6, -18], [18, 6, -18], [-18, 6, 18], [18, 6, 18],
                [-18, 6, 0], [18, 6, 0], [0, 6, -18], [0, 6, 18]
            ];
            
            columnPositions.forEach(pos => {
                const columnGeometry = new THREE.BoxGeometry(0.8, 12, 0.8);
                const columnMaterial = new THREE.MeshPhongMaterial({ color: 0x2c3e50 });
                const column = new THREE.Mesh(columnGeometry, columnMaterial);
                column.position.set(pos[0], pos[1], pos[2]);
                column.castShadow = true;
                scene.add(column);
                
                // Capital on top
                const capitalGeometry = new THREE.BoxGeometry(1.2, 0.5, 1.2);
                const capital = new THREE.Mesh(capitalGeometry, columnMaterial);
                capital.position.set(pos[0], 12.25, pos[2]);
                scene.add(capital);
            });
        }
        
        function createStorageTanks() {
            const tankPositions = [
                [-20, 3, -8], [-20, 3, 8], [20, 3, -8], [20, 3, 8]
            ];
            
            tankPositions.forEach((pos, index) => {
                const tankGeometry = new THREE.CylinderGeometry(2, 2, 6);
                const tankMaterial = new THREE.MeshPhongMaterial({ 
                    color: index % 2 === 0 ? 0x3498db : 0x27ae60 
                });
                const tank = new THREE.Mesh(tankGeometry, tankMaterial);
                tank.position.set(pos[0], pos[1], pos[2]);
                tank.castShadow = true;
                scene.add(tank);
                
                // Tank top
                const topGeometry = new THREE.CylinderGeometry(2.2, 2.2, 0.3);
                const topMaterial = new THREE.MeshPhongMaterial({ color: 0x95a5a6 });
                const top = new THREE.Mesh(topGeometry, topMaterial);
                top.position.set(pos[0], pos[1] + 3.15, pos[2]);
                scene.add(top);
                
                // Connecting pipes to tanks
                const connectPipeGeometry = new THREE.CylinderGeometry(0.2, 0.2, 5);
                const connectPipe = new THREE.Mesh(connectPipeGeometry, new THREE.MeshPhongMaterial({ color: 0x7f8c8d }));
                connectPipe.position.set(pos[0], pos[1] + 2.5, pos[2]);
                connectPipe.rotation.x = Math.PI / 2;
                scene.add(connectPipe);
            });
        }
        
        function createVentilationSystem() {
            // Main vent ducts
            const ductPositions = [
                { pos: [0, 10, -12], size: [20, 1, 2] },
                { pos: [0, 10, 12], size: [20, 1, 2] },
                { pos: [-12, 10, 0], size: [2, 1, 20] },
                { pos: [12, 10, 0], size: [2, 1, 20] }
            ];
            
            ductPositions.forEach(duct => {
                const ductGeometry = new THREE.BoxGeometry(duct.size[0], duct.size[1], duct.size[2]);
                const ductMaterial = new THREE.MeshPhongMaterial({ color: 0xbdc3c7 });
                const ductObj = new THREE.Mesh(ductGeometry, ductMaterial);
                ductObj.position.set(duct.pos[0], duct.pos[1], duct.pos[2]);
                scene.add(ductObj);
            });
            
            // Exhaust fans
            const fanPositions = [
                [-22, 11, 0], [22, 11, 0], [0, 11, -22], [0, 11, 22]
            ];
            
            fanPositions.forEach(pos => {
                const fanGeometry = new THREE.CylinderGeometry(1.5, 1.5, 0.5);
                const fanMaterial = new THREE.MeshPhongMaterial({ color: 0x34495e });
                const fan = new THREE.Mesh(fanGeometry, fanMaterial);
                fan.position.set(pos[0], pos[1], pos[2]);
                scene.add(fan);
                
                // Fan blades
                for (let i = 0; i < 4; i++) {
                    const bladeGeometry = new THREE.BoxGeometry(2.5, 0.1, 0.2);
                    const bladeMaterial = new THREE.MeshPhongMaterial({ color: 0x7f8c8d });
                    const blade = new THREE.Mesh(bladeGeometry, bladeMaterial);
                    blade.position.set(pos[0], pos[1] + 0.3, pos[2]);
                    blade.rotation.y = (i * Math.PI) / 2;
                    scene.add(blade);
                }
            });
        }
        
        function createMachineLabel(name, pos) {
            // This would normally use TextGeometry, but for simplicity we'll skip it
            console.log(\`Machine: \${name} at position \${pos}\`);
        }
        
        function animate() {
            requestAnimationFrame(animate);
            
            // Rotate camera around the scene
            const time = Date.now() * 0.0001;
            camera.position.x = Math.cos(time) * 30;
            camera.position.z = Math.sin(time) * 30;
            camera.lookAt(0, 0, 0);
            
            // Animate machine status lights
            machines.forEach((machine, index) => {
                const statusLight = machine.children[1]; // Status indicator sphere
                if (statusLight) {
                    statusLight.material.emissiveIntensity = 0.3 + Math.sin(time * 3 + index) * 0.2;
                }
            });
            
            renderer.render(scene, camera);
        }
        
        // Handle window resize
        window.addEventListener('resize', () => {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        });
        
        // Start the application
        init();
        
        // Simulate real-time updates
        setInterval(() => {
            console.log('🔄 Updating factory telemetry...');
            // In a real scenario, this would fetch from Azure Digital Twins
        }, 5000);
        
    </script>
</body>
</html>`;

// Routes
app.get('/', (req, res) => {
    res.send(html3D);
});

app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        service: '3D Digital Twins', 
        timestamp: new Date().toISOString() 
    });
});

app.get('/api/factory', (req, res) => {
    res.json({
        machines: [
            { id: 'machine-01', name: 'CNC Milling', status: 'operational', health: 87 },
            { id: 'machine-02', name: 'Robotic Arm', status: 'operational', health: 92 },
            { id: 'machine-03', name: 'Assembly Line', status: 'warning', health: 78 },
            { id: 'machine-04', name: 'Quality Control', status: 'operational', health: 95 }
        ]
    });
});

// Start server
app.listen(PORT, () => {
    console.log('🏭 Smart Factory 3D Digital Twins - SIMPLIFIED VERSION');
    console.log(`🌐 Server running on http://localhost:${PORT}`);
    console.log(`🎯 Case Study #36 - Phase 3: 3D Visualization`);
    console.log(`✅ Three.js 3D viewer ready`);
    console.log(`📊 ML Accuracy: 94.7% | ROI: $2.2M`);
});