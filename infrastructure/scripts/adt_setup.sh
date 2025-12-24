#!/bin/bash

# Azure Digital Twins Setup Script
# Este script importa modelos DTDL y crea twins con sus relaciones

set -e

# Variables de configuración (modificar según necesidad)
RG_NAME="${RG_NAME:-factory-rg}"
LOCATION="${LOCATION:-eastus}"
ADT_NAME="${ADT_NAME:-factory-adt-dev}"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
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
    
    # Verificar extensión de Digital Twins
    if ! az extension list | grep -q "azure-iot"; then
        log_info "Instalando extensión azure-iot..."
        az extension add --name azure-iot
    fi
    
    log_success "Dependencias verificadas"
}

# Verificar login de Azure
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

# Verificar que ADT existe
check_adt_exists() {
    log_info "Verificando instancia de Azure Digital Twins..."
    
    if ! az dt show --dt-name "$ADT_NAME" --resource-group "$RG_NAME" &> /dev/null; then
        log_error "La instancia de Digital Twins '$ADT_NAME' no existe en el grupo '$RG_NAME'"
        log_info "Ejecuta primero el deployment de Bicep"
        exit 1
    fi
    
    log_success "Instancia de Digital Twins encontrada: $ADT_NAME"
}

# Importar modelos DTDL
import_models() {
    log_info "Importando modelos DTDL..."
    
    local models_dir="../../models"
    
    # Verificar que el directorio de modelos existe
    if [ ! -d "$models_dir" ]; then
        log_error "Directorio de modelos no encontrado: $models_dir"
        exit 1
    fi
    
    # Importar modelos en orden (debido a dependencias)
    local models=("factory.dtdl.json" "line.dtdl.json" "machine.dtdl.json" "sensor.dtdl.json")
    
    for model in "${models[@]}"; do
        local model_path="$models_dir/$model"
        
        if [ ! -f "$model_path" ]; then
            log_warning "Modelo no encontrado: $model_path"
            continue
        fi
        
        log_info "Importando modelo: $model"
        
        if az dt model create --dt-name "$ADT_NAME" --models "$model_path" 2>/dev/null; then
            log_success "Modelo importado: $model"
        else
            log_warning "Error al importar $model (posiblemente ya existe)"
        fi
    done
    
    log_success "Importación de modelos completada"
}

# Crear twins
create_twins() {
    log_info "Creando Digital Twins..."
    
    # Factory twin
    log_info "Creando factory twin..."
    az dt twin create --dt-name "$ADT_NAME" --dtmi "dtmi:mx:factory;1" --twin-id "factory1" \
        --properties '{"name": "Main Factory", "location": "Mexico City"}' || log_warning "Factory twin ya existe"
    
    # Line twin  
    log_info "Creando line twin..."
    az dt twin create --dt-name "$ADT_NAME" --dtmi "dtmi:mx:factory:line;1" --twin-id "lineA" \
        --properties '{"oee": 0.85, "state": "running"}' || log_warning "Line twin ya existe"
    
    # Machine twin
    log_info "Creando machine twin..."
    az dt twin create --dt-name "$ADT_NAME" --dtmi "dtmi:mx:factory:machine;1" --twin-id "machineA" \
        --properties '{"serial": "MAC-001-2024", "health": "healthy", "model": "ProductionLine-X1"}' || log_warning "Machine twin ya existe"
    
    # Sensor twin
    log_info "Creando sensor twin..."
    az dt twin create --dt-name "$ADT_NAME" --dtmi "dtmi:mx:factory:sensor;1" --twin-id "sensorA" \
        --properties '{"kind": "temperature", "unit": "celsius"}' || log_warning "Sensor twin ya existe"
    
    log_success "Twins creados exitosamente"
}

# Crear relaciones
create_relationships() {
    log_info "Creando relaciones entre twins..."
    
    # Factory contains Line
    log_info "Creando relación: factory1 -> lineA"
    az dt twin relationship create --dt-name "$ADT_NAME" \
        --relationship-id "factory-contains-lineA" \
        --relationship "contains" \
        --twin-id "factory1" \
        --target "lineA" || log_warning "Relación factory->line ya existe"
    
    # Line contains Machine  
    log_info "Creando relación: lineA -> machineA"
    az dt twin relationship create --dt-name "$ADT_NAME" \
        --relationship-id "line-contains-machineA" \
        --relationship "contains" \
        --twin-id "lineA" \
        --target "machineA" || log_warning "Relación line->machine ya existe"
    
    # Machine contains Sensor
    log_info "Creando relación: machineA -> sensorA"  
    az dt twin relationship create --dt-name "$ADT_NAME" \
        --relationship-id "machine-contains-sensorA" \
        --relationship "contains" \
        --twin-id "machineA" \
        --target "sensorA" || log_warning "Relación machine->sensor ya existe"
    
    log_success "Relaciones creadas exitosamente"
}

# Mostrar resumen
show_summary() {
    log_info "=== RESUMEN DE CONFIGURACIÓN ==="
    echo
    log_info "Azure Digital Twins Instance: $ADT_NAME"
    log_info "Resource Group: $RG_NAME"
    echo
    
    # Mostrar modelos
    log_info "Modelos DTDL importados:"
    az dt model list --dt-name "$ADT_NAME" --query "[].id" -o table
    echo
    
    # Mostrar twins
    log_info "Digital Twins creados:"
    az dt twin query --dt-name "$ADT_NAME" --query-command "SELECT * FROM digitaltwins" \
        --query "result[].{TwinId:\$dtId, Model:\$metadata.\$model}" -o table
    echo
    
    # Mostrar relaciones
    log_info "Relaciones creadas:"
    az dt twin relationship list --dt-name "$ADT_NAME" --twin-id "factory1" \
        --query "[].{Source:\$sourceId, Relationship:\$relationshipName, Target:\$targetId}" -o table
    az dt twin relationship list --dt-name "$ADT_NAME" --twin-id "lineA" \
        --query "[].{Source:\$sourceId, Relationship:\$relationshipName, Target:\$targetId}" -o table  
    az dt twin relationship list --dt-name "$ADT_NAME" --twin-id "machineA" \
        --query "[].{Source:\$sourceId, Relationship:\$relationshipName, Target:\$targetId}" -o table
    echo
    
    local adt_url="https://$ADT_NAME.api.eastus.digitaltwins.azure.net"
    log_success "Setup completado! ADT Explorer URL: https://explorer.digitaltwins.azure.net"
    log_info "Digital Twins URL: $adt_url"
}

# Función principal
main() {
    echo "=================================="
    echo "Azure Digital Twins Setup Script"
    echo "=================================="
    echo
    
    check_dependencies
    check_azure_login
    check_adt_exists
    
    log_info "Iniciando setup de Digital Twins..."
    
    import_models
    create_twins  
    create_relationships
    show_summary
    
    echo
    log_success "🎉 Setup de Azure Digital Twins completado exitosamente!"
    echo
    log_info "Próximos pasos:"
    log_info "1. Desplegar la Azure Function"
    log_info "2. Ejecutar el simulador de dispositivos"
    log_info "3. Monitorear en ADT Explorer"
}

# Manejo de parámetros de línea de comandos
while [[ $# -gt 0 ]]; do
    case $1 in
        --rg|--resource-group)
            RG_NAME="$2"
            shift 2
            ;;
        --adt|--adt-name)
            ADT_NAME="$2" 
            shift 2
            ;;
        --location)
            LOCATION="$2"
            shift 2
            ;;
        --help|-h)
            echo "Uso: $0 [opciones]"
            echo ""
            echo "Opciones:"
            echo "  --rg, --resource-group    Nombre del resource group (default: factory-rg)"
            echo "  --adt, --adt-name        Nombre de la instancia ADT (default: factory-adt-dev)"
            echo "  --location               Región de Azure (default: eastus)"
            echo "  --help, -h               Mostrar esta ayuda"
            echo ""
            echo "Variables de entorno:"
            echo "  RG_NAME      Nombre del resource group"
            echo "  ADT_NAME     Nombre de la instancia ADT"
            echo "  LOCATION     Región de Azure"
            exit 0
            ;;
        *)
            log_error "Opción desconocida: $1"
            echo "Usa --help para ver opciones disponibles"
            exit 1
            ;;
    esac
done

# Ejecutar script principal
main