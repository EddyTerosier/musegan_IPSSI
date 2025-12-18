#!/usr/bin/env bash
set -euo pipefail

WORKDIR="/app"
MUSEGAN_DIR="$WORKDIR/third_party/musegan"
ARCHIVE="$MUSEGAN_DIR/exp/pretrained_models.tar.gz"
CHECKPOINT_DIR="$MUSEGAN_DIR/exp/default/checkpoints"
GITHUB_URL="https://github.com/salu133445/musegan/releases/download/v1.0/pretrained_models.tar.gz"

# Vérifier si les modèles sont déjà extraits
if [ -d "$CHECKPOINT_DIR" ] && [ -f "$CHECKPOINT_DIR/checkpoint" ]; then
    echo "[OK] Modèles déjà extraits dans $CHECKPOINT_DIR"
    exit 0
fi

mkdir -p "$MUSEGAN_DIR/exp"

# Si l'archive existe déjà, juste extraire
if [ -f "$ARCHIVE" ]; then
    echo "[INFO] Archive trouvée, extraction en cours..."
    cd "$MUSEGAN_DIR/exp"
    tar -xzf pretrained_models.tar.gz --skip-old-files
    echo "[OK] Extraction terminée"
    exit 0
fi

# Tentative 1 : gdown (via script MuseGAN)
echo "[INFO] Tentative téléchargement via gdown..."
cd "$MUSEGAN_DIR"
if bash scripts/download_models.sh 2>/dev/null && [ -f "exp/pretrained_models.tar.gz" ]; then
    echo "[OK] Téléchargement via gdown réussi"
    cd exp
    tar -xzf pretrained_models.tar.gz --skip-old-files
    echo "[OK] Extraction terminée"
    exit 0
fi

# Tentative 2 : wget direct depuis GitHub
echo "[INFO] gdown échoué, tentative wget depuis GitHub..."
cd "$MUSEGAN_DIR/exp"
if wget -q --show-progress "$GITHUB_URL" -O pretrained_models.tar.gz; then
    echo "[OK] Téléchargement wget réussi"
    tar -xzf pretrained_models.tar.gz --skip-old-files
    echo "[OK] Extraction terminée"
    exit 0
fi

# Tentative 3 : curl direct depuis GitHub
echo "[INFO] wget échoué, tentative curl..."
if curl -L -o pretrained_models.tar.gz "$GITHUB_URL" 2>/dev/null; then
    echo "[OK] Téléchargement curl réussi"
    tar -xzf pretrained_models.tar.gz --skip-old-files
    echo "[OK] Extraction terminée"
    exit 0
fi

# Si tout échoue
echo ""
echo "[ERREUR] Tous les téléchargements ont échoué"
echo "Vérifiez votre connexion internet ou téléchargez manuellement:"
echo "  URL: $GITHUB_URL"
echo ""
exit 1
