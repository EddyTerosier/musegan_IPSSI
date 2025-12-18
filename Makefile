SHELL := /bin/bash
PYTHON := python

.PHONY: help infer midi-batch score report pipeline midi-batch2 score2 report2 pipeline2

help:
	@echo "Targets disponibles:"
	@echo "  infer       - Inférence MuseGAN"
	@echo "  midi-batch  - Conversion NPY → MIDI (batch 1)"
	@echo "  score       - Calcul des scores"
	@echo "  report      - Génération des graphiques + best-of"
	@echo "  pipeline    - Pipeline complet (infer + midi + score + report)"
	@echo "  pipeline2   - Pipeline alternatif (outputs dans run2/)"

infer:
	cd third_party/musegan && bash scripts/run_inference.sh ./exp/default/ 0

midi-batch:
	$(PYTHON) tools/npy_to_midi_batch.py \
		--npy third_party/musegan/exp/default/results/inference/arrays/fake_x/fake_x_0.npy \
		--outdir reports/samples/midi_batch \
		--n 10 --thresh 0.6 --min_steps 2

score:
	$(PYTHON) tools/score_midis.py \
		--in_dir reports/samples/midi_batch \
		--out_csv reports/metrics/scoring.csv \
		--out_json reports/metrics/scoring.json \
		--top 3

report:
	$(PYTHON) tools/make_report_figures.py \
		--scoring_json reports/metrics/scoring.json \
		--midi_dir reports/samples/midi_batch \
		--out_dir reports/figures \
		--best_of_dir reports/samples/best_of \
		--top 3

pipeline: infer midi-batch score report
	@echo "[OK] Pipeline complet terminé"

midi-batch2:
	$(PYTHON) tools/npy_to_midi_batch.py \
		--npy third_party/musegan/exp/default/results/inference/arrays/fake_x/fake_x_0.npy \
		--outdir reports/samples/midi_batch2 \
		--n 10 --thresh 0.6 --min_steps 2

score2:
	$(PYTHON) tools/score_midis.py \
		--in_dir reports/samples/midi_batch2 \
		--out_csv reports/metrics/scoring2.csv \
		--out_json reports/metrics/scoring2.json \
		--top 3

report2:
	$(PYTHON) tools/make_report_figures.py \
		--scoring_json reports/metrics/scoring2.json \
		--midi_dir reports/samples/midi_batch2 \
		--out_dir reports/figures/run2 \
		--best_of_dir reports/samples/best_of_run2 \
		--top 3

pipeline2: infer midi-batch2 score2 report2
	@echo "[OK] Pipeline2 terminé"
