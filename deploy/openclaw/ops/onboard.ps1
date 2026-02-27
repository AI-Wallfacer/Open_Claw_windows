$ErrorActionPreference = "Stop"
Set-Location -Path (Join-Path $PSScriptRoot "..")

docker compose run --rm openclaw-cli onboard --no-install-daemon

