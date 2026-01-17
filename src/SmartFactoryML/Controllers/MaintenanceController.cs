using Microsoft.AspNetCore.Mvc;
using SmartFactoryML.Models;
using SmartFactoryML.Services;

namespace SmartFactoryML.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MaintenanceController : ControllerBase
{
    private readonly IMaintenancePredictionService _predictionService;
    private readonly IDeviceDataService _deviceDataService;
    private readonly IDigitalTwinService _digitalTwinService;
    private readonly ILogger<MaintenanceController> _logger;

    // Known factory devices - per integration requirements
    private static readonly string[] FACTORY_DEVICES = 
    [
        "LINE_1_CNC_01", "LINE_1_ROBOT_01", "LINE_1_CONV_01",
        "LINE_2_CNC_02", "LINE_2_ROBOT_02", "LINE_2_CONV_02",
        "LINE_3_CNC_03", "LINE_3_ROBOT_03", "LINE_3_CONV_03"
    ];

    public MaintenanceController(
        IMaintenancePredictionService predictionService,
        IDeviceDataService deviceDataService,
        IDigitalTwinService digitalTwinService,
        ILogger<MaintenanceController> logger)
    {
        _predictionService = predictionService;
        _deviceDataService = deviceDataService;
        _digitalTwinService = digitalTwinService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> GetMaintenance([FromQuery] string deviceId, [FromQuery] bool real = true)
    {
        if (!real)
            return BadRequest("Only real ML models allowed in integration phase");

        if (string.IsNullOrEmpty(deviceId) || !FACTORY_DEVICES.Contains(deviceId))
            return BadRequest($"Invalid deviceId. Must be one of: {string.Join(", ", FACTORY_DEVICES)}");

        try
        {
            // Get latest device telemetry from Cosmos DB
            var deviceData = await _deviceDataService.GetLatestTelemetryAsync(deviceId);
            if (deviceData == null)
                return NotFound($"No telemetry data found for device {deviceId}");

            // Generate ML prediction using real model weights
            var prediction = await _predictionService.PredictMaintenanceAsync(deviceId, deviceData);

            // Update both Cosmos DB and Digital Twins with prediction
            await _deviceDataService.UpdatePredictionAsync(deviceId, prediction);
            await _digitalTwinService.UpdateTwinAsync(deviceId, prediction);

            _logger.LogInformation("Maintenance prediction completed for device {DeviceId}", deviceId);
            
            return Ok(prediction);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Prediction failed for device {DeviceId}", deviceId);
            return StatusCode(500, "Prediction service temporarily unavailable");
        }
    }

    [HttpPost("feedback")]
    public async Task<IActionResult> PostFeedback([FromBody] MaintenanceFeedback feedback)
    {
        if (feedback == null || string.IsNullOrEmpty(feedback.DeviceId))
            return BadRequest("Invalid feedback data");

        if (!FACTORY_DEVICES.Contains(feedback.DeviceId))
            return BadRequest($"Invalid deviceId. Must be one of: {string.Join(", ", FACTORY_DEVICES)}");

        try
        {
            // Store feedback for model improvement
            await _deviceDataService.StoreFeedbackAsync(feedback);
            
            // Update digital twin with feedback
            await _digitalTwinService.UpdateFeedbackAsync(feedback.DeviceId, feedback);

            _logger.LogInformation("Feedback stored for device {DeviceId}", feedback.DeviceId);
            
            return Ok(new { success = true, message = "Feedback stored successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to store feedback for device {DeviceId}", feedback.DeviceId);
            return StatusCode(500, "Failed to store feedback");
        }
    }
}