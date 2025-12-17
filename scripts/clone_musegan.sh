#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
mkdir -p third_party

if [ -d "third_party/musegan/.git" ]; then
  echo "[OK] MuseGAN deja clone."
  exit 0
fi

git clone https://github.com/salu133445/musegan.git third_party/musegan
echo "[OK] MuseGAN clone dans third_party/musegan"
