#!/bin/bash

# Deploy Azure Infrastructure for Factory Digital Twins MVP
# Este script despliega toda la infraestructura necesaria usando Bicep

set -e

# Variables de configuración
RG_NAME="${RG_NAME:-factory-rg}"
LOCATION="${LOCATION:-eastus}"
RESOURCE_PREFIX="${RESOURCE_PREFIX:-factory}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
DEPLOYMENT_NAME="factory-deployment-$(date +%Y%m%d-%H%M%S)"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar dependencias
check_dependencies() {
    log_info "Verificando dependencias..."
    
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI no está instalado"
        exit 1
    fi
    
    log_success "Dependencias verificadas"
}

# Verificar login
check_azure_login() {
    log_info "Verificando login de Azure..."
    
    if ! az account show &> /dev/null; then
        log_error "No hay sesión activa en Azure CLI"
        log_info "Ejecuta: az login"
        exit 1
    fi
    
    local subscription=$(az account show --query name -o tsv)
    log_success "Conectado a Azure - Subscription: $subscription"
}

# Crear resource group
create_resource_group() {
    log_info "Creando resource group: $RG_NAME"
    
    if az group show --name "$RG_NAME" &> /dev/null; then
        log_warning "Resource group ya existe: $RG_NAME"
    else
        az group create --name "$RG_NAME" --location "$LOCATION"
        log_success "Resource group creado: $RG_NAME"
    fi
}

# Desplegar infraestructura
deploy_infrastructure() {
    log_info "Desplegando infraestructura con Bicep..."
    
    local bicep_file="../bicep/main.bicep"
    
    if [ ! -f "$bicep_file" ]; then
        log_error "Archivo Bicep no encontrado: $bicep_file"
        exit 1
    fi
    
    log_info "Ejecutando deployment: $DEPLOYMENT_NAME"
    
    az deployment group create \
        --resource-group "$RG_NAME" \
        --name "$DEPLOYMENT_NAME" \
        --template-file "$bicep_file" \
        --parameters \
            location="$LOCATION" \
            resourcePrefix="$RESOURCE_PREFIX" \
            environment="$ENVIRONMENT" \
        --verbose
    
    log_success "Deployment completado: $DEPLOYMENT_NAME"
}

# Obtener outputs del deployment
get_deployment_outputs() {
    log_info "Obteniendo outputs del deployment..."
    
    local outputs=$(az deployment group show \
        --resource-group "$RG_NAME" \
        --name "$DEPLOYMENT_NAME" \
        --query properties.outputs)
    
    echo "$outputs" > deployment_outputs.json
    
    # Extraer valores importantes
    DIGITAL_TWINS_NAME=$(echo "$outputs" | jq -r '.digitalTwinsName.value')
    DIGITAL_TWINS_URL=$(echo "$outputs" | jq -r '.digitalTwinsUrl.value')
    IOT_HUB_NAME=$(echo "$outputs" | jq -r '.iotHubName.value')
    FUNCTION_APP_NAME=$(echo "$outputs" | jq -r '.functionAppName.value')
    DEVICE_CONNECTION_STRING=$(echo "$outputs" | jq -r '.deviceConnectionString.value')
    IOTHUB_CONNECTION_STRING=$(echo "$outputs" | jq -r '.iotHubConnectionString.value')
    
    log_success "Outputs obtenidos y guardados en deployment_outputs.json"
}

# Crear archivo de configuración
create_config_file() {
    log_info "Creando archivo de configuración..."
    
    cat > factory_config.env << EOF
# Factory Digital Twins - Configuration
# Generado automáticamente el $(date)

# Azure Resources
RESOURCE_GROUP=$RG_NAME
LOCATION=$LOCATION

# Digital Twins
DIGITAL_TWINS_NAME=$DIGITAL_TWINS_NAME
DIGITAL_TWINS_URL=$DIGITAL_TWINS_URL

# IoT Hub
IOT_HUB_NAME=$IOT_HUB_NAME

# Function App
FUNCTION_APP_NAME=$FUNCTION_APP_NAME

# Connection Strings
DEVICE_CONN_STRING="$DEVICE_CONNECTION_STRING"
IOTHUB_CONNECTION="$IOTHUB_CONNECTION_STRING"

# Para usar estas variables:
# source factory_config.env
EOF
    
    log_success "Configuración guardada en: factory_config.env"
}

# Mostrar resumen
show_summary() {
    echo
    log_info "=== RESUMEN DEL DEPLOYMENT ==="
    echo
    log_info "Resource Group: $RG_NAME"
    log_info "Location: $LOCATION"
    log_info "Deployment Name: $DEPLOYMENT_NAME"
    echo
    log_info "Recursos creados:"
    log_info "  • Digital Twins: $DIGITAL_TWINS_NAME"
    log_info "  • IoT Hub: $IOT_HUB_NAME" 
    log_info "  • Function App: $FUNCTION_APP_NAME"
    echo
    log_info "URLs importantes:"
    log_info "  • Digital Twins: $DIGITAL_TWINS_URL"
    log_info "  • ADT Explorer: https://explorer.digitaltwins.azure.net"
    log_info "  • Function App: https://$FUNCTION_APP_NAME.azurewebsites.net"
    echo
    log_success "✅ Infraestructura desplegada exitosamente!"
    echo
    log_info "Próximos pasos:"
    log_info "1. Ejecutar: ./adt_setup.sh --rg $RG_NAME --adt $DIGITAL_TWINS_NAME"
    log_info "2. Desplegar el código de la Azure Function"
    log_info "3. Ejecutar el simulador con: source factory_config.env && npm start"
    echo
}

# Función principal
main() {
    echo "============================================="
    echo "Factory Digital Twins Infrastructure Deploy"
    echo "============================================="
    echo
    
    check_dependencies
    check_azure_login
    create_resource_group
    deploy_infrastructure
    get_deployment_outputs
    create_config_file
    show_summary
}

# Manejo de parámetros
while [[ $# -gt 0 ]]; do
    case $1 in
        --rg|--resource-group)
            RG_NAME="$2"
            shift 2
            ;;
        --location)
            LOCATION="$2"
            shift 2
            ;;
        --prefix)
            RESOURCE_PREFIX="$2"
            shift 2
            ;;
        --env|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --help|-h)
            echo "Uso: $0 [opciones]"
            echo ""
            echo "Opciones:"
            echo "  --rg, --resource-group     Nombre del resource group (default: factory-rg)"
            echo "  --location                 Región de Azure (default: eastus)"
            echo "  --prefix                   Prefijo para recursos (default: factory)"
            echo "  --env, --environment       Environment suffix (default: dev)"
            echo "  --help, -h                 Mostrar esta ayuda"
            echo ""
            echo "Variables de entorno:"
            echo "  RG_NAME           Nombre del resource group"
            echo "  LOCATION          Región de Azure"
            echo "  RESOURCE_PREFIX   Prefijo para recursos"
            echo "  ENVIRONMENT       Environment suffix"
            exit 0
            ;;
        *)
            log_error "Opción desconocida: $1"
            echo "Usa --help para ver opciones disponibles"
            exit 1
            ;;
    esac
done

# Ejecutar
main