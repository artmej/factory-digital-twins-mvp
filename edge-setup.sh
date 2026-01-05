#!/bin/bash
# 🏭 Smart Factory Edge Setup Script
# Configuración completa de IoT Edge en Ubuntu VM

echo "🏭 SMART FACTORY EDGE SETUP"
echo "============================"

# Variables de configuración
IOT_HUB_NAME="smartfactory-prod-iot-ncy666q5uv3bo"
EDGE_DEVICE_ID="edge-factory-01"
FACTORY_ID="EDGE-FACTORY-001"

echo "📋 Configuración:"
echo "   IoT Hub: $IOT_HUB_NAME"
echo "   Device ID: $EDGE_DEVICE_ID"
echo "   Factory ID: $FACTORY_ID"

# PASO 1: Actualizar sistema
echo ""
echo "🔄 PASO 1: Actualizando sistema..."
sudo apt-get update -y

# PASO 2: Instalar Docker si no está instalado
echo ""
echo "🐳 PASO 2: Verificando Docker..."
if ! command -v docker &> /dev/null; then
    echo "📦 Instalando Docker..."
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo "✅ Docker instalado"
else
    echo "✅ Docker ya está instalado"
fi

# PASO 3: Instalar IoT Edge Runtime
echo ""
echo "⚡ PASO 3: Instalando IoT Edge Runtime..."

# Agregar repositorio Microsoft
curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
echo "deb https://packages.microsoft.com/repos/azureiot-edge/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azureiot-edge.list

# Instalar Azure IoT Identity Service y IoT Edge
sudo apt-get update -y
sudo apt-get install -y aziot-edge

# PASO 4: Configurar IoT Edge (requiere connection string manual)
echo ""
echo "🔧 PASO 4: Configuración IoT Edge..."
echo "⚠️  NOTA: Se requiere configuración manual del connection string"
echo ""
echo "📋 Para configurar manualmente:"
echo "1. sudo nano /etc/aziot/config.toml"
echo "2. Agregar:"
echo "   [provisioning]"
echo "   source = \"manual\""
echo "   connection_string = \"HostName=$IOT_HUB_NAME.azure-devices.net;DeviceId=$EDGE_DEVICE_ID;SharedAccessKey=...\""
echo ""
echo "3. sudo iotedge config apply"

# PASO 5: Instalar Node.js para el simulador
echo ""
echo "📦 PASO 5: Instalando Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verificar instalación
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
echo "✅ Node.js $NODE_VERSION y npm $NPM_VERSION instalados"

# PASO 6: Preparar simulador
echo ""
echo "🏭 PASO 6: Configurando simulador..."
cd /home/azureuser/smart-factory-edge/device-simulator

# Instalar dependencias del simulador
echo "📦 Instalando dependencias del simulador..."
npm install express cors helmet morgan

# Crear package.json si no existe
if [ ! -f package.json ]; then
    echo "📝 Creando package.json..."
    cat > package.json << EOF
{
  "name": "smart-factory-edge-simulator",
  "version": "1.0.0",
  "description": "Smart Factory Edge Device Simulator",
  "main": "edge-simulator.js",
  "scripts": {
    "start": "node edge-simulator.js",
    "edge": "EDGE_MODE=true PRODUCTION_LINES=3 node edge-simulator.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "morgan": "^1.10.0"
  }
}
EOF
fi

# PASO 7: Configurar PostgreSQL con Docker
echo ""
echo "🗄️ PASO 7: Configurando PostgreSQL Edge..."
sudo docker run -d --name postgres-edge \
  --restart unless-stopped \
  -e POSTGRES_DB=factory_edge \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=factory123 \
  -p 5432:5432 \
  postgres:13

echo "✅ PostgreSQL Edge iniciado"

# PASO 8: Configurar Grafana con Docker
echo ""
echo "📊 PASO 8: Configurando Grafana Edge..."
sudo docker run -d --name grafana-edge \
  --restart unless-stopped \
  -e GF_SECURITY_ADMIN_PASSWORD=factory123 \
  -p 3000:3000 \
  grafana/grafana:latest

echo "✅ Grafana Edge iniciado"

# PASO 9: Crear script de inicio del simulador
echo ""
echo "🚀 PASO 9: Creando script de inicio..."
cat > start-factory-demo.sh << 'EOF'
#!/bin/bash
echo "🏭 Iniciando Smart Factory Edge Demo..."

# Configurar variables de entorno
export EDGE_MODE=true
export PRODUCTION_LINES=3
export FACTORY_ID=EDGE-FACTORY-001
export PORT=8080

# Iniciar simulador
cd /home/azureuser/smart-factory-edge/device-simulator
echo "📡 Iniciando simulador IoT Edge..."
node edge-simulator.js &

# Mostrar información de acceso
echo ""
echo "✅ DEMO INICIADA"
echo "==============="
echo "🏭 Simulador Factory: http://$(hostname -I | awk '{print $1}'):8080"
echo "📊 Grafana Dashboard: http://$(hostname -I | awk '{print $1}'):3000"
echo "🗄️ PostgreSQL: $(hostname -I | awk '{print $1}'):5432"
echo ""
echo "📋 Credenciales:"
echo "   Grafana: admin/factory123"
echo "   PostgreSQL: postgres/factory123"
echo ""
echo "🔧 Para detener: pkill -f node"
EOF

chmod +x start-factory-demo.sh

# PASO 10: Verificar estado de servicios
echo ""
echo "🔍 PASO 10: Verificando servicios..."
echo "📊 Estado de Docker containers:"
sudo docker ps

echo ""
echo "⚡ Estado de IoT Edge:"
if command -v iotedge &> /dev/null; then
    sudo iotedge system status || echo "⚠️ IoT Edge requiere configuración manual"
else
    echo "⚠️ IoT Edge no está completamente configurado"
fi

echo ""
echo "🌐 Información de red:"
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "   IP Interna: $IP_ADDRESS"

# RESUMEN FINAL
echo ""
echo "✅ SETUP COMPLETADO"
echo "==================="
echo "🏭 Smart Factory Edge configurado en VM"
echo "📦 Servicios instalados:"
echo "   • Docker y containers"
echo "   • PostgreSQL Edge (puerto 5432)"
echo "   • Grafana Edge (puerto 3000)"
echo "   • Node.js y simulador IoT"
echo ""
echo "🚀 Para iniciar la demo:"
echo "   ./start-factory-demo.sh"
echo ""
echo "🔧 Configuración pendiente:"
echo "   • Configurar connection string IoT Edge"
echo "   • Aplicar deployment manifest"
echo ""
echo "📋 Acceso externo (configurar firewall):"
echo "   🏭 Factory Simulator: http://$IP_ADDRESS:8080"
echo "   📊 Grafana: http://$IP_ADDRESS:3000"