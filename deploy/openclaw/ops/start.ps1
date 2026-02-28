$ErrorActionPreference = "Stop"
Set-Location -Path (Join-Path $PSScriptRoot "..")

if (-not (Test-Path ".env")) {
  Copy-Item ".env.example" ".env"
  Write-Host "[init] Created .env from .env.example"
}

New-Item -ItemType Directory -Force -Path ".\volumes\openclaw\config" | Out-Null
New-Item -ItemType Directory -Force -Path ".\volumes\openclaw\workspace" | Out-Null
New-Item -ItemType Directory -Force -Path ".\volumes\openclaw\logs" | Out-Null

# 只拉取官方基础镜像（openclaw-local-custom 是本地构建的，不在 Docker Hub）
docker pull ghcr.io/openclaw/openclaw:main
docker compose up -d --build openclaw-gateway
docker compose ps

