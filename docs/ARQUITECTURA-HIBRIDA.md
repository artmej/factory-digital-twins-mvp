# Arquitectura Híbrida - Smart Factory

## Diagrama de Arquitectura General

```mermaid
graph TB
    %% Azure Local (On-Premise)
    subgraph "🏭 AZURE LOCAL (On-Premise)"
        direction TB
        VM[🖥️ arc-simple VM<br/>130.131.248.173]
        FS[📊 Factory Simulator<br/>Node.js/PowerShell]
        ARC[🔗 Azure Arc Agent]
        
        VM --> FS
        VM --> ARC
    end
    
    %% Connectivity
    subgraph "🌉 CONECTIVIDAD HÍBRIDA"
        direction TB
        VPN[🔒 VPN/ExpressRoute<br/>Secure Connection]
        IOT[📡 IoT Hub<br/>Telemetry Ingestion]
        
        ARC -.->|"Azure Arc<br/>Management"| VPN
        FS -->|"Device Telemetry<br/>JSON/MQTT"| IOT
    end
    
    %% Azure Cloud
    subgraph "☁️ AZURE CLOUD"
        direction TB
        
        subgraph "Core Services"
            FUNC[⚡ Azure Functions<br/>ADT Projection]
            ADT[🔷 Azure Digital Twins<br/>DTDL Models]
            STOR[💾 Storage Account<br/>Telemetry Archive]
        end
        
        subgraph "Intelligence"
            AI[🤖 Azure OpenAI<br/>Predictive Maintenance]
            COGSVC[🧠 Cognitive Services<br/>Computer Vision]
        end
        
        subgraph "Analytics"
            PBI[📊 Power BI<br/>Executive Dashboards]
            SYNAPSE[📈 Azure Synapse<br/>Data Warehouse]
        end
        
        IOT --> FUNC
        FUNC --> ADT
        FUNC --> STOR
        ADT --> AI
        ADT --> PBI
        STOR --> SYNAPSE
    end
    
    %% Applications
    subgraph "📱 APLICACIONES"
        direction TB
        MOBILE[📱 React Native<br/>Factory Worker App]
        WEB[🌐 Progressive Web App<br/>Control Room]
        VOICE[🗣️ Voice Agents<br/>Conversational AI]
        
        ADT --> MOBILE
        ADT --> WEB
        AI --> VOICE
    end
    
    %% Users
    subgraph "👥 USUARIOS"
        direction TB
        WORKER[👷 Factory Workers]
        ENGINEER[👨‍🔬 Process Engineers]
        MANAGER[👔 Plant Managers]
        
        WORKER --> MOBILE
        ENGINEER --> WEB
        MANAGER --> PBI
    end
    
    style VM fill:#e1f5fe
    style FS fill:#e8f5e8
    style ADT fill:#fff3e0
    style IOT fill:#f3e5f5
    style FUNC fill:#e0f2f1
```

## Flujo de Datos End-to-End

### 1. **Data Generation (Azure Local)**
```
Factory Simulator → Sensors Data → Azure Arc → Cloud
```

### 2. **Cloud Processing** 
```
IoT Hub → Azure Functions → Digital Twins → Applications
```

### 3. **User Consumption**
```
Digital Twins → Mobile App → Factory Workers
Digital Twins → Web Dashboard → Engineers  
Digital Twins → Power BI → Management
```

## Componentes por Capa

### **🏭 Azure Local (On-Premise)**
- **arc-simple VM**: Windows Server con Azure Arc
- **Factory Simulator**: Generador de telemetría industrial
- **Local Dashboard**: Control room local (futuro)

### **🌉 Conectividad Híbrida**
- **Azure Arc**: Gestión híbrida VM → Cloud
- **IoT Hub**: Ingesta de telemetría industrial
- **ExpressRoute**: Conectividad dedicada (opcional)

### **☁️ Azure Cloud**
- **Digital Twins**: Modelo digital de la fábrica
- **Azure Functions**: Procesamiento serverless
- **Azure OpenAI**: Inteligencia artificial
- **Power BI**: Analytics y dashboards

### **📱 Aplicaciones**
- **React Native**: App móvil para trabajadores  
- **PWA**: Dashboard web responsive
- **Voice Agents**: Asistentes conversacionales

## Tecnologías Utilizadas

### **Backend Cloud**
- Azure Digital Twins, IoT Hub, Functions
- Azure OpenAI, Cognitive Services
- Power BI, Azure Synapse

### **Frontend Applications** 
- React Native (Mobile)
- React + TypeScript (Web)
- Progressive Web App (PWA)

### **Edge/Local**
- Windows Server + Azure Arc
- PowerShell + Node.js
- Local SQLite storage

### **Infrastructure**
- Bicep Infrastructure as Code
- GitHub Actions CI/CD
- Azure DevOps Pipelines