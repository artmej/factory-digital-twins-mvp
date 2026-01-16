# GitHub Copilot Instructions - Smart Factory Integration

## Project Context
This is an **Azure Smart Factory Integration Project** in **INTEGRATION PHASE**. All code generation must follow production-ready patterns with real Azure services.

⚠️ **CRITICAL VALIDATION REQUIREMENT:**
- **NO MOCK DATA ALLOWED** - Any mock data will cause validation failures
- **NO FAKE APIs** - Only real Azure service endpoints permitted  
- **NO HARDCODED VALUES** - All data must come from Azure services
- **NO SIMULATION MODE** - Production integration phase requires real connections

## Code Generation Rules

### 🌐 UI AND DOCUMENTATION LANGUAGE
- ✅ **REQUIRED:** All UI text, labels, and user-facing content MUST be in **English**
- ✅ **REQUIRED:** Dashboard titles, buttons, metrics, and status messages in English only
- ✅ **REQUIRED:** Error messages, tooltips, and help text in English
- ✅ **REQUIRED:** API response messages and field names in English
- ❌ **FORBIDDEN:** Spanish, Portuguese, or any non-English text in user interfaces

### 🚫 FORBIDDEN CODE PATTERNS - WILL CAUSE VALIDATION FAILURES
```typescript
// ❌ NEVER generate mock data - VALIDATION FAILURE
const mockData = { temperature: 25, pressure: 100 };
const machines = [{id: 'fake', status: 'online'}]; // ❌ FORBIDDEN

// ❌ NEVER use fake APIs - VALIDATION FAILURE  
const fakeApiUrl = 'http://localhost:3000/fake-ml';
const mockEndpoint = 'https://example.com/fake'; // ❌ FORBIDDEN

// ❌ NEVER use hardcoded arrays - VALIDATION FAILURE
const hardcodedPredictions = [
    {machine: 'LINE_1', days: 3, confidence: 87} // ❌ FORBIDDEN
];

// ❌ NEVER use connection strings in code
const connectionString = 'Server=...;Database=...';
```

⚠️ **ANY MOCK DATA USAGE WILL CAUSE INTEGRATION VALIDATION TO FAIL**

### ✅ REQUIRED CODE PATTERNS

#### Azure Authentication - Always Use Managed Identity
```csharp
// ✅ Correct authentication pattern
var credential = new DefaultAzureCredential();
var cosmosClient = new CosmosClient(cosmosEndpoint, credential);
```

```typescript
// ✅ Correct authentication pattern
const credential = new DefaultAzureCredential();
const dtClient = new DigitalTwinsClient(dtEndpoint, credential);
```

#### ML API Integration - Only Real Models
```csharp
// ✅ Correct ML API pattern
[HttpGet]
public async Task<IActionResult> GetMaintenance([FromQuery] string deviceId, [FromQuery] bool real = true)
{
    if (!real) return BadRequest("Only real ML models allowed in integration phase");

    // Use actual ML Studio trained model weights
    var weights = new { temperature = 0.234, vibration = 0.456, pressure = -0.123 };
    // ... actual prediction logic
}
```

### Factory Configuration - Always Use Real Device IDs
```typescript
// ✅ Correct device configuration
const FACTORY_DEVICES = [
    'LINE_1_CNC_01', 'LINE_1_ROBOT_01', 'LINE_1_CONV_01',
    'LINE_2_CNC_02', 'LINE_2_ROBOT_02', 'LINE_2_CONV_02',
    'LINE_3_CNC_03', 'LINE_3_ROBOT_03', 'LINE_3_CONV_03'
];
```

#### Authentication Requirements
```typescript
// ✅ Always implement Microsoft Authentication
const msalConfig = {
    auth: {
        clientId: "valid-app-id",
        authority: "https://login.microsoftonline.com/common"
    }
};
// Force login on application start
async function initializeAuth() {
    const accounts = msalInstance.getAllAccounts();
    if (accounts.length === 0) {
        await msalInstance.loginPopup();
    }
}
```

## Data Flow Architecture

When generating code, always follow this flow:
```
IoT Hub → Event Hub → Logic App → [Cosmos DB + Digital Twins]
                                        ↕️
Dashboard ← ML APIs ← [Cosmos DB + Digital Twins]
```

## Specific Implementation Requirements

### Logic Apps
- Always use Managed Identity connectors
- Include error handling and retry logic
- Write to both Cosmos DB AND Digital Twins in parallel

### ML APIs
- Must include feedback loop to update Cosmos DB and Digital Twins
- Confidence levels must be realistic (65-95%, never 100%)
- Always validate deviceId against known factory devices

### Cosmos DB Operations
```csharp
// ✅ Always include partition key
await container.CreateItemAsync(item, new PartitionKey(deviceId));

// ✅ Always use async patterns
var response = await container.ReadItemAsync<DeviceData>(id, new PartitionKey(deviceId));
```

### Digital Twins Operations
```csharp
// ✅ Always update twin properties after ML predictions
var patch = new JsonPatchDocument();
patch.AppendReplace("/MaintenancePrediction", predictionResult);
patch.AppendReplace("/LastUpdated", DateTime.UtcNow);
await dtClient.UpdateDigitalTwinAsync(twinId, patch);
```

### Error Handling Patterns
```csharp
// ✅ Always include proper error handling
try
{
    var result = await mlService.PredictMaintenanceAsync(deviceData);
    await cosmosService.UpdatePredictionAsync(deviceId, result);
    await digitalTwinService.UpdateTwinAsync(deviceId, result);
    return Ok(result);
}
catch (CosmosException ex) when (ex.StatusCode == HttpStatusCode.TooManyRequests)
{
    await Task.Delay(ex.RetryAfter ?? TimeSpan.FromSeconds(1));
    // Retry logic
}
catch (Exception ex)
{
    logger.LogError(ex, "Prediction failed for device {DeviceId}", deviceId);
    return StatusCode(500, "Prediction service temporarily unavailable");
}
```

## Network & Security Requirements

### VNet Configuration
- All services must communicate through VNet
- Use Service Endpoints for PaaS services
- No public internet communication between Azure services

### RBAC Roles Required
```json
{
  "LogicApp_ManagedIdentity": [
    "Event Hubs Data Receiver",
    "Cosmos DB Data Contributor",
    "Digital Twins Data Owner"
  ],
  "MLApi_ManagedIdentity": [
    "Cosmos DB Data Contributor",
    "Digital Twins Data Owner"
  ]
}
```

## Testing Patterns

### Always Generate Proper Tests
```csharp
[Test]
public async Task PredictMaintenance_WithRealDevice_ReturnsValidPrediction()
{
    // Arrange - use real device IDs
    var deviceId = "LINE_1_CNC_01";
    var telemetry = new DeviceTelemetry { Temperature = 72, Vibration = 0.5 };

    // Act
    var result = await mlService.PredictMaintenanceAsync(deviceId, telemetry, real: true);

    // Assert - validate realistic confidence
    Assert.That(result.Confidence, Is.InRange(0.65, 0.95));
    Assert.That(result.DeviceId, Is.EqualTo(deviceId));
}
```

## File Structure Patterns

### Project Organization
```
/SmartFactoryML/          # C# ML APIs
/src/logicapps/          # Logic App definitions
/src/digitaltwins/       # Digital Twin models
/docs/                   # Documentation and dashboards
/.github/                # GitHub configuration
```

### GitHub Pages Deployment
- ✅ **REQUIRED:** All dashboard files must be in `/docs/` folder
- ✅ **REQUIRED:** Dashboards deployed automatically to GitHub Pages
- ✅ **REQUIRED:** Use GitHub Pages URLs for live demo links
- ✅ **REQUIRED:** Test dashboards on GitHub Pages after deployment
- 🔗 **Live URL Pattern:** `https://username.github.io/repo-name/dashboard-name.html`

## Integration Testing Requirements

When generating test code, always validate:
1. End-to-end data flow from IoT to storage
2. ML model accuracy with real data
3. Feedback loops updating both Cosmos DB and Digital Twins
4. Managed Identity authentication
5. VNet connectivity between services

## Performance & Monitoring

Always include:
- Application Insights telemetry
- Health check endpoints
- Retry policies with exponential backoff
- Circuit breaker patterns for external dependencies

---

**CRITICAL:** This project is in integration phase. Generate only production-ready, secure code that follows Azure best practices and uses real services.