#!/bin/bash

# Smart Factory Deployment Script for Azure Local (AKS)
# This script deploys the complete factory simulation on Kubernetes

echo "🏭 Starting Smart Factory deployment on Azure Local (AKS)..."
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check cluster connectivity
print_status "Checking Kubernetes cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

print_success "Connected to Kubernetes cluster"
kubectl cluster-info

echo ""
print_status "Current cluster nodes:"
kubectl get nodes

echo ""
print_status "Available storage classes:"
kubectl get storageclass

echo ""
print_status "Starting Smart Factory deployment..."

# Step 1: Create namespaces
print_status "Step 1/6: Creating namespaces..."
if kubectl apply -f 00-namespace.yaml; then
    print_success "Namespaces created"
else
    print_error "Failed to create namespaces"
    exit 1
fi

# Step 2: Setup storage
print_status "Step 2/6: Setting up storage..."
if kubectl apply -f 01-storage.yaml; then
    print_success "Storage resources created"
    print_status "Waiting for PVCs to be bound..."
    kubectl wait --for=condition=bound --timeout=120s pvc --all -n smart-factory
else
    print_error "Failed to create storage resources"
    exit 1
fi

# Step 3: Apply configurations
print_status "Step 3/6: Applying configurations..."
if kubectl apply -f 02-configmaps.yaml && kubectl apply -f 03-configmaps-secrets.yaml; then
    print_success "Configurations applied"
else
    print_error "Failed to apply configurations"
    exit 1
fi

# Step 4: Create services
print_status "Step 4/6: Creating services..."
if kubectl apply -f 04-services.yaml; then
    print_success "Services created"
else
    print_error "Failed to create services"
    exit 1
fi

# Step 5: Deploy applications
print_status "Step 5/6: Deploying applications..."
if kubectl apply -f 05-deployments.yaml; then
    print_success "Applications deployed"
else
    print_error "Failed to deploy applications"
    exit 1
fi

# Step 6: Wait for deployments to be ready
print_status "Step 6/6: Waiting for deployments to be ready..."
print_warning "This may take several minutes as images are pulled and containers start..."

if kubectl wait --for=condition=available --timeout=600s deployment --all -n smart-factory; then
    print_success "All deployments are ready!"
else
    print_warning "Some deployments may still be starting. Check status manually."
fi

echo ""
print_success "🎉 Smart Factory deployment completed!"
echo "=============================================="

# Display deployment status
echo ""
print_status "Deployment Status:"
kubectl get all -n smart-factory

echo ""
print_status "Persistent Volumes:"
kubectl get pv

echo ""
print_status "Storage Status:"
kubectl get pvc -n smart-factory

# Get service information
echo ""
print_status "Services and External Access:"
kubectl get services -n smart-factory

# Check for LoadBalancer external IP
echo ""
EXTERNAL_IP=$(kubectl get service factory-dashboard-lb -n smart-factory -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [[ -n "$EXTERNAL_IP" && "$EXTERNAL_IP" != "null" ]]; then
    print_success "🌐 Factory Dashboard is accessible at:"
    echo "   SCADA Interface: http://$EXTERNAL_IP:8080"
    echo "   Factory Simulator: http://$EXTERNAL_IP:8081"  
    echo "   Robot Controller: http://$EXTERNAL_IP:8082"
else
    print_warning "LoadBalancer external IP not yet assigned. Run this command to check later:"
    echo "   kubectl get service factory-dashboard-lb -n smart-factory"
    echo ""
    print_status "For local testing, you can use port forwarding:"
    echo "   kubectl port-forward service/factory-dashboard-lb 8080:8080 8081:8081 8082:8082 -n smart-factory"
fi

echo ""
print_status "📊 Monitor your deployment:"
echo "   kubectl get pods -n smart-factory -w"
echo "   kubectl logs -f deployment/factory-simulator -n smart-factory"
echo "   kubectl logs -f deployment/robot-controller -n smart-factory"

echo ""
print_status "🔧 Troubleshooting commands:"
echo "   kubectl describe pods -n smart-factory"
echo "   kubectl get events -n smart-factory --sort-by='.metadata.creationTimestamp'"

echo ""
print_success "✅ Azure Local Smart Factory is now running!"
print_status "This deployment provides:"
echo "   • Autonomous local operations"
echo "   • Real-time factory simulation" 
echo "   • Industrial robot control"
echo "   • SCADA monitoring dashboard"
echo "   • Edge processing capabilities"
echo "   • Cloud sync when connectivity available"

echo ""
print_status "🏭 Welcome to your Smart Factory on Azure Local! 🎯"