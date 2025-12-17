#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_ensure_env.sh"
"$VENV_PY" tools/eval_metrics.py --samples_dir reports/samples --out reports/metrics/metrics.json
