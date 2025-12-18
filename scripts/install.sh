#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════════"
echo "  MuseGAN TP — Installation Docker (Linux)"
echo "═══════════════════════════════════════════════════════════"

if ! command -v docker &> /dev/null; then
    echo "[ERREUR] Docker n'est pas installé"
    echo "Installez Docker: https://docs.docker.com/engine/install/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "[ERREUR] Docker Compose n'est pas installé"
    echo "Installez Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "[1/4] Construction des images Docker..."
make -f Makefile.docker build

echo "[2/4] Démarrage des services..."
make -f Makefile.docker up

echo "[3/4] Attente du démarrage des services (30s)..."
sleep 30

echo "[4/4] Téléchargement des modèles pré-entraînés..."
make -f Makefile.docker setup-models || {
    echo ""
    echo "[WARN] Téléchargement automatique échoué"
    echo "Téléchargez manuellement:"
    echo "  wget https://github.com/salu133445/musegan/releases/download/v1.0/pretrained_models.tar.gz"
    echo "  docker cp pretrained_models.tar.gz musegan_backend:/app/third_party/musegan/exp/"
    echo "  make -f Makefile.docker shell"
    echo "  cd third_party/musegan/exp && tar -xzf pretrained_models.tar.gz"
}

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✓ Installation terminée !"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Accès:"
echo "  - Frontend: http://localhost:5173"
echo "  - Backend:  http://localhost:8000"
echo ""
echo "Prochaines étapes:"
echo "  make -f Makefile.docker pipeline   # Lancer la génération"
echo "  make -f Makefile.docker logs       # Voir les logs"
echo ""
