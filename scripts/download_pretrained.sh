#!/usr/bin/env bash
set -euo pipefail

WORKDIR="/app"
MUSEGAN_DIR="$WORKDIR/third_party/musegan"
ARCHIVE="$MUSEGAN_DIR/exp/pretrained_models.tar.gz"
CHECKPOINT_DIR="$MUSEGAN_DIR/exp/default/checkpoints"
CONFIG_FILE="$MUSEGAN_DIR/exp/default/config.yaml"

# Miroirs de fallback
ZENODO_URL="https://zenodo.org/records/1283510/files/pretrained_models.tar.gz"
GITHUB_URL="https://github.com/salu133445/musegan/releases/download/v1.0/pretrained_models.tar.gz"

# Fonction pour patcher le config.yaml après extraction
patch_config() {
    if [ -f "$CONFIG_FILE" ]; then
        echo "[INFO] Patch config.yaml pour désactiver pianoroll/images..."
        sed -i 's/save_pianoroll_samples: true/save_pianoroll_samples: false/g' "$CONFIG_FILE"
        sed -i 's/save_pianoroll_samples: True/save_pianoroll_samples: false/g' "$CONFIG_FILE"
        sed -i 's/save_image_samples: true/save_image_samples: false/g' "$CONFIG_FILE"
        sed -i 's/save_image_samples: True/save_image_samples: false/g' "$CONFIG_FILE"
        sed -i 's/save_array_samples: false/save_array_samples: true/g' "$CONFIG_FILE"
        sed -i 's/save_array_samples: False/save_array_samples: true/g' "$CONFIG_FILE"
        echo "[OK] Config patché"
    fi
}

# Vérifier si les modèles sont déjà extraits
if [ -d "$CHECKPOINT_DIR" ] && [ -f "$CHECKPOINT_DIR/checkpoint" ]; then
    echo "[OK] Modèles déjà extraits dans $CHECKPOINT_DIR"
    patch_config
    exit 0
fi

mkdir -p "$MUSEGAN_DIR/exp"

# Si l'archive existe dans le repo (cas idéal) et est valide
if [ -f "$ARCHIVE" ]; then
    echo "[INFO] Archive trouvée dans le repo"
    if tar -tzf "$ARCHIVE" >/dev/null 2>&1; then
        echo "[INFO] Archive valide, extraction en cours..."
        cd "$MUSEGAN_DIR/exp"
        tar -xzf pretrained_models.tar.gz --skip-old-files
        echo "[OK] Extraction terminée"
        patch_config
        exit 0
    else
        echo "[WARN] Archive corrompue, suppression..."
        rm -f "$ARCHIVE"
    fi
fi

# Sinon, télécharger automatiquement
echo "[INFO] Archive absente, téléchargement automatique..."
cd "$MUSEGAN_DIR/exp"

# Tentative 1 : gdown (Google Drive via script MuseGAN)
echo "[INFO] Tentative 1/3 : Google Drive (gdown)..."
cd "$MUSEGAN_DIR"
if bash scripts/download_models.sh 2>/dev/null && [ -f "exp/pretrained_models.tar.gz" ] && tar -tzf "exp/pretrained_models.tar.gz" >/dev/null 2>&1; then
    echo "[OK] Téléchargement Google Drive réussi"
    cd exp
    tar -xzf pretrained_models.tar.gz --skip-old-files
    echo "[OK] Extraction terminée"
    patch_config
    exit 0
fi

cd "$MUSEGAN_DIR/exp"
rm -f pretrained_models.tar.gz

# Tentative 2 : Zenodo (miroir académique fiable)
echo "[INFO] Tentative 2/3 : Zenodo..."
if curl -fL --connect-timeout 10 --max-time 300 --progress-bar "$ZENODO_URL" -o pretrained_models.tar.gz && tar -tzf pretrained_models.tar.gz >/dev/null 2>&1; then
    echo "[OK] Téléchargement Zenodo réussi"
    tar -xzf pretrained_models.tar.gz --skip-old-files
    echo "[OK] Extraction terminée"
    patch_config
    exit 0
fi
rm -f pretrained_models.tar.gz

# Tentative 3 : GitHub Release
echo "[INFO] Tentative 3/3 : GitHub..."
if curl -fL --connect-timeout 10 --max-time 300 --progress-bar "$GITHUB_URL" -o pretrained_models.tar.gz && tar -tzf pretrained_models.tar.gz >/dev/null 2>&1; then
    echo "[OK] Téléchargement GitHub réussi"
    tar -xzf pretrained_models.tar.gz --skip-old-files
    echo "[OK] Extraction terminée"
    patch_config
    exit 0
fi
rm -f pretrained_models.tar.gz

# Si tout échoue
echo ""
echo "[ERREUR] Tous les téléchargements automatiques ont échoué"
echo ""
echo "Solution : Ajouter l'archive manuellement au repo Git"
echo "  1. Télécharger depuis : https://ucsdcloud-my.sharepoint.com/... (via navigateur)"
echo "  2. Placer dans : third_party/musegan/exp/pretrained_models.tar.gz"
echo "  3. Git add + commit + push"
echo "  4. Rebuild : make -f Makefile.docker build"
echo ""
exit 1
