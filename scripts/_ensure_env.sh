#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MUSEGAN_DIR="$ROOT_DIR/third_party/musegan"
VENV_BIN="$ROOT_DIR/.venv/Scripts"
VENV_PY="$ROOT_DIR/.venv/Scripts/python.exe"

if [ ! -d "$MUSEGAN_DIR" ]; then
  echo "[ERREUR] MuseGAN introuvable. Lancez: make clone-musegan"
  exit 1
fi
if [ ! -f "$VENV_PY" ]; then
  echo "[ERREUR] venv introuvable. Lancez: make bootstrap"
  exit 1
fi

export PATH="$VENV_BIN:$PATH"
hash -r
