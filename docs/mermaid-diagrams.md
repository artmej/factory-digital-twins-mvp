# Factory Digital Twins - Mermaid Diagrams

Diagramas en formato Mermaid que se renderizan automáticamente en GitHub, GitLab, VS Code y muchas plataformas.

## 🏗️ Arquitectura General

```mermaid
graph TB
    %% Styling
    classDef physical fill:#fff2cc,stroke:#d6b656,stroke-width:2px
    classDef edge fill:#ffe6cc,stroke:#d79b00,stroke-width:2px
    classDef azure fill:#dae8fc,stroke:#6c8ebf,stroke-width:2px
    classDef processing fill:#e1d5e7,stroke:#9673a6,stroke-width:2px
    classDef twins fill:#f8cecc,stroke:#b85450,stroke-width:2px
    classDef viz fill:#d5e8d4,stroke:#82b366,stroke-width:2px
    
    %% Physical Layer
    subgraph Physical["🏭 Physical Factory"]
        PF[🏭 Factory]
        PL[📈 Production Line]  
        PM[⚙️ Machine]
        PS[📡 IoT Sensors]
    end
    
    %% Edge Computing (Optional)
    subgraph Edge["🔧 Edge Computing"]
        ER[IoT Edge Runtime]
        ES[Simulator Module]
        EH[Edge Hub]
    end
    
    %% Cloud Ingestion
    subgraph Cloud["☁️ Azure IoT Platform"]
        IOT[IoT Hub<br/>Message Ingestion]
        EHP[Event Hub Endpoint<br/>Built-in]
    end
    
    %% Device Simulator
    SIM[💻 Device Simulator<br/>Node.js App<br/>Realistic Telemetry]
    
    %% Processing
    subgraph Process["⚡ Event Processing"]
        FUNC[Azure Function<br/>ADT Projection<br/><br/>• Update Properties<br/>• Publish Telemetry]
    end
    
    %% Digital Twins
    subgraph Twins["🔗 Azure Digital Twins"]
        MODELS[📋 DTDL Models<br/><br/>• Factory Interface<br/>• Line Interface<br/>• Machine Interface<br/>• Sensor Interface]
        INSTANCES[🌐 Digital Twins<br/><br/>Factory1 → LineA → MachineA → SensorA<br/><br/>Properties: health, state, oee<br/>Telemetry: temp, throughput, value]
        QUERY[🔍 Twin Graph & Query Engine<br/><br/>SELECT * FROM digitaltwins T<br/>WHERE T.$dtId = 'lineA'<br/>AND T.oee > 0.8]
    end
    
    %% Visualization
    subgraph Viz["📊 Visualization & Analytics"]
        EXPLORER[🔍 ADT Explorer<br/><br/>• Model Viewer<br/>• Twin Graph<br/>• Live Updates]
        ADX[📊 Azure Data Explorer<br/>Optional<br/><br/>• Historical Data<br/>• Time Series Analysis]
        PBI[📈 Power BI / Fabric<br/>Optional<br/><br/>• Dashboards<br/>• Reports<br/>• KPIs]
    end
    
    %% Data Flow
    PS -.->|📡 IoT Telemetry| IOT
    ES -.->|🔧 Edge Messages| IOT
    SIM -->|📱 Simulated Data| IOT
    IOT -->|📨 Event Stream| EHP
    EHP -->|⚡ Event Trigger| FUNC
    FUNC -->|🔄 Update Properties<br/>📊 Publish Telemetry| INSTANCES
    MODELS -.->|📋 Model Definition| INSTANCES
    INSTANCES -->|🔍 Real-time Queries| EXPLORER
    INSTANCES -.->|📊 Historical Data| ADX
    ADX -.->|📈 Dashboards| PBI
    INSTANCES -.->|🔍 Twin Graph| QUERY
    
    %% Apply styles
    class PF,PL,PM,PS physical
    class ER,ES,EH edge
    class IOT,EHP azure
    class FUNC processing
    class MODELS,INSTANCES,QUERY twins
    class EXPLORER,ADX,PBI viz
    class SIM azure
```

## 📊 Data Flow Diagram

```mermaid
sequenceDiagram
    participant S as 📡 Sensor/Simulator
    participant IOT as ☁️ IoT Hub
    participant EH as 📨 Event Hub
    participant FUNC as ⚡ Azure Function
    participant ADT as 🔗 Digital Twins
    participant VIZ as 🔍 ADT Explorer
    
    Note over S,VIZ: Factory Telemetry Data Flow
    
    S->>+IOT: Send telemetry message
    Note right of S: {"machineId":"machineA",<br/>"temperature":78.2,<br/>"health":"healthy"}
    
    IOT->>+EH: Route to Event Hub endpoint
    Note right of IOT: Built-in routing
    
    EH->>+FUNC: Trigger function execution
    Note right of EH: EventHub trigger
    
    FUNC->>+ADT: Update twin properties
    Note right of FUNC: PATCH /digitaltwins/machineA<br/>{"health":"healthy"}
    
    FUNC->>+ADT: Publish telemetry
    Note right of FUNC: POST /digitaltwins/machineA/telemetry<br/>{"temperature":78.2}
    
    ADT-->>-VIZ: Real-time twin updates
    Note right of ADT: Live query results
    
    VIZ-->>S: Visual feedback loop
    Note left of VIZ: Monitor & control
```

## 🌐 Digital Twin Graph Structure

```mermaid
graph TD
    F1[🏭 Factory1<br/>📍 Mexico City<br/>name: Main Factory]
    
    L1[📈 LineA<br/>⚡ OEE: 0.84<br/>📊 State: running<br/>🔄 Throughput: 120.5/min]
    
    M1[⚙️ MachineA<br/>🔧 Serial: MAC-001-2024<br/>❤️ Health: healthy<br/>🌡️ Temp: 78.2°C]
    
    S1[📡 SensorA<br/>📊 Kind: temperature<br/>📏 Unit: celsius<br/>📈 Value: 78.2]
    
    F1 -->|contains| L1
    L1 -->|contains| M1  
    M1 -->|contains| S1
    
    %% Properties vs Telemetry
    L1 -.->|Property| OEE[OEE: 0.84<br/>🔄 Persisted State]
    L1 -.->|Telemetry| THR[Throughput: 120.5<br/>📊 Streaming Data]
    
    M1 -.->|Property| HEALTH[Health: healthy<br/>❤️ Persisted State]
    M1 -.->|Telemetry| TEMP[Temperature: 78.2<br/>🌡️ Streaming Data]
    
    S1 -.->|Property| KIND[Kind: temperature<br/>📊 Persisted State]
    S1 -.->|Telemetry| VAL[Value: 78.2<br/>📈 Streaming Data]
    
    %% Styling
    classDef factory fill:#fff2cc,stroke:#d6b656,stroke-width:2px
    classDef line fill:#e1d5e7,stroke:#9673a6,stroke-width:2px
    classDef machine fill:#dae8fc,stroke:#6c8ebf,stroke-width:2px
    classDef sensor fill:#d5e8d4,stroke:#82b366,stroke-width:2px
    classDef property fill:#f8cecc,stroke:#b85450,stroke-width:1px,stroke-dasharray: 5 5
    classDef telemetry fill:#fff,stroke:#333,stroke-width:1px,stroke-dasharray: 2 2
    
    class F1 factory
    class L1 line
    class M1 machine
    class S1 sensor
    class OEE,HEALTH,KIND property
    class THR,TEMP,VAL telemetry
```

## 🔄 Event Processing Flow

```mermaid
flowchart LR
    subgraph Input["📥 Input Message"]
        MSG["{<br/>'lineId': 'lineA',<br/>'machineId': 'machineA',<br/>'sensorId': 'sensorA',<br/>'throughput': 120.5,<br/>'temperature': 78.2,<br/>'value': 78.2,<br/>'state': 'running',<br/>'oee': 0.84,<br/>'health': 'healthy',<br/>'ts': '2025-12-07T10:30:00Z'<br/>}"]
    end
    
    subgraph Processing["⚡ Azure Function Processing"]
        PARSE[📋 Parse Message]
        VALIDATE[✅ Validate Data]
        SPLIT[🔀 Split by Target Twin]
    end
    
    subgraph Updates["🔄 Digital Twin Updates"]
        UP1[📈 Line Updates<br/>Property: oee, state<br/>Telemetry: throughput]
        UP2[⚙️ Machine Updates<br/>Property: health<br/>Telemetry: temperature]  
        UP3[📡 Sensor Updates<br/>Telemetry: value]
    end
    
    subgraph Outputs["📤 Results"]
        TWIN1[🔗 LineA Twin<br/>Updated in ADT]
        TWIN2[🔗 MachineA Twin<br/>Updated in ADT]
        TWIN3[🔗 SensorA Twin<br/>Updated in ADT]
    end
    
    MSG --> PARSE
    PARSE --> VALIDATE
    VALIDATE --> SPLIT
    
    SPLIT --> UP1
    SPLIT --> UP2
    SPLIT --> UP3
    
    UP1 --> TWIN1
    UP2 --> TWIN2
    UP3 --> TWIN3
    
    %% Error handling
    VALIDATE -.->|❌ Invalid Data| ERR[🚨 Error Log<br/>Skip Processing]
    UP1 -.->|❌ Update Failed| ERR
    UP2 -.->|❌ Update Failed| ERR
    UP3 -.->|❌ Update Failed| ERR
```

## 🎯 Query Examples

```mermaid
graph TD
    subgraph Queries["🔍 DTDL Query Examples"]
        Q1["SELECT * FROM digitaltwins T<br/>WHERE T.$dtId = 'lineA'"]
        Q2["SELECT T.$dtId, T.oee<br/>FROM digitaltwins T<br/>WHERE IS_OF_MODEL(T, 'dtmi:mx:factory:line;1')<br/>AND T.oee < 0.7"]
        Q3["SELECT F, L, M FROM digitaltwins F<br/>JOIN L RELATED F.contains<br/>JOIN M RELATED L.contains<br/>WHERE F.$dtId = 'factory1'"]
        Q4["SELECT AVG(T.oee) as avgOEE<br/>FROM digitaltwins T<br/>WHERE IS_OF_MODEL(T, 'dtmi:mx:factory:line;1')"]
    end
    
    subgraph Results["📊 Query Results"]
        R1["🔍 Single Twin Details<br/>Properties + Metadata"]
        R2["📋 List of Underperforming Lines<br/>OEE < 0.7"]
        R3["🌐 Complete Factory Hierarchy<br/>All related twins"]
        R4["📈 Aggregated Metrics<br/>Average OEE across lines"]
    end
    
    Q1 --> R1
    Q2 --> R2
    Q3 --> R3
    Q4 --> R4
    
    %% Styling
    classDef query fill:#e1d5e7,stroke:#9673a6,stroke-width:2px,font-family:monospace
    classDef result fill:#d5e8d4,stroke:#82b366,stroke-width:2px
    
    class Q1,Q2,Q3,Q4 query
    class R1,R2,R3,R4 result
```

## 🔧 Deployment Architecture

```mermaid
graph TB
    subgraph Dev["🧪 Development Environment"]
        D1[Local Simulator]
        D2[IoT Hub Cloud]
        D3[Function Local/Cloud]
        D4[ADT Cloud]
        
        D1 --> D2
        D2 --> D3
        D3 --> D4
    end
    
    subgraph Prod["🚀 Production Environment"]
        P1[Edge Devices]
        P2[IoT Edge Gateway]
        P3[IoT Hub]
        P4[Function App]
        P5[Digital Twins]
        P6[Monitoring]
        
        P1 --> P2
        P2 --> P3
        P3 --> P4
        P4 --> P5
        P5 --> P6
    end
    
    subgraph Edge["🏭 Factory Edge"]
        E1[Physical Sensors]
        E2[Edge Runtime]
        E3[Store & Forward]
        E4[Local Processing]
        
        E1 --> E2
        E2 --> E3
        E2 --> E4
        E3 -.->|When Connected| P3
    end
    
    %% Environment promotion
    Dev -.->|🚀 Deploy| Prod
    Edge -->|📡 Telemetry| Prod
    
    %% Styling
    classDef dev fill:#e1f5fe,stroke:#0277bd,stroke-width:2px
    classDef prod fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef edge fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    
    class D1,D2,D3,D4 dev
    class P1,P2,P3,P4,P5,P6 prod
    class E1,E2,E3,E4 edge
```

---

## 📝 Cómo Usar estos Diagramas

### **1. En GitHub/GitLab**
Los diagramas se renderizan automáticamente al abrir este archivo.

### **2. En VS Code**
Instala la extensión "Markdown Preview Mermaid Support" para ver los diagramas.

### **3. En Documentación Web**
Muchas plataformas como Notion, GitBook, etc. soportan Mermaid nativamente.

### **4. Exportar como Imagen**
Usa herramientas como:
- https://mermaid.live (online)
- mermaid-cli (command line)
- VS Code extensions

### **5. Personalizar**
Modifica el código Mermaid directamente en este archivo para adaptarlo a tus necesidades.

**¡Los diagramas están listos para usar y personalizar! 📊✨**