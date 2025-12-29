# PowerBI Configuration for Smart Factory

## Cosmos DB Connection Details

**Account Name:** smartfactory-prod-cosmos
**Endpoint:** https://smartfactory-prod-cosmos.documents.azure.com:443/
**Database:** smartfactory
**Container:** telemetry
**Key Type:** Read-only

## PowerBI Data Sources

### 1. Factory Performance Metrics
- **Source:** telemetry container
- **Query:** 
```sql
SELECT 
    c.factoryId,
    c.timestamp,
    c.data.efficiency,
    c.data.performance,
    c.data.temperature,
    c.data.alerts
FROM c 
WHERE c.timestamp >= DateTimeAdd('hour', -24, GetCurrentDateTime())
```

### 2. Machine Status Dashboard
- **Source:** telemetry container  
- **Query:**
```sql
SELECT 
    c.machineId,
    c.data.status,
    c.data.temperature,
    c.data.efficiency,
    c.timestamp
FROM c 
WHERE c.deviceType = 'machine'
ORDER BY c.timestamp DESC
```

### 3. Production Line Performance
- **Source:** telemetry container
- **Query:**
```sql
SELECT 
    c.lineId,
    AVG(c.data.efficiency) as avg_efficiency,
    COUNT(1) as record_count,
    MAX(c.timestamp) as last_update
FROM c 
WHERE c.deviceType = 'production-line'
GROUP BY c.lineId
```

## Setup Instructions

### Step 1: Open PowerBI Desktop
1. Download and install PowerBI Desktop
2. Open PowerBI Desktop
3. Click "Get Data" > "More"

### Step 2: Connect to Cosmos DB
1. Search for "Azure Cosmos DB"
2. Enter connection details:
   - **Account endpoint:** https://smartfactory-prod-cosmos.documents.azure.com:443/
   - **Database:** smartfactory
   - **Authentication:** Account key
   - **Account key:** [Use readonly key from Azure]

### Step 3: Import Data
1. Select "telemetry" container
2. Choose "DirectQuery" for real-time data
3. Apply transformations as needed

### Step 4: Create Visualizations
1. **Factory Efficiency Chart** - Time series line chart
2. **Machine Temperature Heatmap** - Matrix visualization
3. **Alert Status Cards** - Card visualizations
4. **Production KPIs** - Gauge charts

### Step 5: Set Up Auto-Refresh
1. Go to "Transform data" > "Data source settings"
2. Set refresh interval to 15 minutes
3. Configure credentials for unattended refresh

## Sample Measures (DAX)

```dax
Factory Efficiency = 
AVERAGE(telemetry[data.efficiency])

Current Temperature = 
CALCULATE(
    AVERAGE(telemetry[data.temperature]),
    telemetry[timestamp] = MAX(telemetry[timestamp])
)

Alert Count = 
COUNTROWS(
    FILTER(telemetry, telemetry[data.alerts] <> BLANK())
)
```

## Dashboard Layout Recommendations

### Executive Summary Page
- Factory efficiency trend (last 24h)
- Current machine status grid
- Alert summary cards
- Production targets vs actual

### Detailed Analytics Page  
- Machine performance by hour
- Temperature patterns
- Efficiency correlation analysis
- Historical trends

### Maintenance Dashboard
- Machine health indicators
- Predictive maintenance alerts
- Downtime analysis
- Maintenance schedule integration