# Smart Factory Digital Twins MVP

🏭 **Smart Factory Digital Twins with Real-time ML Analytics**

## 🌐 Live Dashboards (GitHub Pages)

- **🎮 3D Dashboard:** https://artmej.github.io/factory-digital-twins-mvp/3d-dashboard.html
- **💼 Executive Dashboard:** https://artmej.github.io/factory-digital-twins-mvp/executive-dashboard.html  
- **🔧 Maintenance Dashboard:** https://artmej.github.io/factory-digital-twins-mvp/maintenance-dashboard.html
- **📱 Mobile Dashboard:** https://artmej.github.io/factory-digital-twins-mvp/mobile-dashboard.html
- **🤖 Copilot Dashboard:** https://artmej.github.io/factory-digital-twins-mvp/copilot-dashboard.html
- **🧪 Test Dashboard:** https://artmej.github.io/factory-digital-twins-mvp/test-dashboard.html
- **📊 Simple Dashboard:** https://artmej.github.io/factory-digital-twins-mvp/simple.html

## 🧪 Testing & Validation

- **🔧 Architecture Integration Test:** https://artmej.github.io/factory-digital-twins-mvp/test-architecture-integration.html

## 🚀 Azure ML APIs

- **Endpoint:** https://smartfactoryml-api.azurewebsites.net
- **Real ML Models:** Maintenance, Quality, Energy, Anomaly Detection
- **Realistic Confidence:** 65-95% range (no more 100%)

## 🏗️ Architecture Integration

All dashboards now implement **unified Application Gateway + Function Apps + WebApps architecture**:

```
🌐 Application Gateway (smartfactory-gw.azurefd.net)
    ↓
📱 Function Apps (Middleware Layer)
    ├── Auth Function   (smartfactory-auth-func.azurewebsites.net)
    ├── Data Function   (smartfactory-data-func.azurewebsites.net)  
    ├── ML Function     (smartfactory-ml-func.azurewebsites.net)
    └── IoT Function    (smartfactory-iot-func.azurewebsites.net)
    ↓
🏗️ WebApp APIs (Backend Layer)
    ├── ML API          (smartfactoryml-api.azurewebsites.net)
    ├── Cosmos API      (smartfactory-cosmos-api.azurewebsites.net)
    ├── Digital Twins   (smartfactory-dt-api.azurewebsites.net)
    └── Main API        (smartfactory-prod-web.azurewebsites.net)
```

### Environment Detection
- **Development Mode:** GitHub Pages deployment with null Azure endpoints
- **Production Mode:** Full Azure integration with real API endpoints
- **Authentication:** Microsoft MSAL integrated across all dashboards

## 🏭 Factory Structure

**3 Production Lines - 9 Machines Total:**
- **LINE_1:** CNC_01, ROBOT_01, CONV_01  
- **LINE_2:** CNC_02, ROBOT_02, CONV_02
- **LINE_3:** CNC_03, ROBOT_03, CONV_03

## 🔒 Security Features

- **Microsoft Authentication:** Required for all dashboards
- **Azure Managed Identity:** For secure API access
- **No Secrets:** Connection strings excluded from repository

## 📊 Tech Stack

- **Frontend:** HTML5, Three.js, Microsoft MSAL
- **Backend:** .NET 8 Azure App Service  
- **ML Platform:** Azure ML Studio
- **Hosting:** GitHub Pages + Azure
- **Auth:** Microsoft Azure AD

---
*Clean deployment without sensitive information*