#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MUSEGAN_DIR="$ROOT_DIR/third_party/musegan"

ARCHIVE_A="$MUSEGAN_DIR/exp/pretrained_models.tar.gz"
ARCHIVE_B="$ROOT_DIR/exp/pretrained_models.tar.gz"

mkdir -p "$MUSEGAN_DIR/exp"

if [ -f "$ARCHIVE_A" ]; then
  ARCHIVE="$ARCHIVE_A"
elif [ -f "$ARCHIVE_B" ]; then
  echo "[INFO] Archive trouvee dans exp/. Copie vers MuseGAN exp/…"
  cp "$ARCHIVE_B" "$ARCHIVE_A"
  ARCHIVE="$ARCHIVE_A"
else
  echo "[ERREUR] Archive absente. Attendu:"
  echo " - $ARCHIVE_A"
  echo " ou"
  echo " - $ARCHIVE_B"
  exit 1
fi

echo "[INFO] Extraction de $ARCHIVE …"
(cd "$MUSEGAN_DIR" && tar -xzf "$ARCHIVE" -C "./exp")
echo "[OK] Extraction terminee."
