# Factory Digital Twins MVP

[![CI/CD](https://github.com/artmej/factory-digital-twins-mvp/actions/workflows/ci-cd-oidc.yml/badge.svg)](https://github.com/artmej/factory-digital-twins-mvp/actions/workflows/ci-cd-oidc.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Un MVP (Minimum Viable Product) completo de **Azure Digital Twins** para monitoreo de fábrica con IoT, incluyendo CI/CD automatizado con GitHub Actions.

## 🏭 **Arquitectura**

```
IoT Devices → IoT Hub → Azure Function → Digital Twins → Power BI
     ↓
Device Simulator (para testing)
```

## 🚀 **Componentes**

- **Azure Digital Twins**: Gemelos digitales de fábrica, líneas, máquinas y sensores
- **IoT Hub**: Ingesta de telemetría en tiempo real
- **Azure Function**: Procesamiento y proyección de datos a Digital Twins
- **Device Simulator**: Simulador de dispositivos IoT para testing
- **Infrastructure as Code**: Bicep templates para deployment automatizado
- **CI/CD Pipeline**: GitHub Actions con OpenID Connect (OIDC)

## 📁 **Estructura del Proyecto**

```
├── .github/workflows/     # GitHub Actions pipelines
├── docs/                  # Documentación y diagramas
├── infra/                 # Infrastructure as Code
│   ├── bicep/            # Azure Bicep templates
│   └── scripts/          # Deployment scripts
├── models/               # Azure Digital Twins models (DTDL)
├── src/
│   ├── device-simulator/ # IoT device simulator
│   └── function-adt-projection/ # Azure Function
├── tests/
│   ├── unit/            # Unit tests
│   └── integration/     # Integration tests
└── edge/                # IoT Edge configuration
```

## ⚡ **Quick Start**

### 1. **Setup Prerequisites**
```bash
# Instalar herramientas necesarias
winget install Microsoft.AzureCLI
winget install Git.Git
winget install OpenJS.NodeJS
```

### 2. **Clone y Deploy**
```bash
git clone https://github.com/artmej/factory-digital-twins-mvp.git
cd factory-digital-twins-mvp

# Deploy manual (opción rápida)
cd infra/scripts
./deploy.sh --rg factory-rg --location eastus
```

### 3. **Deploy Automatizado (CI/CD)**
- Fork este repositorio
- Configurar GitHub Secrets (ver [Setup Guide](SETUP-FINAL.md))
- Push a `develop` → Auto-deploy a DEV
- Push a `main` → Auto-deploy a STAGING
- Manual dispatch → Deploy a PRODUCTION

## 🧪 **Testing**

```bash
# Unit Tests
cd tests
npm install
npm test

# Integration Tests (requiere Azure setup)
npm run test:integration

# Coverage Report
npm run test:coverage
```

## 🔧 **CI/CD Pipeline**

### **Features:**
- ✅ **Multi-environment** (dev/staging/prod)
- ✅ **Pull Request environments** (temporal)
- ✅ **Automated testing** (unit + integration)
- ✅ **Infrastructure validation** (Bicep + DTDL)
- ✅ **Security** (OIDC, no long-lived secrets)
- ✅ **Quality gates** (70% code coverage)

### **Workflow:**
```mermaid
graph LR
    A[Feature Branch] --> B[PR Created]
    B --> C[Temp Environment]
    C --> D[Tests & Validation]
    D --> E[Merge to develop]
    E --> F[Deploy to DEV]
    F --> G[Merge to main]
    G --> H[Deploy to STAGING]
    H --> I[Manual Approval]
    I --> J[Deploy to PROD]
```

## 🏗️ **Azure Resources Deployed**

| Resource | SKU | Purpose |
|----------|-----|---------|
| Digital Twins | Standard | Gemelos digitales |
| IoT Hub | S1 | Ingesta de telemetría |
| Function App | Consumption | Procesamiento de eventos |
| Storage Account | Standard_LRS | Function App storage |
| App Service Plan | Y1 (Dynamic) | Serverless hosting |

## 📊 **Modelos de Datos (DTDL)**

- **Factory**: Fábrica principal
- **Line**: Líneas de producción
- **Machine**: Máquinas industriales
- **Sensor**: Sensores IoT

## 🔐 **Seguridad**

- **OIDC Authentication** para GitHub Actions
- **Managed Identity** para Azure services
- **Least privilege** access con service principals
- **Secrets management** con GitHub Secrets

## 📈 **Monitoreo**

- **Application Insights** para telemetría de aplicaciones
- **Digital Twins Explorer** para visualización
- **IoT Hub monitoring** para conectividad de dispositivos
- **GitHub Actions** para pipeline health

## 🤝 **Contribución**

1. Fork el repositorio
2. Crear feature branch (`git checkout -b feature/nueva-funcionalidad`)
3. Commit changes (`git commit -am 'Add nueva funcionalidad'`)
4. Push to branch (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## 📄 **Documentación**

- [🚀 Deployment Guide](docs/runbook.md)
- [🔧 DevOps Setup](docs/devops-setup.md)
- [🏗️ Architecture](docs/visual-diagrams-guide.md)
- [⚙️ Final Setup](SETUP-FINAL.md)

## 📝 **License**

Este proyecto está licenciado bajo la licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 🆘 **Support**

¿Problemas o preguntas?
- 📖 Revisar la [documentación](docs/)
- 🐛 Reportar un [issue](https://github.com/artmej/factory-digital-twins-mvp/issues)
- 💬 Iniciar una [discusión](https://github.com/artmej/factory-digital-twins-mvp/discussions)

---

**Hecho con ❤️ para Azure Digital Twins**