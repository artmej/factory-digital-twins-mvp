using SmartFactoryML.Models;

namespace SmartFactoryML.Services;

public interface IDeviceDataService
{
    Task<DeviceTelemetry?> GetLatestTelemetryAsync(string deviceId);
    Task UpdatePredictionAsync(string deviceId, MaintenancePrediction prediction);
    Task StoreFeedbackAsync(MaintenanceFeedback feedback);
}