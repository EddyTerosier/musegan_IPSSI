\
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if command -v py >/dev/null 2>&1; then
  echo "[INFO] Creation du venv avec: py -3.10"
  py -3.10 -m venv .venv
else
  echo "[WARN] 'py' non trouve. Tentative avec 'python'..."
  python -m venv .venv
fi

VENV_PY="$ROOT_DIR/.venv/Scripts/python.exe"
if [ ! -f "$VENV_PY" ]; then
  echo "[ERREUR] python.exe introuvable dans .venv. Installez Python 3.10 + le launcher 'py'."
  exit 1
fi

"$VENV_PY" -m pip install -U pip setuptools wheel
"$VENV_PY" -m pip install -r requirements.lock.txt

# Fix python3 for Git Bash (avoid WindowsApps alias)
VENV_BIN="$ROOT_DIR/.venv/Scripts"
cat > "$VENV_BIN/python3" <<'EOF'
#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
"$DIR/python.exe" "$@"
EOF
chmod +x "$VENV_BIN/python3"

echo "[OK] Venv pret."
"$VENV_PY" -c "import numpy as np; print('numpy', np.__version__)"
"$VENV_PY" -c "import tensorflow as tf; print('tf', tf.__version__)"
