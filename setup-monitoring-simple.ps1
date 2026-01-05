# 📊 Smart Factory Real-time Monitoring Setup - Simple Version
# Configures basic Application Insights monitoring

param(
    [string]$ResourceGroupName = "smart-factory-v2-rg"
)

Write-Host "📊 Smart Factory Real-time Monitoring Setup" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Get Application Insights instance
Write-Host "🔍 Finding Application Insights instance..." -ForegroundColor Yellow
$appInsights = az monitor app-insights component list --resource-group $ResourceGroupName --query "[0]" | ConvertFrom-Json

if (!$appInsights) {
    Write-Error "No Application Insights instance found in resource group: $ResourceGroupName"
    exit 1
}

$appInsightsName = $appInsights.name
Write-Host "✅ Found Application Insights: $appInsightsName" -ForegroundColor Green

# Create basic monitoring queries
Write-Host "`n📝 Essential KQL Queries for Monitoring:" -ForegroundColor Cyan

$queries = @{
    "Service Health" = "requests | where name contains 'health' | summarize HealthyCount = countif(resultCode == 200), UnhealthyCount = countif(resultCode != 200) by bin(timestamp, 5m)"
    "Error Rate" = "exceptions | summarize ErrorCount = count() by bin(timestamp, 5m), cloud_RoleName"
    "Response Times" = "requests | summarize AvgDuration = avg(duration) by bin(timestamp, 5m), name"
    "IoT Messages" = "customEvents | where name == 'IoTMessage' | summarize MessageCount = count() by bin(timestamp, 1m)"
}

foreach ($query in $queries.GetEnumerator()) {
    Write-Host "`n🔍 $($query.Key):" -ForegroundColor Yellow
    Write-Host "   $($query.Value)" -ForegroundColor Gray
}

# Test Application Insights connection
Write-Host "`n🧪 Testing Application Insights connection..." -ForegroundColor Yellow
try {
    $testQuery = "requests | take 1"
    $result = az monitor app-insights query --app $appInsightsName --analytics-query $testQuery 2>$null
    if ($result) {
        Write-Host "✅ Application Insights connection successful" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Application Insights connection test inconclusive" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Application Insights connection failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎯 Monitoring setup completed!" -ForegroundColor Green
Write-Host "Next: Proceeding to CI/CD Pipeline setup..." -ForegroundColor Cyan