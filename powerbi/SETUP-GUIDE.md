# Smart Factory PowerBI Dashboard - Setup Instructions

## 🎯 Dashboard Overview
Professional executive dashboard connecting directly to Cosmos DB for real-time Smart Factory analytics.

## 📋 Prerequisites
1. **PowerBI Desktop** - Download from Microsoft Store or powerbi.microsoft.com
2. **Azure Cosmos DB Access** - Read access to smartfactory-prod-cosmos
3. **Account Key** - Readonly key for secure connection

## 🚀 Step-by-Step Setup

### Step 1: Download PowerBI Desktop
```powershell
# Option 1: Microsoft Store
start ms-windows-store://pdp/?ProductId=9ntxr16hnw1t

# Option 2: Direct Download  
start https://www.microsoft.com/en-us/download/details.aspx?id=58494
```

### Step 2: Get Cosmos DB Connection Key
- **Endpoint:** `https://smartfactory-prod-cosmos.documents.azure.com:443/`
- **Database:** `smartfactory`
- **Container:** `telemetry`
- **Key Type:** Read-only (for security)

### Step 3: Connect to Cosmos DB

1. **Open PowerBI Desktop**
2. **Get Data** > **More** > **Azure** > **Azure Cosmos DB**
3. **Enter Connection Details:**
   - **Account endpoint or URL:** `https://smartfactory-prod-cosmos.documents.azure.com:443/`
   - **Database name:** `smartfactory`
4. **Authentication:**
   - **Authentication Kind:** Account key
   - **Account key:** [Use readonly key from Azure]
5. **Select Data:**
   - Choose `telemetry` container
   - Click **Transform Data** for customizations

### Step 4: Data Transformation (Power Query)

Use the provided query in `cosmos-connection.pq`:

1. **Advanced Editor** > Paste the connection script
2. **Apply transformations** for nested JSON expansion
3. **Set data types** for proper aggregations
4. **Filter date range** for performance (last 30 days)

### Step 5: Create Visualizations

#### Executive Summary Page
1. **KPI Cards:**
   - Factory Efficiency (Average)
   - Current Temperature 
   - Active Alerts Count
   - Performance Score

2. **Trend Charts:**
   - Efficiency over time (Line chart)
   - Temperature patterns (Area chart)
   - Machine performance by line (Bar chart)

3. **Gauges:**
   - Overall factory performance
   - Target vs. actual efficiency
   - SLA compliance

#### Detailed Analytics Page
1. **Machine Health Matrix**
2. **Predictive Maintenance Alerts**
3. **Production Line Comparison**
4. **Historical Trends (30 days)**

### Step 6: Configure Auto-Refresh

1. **File** > **Options and settings** > **Data source settings**
2. **Set credentials** for unattended refresh
3. **Configure refresh schedule:**
   - **Frequency:** Every 15 minutes
   - **Time range:** Business hours
   - **Email notifications:** On failure

### Step 7: Publish to PowerBI Service

1. **Publish** > **My workspace** (or designated workspace)
2. **Configure gateway** for on-premises data refresh (if needed)
3. **Set up alerts** for key metrics
4. **Share with stakeholders**

## 📊 Key Measures (DAX Formulas)

```dax
// Factory Efficiency
Factory_Efficiency = AVERAGE(Telemetry[efficiency])

// Current Temperature
Current_Temperature = 
CALCULATE(
    AVERAGE(Telemetry[temperature]),
    Telemetry[timestamp] = MAX(Telemetry[timestamp])
)

// Alert Count
Alert_Count = 
COUNTROWS(
    FILTER(Telemetry, NOT(ISBLANK(Telemetry[alerts])))
)

// Performance KPI
Performance_KPI = 
VAR CurrentPerf = AVERAGE(Telemetry[performance])
VAR Target = 0.95
RETURN 
DIVIDE(CurrentPerf, Target, 0)

// Efficiency Trend
Efficiency_Trend = 
CALCULATE(
    AVERAGE(Telemetry[efficiency]),
    DATESINPERIOD(
        Telemetry[timestamp],
        MAX(Telemetry[timestamp]),
        -24,
        HOUR
    )
)
```

## 🎨 Dashboard Design Guidelines

### Color Palette
- **Primary:** #0078D4 (Azure Blue)
- **Success:** #107C10 (Green) 
- **Warning:** #FFB900 (Yellow)
- **Danger:** #D13438 (Red)
- **Neutral:** #605E5C (Gray)

### Visual Standards
- **Cards:** Use for KPIs and single metrics
- **Line Charts:** For trends over time
- **Bar Charts:** For comparisons between categories  
- **Gauges:** For performance against targets
- **Tables:** For detailed drill-down data

### Layout Principles
- **Top Row:** Key KPIs (Factory Efficiency, Alerts, Performance)
- **Middle Section:** Trend visualizations
- **Bottom Section:** Detailed breakdowns and comparisons

## 🔧 Troubleshooting

### Connection Issues
- Verify Cosmos DB endpoint URL
- Check account key permissions (read access required)
- Ensure firewall allows PowerBI IP ranges

### Performance Optimization
- Limit data to last 30 days for initial load
- Use DirectQuery for real-time data
- Implement incremental refresh for large datasets

### Data Refresh Errors
- Check gateway connectivity
- Verify service account permissions
- Monitor Azure Cosmos DB throttling limits

## 📈 Business Value

### Executive Benefits
- **Real-time visibility** into factory operations
- **KPI tracking** against targets and SLAs
- **Predictive insights** for maintenance planning
- **Performance benchmarking** across production lines

### Operational Benefits  
- **Faster decision making** with current data
- **Proactive alerting** for critical issues
- **Trend analysis** for continuous improvement
- **Mobile access** for on-the-go monitoring

## 🎯 Success Metrics

Track dashboard adoption and value:
- **User engagement:** Daily active users
- **Response time:** Incident resolution improvement
- **Decision speed:** Time to action on alerts
- **ROI:** Efficiency improvements attributable to insights

---

## 📞 Support Resources

- **PowerBI Documentation:** https://docs.microsoft.com/en-us/power-bi/
- **Cosmos DB Connector:** https://docs.microsoft.com/en-us/power-bi/connect-data/desktop-connect-cosmosdb
- **DAX Reference:** https://docs.microsoft.com/en-us/dax/