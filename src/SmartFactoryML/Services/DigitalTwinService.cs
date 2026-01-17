using Azure.DigitalTwins.Core;
using SmartFactoryML.Models;
using System.Text.Json;

namespace SmartFactoryML.Services;

public class DigitalTwinService : IDigitalTwinService
{
    private readonly DigitalTwinsClient _dtClient;
    private readonly ILogger<DigitalTwinService> _logger;

    public DigitalTwinService(DigitalTwinsClient dtClient, ILogger<DigitalTwinService> logger)
    {
        _dtClient = dtClient;
        _logger = logger;
    }

    public async Task UpdateTwinAsync(string deviceId, MaintenancePrediction prediction)
    {
        try
        {
            var twinId = $"factory-{deviceId.ToLower()}";
            
            var patch = new JsonPatchDocument();
            patch.AppendReplace("/MaintenancePrediction", JsonSerializer.Serialize(prediction));
            patch.AppendReplace("/LastPredictionUpdate", DateTime.UtcNow);
            patch.AppendReplace("/DaysUntilMaintenance", prediction.DaysUntilMaintenance);
            patch.AppendReplace("/RiskLevel", prediction.RiskLevel);
            patch.AppendReplace("/Confidence", prediction.Confidence);
            
            await _dtClient.UpdateDigitalTwinAsync(twinId, patch);
            _logger.LogInformation("Updated digital twin {TwinId} with prediction", twinId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update digital twin for device {DeviceId}", deviceId);
            throw;
        }
    }

    public async Task UpdateFeedbackAsync(string deviceId, MaintenanceFeedback feedback)
    {
        try
        {
            var twinId = $"factory-{deviceId.ToLower()}";
            
            var patch = new JsonPatchDocument();
            patch.AppendReplace("/LastFeedback", JsonSerializer.Serialize(feedback));
            patch.AppendReplace("/LastFeedbackUpdate", DateTime.UtcNow);
            patch.AppendReplace("/FeedbackRating", feedback.Rating);
            
            await _dtClient.UpdateDigitalTwinAsync(twinId, patch);
            _logger.LogInformation("Updated digital twin {TwinId} with feedback", twinId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update digital twin feedback for device {DeviceId}", deviceId);
            throw;
        }
    }
}