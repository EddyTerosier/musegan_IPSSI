#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MUSEGAN_SRC="$ROOT_DIR/third_party/musegan/src"
DEFAULT_CFG="$ROOT_DIR/third_party/musegan/exp/default/config.yaml"

if [ ! -d "$MUSEGAN_SRC" ]; then
  echo "[ERREUR] MuseGAN src introuvable: $MUSEGAN_SRC"
  exit 1
fi

echo "[INFO] Patch TensorFlow (TF1-compat) sur MuseGAN src..."
"$ROOT_DIR/.venv/Scripts/python.exe" - <<'PY'
from pathlib import Path
root = Path("third_party/musegan/src")
patched = 0
for p in root.rglob("*.py"):
    txt = p.read_text(encoding="utf-8", errors="ignore")
    if "import tensorflow as tf" in txt and "tensorflow.compat.v1 as tf" not in txt:
        txt = txt.replace(
            "import tensorflow as tf",
            "import tensorflow.compat.v1 as tf\n\ntf.disable_v2_behavior()",
            1
        )
        p.write_text(txt, encoding="utf-8", newline="\n")
        patched += 1
print(f"[OK] TF1-compat appliqué sur {patched} fichier(s).")
PY

if [ -f "$DEFAULT_CFG" ]; then
  echo "[INFO] Patch config.yaml (disable pianoroll/images, keep arrays)"
  sed -i 's/^save_pianoroll_samples:.*/save_pianoroll_samples: False/' "$DEFAULT_CFG" || true
  sed -i 's/^save_image_samples:.*/save_image_samples: False/' "$DEFAULT_CFG" || true
  sed -i 's/^save_array_samples:.*/save_array_samples: True/' "$DEFAULT_CFG" || true
else
  echo "[WARN] config.yaml default introuvable ($DEFAULT_CFG)"
fi

IOU="$ROOT_DIR/third_party/musegan/src/musegan/io_utils.py"
if [ -f "$IOU" ]; then
  echo "[INFO] Patch io_utils.py (beat_resolution -> resolution)"
  sed -i 's/beat_resolution=/resolution=/g' "$IOU" || true
fi

echo "[OK] Patch python MuseGAN termine."
