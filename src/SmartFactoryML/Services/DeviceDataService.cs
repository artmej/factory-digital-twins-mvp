using Microsoft.Azure.Cosmos;
using SmartFactoryML.Models;
using System.Net;

namespace SmartFactoryML.Services;

public class DeviceDataService : IDeviceDataService
{
    private readonly CosmosClient _cosmosClient;
    private readonly Container _telemetryContainer;
    private readonly Container _predictionsContainer;
    private readonly Container _feedbackContainer;
    private readonly ILogger<DeviceDataService> _logger;

    public DeviceDataService(CosmosClient cosmosClient, ILogger<DeviceDataService> logger)
    {
        _cosmosClient = cosmosClient;
        _logger = logger;
        
        // Initialize containers - using configured database name
        var database = _cosmosClient.GetDatabase("SmartFactoryDB");
        _telemetryContainer = database.GetContainer("DeviceTelemetry");
        _predictionsContainer = database.GetContainer("MaintenancePredictions");
        _feedbackContainer = database.GetContainer("MaintenanceFeedback");
    }

    public async Task<DeviceTelemetry?> GetLatestTelemetryAsync(string deviceId)
    {
        try
        {
            var query = new QueryDefinition(
                "SELECT TOP 1 * FROM c WHERE c.deviceId = @deviceId ORDER BY c.timestamp DESC")
                .WithParameter("@deviceId", deviceId);

            var results = _telemetryContainer.GetItemQueryIterator<DeviceTelemetry>(query);
            
            while (results.HasMoreResults)
            {
                var response = await results.ReadNextAsync();
                return response.FirstOrDefault();
            }
            
            return null;
        }
        catch (CosmosException ex) when (ex.StatusCode == HttpStatusCode.TooManyRequests)
        {
            await Task.Delay(ex.RetryAfter ?? TimeSpan.FromSeconds(1));
            return await GetLatestTelemetryAsync(deviceId); // Retry
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get telemetry for device {DeviceId}", deviceId);
            throw;
        }
    }

    public async Task UpdatePredictionAsync(string deviceId, MaintenancePrediction prediction)
    {
        try
        {
            await _predictionsContainer.CreateItemAsync(prediction, new PartitionKey(deviceId));
            _logger.LogInformation("Updated prediction for device {DeviceId}", deviceId);
        }
        catch (CosmosException ex) when (ex.StatusCode == HttpStatusCode.TooManyRequests)
        {
            await Task.Delay(ex.RetryAfter ?? TimeSpan.FromSeconds(1));
            await UpdatePredictionAsync(deviceId, prediction); // Retry
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update prediction for device {DeviceId}", deviceId);
            throw;
        }
    }

    public async Task StoreFeedbackAsync(MaintenanceFeedback feedback)
    {
        try
        {
            await _feedbackContainer.CreateItemAsync(feedback, new PartitionKey(feedback.DeviceId));
            _logger.LogInformation("Stored feedback for device {DeviceId}", feedback.DeviceId);
        }
        catch (CosmosException ex) when (ex.StatusCode == HttpStatusCode.TooManyRequests)
        {
            await Task.Delay(ex.RetryAfter ?? TimeSpan.FromSeconds(1));
            await StoreFeedbackAsync(feedback); // Retry
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to store feedback for device {DeviceId}", feedback.DeviceId);
            throw;
        }
    }
}