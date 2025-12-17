#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MUSEGAN_DIR="$ROOT_DIR/third_party/musegan"
EXP_DIR="$ROOT_DIR/exp/my_experiment"

if [ ! -d "$MUSEGAN_DIR" ]; then
  echo "[ERREUR] MuseGAN introuvable. Lancez: make clone-musegan"
  exit 1
fi
if [ -d "$EXP_DIR" ]; then
  echo "[OK] Exp deja presente: $EXP_DIR"
  exit 0
fi

mkdir -p "$ROOT_DIR/exp"
cd "$MUSEGAN_DIR"
bash scripts/setup_exp.sh "$EXP_DIR" "TP MuseGAN - experience"
echo "[OK] Exp creee: $EXP_DIR"
