# MuseGAN TP – Projet propre (Windows + Git Bash)

## Démarrage rapide (ordre exact)
```bash
make bootstrap
make clone-musegan
make patch-musegan
make patch-musegan-py

# pretrained models
make download-models
# si download-models echoue: telecharger manuellement pretrained_models.tar.gz puis:
make extract-models

# inference
make infer

# conversion en MIDI (batch 10)
make midi-batch
```

## Écouter un MIDI
Un fichier `.mid` n’est pas du son, c’est une partition (événements MIDI).
Pour écouter:
- Ouvrir dans MuseScore (recommandé) puis jouer / exporter en WAV/MP3
- Ou ouvrir dans un DAW (FL Studio / Ableton / Reaper)
- Ou un lecteur MIDI selon votre configuration Windows

Les MIDIs générés sont dans `reports/samples/midi_batch/`.
