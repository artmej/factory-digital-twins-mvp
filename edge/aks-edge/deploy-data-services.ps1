# Smart Factory Data Services Deployment
# Deploys PostgreSQL, InfluxDB, Grafana, and ML services on AKS Edge

param(
    [string]$Namespace = "smart-factory",
    [string]$StorageClass = "local-path"
)

Write-Host "🏭 Deploying Smart Factory Data Services..." -ForegroundColor Cyan

# Create namespace
Write-Host "📁 Creating namespace: $Namespace" -ForegroundColor Yellow
kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -

# Deploy PostgreSQL
Write-Host "🐘 Deploying PostgreSQL..." -ForegroundColor Yellow
kubectl apply -n $Namespace -f ./manifests/postgresql.yaml

# Deploy InfluxDB
Write-Host "📊 Deploying InfluxDB..." -ForegroundColor Yellow
kubectl apply -n $Namespace -f ./manifests/influxdb.yaml

# Deploy Redis
Write-Host "🔴 Deploying Redis..." -ForegroundColor Yellow
kubectl apply -n $Namespace -f ./manifests/redis.yaml

# Deploy Grafana
Write-Host "📈 Deploying Grafana..." -ForegroundColor Yellow
kubectl apply -n $Namespace -f ./manifests/grafana.yaml

# Deploy Prometheus
Write-Host "📊 Deploying Prometheus..." -ForegroundColor Yellow
kubectl apply -n $Namespace -f ./manifests/prometheus.yaml

# Deploy Node-RED
Write-Host "🔴 Deploying Node-RED..." -ForegroundColor Yellow
kubectl apply -n $Namespace -f ./manifests/node-red.yaml

# Deploy ML Inference API
Write-Host "🧠 Deploying ML Inference API..." -ForegroundColor Yellow
kubectl apply -n $Namespace -f ./manifests/ml-inference.yaml

# Deploy Factory Data API
Write-Host "🏭 Deploying Factory Data API..." -ForegroundColor Yellow
kubectl apply -n $Namespace -f ./manifests/factory-api.yaml

# Wait for deployments
Write-Host "⏳ Waiting for deployments to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment -n $Namespace --all

# Show service status
Write-Host "📊 Service Status:" -ForegroundColor Green
kubectl get pods -n $Namespace -o wide

Write-Host "🌐 Access URLs:" -ForegroundColor Cyan
Write-Host "Grafana:     http://localhost:30000 (admin/admin123)" -ForegroundColor White
Write-Host "Node-RED:    http://localhost:30001" -ForegroundColor White
Write-Host "PostgreSQL:  localhost:30432" -ForegroundColor White
Write-Host "InfluxDB:    http://localhost:30086" -ForegroundColor White
Write-Host "ML API:      http://localhost:30002" -ForegroundColor White
Write-Host "Factory API: http://localhost:30003" -ForegroundColor White

Write-Host "🏭 Data Services deployment completed!" -ForegroundColor Green