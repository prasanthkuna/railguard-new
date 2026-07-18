#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec powershell -NoProfile -File "$ROOT/scripts/deploy-anvil.ps1"
