# PowerBI Connection Script for Smart Factory (Managed Identity)
# Execute this in PowerBI Desktop's Advanced Editor

let
    // Cosmos DB Connection Details
    cosmosEndpoint = "https://smartfactory-prod-cosmos.documents.azure.com:443/",
    databaseName = "smartfactory",
    containerName = "telemetry",
    
    // Connect to Cosmos DB using Managed Identity (Secure)
    cosmosDb = AzureCosmosDB.Database(cosmosEndpoint, databaseName, [AuthenticationKind="ManagedServiceIdentity"]),
    telemetryContainer = cosmosDb{[Name=containerName]}[Data],
    
    // Expand nested data structure
    #"Expanded Document" = Table.ExpandRecordColumn(telemetryContainer, "Document", 
        {"id", "deviceId", "deviceType", "timestamp", "factoryId", "lineId", "machineId", "data"}, 
        {"id", "deviceId", "deviceType", "timestamp", "factoryId", "lineId", "machineId", "data"}),
    
    // Expand the 'data' field which contains metrics
    #"Expanded Data" = Table.ExpandRecordColumn(#"Expanded Document", "data", 
        {"temperature", "pressure", "vibration", "efficiency", "performance", "status", "alerts"}, 
        {"temperature", "pressure", "vibration", "efficiency", "performance", "status", "alerts"}),
    
    // Convert timestamp to datetime
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded Data", {
        {"timestamp", type datetimezone},
        {"temperature", type number},
        {"pressure", type number}, 
        {"vibration", type number},
        {"efficiency", type number},
        {"performance", type number}
    }),
    
    // Filter last 30 days for performance
    #"Filtered Rows" = Table.SelectRows(#"Changed Type", each [timestamp] >= DateTime.AddDays(DateTime.LocalNow(), -30))

in
    #"Filtered Rows"