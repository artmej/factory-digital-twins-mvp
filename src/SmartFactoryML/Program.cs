using Azure.DigitalTwins.Core;
using Azure.Identity;
using Microsoft.Azure.Cosmos;
using SmartFactoryML.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add Azure services
var cosmosEndpoint = builder.Configuration["CosmosDb:Endpoint"] ?? throw new ArgumentNullException("CosmosDb:Endpoint");
var digitalTwinsUrl = builder.Configuration["DigitalTwins:Url"] ?? throw new ArgumentNullException("DigitalTwins:Url");

// Use Managed Identity for authentication
var credential = new DefaultAzureCredential();

builder.Services.AddSingleton<CosmosClient>(provider => 
    new CosmosClient(cosmosEndpoint, credential));

builder.Services.AddSingleton<DigitalTwinsClient>(provider => 
    new DigitalTwinsClient(new Uri(digitalTwinsUrl), credential));

// Register services
builder.Services.AddScoped<IMaintenancePredictionService, MaintenancePredictionService>();
builder.Services.AddScoped<IDeviceDataService, DeviceDataService>();
builder.Services.AddScoped<IDigitalTwinService, DigitalTwinService>();

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("https://*.github.io", "https://localhost:*")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// Add Application Insights
builder.Services.AddApplicationInsightsTelemetry();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors();
app.UseAuthorization();
app.MapControllers();

app.Run();