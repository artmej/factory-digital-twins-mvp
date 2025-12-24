# Smart Factory Deployment on Azure Local (AKS)

## 🚀 Quick Deployment

Este script deployará automáticamente toda la Smart Factory sobre AKS en Azure Local.

### Prerequisitos:
- Azure Local (Azure Stack HCI) configurado
- AKS cluster creado en Azure Local
- kubectl configurado
- Acceso al cluster

### Deployment Commands:

```bash
# 1. Create namespaces
kubectl apply -f 00-namespace.yaml

# 2. Setup storage
kubectl apply -f 01-storage.yaml

# 3. Apply configurations
kubectl apply -f 02-configmaps.yaml
kubectl apply -f 03-configmaps-secrets.yaml

# 4. Create services  
kubectl apply -f 04-services.yaml

# 5. Deploy applications
kubectl apply -f 05-deployments.yaml

# 6. Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment --all -n smart-factory

# 7. Get external IPs
kubectl get services -n smart-factory
```

### Verification:

```bash
# Check all resources
kubectl get all -n smart-factory

# Check logs
kubectl logs -l app=factory-simulator -n smart-factory
kubectl logs -l app=robot-controller -n smart-factory
kubectl logs -l app=scada-dashboard -n smart-factory

# Port forward for local testing (if needed)
kubectl port-forward service/factory-dashboard-lb 8080:8080 8081:8081 8082:8082 -n smart-factory
```

### Access URLs:

Once deployed, access the factory through the LoadBalancer service:

```bash
# Get the external IP
kubectl get service factory-dashboard-lb -n smart-factory

# Access URLs (replace <EXTERNAL-IP> with actual IP):
# SCADA Dashboard: http://<EXTERNAL-IP>:8080
# Factory Simulator: http://<EXTERNAL-IP>:8081  
# Robot Controller: http://<EXTERNAL-IP>:8082
```

### Troubleshooting:

```bash
# Check node status
kubectl get nodes

# Check storage classes
kubectl get storageclass

# Check persistent volumes
kubectl get pv

# Describe failed pods
kubectl describe pods -n smart-factory

# Check events
kubectl get events -n smart-factory --sort-by='.metadata.creationTimestamp'
```

### Architecture Deployed:

```
🏭 Smart Factory on Azure Local
├── 📊 Factory Simulator (Node.js)
│   ├── Real-time sensor data
│   ├── Production line simulation  
│   ├── WebSocket updates
│   └── REST API
├── 🤖 Robot Controller (Node.js)
│   ├── Industrial robot control
│   ├── AGV fleet management
│   ├── Safety zone monitoring
│   └── Program execution
├── 📈 SCADA Dashboard (Nginx + Backend)
│   ├── Real-time monitoring
│   ├── Production metrics
│   ├── Alert management
│   └── Local autonomy
├── 💾 Data Layer
│   ├── InfluxDB (time series)
│   ├── Redis (real-time cache)
│   └── Persistent storage
└── 🌐 Load Balancer (External Access)
    ├── Port 8080: SCADA
    ├── Port 8081: Factory
    └── Port 8082: Robots
```

### Features:

✅ **Local Autonomy**: Operates independently without cloud connectivity  
✅ **Real-time Processing**: Edge computing with immediate response  
✅ **Industrial Protocols**: Simulates real factory communication  
✅ **Scalable Architecture**: Kubernetes-native microservices  
✅ **Monitoring & Alerts**: Comprehensive factory oversight  
✅ **Robot Integration**: Multi-vendor robot fleet management  
✅ **Data Persistence**: Local storage with cloud sync capability

### Production Simulation:

- **2 Production Lines** with different machine types
- **3 Industrial Robots** (2x Arms + 1x AGV)
- **Real-time Sensor Data** (temperature, pressure, vibration)
- **Quality Metrics** and OEE calculation
- **Failure Simulation** and anomaly detection
- **Autonomous Operations** with local decision making