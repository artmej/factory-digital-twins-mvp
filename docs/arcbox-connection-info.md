# ArcBox DataOps - Información de Conexión

## 🖥️ **VM Cliente (ArcBox-Client)**
- **IP**: 10.16.1.15
- **Usuario**: arcdemo  
- **Contraseña**: SmartFactory2024!
- **Conexión**: RDP via Bastion Host

## 🔗 **Bastion Host**
- **Nombre**: ArcBox-Bastion
- **Resource Group**: rg-smartfactory-arcbox

## 📊 **Clusters disponibles**
- **K3s Cluster**: ArcBox-K3s-Data-26e7 (Arc-enabled)
- **AKS Cluster**: ArcBox-AKS-Data-26e7 
- **AKS DR Cluster**: ArcBox-AKS-DR-Data-26e7

## 🛠️ **Para conectar vía Bastion:**

1. Ir al Azure Portal
2. Navegar a: rg-smartfactory-arcbox > ArcBox-Client
3. Usar "Connect" > "Bastion"
4. Usuario: arcdemo
5. Contraseña: SmartFactory2024!

## 🔧 **Comandos a ejecutar en ArcBox-Client:**

```bash
# Verificar cluster K3s
kubectl get nodes

# Verificar Arc Data Services
kubectl get namespaces | grep arc

# Ver pods de Arc Data Services
kubectl get pods -n arc

# Estado del data controller
az arcdata dc status show --k8s-namespace arc --use-k8s
```