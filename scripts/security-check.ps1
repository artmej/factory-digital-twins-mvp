#!/usr/bin/env pwsh
# Security Validation Script for Smart Factory
# Checks for potential secrets before commits

param(
    [Parameter(Mandatory=$false)]
    [switch]$Fix,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowDetails
)

Write-Host "🔒 Smart Factory Security Validation" -ForegroundColor Green
Write-Host ""

$errors = @()
$warnings = @()
$fixes = @()

# Check for hardcoded Azure GUIDs
Write-Host "🔍 Checking for hardcoded Azure IDs..." -ForegroundColor Yellow

$guidPattern = '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}'
$guidMatches = Get-ChildItem -Path "." -Include "*.js","*.html","*.ts","*.cs","*.json" -Recurse | 
    Select-String -Pattern $guidPattern | 
    Where-Object { $_.Line -notmatch "your-.*-here" -and $_.Line -notmatch "template" -and $_.Line -notmatch "example" }

foreach ($match in $guidMatches) {
    if ($match.Line -match "clientId|tenantId|subscriptionId") {
        $errors += "❌ Hardcoded ID in $($match.Filename):$($match.LineNumber)"
        if ($ShowDetails) {
            Write-Host "   $($match.Line.Trim())" -ForegroundColor Red
        }
    }
}

# Check for connection strings
Write-Host "🔗 Checking for connection strings..." -ForegroundColor Yellow

$connectionPatterns = @(
    'AccountKey=',
    'SharedAccessKey=',
    'ConnectionString.*=',
    'Password=',
    'pwd=',
    'server=.*password'
)

foreach ($pattern in $connectionPatterns) {
    $matches = Get-ChildItem -Path "." -Include "*.js","*.html","*.cs","*.json","*.bicep" -Recurse |
        Select-String -Pattern $pattern -CaseSensitive:$false |
        Where-Object { $_.Line -notmatch "template|example|your-.*-here|listKeys\(\)" }
    
    foreach ($match in $matches) {
        $warnings += "⚠️ Potential secret in $($match.Filename):$($match.LineNumber)"
        if ($ShowDetails) {
            Write-Host "   $($match.Line.Trim())" -ForegroundColor Yellow
        }
    }
}

# Check for environment files
Write-Host "📁 Checking for untracked environment files..." -ForegroundColor Yellow

$envFiles = @('*.env', '*.secrets', 'local.settings.json', 'appsettings.*.json')
foreach ($pattern in $envFiles) {
    $files = Get-ChildItem -Path "." -Include $pattern -Recurse -Force
    foreach ($file in $files) {
        $gitStatus = git status --porcelain $file.FullName 2>$null
        if ($gitStatus -and $gitStatus.StartsWith("??")) {
            $warnings += "⚠️ Untracked environment file: $($file.Name)"
        }
    }
}

# Check .gitignore coverage
Write-Host "🚫 Validating .gitignore coverage..." -ForegroundColor Yellow

$criticalPatterns = @('*.env', '*.secrets', 'local.settings.json', 'factory_config.env')
$gitignoreContent = Get-Content -Path ".gitignore" -ErrorAction SilentlyContinue

foreach ($pattern in $criticalPatterns) {
    if (-not ($gitignoreContent -contains $pattern)) {
        $warnings += "⚠️ Missing .gitignore pattern: $pattern"
        if ($Fix) {
            Add-Content -Path ".gitignore" -Value $pattern
            $fixes += "✅ Added $pattern to .gitignore"
        }
    }
}

# Check for test secrets
Write-Host "🧪 Checking test files for real secrets..." -ForegroundColor Yellow

$testFiles = Get-ChildItem -Path "tests" -Include "*.js","*.cs","*.json" -Recurse -ErrorAction SilentlyContinue
foreach ($file in $testFiles) {
    $content = Get-Content $file.FullName
    foreach ($line in $content) {
        if ($line -match $guidPattern -and $line -notmatch "test|mock|fake|sample") {
            $warnings += "⚠️ Possible real ID in test file $($file.Name)"
        }
    }
}

# Display results
Write-Host ""
Write-Host "📊 Security Validation Results:" -ForegroundColor Cyan
Write-Host ""

if ($errors.Count -eq 0) {
    Write-Host "✅ No critical security issues found!" -ForegroundColor Green
} else {
    Write-Host "❌ CRITICAL SECURITY ISSUES:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "   $error" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️ WARNINGS:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "   $warning" -ForegroundColor Yellow
    }
}

if ($Fix -and $fixes.Count -gt 0) {
    Write-Host ""
    Write-Host "🔧 FIXES APPLIED:" -ForegroundColor Green
    foreach ($fix in $fixes) {
        Write-Host "   $fix" -ForegroundColor Green
    }
}

Write-Host ""
if ($errors.Count -gt 0) {
    Write-Host "🚨 COMMIT BLOCKED: Fix critical issues before committing" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ Security validation passed - safe to commit" -ForegroundColor Green
    exit 0
}