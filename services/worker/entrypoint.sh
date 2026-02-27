#!/usr/bin/env sh
set -eu

mkdir -p /state
exec python /app/main.py

