using SmartFactoryML.Models;

namespace SmartFactoryML.Services;

public interface IDigitalTwinService
{
    Task UpdateTwinAsync(string deviceId, MaintenancePrediction prediction);
    Task UpdateFeedbackAsync(string deviceId, MaintenanceFeedback feedback);
}