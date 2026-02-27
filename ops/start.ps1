$ErrorActionPreference = "Stop"
Set-Location -Path (Join-Path $PSScriptRoot "..")

if (-not (Test-Path ".env")) {
  Copy-Item ".env.example" ".env"
  Write-Host "[init] .env created from .env.example"
}

New-Item -ItemType Directory -Force -Path "runtime\state" | Out-Null
New-Item -ItemType Directory -Force -Path "runtime\redis" | Out-Null

docker compose up -d --build
docker compose ps

