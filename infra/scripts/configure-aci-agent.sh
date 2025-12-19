#!/bin/bash
# Configure ACI DevOps Agent - Post Deployment
# This script configures the Azure Container Instance to work as a DevOps agent

set -e

echo "🔧 Configurando ACI DevOps Agent..."

# Variables
RESOURCE_GROUP="factory-rg-dev"
ACI_NAME="factory-aci-agent-dev"
DEVOPS_ORG="https://dev.azure.com/arturomej"
AGENT_POOL="factory-agents"

# Check if ACI exists
echo "📍 Verificando ACI: $ACI_NAME"
ACI_EXISTS=$(az container show --name $ACI_NAME --resource-group $RESOURCE_GROUP --query "name" -o tsv 2>/dev/null || echo "")

if [ -z "$ACI_EXISTS" ]; then
    echo "❌ Error: ACI $ACI_NAME no encontrado"
    exit 1
fi

echo "✅ ACI encontrado: $ACI_NAME"

# Instructions for manual PAT configuration
echo ""
echo "🔐 CONFIGURACIÓN REQUERIDA - PERSONAL ACCESS TOKEN:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Ve a Azure DevOps: https://dev.azure.com/arturomej"
echo "2. Ir a User Settings > Personal Access Tokens"
echo "3. Crear nuevo token con permisos:"
echo "   - Agent Pools (read, manage)"
echo "   - Build (read & execute)"
echo "   - Code (read)"
echo "4. Copiar el token generado"
echo ""
echo "5. Ejecutar el siguiente comando con tu token:"
echo ""
echo "az container restart --name $ACI_NAME --resource-group $RESOURCE_GROUP"
echo ""
echo "6. Actualizar variable de entorno:"
echo "az container exec --container-group-name $ACI_NAME --resource-group $RESOURCE_GROUP --exec-command '/bin/bash'"
echo ""
echo "🎯 Una vez configurado, el agent estará disponible en el pool 'factory-agents'"
echo "✅ El agent tendrá acceso completo al VNet y private endpoints"