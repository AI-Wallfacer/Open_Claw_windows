param(
  [string]$Service = "worker"
)

$ErrorActionPreference = "Stop"
Set-Location -Path (Join-Path $PSScriptRoot "..")

docker compose logs -f --tail=200 $Service

