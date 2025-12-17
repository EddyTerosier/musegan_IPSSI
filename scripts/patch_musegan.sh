#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MUSEGAN_DIR="$ROOT_DIR/third_party/musegan"

if [ ! -d "$MUSEGAN_DIR" ]; then
  echo "[ERREUR] MuseGAN introuvable. Lancez: make clone-musegan"
  exit 1
fi

echo "[INFO] CRLF -> LF sur scripts MuseGAN"
sed -i 's/\r$//' "$MUSEGAN_DIR"/scripts/*.sh

echo "[INFO] python3 -> python (si present)"
FILES="$(grep -rl -- "python3" "$MUSEGAN_DIR/scripts" || true)"
if [ -n "$FILES" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] && sed -i 's/\bpython3\b/python/g' "$f"
  done <<< "$FILES"
fi

echo "[OK] Patch scripts MuseGAN applique."
