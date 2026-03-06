# OpenClaw Provider Switcher
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("self", "self2", "codeflow")]
    [string]$Provider,
    [Parameter(Mandatory=$false)]
    [string]$Model
)

$configPath = "D:\openclaw\deploy\openclaw\volumes\openclaw\config\openclaw.json"

# Provider models mapping
$providerModels = @{
    self = @("claude-opus-4-6", "claude-haiku-4-5-20251001", "claude-sonnet-4-6-thinking", "claude-sonnet-4-6")
    self2 = @("claude-opus-4-6", "claude-haiku-4-5-20251001", "claude-sonnet-4-6-thinking", "claude-sonnet-4-6")
    codeflow = @("claude-haiku-4-5-20251001", "claude-sonnet-4-5-20250929", "claude-opus-4-5-20251101", "claude-opus-4-6", "claude-sonnet-4-6")
}

# Show current config if no parameters
if (-not $Provider) {
    Write-Host "=== OpenClaw Provider Switcher ===" -ForegroundColor Cyan
    Write-Host ""

    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    $currentPrimary = $config.agents.defaults.model.primary
    $currentFallbacks = $config.agents.defaults.model.fallbacks -join ", "

    Write-Host "Current Config:" -ForegroundColor Yellow
    Write-Host "  Primary: $currentPrimary" -ForegroundColor Green
    Write-Host "  Fallbacks: $currentFallbacks" -ForegroundColor Green
    Write-Host ""

    Write-Host "Available Providers:" -ForegroundColor Yellow
    Write-Host "  1. self     - FuCheers Key1"
    Write-Host "  2. self2    - FuCheers Key2"
    Write-Host "  3. codeflow - CodeFlow"
    Write-Host ""

    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\switch-provider.ps1 self claude-sonnet-4-6-thinking"
    Write-Host "  .\switch-provider.ps1 codeflow claude-sonnet-4-6"
    Write-Host "  .\switch-provider.ps1 self2"
    Write-Host ""
    exit 0
}

# Default models
$defaultModels = @{
    self = "claude-sonnet-4-6-thinking"
    self2 = "claude-sonnet-4-6-thinking"
    codeflow = "claude-sonnet-4-6"
}

if (-not $Model) {
    $Model = $defaultModels[$Provider]
    Write-Host "Using default model: $Model" -ForegroundColor Yellow
}

# Validate model
if ($providerModels[$Provider] -notcontains $Model) {
    Write-Host "Error: Provider '$Provider' does not support model '$Model'" -ForegroundColor Red
    Write-Host "Supported models: $($providerModels[$Provider] -join ', ')" -ForegroundColor Yellow
    exit 1
}

# Read config
Write-Host "Reading config..." -ForegroundColor Cyan
$config = Get-Content $configPath -Raw | ConvertFrom-Json

# Backup
$backupPath = "$configPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $configPath $backupPath
Write-Host "Backup created: $backupPath" -ForegroundColor Green

# Set new primary
$newPrimary = "$Provider/$Model"
$config.agents.defaults.model.primary = $newPrimary

# Set fallbacks
if ($Provider -eq "codeflow") {
    $config.agents.defaults.model.fallbacks = @(
        "codeflow/claude-opus-4-6",
        "self/claude-sonnet-4-6-thinking",
        "self2/claude-sonnet-4-6-thinking"
    )
} elseif ($Provider -eq "self") {
    $config.agents.defaults.model.fallbacks = @(
        "self2/$Model",
        "codeflow/claude-sonnet-4-6",
        "codeflow/claude-opus-4-6"
    )
} else {
    $config.agents.defaults.model.fallbacks = @(
        "self/$Model",
        "codeflow/claude-sonnet-4-6",
        "codeflow/claude-opus-4-6"
    )
}

# Save config
Write-Host "Saving config..." -ForegroundColor Cyan
$config | ConvertTo-Json -Depth 100 | Set-Content $configPath -Encoding UTF8

Write-Host ""
Write-Host "Config updated!" -ForegroundColor Green
Write-Host "  Primary: $newPrimary" -ForegroundColor Cyan
Write-Host "  Fallbacks: $($config.agents.defaults.model.fallbacks -join ', ')" -ForegroundColor Cyan
Write-Host ""

# Ask to restart
$restart = Read-Host "Restart OpenClaw container? (y/n)"
if ($restart -eq "y" -or $restart -eq "Y") {
    Write-Host "Restarting OpenClaw..." -ForegroundColor Cyan
    docker restart openclaw-gateway
    Write-Host "OpenClaw restarted!" -ForegroundColor Green
} else {
    Write-Host "Please restart manually:" -ForegroundColor Yellow
    Write-Host "  docker restart openclaw-gateway" -ForegroundColor White
}
