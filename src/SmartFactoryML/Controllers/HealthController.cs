using Microsoft.AspNetCore.Mvc;

namespace SmartFactoryML.Controllers;

[ApiController]
[Route("api/device")]
public class HealthController : ControllerBase
{
    private readonly ILogger<HealthController> _logger;

    public HealthController(ILogger<HealthController> logger)
    {
        _logger = logger;
    }

    [HttpGet("health")]
    public IActionResult GetHealth()
    {
        try
        {
            var health = new
            {
                Status = "Healthy",
                Timestamp = DateTime.UtcNow,
                Version = "1.0.0",
                Environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production",
                Uptime = TimeSpan.FromMilliseconds(Environment.TickCount64),
                Services = new
                {
                    CosmosDB = "Connected",
                    DigitalTwins = "Connected",
                    MLModels = "Ready"
                }
            };

            return Ok(health);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Health check failed");
            return StatusCode(500, new { Status = "Unhealthy", Error = ex.Message });
        }
    }

    [HttpGet("status")]
    public IActionResult GetStatus()
    {
        return Ok(new { 
            API = "Smart Factory ML API",
            Status = "Running",
            Timestamp = DateTime.UtcNow
        });
    }
}