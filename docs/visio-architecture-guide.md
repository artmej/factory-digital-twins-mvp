# Visio Architecture Diagram - Smart Factory Physical Architecture

## Instructions for Creating the Visio Diagram

### File Information
- **Template:** Azure Architecture Template
- **Canvas Size:** Landscape (11" x 17")
- **Title:** Smart Factory - Physical Architecture (Production)
- **Case Study:** #36 - Azure Master Program

### Layout Structure (3 Layers)

#### 1. ON-PREMISES LAYER (Bottom - Factory Floor)
**Color Scheme:** Orange/Red (#FF6B35)

**Components:**
- **Production Line A**
  - CNC Milling Machine (Icon: Manufacturing/CNC)
  - Assembly Robot (Icon: Manufacturing/Robot)
  - Quality Control Station (Icon: Manufacturing/Inspection)
  - Packaging Line (Icon: Manufacturing/Conveyor)

- **Edge Computing Infrastructure**
  - Azure Stack Edge (Icon: Azure Stack Edge)
  - IoT Edge Runtime (Icon: Container/Docker)
  - OPC UA Gateway (Icon: Gateway/Bridge)
  - Industrial Network Switch (Icon: Networking/Switch)

#### 2. AZURE CLOUD LAYER (Middle - Core Services)
**Color Scheme:** Blue (#0078D4)

**Network Infrastructure:**
- **Virtual Network (10.0.0.0/16)**
  - VM Subnet (10.0.1.0/24)
  - IoT Subnet (10.0.2.0/24)  
  - Functions Subnet (10.0.3.0/24)
  - Gateway Subnet (10.0.4.0/24)

**Core Azure Services:**
- **IoT & Messaging**
  - Azure IoT Hub (Icon: Azure IoT Hub)
  - Event Hubs (Icon: Azure Event Hubs)
  - Service Bus (Icon: Azure Service Bus)

- **Compute & Processing**
  - Azure Functions (Icon: Azure Functions)
  - Logic Apps (Icon: Azure Logic Apps)
  - VM arc-simple (Icon: Virtual Machines)

- **Data & Analytics**
  - Azure Digital Twins (Icon: Azure Digital Twins)
  - Cosmos DB (Icon: Azure Cosmos DB)
  - Storage Account (Icon: Azure Storage)
  - Azure Synapse (Icon: Azure Synapse)

- **AI & ML**
  - Azure Machine Learning (Icon: Azure ML)
  - Cognitive Services (Icon: Cognitive Services)
  - Stream Analytics (Icon: Stream Analytics)

- **Security & Management**
  - Key Vault (Icon: Azure Key Vault)
  - Azure Monitor (Icon: Azure Monitor)
  - Log Analytics (Icon: Log Analytics)

#### 3. APPLICATIONS LAYER (Top - User Interfaces)
**Color Scheme:** Green (#107C10)

**Web Applications:**
- **3D Digital Twin Viewer**
  - React Web App (Icon: Web App)
  - Three.js 3D Engine (Icon: 3D/Graphics)
  - Real-time Dashboard (Icon: Dashboard)

- **Mobile Applications**
  - Field Engineer App (Icon: Mobile App)
  - Maintenance Scheduler (Icon: Calendar)
  - Alert Manager (Icon: Notifications)

- **Business Intelligence**
  - Power BI Dashboard (Icon: Power BI)
  - Executive Reports (Icon: Reports)
  - KPI Monitor (Icon: Analytics)

### Data Flow Connections

#### 1. Telemetry Flow (Red Arrows - Thick)
```
Factory Devices → Edge Gateway → VPN → IoT Hub → Event Hub → Functions → Digital Twins
```

#### 2. Command Flow (Blue Arrows - Medium)  
```
Dashboard → API → Functions → IoT Hub → Edge Gateway → Devices
```

#### 3. Analytics Flow (Green Arrows - Thin)
```
Digital Twins → Cosmos DB → Synapse → Power BI → Dashboard
```

### Technical Specifications Callouts

#### Performance Metrics Box (Top Right)
```
📊 PERFORMANCE METRICS
• Devices Connected: 5,000+
• Messages/Second: 1,000
• ML Accuracy: 94.7%
• Uptime: 99.9%
• ROI: $2.2M annually
• Latency: <100ms
```

#### Network Architecture Box (Top Left)
```
🌐 NETWORK ARCHITECTURE
• VNet: 10.0.0.0/16
• VM Subnet: 10.0.1.0/24
• IoT Subnet: 10.0.2.0/24
• Functions: 10.0.3.0/24
• Site-to-Site VPN
• Private Endpoints
```

#### Security Features Box (Bottom Right)
```
🔒 SECURITY FEATURES
• Azure AD Integration
• RBAC & Managed Identity
• Private Endpoints
• Network Security Groups
• Key Vault for Secrets
• Encryption (Rest + Transit)
```

### Visio Stencils Required

#### Azure Architecture Stencils
- Azure IoT (download from Microsoft)
- Azure Compute & Web
- Azure Data & Analytics  
- Azure AI & Machine Learning
- Azure Integration
- Azure Security

#### Additional Stencils
- Manufacturing/Industrial Icons
- Network Infrastructure
- 3D Graphics/Visualization Icons

### Color Coding Legend

- **Orange (#FF6B35):** On-Premises/Edge
- **Blue (#0078D4):** Azure Cloud Services
- **Green (#107C10):** Applications/UI
- **Red (#E74C3C):** Data Flow (Telemetry)
- **Purple (#8E44AD):** Security Components
- **Gray (#95A5A6):** Infrastructure/Network

### Text Styling
- **Title:** Calibri 24pt Bold
- **Section Headers:** Calibri 14pt Bold  
- **Component Labels:** Calibri 10pt Regular
- **Technical Details:** Consolas 8pt

### Export Settings
- **Format:** PNG (High Resolution)
- **Resolution:** 300 DPI
- **Size:** 1920x1080 (for presentations)
- **Background:** White

### File Naming Convention
```
SmartFactory_PhysicalArchitecture_Prod_v1.0.vsdx
SmartFactory_PhysicalArchitecture_Prod_v1.0.png
```

---

## Alternative: Lucidchart/Draw.io Instructions

If Visio is not available, the same diagram can be created using:

### Lucidchart
1. Use "Azure" shape library
2. Import additional manufacturing icons
3. Follow same layout structure
4. Export as PNG/PDF

### Draw.io (diagrams.net)
1. Use Azure icon library (available in app)
2. Import custom manufacturing shapes
3. Use same color scheme and layout
4. Export as high-resolution PNG

---

## Integration with Documentation

This physical architecture diagram should be referenced in:
- **Design Document:** Section 1.2 (High-Level Architecture)
- **README.md:** Architecture overview section
- **Presentation Deck:** Technical architecture slide
- **Deployment Guide:** Infrastructure overview

The diagram serves as the visual foundation for understanding the Smart Factory solution's physical deployment and data flow patterns.