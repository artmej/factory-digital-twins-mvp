// 🌐 End-to-End VNet Integration Script
// Conecta VM 130.131.248.173 → VNet → IoT Hub → Functions → Digital Twins

const express = require('express');
// const axios = require('axios'); // Comentado para evitar dependencias adicionales
const app = express();

// VNet Configuration (from existing Bicep templates)
const VNET_CONFIG = {
    vnetName: 'azlocal-vnet',
    addressSpace: '10.0.0.0/16',
    subnetAzLocal: '10.0.1.0/24',
    subnetIoTHub: '10.0.2.0/24',
    subnetFunctions: '10.0.3.0/24'
};

const VM_CONFIG = {
    vmIP: '130.131.248.173',
    internalIP: '10.0.1.4', // Asignada por la VNet
    vmName: 'arc-simple',
    arcConnected: true
};

const AZURE_SERVICES = {
    iotHubEndpoint: 'https://azlocal-iothub.azure-devices.net',
    digitalTwinsEndpoint: 'https://azlocal-adt.api.eastus.digitaltwins.azure.net',
    functionsEndpoint: 'https://azlocal-func-adt.azurewebsites.net',
    storageAccount: 'azlocalstorage'
};

// 🏭 VM Factory Data Connector
class VMFactoryConnector {
    constructor() {
        this.vmConnection = null;
        this.lastSync = null;
        this.connectionStatus = 'initializing';
    }

    async connectToVMviaVNet() {
        try {
            console.log('🔗 Connecting to VM via VNet internal IP...');
            console.log(`   VM: ${VM_CONFIG.vmName} (${VM_CONFIG.vmIP})`);
            console.log(`   Internal: ${VM_CONFIG.internalIP}`);
            
            // Simular conexión VNet privada
            this.vmConnection = {
                public_ip: VM_CONFIG.vmIP,
                private_ip: VM_CONFIG.internalIP,
                vnet: VNET_CONFIG.vnetName,
                subnet: VNET_CONFIG.subnetAzLocal,
                azure_arc: VM_CONFIG.arcConnected,
                connected_at: new Date().toISOString()
            };

            this.connectionStatus = 'connected';
            this.lastSync = new Date().toISOString();
            
            console.log('✅ VM connected via VNet');
            return true;
        } catch (error) {
            console.error('❌ VNet connection failed:', error.message);
            this.connectionStatus = 'failed';
            return false;
        }
    }

    async collectVMTelemetry() {
        if (this.connectionStatus !== 'connected') {
            throw new Error('VM not connected to VNet');
        }

        // Simular recolección de datos desde la VM 130.131.248.173
        console.log('📊 Collecting telemetry from VM via VNet private connection...');
        
        const telemetryData = {
            vm_info: {
                name: VM_CONFIG.vmName,
                public_ip: VM_CONFIG.vmIP,
                private_ip: VM_CONFIG.internalIP,
                azure_arc_connected: VM_CONFIG.arcConnected
            },
            factory_data: {
                factory_id: 'smart-factory-001',
                location: 'Production Floor A',
                timestamp: new Date().toISOString(),
                machines: [
                    {
                        machine_id: 'cnc-milling-01',
                        type: 'CNC Milling Station',
                        temperature: 42.8 + (Math.random() - 0.5) * 4,
                        vibration: 0.23 + (Math.random() - 0.5) * 0.1,
                        production_rate: 95.2 + (Math.random() - 0.5) * 10,
                        health_score: 87 + (Math.random() - 0.5) * 10,
                        status: Math.random() > 0.2 ? 'operational' : 'warning'
                    },
                    {
                        machine_id: 'robotic-arm-02', 
                        type: 'Robotic Arm',
                        temperature: 38.5 + (Math.random() - 0.5) * 3,
                        vibration: 0.15 + (Math.random() - 0.5) * 0.08,
                        production_rate: 98.1 + (Math.random() - 0.5) * 8,
                        health_score: 92 + (Math.random() - 0.5) * 8,
                        status: Math.random() > 0.1 ? 'operational' : 'warning'
                    },
                    {
                        machine_id: 'assembly-line-03',
                        type: 'Assembly Line Conveyor',
                        temperature: 45.2 + (Math.random() - 0.5) * 5,
                        vibration: 0.35 + (Math.random() - 0.5) * 0.15,
                        production_rate: 83.7 + (Math.random() - 0.5) * 12,
                        health_score: 78 + (Math.random() - 0.5) * 15,
                        status: Math.random() > 0.3 ? 'operational' : 'warning'
                    },
                    {
                        machine_id: 'quality-control-04',
                        type: 'Quality Control Station',
                        temperature: 35.8 + (Math.random() - 0.5) * 2,
                        vibration: 0.12 + (Math.random() - 0.5) * 0.05,
                        production_rate: 99.1 + (Math.random() - 0.5) * 5,
                        health_score: 95 + (Math.random() - 0.5) * 5,
                        status: Math.random() > 0.05 ? 'operational' : 'warning'
                    }
                ]
            },
            network_info: {
                source: 'vnet-private-connection',
                vnet: VNET_CONFIG.vnetName,
                subnet: VNET_CONFIG.subnetAzLocal,
                connection_type: 'azure-arc-hybrid'
            }
        };

        return telemetryData;
    }
}

// 🌐 VNet IoT Hub Simulator
class VNetIoTHub {
    constructor() {
        this.devices = new Map();
        this.messageQueue = [];
        this.vnetPrivateEndpoint = true;
    }

    async registerDevice(deviceId, connectionInfo) {
        console.log(`📝 Registering device ${deviceId} via VNet private endpoint...`);
        
        this.devices.set(deviceId, {
            device_id: deviceId,
            connection_info: connectionInfo,
            registered_at: new Date().toISOString(),
            message_count: 0,
            last_seen: null,
            vnet_connected: true
        });

        console.log(`✅ Device ${deviceId} registered in VNet IoT Hub`);
        return true;
    }

    async receiveMessage(deviceId, telemetryData) {
        if (!this.devices.has(deviceId)) {
            throw new Error(`Device ${deviceId} not registered`);
        }

        const device = this.devices.get(deviceId);
        device.message_count++;
        device.last_seen = new Date().toISOString();

        const message = {
            message_id: `msg_${device.message_count}_${Date.now()}`,
            device_id: deviceId,
            received_at: new Date().toISOString(),
            data: telemetryData,
            routing: {
                next_hop: 'azure-functions',
                vnet_internal: true,
                private_endpoint: true
            }
        };

        this.messageQueue.push(message);
        this.devices.set(deviceId, device);

        console.log(`📨 IoT Hub received message from ${deviceId} (count: ${device.message_count})`);
        
        // Trigger Function App via VNet
        await this.triggerFunctionApp(message);
        
        return message;
    }

    async triggerFunctionApp(message) {
        try {
            console.log('⚡ Triggering Function App via VNet private endpoint...');
            
            // Simular llamada a Azure Functions vía VNet
            const functionResponse = await this.simulateFunctionCall(message);
            
            console.log('✅ Function App processed message via VNet');
            return functionResponse;
        } catch (error) {
            console.error('❌ Function App trigger failed:', error.message);
            throw error;
        }
    }

    async simulateFunctionCall(message) {
        console.log('🔧 Function App: Processing IoT Hub message...');
        console.log(`   Processing device: ${message.device_id}`);
        console.log(`   Machines data: ${message.data.factory_data.machines.length} machines`);
        
        // Simular procesamiento de Azure Function
        const processedData = {
            function_execution_id: `exec_${Date.now()}`,
            input_message_id: message.message_id,
            device_id: message.device_id,
            processed_at: new Date().toISOString(),
            digital_twins_updates: message.data.factory_data.machines.map(machine => ({
                twin_id: machine.machine_id,
                updates: {
                    temperature: machine.temperature,
                    vibration: machine.vibration,
                    health_score: machine.health_score,
                    status: machine.status,
                    last_updated: new Date().toISOString()
                }
            })),
            vnet_execution: true,
            adt_endpoint: AZURE_SERVICES.digitalTwinsEndpoint
        };

        // Simular actualización de Digital Twins
        await this.updateDigitalTwins(processedData);
        
        return processedData;
    }

    async updateDigitalTwins(processedData) {
        console.log('🔷 Digital Twins: Updating twins via VNet...');
        
        for (const update of processedData.digital_twins_updates) {
            console.log(`   Updating twin: ${update.twin_id}`);
            console.log(`   Health: ${Math.round(update.updates.health_score)}%, Status: ${update.updates.status}`);
        }
        
        console.log('✅ Digital Twins updated successfully via VNet');
        return true;
    }

    getStatus() {
        return {
            service: 'VNet IoT Hub',
            vnet: VNET_CONFIG.vnetName,
            private_endpoint: this.vnetPrivateEndpoint,
            registered_devices: this.devices.size,
            total_messages: this.messageQueue.length,
            azure_services: AZURE_SERVICES,
            last_activity: new Date().toISOString()
        };
    }
}

// Initialize components
const vmConnector = new VMFactoryConnector();
const iotHub = new VNetIoTHub();

// API Endpoints
app.use(express.json());

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'End-to-End VNet Integration',
        components: {
            vm_connector: vmConnector.connectionStatus,
            iot_hub: 'operational',
            vnet_config: VNET_CONFIG,
            azure_services: AZURE_SERVICES
        },
        timestamp: new Date().toISOString()
    });
});

app.get('/api/vnet/status', (req, res) => {
    res.json({
        vnet_configuration: VNET_CONFIG,
        vm_connection: vmConnector.vmConnection,
        iot_hub_status: iotHub.getStatus(),
        end_to_end_ready: vmConnector.connectionStatus === 'connected'
    });
});

app.post('/api/simulate-end-to-end', async (req, res) => {
    try {
        console.log('🚀 Starting End-to-End VNet simulation...');
        
        // Step 1: Connect to VM via VNet
        if (vmConnector.connectionStatus !== 'connected') {
            await vmConnector.connectToVMviaVNet();
        }
        
        // Step 2: Register VM as IoT device
        const deviceId = 'factory-vm-001';
        await iotHub.registerDevice(deviceId, vmConnector.vmConnection);
        
        // Step 3: Collect telemetry from VM
        const telemetryData = await vmConnector.collectVMTelemetry();
        
        // Step 4: Send to IoT Hub via VNet
        const iotMessage = await iotHub.receiveMessage(deviceId, telemetryData);
        
        console.log('✅ End-to-End VNet simulation completed successfully!');
        
        res.json({
            success: true,
            simulation_id: `sim_${Date.now()}`,
            flow_summary: {
                step1: 'VM Connected via VNet',
                step2: 'Device Registered in IoT Hub',
                step3: 'Telemetry Collected',
                step4: 'Data Processed via Functions',
                step5: 'Digital Twins Updated'
            },
            data_summary: {
                machines_processed: telemetryData.factory_data.machines.length,
                vm_ip: VM_CONFIG.vmIP,
                vnet: VNET_CONFIG.vnetName,
                message_id: iotMessage.message_id
            },
            timing: {
                completed_at: new Date().toISOString(),
                next_simulation: 'Every 15 seconds'
            }
        });
        
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message,
            simulation_id: `sim_error_${Date.now()}`
        });
    }
});

// Automatic VNet End-to-End Simulation
async function startVNetEndToEndSimulation() {
    console.log('🔄 Starting automatic VNet End-to-End simulation...');
    
    // Initial connection
    await vmConnector.connectToVMviaVNet();
    await iotHub.registerDevice('factory-vm-001', vmConnector.vmConnection);
    
    // Continuous simulation
    setInterval(async () => {
        try {
            const telemetryData = await vmConnector.collectVMTelemetry();
            await iotHub.receiveMessage('factory-vm-001', telemetryData);
        } catch (error) {
            console.error('Simulation error:', error.message);
        }
    }, 15000); // Every 15 seconds
}

// Start server
const PORT = 3010;
app.listen(PORT, async () => {
    console.log('🌐 End-to-End VNet Integration Server');
    console.log(`📡 Server running on http://localhost:${PORT}`);
    console.log('🎯 Case Study #36 - VNet Architecture');
    console.log('');
    console.log('📋 VNet Configuration:');
    console.log(`   VNet: ${VNET_CONFIG.vnetName} (${VNET_CONFIG.addressSpace})`);
    console.log(`   VM Subnet: ${VNET_CONFIG.subnetAzLocal}`);
    console.log(`   IoT Subnet: ${VNET_CONFIG.subnetIoTHub}`);
    console.log(`   Functions Subnet: ${VNET_CONFIG.subnetFunctions}`);
    console.log('');
    console.log('🔗 VM Connection:');
    console.log(`   Public IP: ${VM_CONFIG.vmIP}`);
    console.log(`   Private IP: ${VM_CONFIG.internalIP}`);
    console.log(`   Azure Arc: ${VM_CONFIG.arcConnected}`);
    console.log('');
    console.log('📋 Available endpoints:');
    console.log('  📊 GET  /health');
    console.log('  🌐 GET  /api/vnet/status');
    console.log('  🚀 POST /api/simulate-end-to-end');
    
    // Start automatic simulation
    await startVNetEndToEndSimulation();
    
    console.log('✅ End-to-End VNet integration ready!');
});