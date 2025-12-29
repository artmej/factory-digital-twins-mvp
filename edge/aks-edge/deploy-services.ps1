# Script final para desplegar todos los data services en AKS Edge
# Ejecutar después de configurar el cluster

param(
    [string]$VMHost = "130.131.248.173",
    [string]$VMUser = "azureuser",
    [string]$VMPassword = "SmartFactory2025!"
)

Write-Host "🏭 Desplegando Smart Factory Data Services..." -ForegroundColor Cyan

$SecurePassword = ConvertTo-SecureString $VMPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($VMUser, $SecurePassword)

try {
    $Session = New-PSSession -ComputerName $VMHost -Credential $Credential
    Write-Host "✅ Conectado a VM Arc" -ForegroundColor Green
    
    # Script para desplegar servicios
    $DeployScript = {
        Set-Location "C:\SmartFactory\aks-edge"
        $KubectlPath = "C:\SmartFactory\kubectl\kubectl.exe"
        
        Write-Host "📁 Creando namespace..." -ForegroundColor Yellow
        & $KubectlPath create namespace smart-factory --dry-run=client -o yaml | & $KubectlPath apply -f -
        
        # Crear manifests inline para evitar problemas de transferencia
        Write-Host "📝 Creando manifests..." -ForegroundColor Yellow
        
        # PostgreSQL manifest
        $PostgreSQLManifest = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgresql-config
  namespace: smart-factory
data:
  POSTGRES_DB: smart_factory
  POSTGRES_USER: factory_user
  POSTGRES_PASSWORD: SmartFactory2025!
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgresql-pvc
  namespace: smart-factory
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: local-path
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresql
  namespace: smart-factory
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      containers:
      - name: postgresql
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        envFrom:
        - configMapRef:
            name: postgresql-config
        volumeMounts:
        - name: postgresql-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: postgresql-storage
        persistentVolumeClaim:
          claimName: postgresql-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgresql-service
  namespace: smart-factory
spec:
  type: NodePort
  ports:
  - port: 5432
    nodePort: 30432
  selector:
    app: postgresql
"@
        
        # Aplicar PostgreSQL
        Write-Host "🐘 Desplegando PostgreSQL..." -ForegroundColor Yellow
        $PostgreSQLManifest | & $KubectlPath apply -f -
        
        # Grafana manifest simplificado
        $GrafanaManifest = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-config
  namespace: smart-factory
data:
  GF_SECURITY_ADMIN_USER: admin
  GF_SECURITY_ADMIN_PASSWORD: admin123
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: smart-factory
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        envFrom:
        - configMapRef:
            name: grafana-config
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
  namespace: smart-factory
spec:
  type: NodePort
  ports:
  - port: 3000
    nodePort: 30000
  selector:
    app: grafana
"@
        
        # Aplicar Grafana
        Write-Host "📈 Desplegando Grafana..." -ForegroundColor Yellow
        $GrafanaManifest | & $KubectlPath apply -f -
        
        # Factory API simplificada
        $FactoryAPIManifest = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: factory-api
  namespace: smart-factory
spec:
  replicas: 1
  selector:
    matchLabels:
      app: factory-api
  template:
    metadata:
      labels:
        app: factory-api
    spec:
      containers:
      - name: factory-api
        image: node:18-alpine
        ports:
        - containerPort: 3000
        command:
        - /bin/sh
        - -c
        - |
          npm install express
          cat > app.js << 'EOF'
          const express = require('express');
          const app = express();
          
          app.use(express.json());
          
          app.get('/health', (req, res) => {
            res.json({ 
              status: 'healthy', 
              service: 'factory-api',
              timestamp: new Date().toISOString()
            });
          });
          
          app.get('/api/machines', (req, res) => {
            res.json([
              { id: 1, name: 'CNC-001', type: 'CNC Machine', status: 'operational' },
              { id: 2, name: 'PRESS-001', type: 'Hydraulic Press', status: 'maintenance' }
            ]);
          });
          
          const PORT = 3000;
          app.listen(PORT, '0.0.0.0', () => {
            console.log('Factory API running on port ' + PORT);
          });
          EOF
          
          node app.js
---
apiVersion: v1
kind: Service
metadata:
  name: factory-api-service
  namespace: smart-factory
spec:
  type: NodePort
  ports:
  - port: 3000
    nodePort: 30003
  selector:
    app: factory-api
"@
        
        # Aplicar Factory API
        Write-Host "🏭 Desplegando Factory API..." -ForegroundColor Yellow
        $FactoryAPIManifest | & $KubectlPath apply -f -
        
        # Esperar a que se desplieguen
        Write-Host "⏳ Esperando a que los servicios estén listos..." -ForegroundColor Yellow
        Start-Sleep 60
        
        # Verificar estado
        Write-Host "📊 Estado de los servicios:" -ForegroundColor Green
        & $KubectlPath get pods -n smart-factory
        & $KubectlPath get services -n smart-factory
        
        Write-Host "🌐 URLs de acceso:" -ForegroundColor Cyan
        Write-Host "Grafana:     http://130.131.248.173:30000 (admin/admin123)" -ForegroundColor White
        Write-Host "Factory API: http://130.131.248.173:30003/api/machines" -ForegroundColor White
        Write-Host "PostgreSQL:  130.131.248.173:30432" -ForegroundColor White
        
        Write-Host "🎉 Smart Factory Edge Stack desplegado!" -ForegroundColor Green
    }
    
    # Ejecutar despliegue
    Invoke-Command -Session $Session -ScriptBlock $DeployScript
    
    Remove-PSSession -Session $Session
    
    Write-Host "✅ Despliegue completado" -ForegroundColor Green
    Write-Host "🌐 Acceso: http://130.131.248.173:30000" -ForegroundColor Cyan

} catch {
    Write-Error "Error desplegando servicios: $_"
}