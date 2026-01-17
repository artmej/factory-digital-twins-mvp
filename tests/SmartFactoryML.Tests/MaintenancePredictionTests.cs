using NUnit.Framework;
using Microsoft.Extensions.Logging;
using Moq;
using SmartFactoryML.Services;
using SmartFactoryML.Models;

namespace SmartFactoryML.Tests;

[TestFixture]
public class MaintenancePredictionTests
{
    private MaintenancePredictionService _service;
    private Mock<ILogger<MaintenancePredictionService>> _mockLogger;

    [SetUp]
    public void Setup()
    {
        _mockLogger = new Mock<ILogger<MaintenancePredictionService>>();
        _service = new MaintenancePredictionService(_mockLogger.Object);
    }

    [Test]
    public async Task PredictMaintenance_WithRealDevice_ReturnsValidPrediction()
    {
        // Arrange - use real device IDs
        var deviceId = "LINE_1_CNC_01";
        var telemetry = new DeviceTelemetry 
        { 
            DeviceId = deviceId,
            Temperature = 72, 
            Vibration = 0.5,
            Pressure = 85,
            Power = 87
        };

        // Act
        var result = await _service.PredictMaintenanceAsync(deviceId, telemetry);

        // Assert - validate realistic confidence and no mock data
        Assert.That(result, Is.Not.Null);
        Assert.That(result.DeviceId, Is.EqualTo(deviceId));
        Assert.That(result.Confidence, Is.InRange(0.65, 0.95));
        Assert.That(result.DaysUntilMaintenance, Is.InRange(5, 30));
        Assert.That(result.RiskLevel, Is.Not.Empty);
        Assert.That(result.MaintenanceReasons, Is.Not.Empty);
        Assert.That(result.FeatureImportance, Is.Not.Empty);
    }

    [Test]
    public async Task PredictMaintenance_WithHighTemperature_ReturnsHighRisk()
    {
        // Arrange
        var deviceId = "LINE_2_CNC_02";
        var telemetry = new DeviceTelemetry 
        { 
            DeviceId = deviceId,
            Temperature = 95, // High temperature
            Vibration = 0.3,
            Pressure = 80,
            Power = 85
        };

        // Act
        var result = await _service.PredictMaintenanceAsync(deviceId, telemetry);

        // Assert
        Assert.That(result.MaintenanceReasons, Does.Contain("High temperature detected"));
        Assert.That(result.DaysUntilMaintenance, Is.LessThan(20));
    }

    [Test]
    public async Task PredictMaintenance_WithExcessiveVibration_ReturnsVibrationWarning()
    {
        // Arrange
        var deviceId = "LINE_3_ROBOT_03";
        var telemetry = new DeviceTelemetry 
        { 
            DeviceId = deviceId,
            Temperature = 70,
            Vibration = 0.9, // Excessive vibration
            Pressure = 80,
            Power = 85
        };

        // Act
        var result = await _service.PredictMaintenanceAsync(deviceId, telemetry);

        // Assert
        Assert.That(result.MaintenanceReasons, Does.Contain("Excessive vibration"));
    }

    [TestCase("LINE_1_CNC_01")]
    [TestCase("LINE_2_ROBOT_02")]
    [TestCase("LINE_3_CONV_03")]
    public async Task PredictMaintenance_WithValidDevices_ReturnsConsistentResults(string deviceId)
    {
        // Arrange
        var telemetry = new DeviceTelemetry 
        { 
            DeviceId = deviceId,
            Temperature = 75,
            Vibration = 0.6,
            Pressure = 82,
            Power = 88
        };

        // Act
        var result = await _service.PredictMaintenanceAsync(deviceId, telemetry);

        // Assert - ensure no mock data patterns
        Assert.That(result.DeviceId, Is.EqualTo(deviceId));
        Assert.That(result.Confidence, Is.Not.EqualTo(0.87), "Should not use hardcoded mock confidence");
        Assert.That(result.DaysUntilMaintenance, Is.Not.EqualTo(3), "Should not use hardcoded mock days");
    }
}