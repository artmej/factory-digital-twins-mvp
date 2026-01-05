#!/bin/bash
# 🏭 Smart Factory Minimal Arc + AKS Deployment
# Cost-optimized setup for IoT Edge + PostgreSQL

set -e

echo "🏭 Smart Factory Minimal Deployment"
echo "==================================="

# Configuration
RESOURCE_GROUP="rg-smartfactory-prod-arc2"
LOCATION="eastus"
TEMPLATE_FILE="minimal-arc-aks.bicep"

echo "📋 Configuration:"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Location: $LOCATION"
echo "   Cost Target: ~$100-150/month (vs $800+ for ArcBox)"
echo ""

# 1. Create Resource Group
echo "🏗️ Creating Resource Group..."
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --output table

echo "✅ Resource Group created"

# 2. Deploy minimal Arc + AKS infrastructure
echo "🚀 Deploying minimal Arc + AKS infrastructure..."
echo "   - Linux VM with Azure Arc (Standard_B2s)"
echo "   - Small AKS cluster (2 nodes)"
echo "   - Virtual Network"
echo ""

az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file $TEMPLATE_FILE \
    --parameters location=$LOCATION \
    --output table

echo "✅ Infrastructure deployed"

# 3. Get AKS credentials
echo "🔑 Getting AKS credentials..."
AKS_NAME=$(az aks list --resource-group $RESOURCE_GROUP --query "[0].name" --output tsv)
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing

echo "✅ AKS credentials configured"

# 4. Deploy IoT Edge + PostgreSQL to AKS
echo "📦 Deploying Smart Factory workloads to AKS..."
echo "   - PostgreSQL database"
echo "   - IoT Edge runtime"
echo "   - Factory simulator"
echo "   - Data ingestion service"

kubectl apply -f ../k8s/smart-factory-minimal.yaml

echo "✅ Workloads deployed"

# 5. Wait for pods to be ready
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n smart-factory --timeout=300s
kubectl wait --for=condition=ready pod -l app=iotedge -n smart-factory --timeout=300s

# 6. Get service information
echo ""
echo "📊 Deployment Summary:"
echo "====================="

# VM info
VM_NAME=$(az vm list --resource-group $RESOURCE_GROUP --query "[0].name" --output tsv)
VM_IP=$(az vm show --resource-group $RESOURCE_GROUP --name $VM_NAME --show-details --query "publicIps" --output tsv)

echo "🖥️  Arc VM: $VM_NAME"
echo "   IP: $VM_IP"
echo "   SSH: ssh azureuser@$VM_IP"

# AKS info
echo "⚙️  AKS Cluster: $AKS_NAME"
echo "   Nodes: $(kubectl get nodes --no-headers | wc -l)"

# Services
echo "📦 Deployed Services:"
kubectl get services -n smart-factory -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip

# Pods
echo "🚀 Running Pods:"
kubectl get pods -n smart-factory -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,RESTARTS:.status.containerStatuses[0].restartCount

echo ""
echo "💰 COST OPTIMIZATION ACHIEVED:"
echo "   Estimated monthly cost: ~$100-150"
echo "   vs ArcBox cost: ~$800-1200"
echo "   Monthly savings: ~$650-1050 (85-90%)"

echo ""
echo "🎯 NEXT STEPS:"
echo "1. Connect to VM: ssh azureuser@$VM_IP"
echo "2. Configure IoT Hub connection string in Kubernetes"
echo "3. Update Digital Twins endpoint in pods"
echo "4. Deploy your factory simulator code"
echo "5. Test PostgreSQL connection: kubectl exec -it <postgres-pod> -n smart-factory -- psql -U factory_user factory_db"

echo ""
echo "🔧 USEFUL COMMANDS:"
echo "   kubectl get all -n smart-factory"
echo "   kubectl logs -f deployment/postgres -n smart-factory"
echo "   kubectl logs -f deployment/iotedge-runtime -n smart-factory"
echo "   kubectl port-forward service/postgres-service 5432:5432 -n smart-factory"

echo ""
echo "✅ Smart Factory minimal deployment completed!"