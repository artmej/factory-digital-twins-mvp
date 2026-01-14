# Factory Digital Twins - DevOps Setup

## 🚀 CI/CD Pipeline con GitHub Actions

Este proyecto incluye un pipeline completo de CI/CD que automatiza:

### 📋 **Funcionalidades del Pipeline**

#### ✅ **Continuous Integration (CI)**
- **Validación de código**: ESLint para JavaScript
- **Pruebas unitarias**: Jest con coverage mínimo del 70%
- **Validación de Bicep**: Templates de infraestructura
- **Validación DTDL**: Modelos de Digital Twins
- **Build de artefactos**: Function App y Device Simulator

#### 🚀 **Continuous Deployment (CD)**
- **Entornos automáticos**:
  - `DEV`: Deploy automático en branch `develop`
  - `STAGING`: Deploy automático en branch `main`
  - `PRODUCTION`: Deploy manual via workflow dispatch
  
#### 🔧 **Entornos de PR**
- **Ambiente temporal** por cada Pull Request
- **Cleanup automático** cuando se cierra el PR
- **Testing aislado** sin afectar otros entornos

### 🛠️ **Setup Inicial**

#### 1. **Configurar Azure Service Principal**

```bash
# Crear service principal para GitHub Actions
az ad sp create-for-rbac --name "factory-github-actions" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth
```

#### 2. **Configurar GitHub Secrets**

En tu repositorio de GitHub, agregar estos secrets:

```
AZURE_CREDENTIALS={output-del-comando-anterior}
AZURE_SUBSCRIPTION_ID=tu-subscription-id
```

#### 3. **Configurar Environments en GitHub**

Crear los siguientes environments en GitHub:
- `dev`
- `staging` 
- `production` (con required reviewers)

### 🧪 **Testing Automatizado**

#### **Pruebas Unitarias** (`tests/unit/`)
- ✅ **Simulador IoT**: Validación de generación de datos
- ✅ **Azure Function**: Mocking de SDK de Azure
- ✅ **Modelos DTDL**: Validación de estructura y compliance

#### **Pruebas de Integración** (`tests/integration/`)
- ✅ **Azure Digital Twins**: Operaciones CRUD reales
- ✅ **IoT Hub**: Conectividad y envío de mensajes
- ✅ **Function App**: Health checks y triggers

### 📊 **Estrategia de Branching**

```
main (staging)
├── develop (dev)
│   ├── feature/nueva-funcionalidad
│   └── feature/fix-bug
└── hotfix/critical-fix (production)
```

### 🔄 **Flujo de Trabajo**

#### **Development Flow**
1. Crear feature branch desde `develop`
2. **Push** → Ejecuta validaciones + pruebas
3. **PR a develop** → Crea entorno temporal
4. **Merge a develop** → Deploy automático a DEV
5. **PR a main** → Deploy automático a STAGING
6. **Manual trigger** → Deploy a PRODUCTION

#### **Monitoring del Pipeline**
- ✅ **Status badges** en README
- 📧 **Notificaciones** por email/Slack en fallos
- 📈 **Métricas de deployment** en GitHub Actions

### 🛡️ **Seguridad y Compliance**

- 🔐 **Secrets management** via GitHub Secrets
- 🎯 **Least privilege** con service principal específico
- 🧹 **Cleanup automático** de recursos temporales
- 📋 **Approval gates** para producción

### 📈 **Métricas y Calidad**

- **Code Coverage**: Mínimo 70% en todas las ramas
- **Build Success Rate**: Target 95%+
- **Deployment Frequency**: Múltiples deploys diarios
- **Lead Time**: < 30 minutos de commit a deployment

### 🚦 **Como Ejecutar**

#### **Ejecutar Localmente**
```bash
# Instalar dependencias de testing
cd tests
npm install

# Ejecutar pruebas unitarias
npm test

# Ejecutar con coverage
npm run test:coverage

# Ejecutar pruebas de integración (requiere Azure setup)
npm run test:integration
```

#### **Triggers del Pipeline**
- **Push a develop**: Deploy a DEV
- **Push a main**: Deploy a STAGING  
- **PR abierto**: Crea entorno temporal
- **Manual dispatch**: Deploy a PRODUCTION

### 🔧 **Configuración de Variables**

Las variables se configuran automáticamente por environment:

```yaml
DEV:     factory-rg-dev,     factory-adt-dev
STAGING: factory-rg-staging, factory-adt-staging  
PROD:    factory-rg-prod,    factory-adt-prod
```

**¡El pipeline está listo para usar! 🎉**