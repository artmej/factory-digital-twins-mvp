using Microsoft.AspNetCore.Mvc;
using SmartFactoryML.Models;
using SmartFactoryML.Services;

namespace SmartFactoryML.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DeviceController : ControllerBase
{
    private readonly IDeviceDataService _deviceDataService;
    private readonly ILogger<DeviceController> _logger;

    // Known factory devices - per integration requirements
    private static readonly string[] FACTORY_DEVICES = 
    [
        "LINE_1_CNC_01", "LINE_1_ROBOT_01", "LINE_1_CONV_01",
        "LINE_2_CNC_02", "LINE_2_ROBOT_02", "LINE_2_CONV_02",
        "LINE_3_CNC_03", "LINE_3_ROBOT_03", "LINE_3_CONV_03"
    ];

    public DeviceController(
        IDeviceDataService deviceDataService,
        ILogger<DeviceController> logger)
    {
        _deviceDataService = deviceDataService;
        _logger = logger;
    }

    [HttpGet]
    public IActionResult GetDevices()
    {
        var devices = FACTORY_DEVICES.Select(d => new 
        {
            DeviceId = d,
            Line = d.Split('_')[1],
            Type = d.Split('_')[2],
            Number = d.Split('_')[3]
        });

        return Ok(devices);
    }

    [HttpGet("{deviceId}/telemetry")]
    public async Task<IActionResult> GetDeviceTelemetry(string deviceId)
    {
        if (!FACTORY_DEVICES.Contains(deviceId))
            return BadRequest($"Invalid deviceId. Must be one of: {string.Join(", ", FACTORY_DEVICES)}");

        try
        {
            var telemetry = await _deviceDataService.GetLatestTelemetryAsync(deviceId);
            if (telemetry == null)
                return NotFound($"No telemetry data found for device {deviceId}");

            return Ok(telemetry);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get telemetry for device {DeviceId}", deviceId);
            return StatusCode(500, "Failed to retrieve telemetry data");
        }
    }
}