# MuseGAN IPSSI - Génération Musicale IA

Projet de génération automatique de musique MIDI multi-pistes utilisant MuseGAN (GAN symbolique), avec interface web fullstack pour la gestion, l'écoute et l'analyse des compositions générées.

## Aperçu

Ce projet permet de :
- **Générer** des compositions MIDI 5 pistes (Drums, Piano, Guitar, Bass, Strings)
- **Scorer** automatiquement la qualité musicale (densité, polyphonie, équilibre)
- **Visualiser** les métriques via graphiques (histogrammes, scatter plots)
- **Écouter** les MIDIs directement dans le navigateur
- **Comparer** différents runs de génération

**Stack technique :**
- Backend : FastAPI + SQLAlchemy + SQLite
- Frontend : React 18 + Vite + Tone.js
- IA : MuseGAN (TensorFlow 2.10 en mode TF1-compat)
- Déploiement : Docker + docker-compose

---

## Getting Started

### Prérequis

- **Docker** et **Docker Compose** installés ([guide](https://docs.docker.com/get-docker/))
- **8 GB RAM** minimum
- **5 GB espace disque** disponible

### Installation complète (5 minutes)

```bash
# 1. Cloner le projet
git clone https://github.com/EddyTerosier/musegan_IPSSI.git
cd musegan_IPSSI

# 2. Télécharger l'archive ZIP
# Ouvrez ce lien dans votre navigateur : https://ucsdcloud-my.sharepoint.com/:u:/r/personal/h3dong_ucsd_edu/Documents/data/musegan/pretrained_models.tar.gz?csf=1&web=1&e=r0u74h
# Copier l'archive téléchargée dans le dossier third_party/musegan/exp/

# 3. Construire les images Docker
make -f Makefile.docker build

# 4. Démarrer les services (backend + frontend)
make -f Makefile.docker up

# 5. Dans un autre terminal : télécharger les modèles pré-entraînés
make -f Makefile.docker setup-models

# 6. Générer vos premiers MIDIs
make -f Makefile.docker pipeline
```

**C'est tout !** Ouvrez votre navigateur :
- 🎨 **Frontend** : http://localhost:5173
- 🔌 **API** : http://localhost:8000/docs

### Première utilisation

1. Dans l'interface web, cliquez sur **"Importer (pipeline)"** pour charger les MIDIs générés
2. Explorez les métriques, graphiques et écoutez les meilleurs samples
3. Cliquez sur **"Générer + importer"** pour créer de nouveaux MIDIs directement depuis l'interface

---

## Commandes Essentielles

### Pipeline de génération

```bash
# Pipeline complet (recommandé)
make -f Makefile.docker pipeline
# → Génère 10 MIDIs + scores + graphiques en ~2 minutes

# Ou étape par étape :
make -f Makefile.docker infer     # 1. Inférence MuseGAN (numpy arrays)
make -f Makefile.docker midi      # 2. Conversion en MIDIs
make -f Makefile.docker score     # 3. Calcul des scores
make -f Makefile.docker report    # 4. Génération des graphiques + best-of
```

### Gestion des services

```bash
# Voir les logs en temps réel
make -f Makefile.docker logs

# Arrêter les services
make -f Makefile.docker down

# Redémarrer après modifications
make -f Makefile.docker restart

# Shell interactif dans le backend
make -f Makefile.docker shell

# Nettoyer complètement (conteneurs + volumes + images)
make -f Makefile.docker clean
```

### Génération via l'API

```bash
# Depuis l'interface : bouton "Générer + importer"

# Ou via curl :
curl -X POST http://localhost:8000/api/generate \
  -H "Content-Type: application/json" \
  -d '{}'

# Avec paramètres personnalisés :
curl -X POST http://localhost:8000/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "target": "pipeline2",
    "name": "Mon run custom",
    "top": 5
  }'
```

---

## 📊 Système de Scoring

Les MIDIs générés sont évalués selon 5 critères pondérés :

| Critère | Poids | Cible optimale |
|---------|-------|----------------|
| **Densité de notes** | 35% | ~10 notes/sec |
| **Polyphonie moyenne** | 25% | ~3 notes simultanées |
| **Ratio de silence** | 20% | Faible (< 30%) |
| **Range de pitch** | 10% | ~4 octaves (48 demi-tons) |
| **Équilibre pistes** | 10% | CV proche de 0.8 |

**Score final** : combinaison pondérée normalisée entre 0 et 1

Les 3 meilleurs MIDIs sont copiés dans `reports/samples/best_of/` avec préfixe `TOP01_`, `TOP02_`, etc.

---

## Interface Web

### Fonctionnalités

- **Liste des runs** : historique de toutes les générations avec date/nom
- **Métriques KPI** : samples totaux, avg notes/sec, max score
- **Graphiques** :
  - Histogramme des notes totales
  - Histogramme des notes/sec
  - Scatter plot score vs densité
- **Lecture MIDI** : player intégré (Tone.js) directement dans le navigateur
- **Download** : téléchargement des MIDIs best-of

### Workflow typique

1. Cliquer **"Générer + importer"**
2. Attendre ~2 minutes (le backend affiche la progression)
3. Le nouveau run apparaît automatiquement en tête de liste
4. Cliquer dessus pour voir les détails
5. Écouter les best-of avec le bouton **"Play"**

---

## Troubleshooting

### Téléchargement des modèles échoue (quota Google Drive)

```bash
# 1. Télécharger manuellement :
# https://github.com/salu133445/musegan/releases/download/v1.0/pretrained_models.tar.gz

# 2. Copier dans le conteneur :
docker cp pretrained_models.tar.gz musegan_backend:/app/third_party/musegan/exp/

# 3. Extraire :
make -f Makefile.docker shell
cd third_party/musegan/exp && tar -xzf pretrained_models.tar.gz
exit
```

### Port 8000 ou 5173 déjà utilisé

Éditez `docker-compose.yml` :
```yaml
services:
  backend:
    ports:
      - "8001:8000"  # Changer 8000 → 8001
  frontend:
    ports:
      - "5174:5173"  # Changer 5173 → 5174
```

Puis relancez : `make -f Makefile.docker restart`

### Erreur mémoire TensorFlow (OOM)

Ajoutez dans `docker-compose.yml` (section `backend` → `environment`) :
```yaml
environment:
  - TF_FORCE_GPU_ALLOW_GROWTH=true
  - TF_CPP_MIN_LOG_LEVEL=2
```

### Frontend ne se connecte pas au backend

Vérifiez la variable d'environnement dans `apps/web/src/api.js` :
```javascript
const API_BASE = import.meta.env.VITE_API_BASE || "http://localhost:8000";
```

Ou créez `apps/web/.env` :
```
VITE_API_BASE=http://localhost:8000
```

### Les MIDIs générés sont vides ou trop courts

Ajustez les seuils dans `Makefile.docker` (target `midi` ou `midi-batch2`) :
```makefile
--thresh 0.5        # Baisser pour plus de notes (essayez 0.4)
--min_steps 1       # Réduire pour des notes plus courtes
```

---

## Configuration Avancée

### Modifier les paramètres de génération MuseGAN

Après `setup-models`, éditez :
```bash
# Accéder au conteneur
make -f Makefile.docker shell

# Éditer la config
nano third_party/musegan/exp/default/config.yaml

# Exemples de modifications :
# - num_sample: 20      # Générer plus de samples
# - temperature: 1.2    # Augmenter la diversité
```

### Personnaliser le scoring

Éditez `tools/score_midis.py` dans la fonction `score()` :
```python
def score(features):
    density_s = gaussian_score(features["notes_per_sec"], target=12.0, sigma=4.0)  # Modifier cible
    # ... ajuster les pondérations ...
    final = (
        0.40 * density_s +  # Augmenter l'importance de la densité
        0.30 * poly_s +
        # ...
    )
```

Reconstruire l'image : `make -f Makefile.docker build`

### Ajouter de nouveaux instruments

Éditez `tools/npy_to_midi_batch.py` :
```python
programs = [0, 0, 25, 33, 48]  # General MIDI program numbers
is_drums = [1, 0, 0, 0, 0]     # Piste 1 = drums
```

---

## Documentation Technique

### Flux de données

```
MuseGAN (TF)
    ↓ numpy arrays (84 pitches × 5 tracks × 96 timesteps)
npy_to_midi_batch.py
    ↓ MIDI files (.mid)
score_midis.py
    ↓ JSON/CSV (métriques + scores)
make_report_figures.py
    ↓ PNG (graphiques) + best-of (top MIDIs)
FastAPI backend
    ↓ SQLite (runs, métadonnées)
React frontend
    ↓ Tone.js (lecture navigateur)
```

### Architecture réseau

```
┌─────────────────────────────────────────┐
│  Docker Compose Network (musegan_net)   │
│                                          │
│  ┌──────────────┐    ┌───────────────┐ │
│  │   Frontend   │───▶│    Backend    │ │
│  │  React:5173  │    │ FastAPI:8000  │ │
│  │   (Vite)     │    │  (Uvicorn)    │ │
│  └──────────────┘    └───────┬───────┘ │
│                              │          │
│                    ┌─────────▼────────┐ │
│                    │   MuseGAN Core   │ │
│                    │ TensorFlow 2.10  │ │
│                    └──────────────────┘ │
│                                          │
│  Volumes persistants :                  │
│  - ./third_party (code MuseGAN)         │
│  - ./reports (outputs)                  │
│  - ./apps/api/app.db (SQLite)           │
└─────────────────────────────────────────┘
```

### Format des données

**Numpy array** (`fake_x_0.npy`) :
```
Shape: (batch_size, 96, 84, 5)
- 96 timesteps (1 bar à 4/4, 24 steps/beat)
- 84 pitches (7 octaves MIDI: 24-107)
- 5 tracks (Drums, Piano, Guitar, Bass, Strings)
Values: float32 entre 0 et 1 (probabilités)
```

**MIDI output** :
```
Format: Type 1 MIDI (multi-track)
Tempo: 100 BPM
Beat resolution: 12 (steps par temps)
Duration: ~9.6 secondes par sample
```


## Notes

- Les modèles pré-entraînés (~100 MB) doivent être téléchargés une seule fois
- La première inférence est lente (~2-3 min) à cause du chargement TensorFlow
- Les runs suivants sont plus rapides (~30-60 sec)
- Les MIDIs sont jouables dans n'importe quel DAW (FL Studio, Ableton, etc.)
- Le projet peut tourner sans GPU (CPU suffit pour l'inférence)

---
