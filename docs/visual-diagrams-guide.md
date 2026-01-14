# Factory Digital Twins - Visual Diagrams

Esta carpeta contiene diagramas visuales de la arquitectura que puedes modificar y personalizar.

## 🎨 Archivos de Diagramas Disponibles

### 1. **DrawIO (Recomendado para edición)**
📁 `factory-digital-twins-architecture.drawio`
- **Editar online**: https://app.diagrams.net
- **Editar offline**: Descargar DrawIO Desktop
- **Formato**: XML editable con elementos interactivos

### 2. **Mermaid (Para documentación)**
📁 `mermaid-diagrams.md`  
- **Renderiza en**: GitHub, GitLab, VS Code, Notion
- **Formato**: Markdown con sintaxis Mermaid

### 3. **PlantUML (Para desarrolladores)**
📁 `plantuml-diagrams.puml`
- **Renderiza con**: PlantUML server, VS Code extension
- **Formato**: Texto plano con sintaxis UML

## 🎯 Cómo Usar Draw.io

### **Opción 1: Online (Más fácil)**
1. Ve a https://app.diagrams.net
2. Haz clic en "Open Existing Diagram"
3. Selecciona el archivo `factory-digital-twins-architecture.drawio`
4. ¡Edita directamente en el navegador!

### **Opción 2: Offline**
1. Descarga Draw.io Desktop desde https://github.com/jgraph/drawio-desktop/releases
2. Abre el archivo `.drawio` con la aplicación
3. Edita localmente

### **Opción 3: VS Code**
1. Instala la extensión "Draw.io Integration"
2. Abre el archivo `.drawio` directamente en VS Code
3. Edita dentro del editor

## 🔧 Elementos del Diagrama

### **Componentes Principales**
| Elemento | Color | Descripción |
|----------|-------|-------------|
| 🏭 Physical Assets | 🟨 Amarillo | Sensores, máquinas, líneas físicas |
| 🔧 Edge Computing | 🟧 Naranja | IoT Edge runtime y módulos |
| ☁️ Azure Services | 🟦 Azul | IoT Hub, Function App |
| ⚡ Processing | 🟪 Morado | Azure Functions, event processing |
| 🔗 Digital Twins | 🟥 Rojo | DTDL models, twin instances |
| 📊 Visualization | 🟩 Verde | ADT Explorer, Power BI |

### **Tipos de Conexión**
- **Líneas sólidas** (━━━): Flujo de datos en tiempo real
- **Líneas punteadas** (┅┅┅): Componentes opcionales
- **Flechas gruesas**: Flujo principal de datos
- **Flechas delgadas**: Flujos secundarios o de configuración

## 🎨 Personalización Sugerida

### **Para tu Empresa**
```xml
<!-- Cambiar colores corporativos -->
<mxCell fillColor="#TU_COLOR_PRINCIPAL" strokeColor="#TU_COLOR_SECUNDARIO">

<!-- Agregar tu logo -->
<mxCell value="🏢 TU_EMPRESA Factory" style="...">

<!-- Modificar nombres de componentes -->
<mxCell value="🏭 TU_FABRICA_NOMBRE">
```

### **Para Diferentes Industrias**
- **Automotriz**: 🚗 Assembly Line, 🔧 Robot Welding, ⚙️ Paint Booth
- **Alimentaria**: 🍕 Production Line, 🌡️ Cold Chain, 📦 Packaging
- **Farmacéutica**: 💊 Clean Room, 🧪 Quality Control, 📋 Batch Tracking
- **Energía**: ⚡ Power Plant, 🔋 Battery Storage, 📊 Grid Management

### **Agregar Nuevos Componentes**
```xml
<!-- Nuevo servicio Azure -->
<mxCell id="nuevo-servicio" value="🤖 Azure ML&#xa;Predictive Maintenance" 
       style="rounded=1;fillColor=#e1d5e7;strokeColor=#9673a6;" 
       vertex="1" parent="processing-layer">
  <mxGeometry x="20" y="200" width="160" height="60" as="geometry" />
</mxCell>

<!-- Nueva conexión -->
<mxCell style="strokeWidth=2;strokeColor=#9673a6;" 
       edge="1" parent="1" source="twin-instances" target="nuevo-servicio">
</mxCell>
```

## 📱 Otros Formatos Disponibles

### **Export Options desde Draw.io**
- **PNG/JPG**: Para presentaciones y documentos
- **SVG**: Para web y documentación técnica  
- **PDF**: Para reportes y documentación formal
- **XML**: Para backup y versionado
- **VSDX**: Para Microsoft Visio

### **Integración con Documentación**
```markdown
<!-- En README.md -->
![Architecture](docs/architecture-diagram.png)

<!-- En wiki corporativo -->
<img src="factory-architecture.svg" alt="Factory Architecture" width="800">
```

## 🔄 Mantenimiento del Diagrama

### **Versionado**
```bash
# Crear versiones por fecha
factory-digital-twins-architecture-v1.0-2025-12-07.drawio
factory-digital-twins-architecture-v1.1-2025-12-15.drawio

# O por feature
factory-digital-twins-basic.drawio
factory-digital-twins-with-ml.drawio
factory-digital-twins-multi-tenant.drawio
```

### **Sincronización con Código**
1. **CI/CD Integration**: Auto-generar diagramas desde código
2. **Documentation as Code**: Mantener diagramas en el repositorio
3. **Review Process**: Incluir diagramas en code reviews

## 🎯 Casos de Uso del Diagrama

### **Para Stakeholders**
- **Ejecutivos**: Vista de alto nivel del ROI y capacidades
- **Arquitectos**: Detalles técnicos y dependencias
- **Desarrolladores**: Flujos de datos y APIs
- **Operaciones**: Monitoreo y troubleshooting

### **Para Presentaciones**
- **Sales Pitches**: Mostrar capacidades de IoT y Digital Twins
- **Technical Reviews**: Validar arquitectura con el equipo
- **Training Sessions**: Enseñar la solución a nuevos miembros
- **Customer Demos**: Explicar el valor del Digital Twin

### **Para Documentación**
- **Architecture Decision Records (ADR)**
- **System Design Documents**
- **Onboarding Materials**
- **Troubleshooting Guides**

---

## 🚀 Quick Start para Editar

```bash
# 1. Abrir Draw.io online
start https://app.diagrams.net

# 2. Cargar el archivo
# File > Open from > Computer > Seleccionar factory-digital-twins-architecture.drawio

# 3. Personalizar
# - Doble clic en texto para editar
# - Clic derecho para cambiar colores/estilos
# - Arrastra para reorganizar elementos

# 4. Exportar
# File > Export as > PNG/SVG/PDF
```

**¡El diagrama está listo para personalizar según tus necesidades! 🎨✨**