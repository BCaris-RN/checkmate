#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"
SPIKE_STALE_HOURS="${CARIS_SPIKE_STALE_HOURS:-48}"
FAIL_ON_STALE_SPIKES="${CARIS_FAIL_ON_STALE_SPIKES:-0}"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/enforce_exclusion_zones.py"

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
else
  echo "[ERROR] Python is required for exclusion checks." >&2
  exit 2
fi

args=(
  "$HELPER"
  --root "$ROOT_DIR"
  --spike-stale-hours "$SPIKE_STALE_HOURS"
)

if [ "$FAIL_ON_STALE_SPIKES" = "1" ]; then
  args+=(--fail-on-stale-spikes)
fi

"$PYTHON_BIN" "${args[@]}"
