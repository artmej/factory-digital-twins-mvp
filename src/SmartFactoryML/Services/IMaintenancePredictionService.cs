using SmartFactoryML.Models;

namespace SmartFactoryML.Services;

public interface IMaintenancePredictionService
{
    Task<MaintenancePrediction> PredictMaintenanceAsync(string deviceId, DeviceTelemetry telemetry);
}