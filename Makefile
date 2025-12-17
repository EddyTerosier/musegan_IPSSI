SHELL := bash

.PHONY: help bootstrap clone-musegan patch-musegan patch-musegan-py setup-exp download-models extract-models infer midi-batch eval clean

help:
	@echo "Targets:"
	@echo "  bootstrap         - cree le venv (py -3.10) + installe requirements.lock.txt"
	@echo "  clone-musegan     - clone MuseGAN dans third_party/musegan"
	@echo "  patch-musegan     - patch scripts MuseGAN (LF + python3->python)"
	@echo "  patch-musegan-py  - patch code MuseGAN pour TF1-compat + config safe (no pianoroll/images)"
	@echo "  download-models   - tente de telecharger pretrained_models.tar.gz (peut necessiter manuel)"
	@echo "  extract-models    - extrait pretrained_models.tar.gz dans third_party/musegan/exp"
	@echo "  infer             - lance inference MuseGAN sur exp/default"
	@echo "  midi-batch        - convertit fake_x_0.npy en batch de MIDIs (10)"
	@echo "  eval              - metriques simples (sur reports/samples)"
	@echo "  clean             - supprime .venv"

bootstrap:
	bash scripts/bootstrap.sh

clone-musegan:
	bash scripts/clone_musegan.sh

patch-musegan:
	bash scripts/patch_musegan.sh

patch-musegan-py:
	bash scripts/patch_musegan_py.sh

setup-exp:
	bash scripts/setup_exp.sh

download-models:
	bash scripts/download_models.sh

extract-models:
	bash scripts/extract_models.sh

infer:
	bash scripts/infer.sh

midi-batch:
	./.venv/Scripts/python.exe tools/npy_to_midi_batch.py \
	  --npy third_party/musegan/exp/default/results/inference/arrays/fake_x/fake_x_0.npy \
	  --outdir reports/samples/midi_batch \
	  --n 10 --thresh 0.6 --min_steps 2

eval:
	bash scripts/eval.sh

clean:
	rm -rf .venv

score:
	./.venv/Scripts/python.exe tools/score_midis.py \
	  --in_dir reports/samples/midi_batch \
	  --out_csv reports/metrics/scoring.csv \
	  --out_json reports/metrics/scoring.json \
	  --top 3

report:
	./.venv/Scripts/python.exe tools/make_report_figures.py

pipeline: infer midi-batch score report
	@echo "[OK] Pipeline complet termine."

midi-batch2:
	./.venv/Scripts/python.exe tools/npy_to_midi_batch.py \
	  --npy third_party/musegan/exp/default/results/inference/arrays/fake_x/fake_x_0.npy \
	  --outdir reports/samples/midi_batch2 \
	  --n 10 --thresh 0.6 --min_steps 2

score2:
	./.venv/Scripts/python.exe tools/score_midis.py \
	  --in_dir reports/samples/midi_batch2 \
	  --out_csv reports/metrics/scoring2.csv \
	  --out_json reports/metrics/scoring2.json \
	  --top 3

report2:
	./.venv/Scripts/python.exe tools/make_report_figures.py \
	  --scoring_json reports/metrics/scoring2.json \
	  --midi_dir reports/samples/midi_batch2 \
	  --out_dir reports/figures/run2 \
	  --best_of_dir reports/samples/best_of_run2 \
	  --top 3

pipeline2: infer midi-batch2 score2 report2
	@echo "[OK] Pipeline2 termine."
