#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORGE="${FORGE:-$HOME/.foundry/bin/forge}"
if ! command -v forge >/dev/null 2>&1; then
  if [ -x "$FORGE" ]; then
    export PATH="$(dirname "$FORGE"):$PATH"
  else
  exec powershell -NoProfile -File "$ROOT/scripts/demo-onchain.ps1"
  fi
fi
cd "$ROOT/contracts"
exec forge test --match-contract PrdDemoTest -vv
