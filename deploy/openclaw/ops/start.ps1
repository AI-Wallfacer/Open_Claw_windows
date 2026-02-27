$ErrorActionPreference = "Stop"
Set-Location -Path (Join-Path $PSScriptRoot "..")

if (-not (Test-Path ".env")) {
  Copy-Item ".env.example" ".env"
  Write-Host "[init] Created .env from .env.example"
}

New-Item -ItemType Directory -Force -Path ".\volumes\openclaw\config" | Out-Null
New-Item -ItemType Directory -Force -Path ".\volumes\openclaw\workspace" | Out-Null
New-Item -ItemType Directory -Force -Path ".\volumes\openclaw\logs" | Out-Null

docker compose pull
docker compose up -d openclaw-gateway
docker compose ps

