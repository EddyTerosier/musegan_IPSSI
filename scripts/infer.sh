#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_ensure_env.sh"

echo "[INFO] Python: $(command -v python)"
python --version

cd "$MUSEGAN_DIR"
bash scripts/run_inference.sh "./exp/default/" "0"
