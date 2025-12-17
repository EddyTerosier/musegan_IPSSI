#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_ensure_env.sh"

mkdir -p "$MUSEGAN_DIR/exp"
ARCHIVE="$MUSEGAN_DIR/exp/pretrained_models.tar.gz"

echo "[INFO] Tentative telechargement auto via scripts MuseGAN (gdown)."
set +e
(cd "$MUSEGAN_DIR" && bash scripts/download_models.sh)
STATUS=$?
set -e

if [ $STATUS -ne 0 ] || [ ! -s "$ARCHIVE" ]; then
  echo ""
  echo "[WARN] Telechargement auto echoue (quota/permissions)."
  echo "Mode manuel:"
  echo "  - telechargez pretrained_models.tar.gz"
  echo "  - placez-le dans l'un des chemins suivants:"
  echo "      1) $MUSEGAN_DIR/exp/pretrained_models.tar.gz"
  echo "      2) $ROOT_DIR/exp/pretrained_models.tar.gz"
  echo "  - puis: make extract-models"
  echo ""
  exit 1
fi

echo "[OK] Archive presente: $ARCHIVE"
