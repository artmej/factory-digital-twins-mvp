// 🏭 Smart Factory 3D Digital Twins - Three.js Implementation
// Case Study #36 - Phase 3: Immersive 3D Visualization

class SmartFactory3D {
    constructor() {
        this.scene = null;
        this.camera = null;
        this.renderer = null;
        this.machines = {};
        this.sensors = {};
        this.socket = null;
        this.selectedMachine = null;
        this.animationId = null;
        
        this.init();
    }
    
    // 🚀 Initialize 3D Scene
    init() {
        console.log('🏭 Initializing Smart Factory 3D...');
        
        this.setupScene();
        this.setupLighting();
        this.setupCamera();
        this.setupRenderer();
        this.setupControls();
        
        // Load demo data immediately instead of waiting for socket
        this.createDemoLayout();
        
        // Try socket connection but don't wait for it
        this.setupSocketConnection();
        
        // Hide loading screen after 1 second
        setTimeout(() => {
            const loading = document.getElementById('loading');
            if (loading) {
                loading.style.display = 'none';
            }
        }, 1000);
        
        this.animate();
    }
    
    // 🌎 Setup Scene
    setupScene() {
        this.scene = new THREE.Scene();
        this.scene.background = new THREE.Color(0x1a1a2e);
        this.scene.fog = new THREE.Fog(0x1a1a2e, 10, 50);
        
        // 🏢 Factory Floor
        const floorGeometry = new THREE.PlaneGeometry(30, 25);
        const floorMaterial = new THREE.MeshStandardMaterial({
            color: 0x333333,
            roughness: 0.8,
            metalness: 0.2
        });
        const floor = new THREE.Mesh(floorGeometry, floorMaterial);
        floor.rotation.x = -Math.PI / 2;
        floor.position.y = -1;
        this.scene.add(floor);
        
        // 🏢 Factory Walls
        this.createFactoryWalls();
        
        // ✨ Grid Helper
        const gridHelper = new THREE.GridHelper(30, 20, 0x00ff88, 0x444444);
        gridHelper.position.y = -0.9;
        this.scene.add(gridHelper);
    }
    
    // 🏢 Create Factory Walls
    createFactoryWalls() {
        const wallMaterial = new THREE.MeshStandardMaterial({
            color: 0x2c2c54,
            transparent: true,
            opacity: 0.6
        });
        
        // Back wall
        const backWall = new THREE.Mesh(
            new THREE.PlaneGeometry(30, 8),
            wallMaterial
        );
        backWall.position.set(0, 3, -12.5);
        this.scene.add(backWall);
        
        // Side walls
        const leftWall = new THREE.Mesh(
            new THREE.PlaneGeometry(25, 8),
            wallMaterial
        );
        leftWall.rotation.y = Math.PI / 2;
        leftWall.position.set(-15, 3, 0);
        this.scene.add(leftWall);
        
        const rightWall = new THREE.Mesh(
            new THREE.PlaneGeometry(25, 8),
            wallMaterial
        );
        rightWall.rotation.y = -Math.PI / 2;
        rightWall.position.set(15, 3, 0);
        this.scene.add(rightWall);
    }
    
    // 💡 Setup Lighting
    setupLighting() {
        // Ambient light
        const ambientLight = new THREE.AmbientLight(0x404040, 0.4);
        this.scene.add(ambientLight);
        
        // Main directional light
        const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
        directionalLight.position.set(10, 20, 10);
        directionalLight.castShadow = true;
        directionalLight.shadow.mapSize.width = 2048;
        directionalLight.shadow.mapSize.height = 2048;
        this.scene.add(directionalLight);
        
        // Accent lights
        const greenLight = new THREE.PointLight(0x00ff88, 0.5, 20);
        greenLight.position.set(-10, 5, -5);
        this.scene.add(greenLight);
        
        const blueLight = new THREE.PointLight(0x4ecdc4, 0.5, 20);
        blueLight.position.set(10, 5, 5);
        this.scene.add(blueLight);
    }
    
    // 📹 Setup Camera
    setupCamera() {
        this.camera = new THREE.PerspectiveCamera(
            75,
            window.innerWidth / window.innerHeight,
            0.1,
            1000
        );
        this.camera.position.set(15, 10, 15);
        this.camera.lookAt(0, 0, 0);
    }
    
    // 🌌 Setup Renderer
    setupRenderer() {
        this.renderer = new THREE.WebGLRenderer({ antialias: true });
        this.renderer.setSize(window.innerWidth, window.innerHeight);
        this.renderer.shadowMap.enabled = true;
        this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
        
        document.getElementById('threejs-container').appendChild(this.renderer.domElement);
        
        // Handle window resize
        window.addEventListener('resize', () => this.onWindowResize());
    }
    
    // 🎮 Setup Controls
    setupControls() {
        // Mouse interaction for camera rotation
        let isMouseDown = false;
        let mouseX = 0;
        let mouseY = 0;
        
        this.renderer.domElement.addEventListener('mousedown', (event) => {
            isMouseDown = true;
            mouseX = event.clientX;
            mouseY = event.clientY;
        });
        
        this.renderer.domElement.addEventListener('mousemove', (event) => {
            if (!isMouseDown) return;
            
            const deltaX = event.clientX - mouseX;
            const deltaY = event.clientY - mouseY;
            
            const spherical = new THREE.Spherical();
            spherical.setFromVector3(this.camera.position);
            spherical.theta -= deltaX * 0.01;
            spherical.phi += deltaY * 0.01;
            spherical.phi = Math.max(0.1, Math.min(Math.PI - 0.1, spherical.phi));
            
            this.camera.position.setFromSpherical(spherical);
            this.camera.lookAt(0, 0, 0);
            
            mouseX = event.clientX;
            mouseY = event.clientY;
        });
        
        this.renderer.domElement.addEventListener('mouseup', () => {
            isMouseDown = false;
        });
        
        // Mouse wheel for zoom
        this.renderer.domElement.addEventListener('wheel', (event) => {
            const distance = this.camera.position.length();
            const newDistance = distance + event.deltaY * 0.01;
            
            this.camera.position.normalize().multiplyScalar(
                Math.max(5, Math.min(50, newDistance))
            );
        });
        
        // Click to select machines
        this.renderer.domElement.addEventListener('click', (event) => {
            this.onMachineClick(event);
        });
    }
    
    // 🔗 Setup WebSocket Connection
    setupSocketConnection() {
        this.socket = io();
        
        this.socket.on('connect', () => {
            console.log('🔗 Connected to 3D Digital Twins server');
        });
        
        this.socket.on('factory-layout', (data) => {
            console.log('🏭 Received factory layout:', data);
            this.createFactoryLayout(data);
            this.updateHUD(data);
        });
        
        this.socket.on('realtime-predictions', (predictions) => {
            this.updateMachinePredictions(predictions);
        });
        
        this.socket.on('machine-details', (data) => {
            this.showMachineDetails(data);
        });
        
        this.socket.on('disconnect', () => {
            console.log('❌ Disconnected from server');
        });
        
        this.socket.on('connect_error', (error) => {
            console.error('Connection error:', error);
            // Still show demo with simulated data
            this.createDemoLayout();
        });
    }
    
    // 🎭 Create Demo Layout (fallback)
    createDemoLayout() {
        console.log('🎭 Creating demo factory layout...');
        
        const demoData = {
            machines: [
                {
                    id: 'machine-01',
                    name: 'CNC Milling Station',
                    position: { x: -5, y: 0, z: -3 },
                    rotation: { x: 0, y: Math.PI/4, z: 0 },
                    status: 'operational',
                    health: 85
                },
                {
                    id: 'machine-02',
                    name: 'Assembly Robot', 
                    position: { x: 5, y: 0, z: -3 },
                    rotation: { x: 0, y: -Math.PI/4, z: 0 },
                    status: 'operational',
                    health: 92
                },
                {
                    id: 'machine-03',
                    name: 'Quality Control',
                    position: { x: 0, y: 0, z: 3 },
                    rotation: { x: 0, y: Math.PI, z: 0 },
                    status: 'maintenance', 
                    health: 45
                }
            ],
            sensors: [
                { id: 'temp-01', position: { x: -5, y: 3, z: -3 }, value: 75.2, unit: '°C' },
                { id: 'vibr-01', position: { x: 5, y: 1, z: -3 }, value: 0.8, unit: 'mm/s' }
            ]
        };
        
        console.log('📊 Demo data created, building 3D scene...');
        this.createFactoryLayout(demoData);
        this.updateHUD(demoData);
        console.log('✅ Demo factory scene ready!');
        
        // Start demo updates
        setInterval(() => {
            this.updateMachinePredictions([
                { id: 'machine-01', predictions: { health: 85 + Math.random() * 10, failureRisk: Math.random() * 0.3, anomalyScore: Math.random() * 0.5 }},
                { id: 'machine-02', predictions: { health: 90 + Math.random() * 8, failureRisk: Math.random() * 0.2, anomalyScore: Math.random() * 0.3 }},
                { id: 'machine-03', predictions: { health: 40 + Math.random() * 20, failureRisk: 0.7 + Math.random() * 0.2, anomalyScore: 0.8 + Math.random() * 0.15 }}
            ]);
        }, 3000);
    }
    
    // 🏭 Create Factory Layout
    createFactoryLayout(data) {
        // Create machines
        data.machines.forEach(machine => {
            this.createMachine(machine);
        });
        
        // Create sensors
        data.sensors.forEach(sensor => {
            this.createSensor(sensor);
        });
    }
    
    // 🤖 Create Machine 3D Model
    createMachine(machine) {
        const group = new THREE.Group();
        
        // Main body
        const bodyGeometry = new THREE.BoxGeometry(3, 2, 2);
        const bodyMaterial = new THREE.MeshStandardMaterial({
            color: this.getMachineColor(machine.status),
            metalness: 0.7,
            roughness: 0.3
        });
        const body = new THREE.Mesh(bodyGeometry, bodyMaterial);
        body.position.y = 1;
        body.castShadow = true;
        group.add(body);
        
        // Status indicator
        const indicatorGeometry = new THREE.SphereGeometry(0.3, 8, 8);
        const indicatorMaterial = new THREE.MeshBasicMaterial({
            color: this.getStatusColor(machine.status),
            transparent: true,
            opacity: 0.8
        });
        const indicator = new THREE.Mesh(indicatorGeometry, indicatorMaterial);
        indicator.position.set(0, 3, 0);
        group.add(indicator);
        
        // Machine label
        this.createMachineLabel(group, machine.name);
        
        // Position machine
        group.position.set(machine.position.x, 0, machine.position.z);
        group.rotation.set(machine.rotation.x, machine.rotation.y, machine.rotation.z);
        
        // Store reference
        group.userData = { type: 'machine', data: machine };
        this.machines[machine.id] = group;
        
        this.scene.add(group);
    }
    
    // 📶 Create Sensor 3D Model
    createSensor(sensor) {
        const sensorGroup = new THREE.Group();
        
        // Sensor housing
        const housingGeometry = new THREE.CylinderGeometry(0.2, 0.2, 0.5, 8);
        const housingMaterial = new THREE.MeshStandardMaterial({
            color: 0x666666,
            metalness: 0.8,
            roughness: 0.2
        });
        const housing = new THREE.Mesh(housingGeometry, housingMaterial);
        housing.castShadow = true;
        sensorGroup.add(housing);
        
        // Signal indicator
        const signalGeometry = new THREE.SphereGeometry(0.1, 6, 6);
        const signalMaterial = new THREE.MeshBasicMaterial({
            color: 0x00ff88,
            transparent: true,
            opacity: 0.7
        });
        const signal = new THREE.Mesh(signalGeometry, signalMaterial);
        signal.position.y = 0.4;
        sensorGroup.add(signal);
        
        sensorGroup.position.copy(sensor.position);
        sensorGroup.userData = { type: 'sensor', data: sensor };
        
        this.sensors[sensor.id] = sensorGroup;
        this.scene.add(sensorGroup);
    }
    
    // 🏷️ Create Machine Label
    createMachineLabel(group, text) {
        const canvas = document.createElement('canvas');
        const context = canvas.getContext('2d');
        canvas.width = 256;
        canvas.height = 64;
        
        context.fillStyle = 'rgba(0, 0, 0, 0.8)';
        context.fillRect(0, 0, canvas.width, canvas.height);
        
        context.fillStyle = '#ffffff';
        context.font = '18px Arial';
        context.textAlign = 'center';
        context.fillText(text, canvas.width / 2, canvas.height / 2 + 6);
        
        const texture = new THREE.CanvasTexture(canvas);
        const labelMaterial = new THREE.SpriteMaterial({ map: texture });
        const label = new THREE.Sprite(labelMaterial);
        label.position.set(0, 4, 0);
        label.scale.set(4, 1, 1);
        
        group.add(label);
    }
    
    // 🎨 Helper Functions
    getMachineColor(status) {
        switch(status) {
            case 'operational': return 0x00ff88;
            case 'maintenance': return 0xff6b6b;
            case 'warning': return 0xffd93d;
            default: return 0x666666;
        }
    }
    
    getStatusColor(status) {
        return this.getMachineColor(status);
    }
    
    // 📈 Update Machine Predictions
    updateMachinePredictions(predictions) {
        predictions.forEach(prediction => {
            const machineGroup = this.machines[prediction.id];
            if (machineGroup) {
                // Update status indicator based on health
                const indicator = machineGroup.children.find(child => 
                    child.geometry instanceof THREE.SphereGeometry
                );
                if (indicator) {
                    const health = prediction.predictions.health;
                    let color;
                    if (health > 70) color = 0x00ff88;      // Green
                    else if (health > 40) color = 0xffd93d;  // Yellow
                    else color = 0xff6b6b;                   // Red
                    
                    indicator.material.color.setHex(color);
                }
                
                // Animate based on anomaly score
                const anomaly = prediction.predictions.anomalyScore;
                if (anomaly > 0.5) {
                    // Make machine pulse if high anomaly detected
                    machineGroup.children[0].material.emissive.setHex(0x441100);
                } else {
                    machineGroup.children[0].material.emissive.setHex(0x000000);
                }
            }
        });
    }
    
    // 📋 Update HUD
    updateHUD(data) {
        const overview = document.getElementById('factory-overview');
        overview.innerHTML = '';
        
        data.machines.forEach(machine => {
            const statusDiv = document.createElement('div');
            statusDiv.className = `machine-status status-${machine.status}`;
            statusDiv.innerHTML = `
                <strong>${machine.name}</strong><br>
                <small>Health: ${machine.health}% | Status: ${machine.status}</small>
            `;
            overview.appendChild(statusDiv);
        });
    }
    
    // 💆‍♂️ Handle Machine Click
    onMachineClick(event) {
        const raycaster = new THREE.Raycaster();
        const mouse = new THREE.Vector2();
        
        mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
        mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
        
        raycaster.setFromCamera(mouse, this.camera);
        
        const intersects = raycaster.intersectObjects(this.scene.children, true);
        
        if (intersects.length > 0) {
            let targetObject = intersects[0].object;
            
            // Find parent machine group
            while (targetObject.parent && !targetObject.userData.type) {
                targetObject = targetObject.parent;
            }
            
            if (targetObject.userData && targetObject.userData.type === 'machine') {
                const machineId = targetObject.userData.data.id;
                this.socket.emit('machine-selected', machineId);
                this.selectedMachine = machineId;
            }
        }
    }
    
    // 📊 Show Machine Details Panel
    showMachineDetails(data) {
        const panel = document.getElementById('machine-details');
        const nameEl = document.getElementById('machine-name');
        const metricsEl = document.getElementById('machine-metrics');
        
        nameEl.textContent = data.machine.name;
        
        const health = data.predictions.predictions.health;
        const healthClass = health > 70 ? 'health-high' : health > 40 ? 'health-medium' : 'health-low';
        
        metricsEl.innerHTML = `
            <div class="metric">
                <span class="metric-label">Health Score:</span>
                <span class="metric-value ${healthClass}">${health.toFixed(1)}%</span>
            </div>
            <div class="metric">
                <span class="metric-label">Failure Risk:</span>
                <span class="metric-value">${(data.predictions.predictions.failureRisk * 100).toFixed(1)}%</span>
            </div>
            <div class="metric">
                <span class="metric-label">Anomaly Score:</span>
                <span class="metric-value">${data.predictions.predictions.anomalyScore.toFixed(3)}</span>
            </div>
            <div class="metric">
                <span class="metric-label">Temperature:</span>
                <span class="metric-value">${data.predictions.telemetry.temperature.toFixed(1)}°C</span>
            </div>
            <div class="metric">
                <span class="metric-label">Vibration:</span>
                <span class="metric-value">${data.predictions.telemetry.vibration.toFixed(2)} mm/s</span>
            </div>
            <div class="metric">
                <span class="metric-label">Pressure:</span>
                <span class="metric-value">${data.predictions.telemetry.pressure.toFixed(1)} PSI</span>
            </div>
            <div class="metric">
                <span class="metric-label">Last Maintenance:</span>
                <span class="metric-value">${data.machine.lastMaintenance}</span>
            </div>
        `;
        
        panel.style.display = 'block';
    }
    
    // 🔄 Animation Loop
    animate() {
        this.animationId = requestAnimationFrame(() => this.animate());
        
        // Rotate sensor indicators
        Object.values(this.sensors).forEach(sensor => {
            const signal = sensor.children[1]; // Signal sphere
            if (signal) {
                signal.rotation.y += 0.05;
            }
        });
        
        this.renderer.render(this.scene, this.camera);
    }
    
    // 📱 Window Resize Handler
    onWindowResize() {
        this.camera.aspect = window.innerWidth / window.innerHeight;
        this.camera.updateProjectionMatrix();
        this.renderer.setSize(window.innerWidth, window.innerHeight);
    }
}

// 🎮 Global Control Functions
function resetCamera() {
    if (window.factory3D) {
        window.factory3D.camera.position.set(15, 10, 15);
        window.factory3D.camera.lookAt(0, 0, 0);
    }
}

function toggleWireframe() {
    if (window.factory3D) {
        Object.values(window.factory3D.machines).forEach(machine => {
            machine.children[0].material.wireframe = !machine.children[0].material.wireframe;
        });
    }
}

function toggleFullscreen() {
    if (!document.fullscreenElement) {
        document.documentElement.requestFullscreen();
    } else {
        document.exitFullscreen();
    }
}

function closeMachineDetails() {
    document.getElementById('machine-details').style.display = 'none';
}

// 🚀 Initialize when page loads
document.addEventListener('DOMContentLoaded', () => {
    console.log('🏭 Initializing Smart Factory 3D Digital Twins...');
    window.factory3D = new SmartFactory3D();
});