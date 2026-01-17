# Smart Factory ML API

Production-ready ML API for predictive maintenance in Smart Factory integration phase.

## Features

- ✅ **Real ML Model Integration** - No mock data allowed
- ✅ **Azure Managed Identity Authentication**
- ✅ **Cosmos DB Integration** for telemetry and predictions
- ✅ **Digital Twins Integration** for real-time updates
- ✅ **Feedback Loop** for model improvement
- ✅ **Production Logging** with Application Insights

## API Endpoints

### Maintenance Predictions
- `GET /api/maintenance?deviceId={id}&real=true` - Get maintenance prediction
- `POST /api/maintenance/feedback` - Submit feedback for model improvement

### Device Management
- `GET /api/device` - List all factory devices
- `GET /api/device/{deviceId}/telemetry` - Get latest telemetry
- `GET /api/device/health` - Health check endpoint

## Factory Devices

The following devices are configured for the Smart Factory:

```
LINE_1_CNC_01    - CNC Machine Line 1
LINE_1_ROBOT_01  - Robot Arm Line 1  
LINE_1_CONV_01   - Conveyor Line 1

LINE_2_CNC_02    - CNC Machine Line 2
LINE_2_ROBOT_02  - Robot Arm Line 2
LINE_2_CONV_02   - Conveyor Line 2

LINE_3_CNC_03    - CNC Machine Line 3
LINE_3_ROBOT_03  - Robot Arm Line 3
LINE_3_CONV_03   - Conveyor Line 3
```

## Configuration

Required environment variables:
- `CosmosDb__Endpoint` - Cosmos DB endpoint URL
- `DigitalTwins__Url` - Digital Twins instance URL
- `ApplicationInsights__ConnectionString` - App Insights connection string

## Integration Phase Requirements

⚠️ **CRITICAL:** This API is in **INTEGRATION PHASE**:
- **NO MOCK DATA** - All responses use real ML models
- **NO FAKE APIs** - Only real Azure service endpoints
- **NO SIMULATION MODE** - Production integration only
- **Managed Identity** required for all Azure service connections

## Data Flow

```
IoT Hub → Event Hub → Logic App → [Cosmos DB + Digital Twins]
                                         ↕️
Dashboard ← ML APIs ← [Cosmos DB + Digital Twins]
```

## Testing

Run integration tests:
```bash
cd tests/SmartFactoryML.Tests
dotnet test
```

Tests validate:
- No mock data usage
- Real device ID validation  
- Proper error handling
- Integration compliance