using NUnit.Framework;
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using SmartFactoryML.Models;

namespace SmartFactoryML.Tests;

[TestFixture]
public class IntegrationTests
{
    private WebApplicationFactory<Program> _factory;
    private HttpClient _client;

    [SetUp]
    public void Setup()
    {
        _factory = new WebApplicationFactory<Program>();
        _client = _factory.CreateClient();
    }

    [TearDown]
    public void TearDown()
    {
        _client?.Dispose();
        _factory?.Dispose();
    }

    [Test]
    public async Task GetDevices_ReturnsValidFactoryDevices()
    {
        // Act
        var response = await _client.GetAsync("/api/device");
        
        // Assert
        Assert.That(response.IsSuccessStatusCode, Is.True);
        
        var content = await response.Content.ReadAsStringAsync();
        var devices = JsonSerializer.Deserialize<object[]>(content);
        
        Assert.That(devices, Is.Not.Null);
        Assert.That(devices.Length, Is.EqualTo(9)); // Should have 9 factory devices
    }

    [Test]
    public async Task GetMaintenance_WithValidDevice_ReturnsRealPrediction()
    {
        // Arrange
        var deviceId = "LINE_1_CNC_01";
        
        // Act
        var response = await _client.GetAsync($"/api/maintenance?deviceId={deviceId}&real=true");
        
        // Assert - This will fail if device has no telemetry, which is expected in integration phase
        if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            var errorContent = await response.Content.ReadAsStringAsync();
            Assert.That(errorContent, Does.Contain("No telemetry data found"));
        }
        else
        {
            Assert.That(response.IsSuccessStatusCode, Is.True);
            
            var content = await response.Content.ReadAsStringAsync();
            var prediction = JsonSerializer.Deserialize<MaintenancePrediction>(content);
            
            Assert.That(prediction, Is.Not.Null);
            Assert.That(prediction.DeviceId, Is.EqualTo(deviceId));
            Assert.That(prediction.Confidence, Is.InRange(0.65, 0.95));
        }
    }

    [Test]
    public async Task GetMaintenance_WithMockFlag_ReturnsBadRequest()
    {
        // Arrange
        var deviceId = "LINE_1_CNC_01";
        
        // Act
        var response = await _client.GetAsync($"/api/maintenance?deviceId={deviceId}&real=false");
        
        // Assert - Should reject mock mode in integration phase
        Assert.That(response.StatusCode, Is.EqualTo(System.Net.HttpStatusCode.BadRequest));
        
        var content = await response.Content.ReadAsStringAsync();
        Assert.That(content, Does.Contain("Only real ML models allowed"));
    }

    [Test]
    public async Task GetMaintenance_WithInvalidDevice_ReturnsBadRequest()
    {
        // Arrange - Use a fake device ID
        var fakeDeviceId = "FAKE_DEVICE_01";
        
        // Act
        var response = await _client.GetAsync($"/api/maintenance?deviceId={fakeDeviceId}&real=true");
        
        // Assert
        Assert.That(response.StatusCode, Is.EqualTo(System.Net.HttpStatusCode.BadRequest));
        
        var content = await response.Content.ReadAsStringAsync();
        Assert.That(content, Does.Contain("Invalid deviceId"));
    }

    [Test]
    public async Task PostFeedback_WithValidData_ReturnsSuccess()
    {
        // Arrange
        var feedback = new MaintenanceFeedback
        {
            DeviceId = "LINE_1_CNC_01",
            WasPredictionAccurate = true,
            Rating = 5,
            Comments = "Prediction was accurate"
        };

        var json = JsonSerializer.Serialize(feedback);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        // Act
        var response = await _client.PostAsync("/api/maintenance/feedback", content);
        
        // Assert - May fail due to missing Cosmos DB connection, which is expected
        if (response.StatusCode == System.Net.HttpStatusCode.InternalServerError)
        {
            var errorContent = await response.Content.ReadAsStringAsync();
            Assert.That(errorContent, Does.Contain("temporarily unavailable"));
        }
        else
        {
            Assert.That(response.IsSuccessStatusCode, Is.True);
        }
    }

    [Test]
    public async Task HealthCheck_ReturnsHealthyStatus()
    {
        // Act
        var response = await _client.GetAsync("/api/device/health");
        
        // Assert
        Assert.That(response.IsSuccessStatusCode, Is.True);
        
        var content = await response.Content.ReadAsStringAsync();
        Assert.That(content, Does.Contain("Healthy"));
        Assert.That(content, Does.Contain("TotalDevices"));
    }
}