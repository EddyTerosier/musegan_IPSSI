import argparse
from pathlib import Path
import math
import csv
import json

import numpy as np
import pretty_midi


def gaussian_score(x: float, target: float, sigma: float) -> float:
    if sigma <= 0:
        return 0.0
    z = (x - target) / sigma
    return float(math.exp(-(z * z)))


def safe_mean(arr):
    arr = np.asarray(arr)
    return float(arr.mean()) if arr.size else 0.0


def midi_features(midi_path: Path, fs: int = 20):
    pm = pretty_midi.PrettyMIDI(str(midi_path))
    dur = float(pm.get_end_time()) if pm.instruments else 0.0

    notes_per_track = []
    pitches = []

    total_notes = 0
    for inst in pm.instruments:
        n = len(inst.notes)
        total_notes += n
        notes_per_track.append(n)
        if not inst.is_drum:
            for note in inst.notes:
                pitches.append(note.pitch)

    nps = (total_notes / dur) if dur > 0 else 0.0

    # Piano roll global pour approx polyphonie / silence
    if dur > 0:
        roll = pm.get_piano_roll(fs=fs)  # shape (128, T)
        active = (roll > 0).sum(axis=0)  # nb notes actives à chaque frame
        poly_avg = safe_mean(active)
        silence_ratio = float((active == 0).mean()) if active.size else 1.0
    else:
        poly_avg = 0.0
        silence_ratio = 1.0

    if pitches:
        pitch_min = int(min(pitches))
        pitch_max = int(max(pitches))
        pitch_range = int(pitch_max - pitch_min)
    else:
        pitch_min, pitch_max, pitch_range = 0, 0, 0

    # Équilibre entre pistes (plus c'est homogène, mieux c'est)
    arr = np.asarray(notes_per_track, dtype=np.float32)
    mean_t = float(arr.mean()) if arr.size else 0.0
    std_t = float(arr.std()) if arr.size else 0.0
    cv = (std_t / mean_t) if mean_t > 0 else 10.0  # coefficient of variation

    return {
        "file": midi_path.name,
        "duration_sec": round(dur, 3),
        "total_notes": int(total_notes),
        "notes_per_sec": round(nps, 3),
        "polyphony_avg": round(poly_avg, 3),
        "silence_ratio": round(silence_ratio, 3),
        "pitch_min": pitch_min,
        "pitch_max": pitch_max,
        "pitch_range": pitch_range,
        "track_cv": round(cv, 3),
        "notes_per_track": notes_per_track,
    }


def score(features):
    # Cibles “musicales” raisonnables pour vos outputs (9.6s)
    density_s = gaussian_score(features["notes_per_sec"], target=10.0, sigma=3.0)
    poly_s    = gaussian_score(features["polyphony_avg"], target=3.0, sigma=1.5)

    # On veut peu de silence (mais pas forcément 0)
    silence_s = max(0.0, 1.0 - features["silence_ratio"])

    # Pitch range : on veut au moins ~2 octaves (24 demi-tons) et idéalement 4 (48)
    pr = features["pitch_range"]
    pitch_s = min(1.0, pr / 48.0) if pr > 0 else 0.0

    # Équilibre des pistes : CV faible = mieux
    cv = features["track_cv"]
    balance_s = gaussian_score(cv, target=0.8, sigma=0.6)

    # Pondérations simples
    final = (
        0.35 * density_s +
        0.25 * poly_s +
        0.20 * silence_s +
        0.10 * pitch_s +
        0.10 * balance_s
    )

    # Pénalité si trop peu de notes (souvent “vide”)
    if features["total_notes"] < 60:
        final *= 0.85

    return round(float(final), 4)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in_dir", required=True, help="Dossier contenant des .mid (récursif)")
    ap.add_argument("--out_csv", default="reports/metrics/scoring.csv")
    ap.add_argument("--out_json", default="reports/metrics/scoring.json")
    ap.add_argument("--top", type=int, default=3)
    args = ap.parse_args()

    in_dir = Path(args.in_dir)
    mids = sorted(in_dir.rglob("*.mid"))
    if not mids:
        raise SystemExit(f"Aucun .mid trouvé dans {in_dir}")

    rows = []
    for m in mids:
        f = midi_features(m)
        f["score"] = score(f)
        rows.append(f)

    rows.sort(key=lambda x: x["score"], reverse=True)

    out_csv = Path(args.out_csv)
    out_csv.parent.mkdir(parents=True, exist_ok=True)

    fieldnames = [
        "file", "score", "duration_sec", "total_notes", "notes_per_sec",
        "polyphony_avg", "silence_ratio", "pitch_min", "pitch_max", "pitch_range",
        "track_cv"
    ]
    with out_csv.open("w", newline="", encoding="utf-8") as fp:
        w = csv.DictWriter(fp, fieldnames=fieldnames)
        w.writeheader()
        for r in rows:
            w.writerow({k: r[k] for k in fieldnames})

    out_json = Path(args.out_json)
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(rows, indent=2, ensure_ascii=False), encoding="utf-8")

    print("[OK] CSV:", out_csv)
    print("[OK] JSON:", out_json)
    print("\nTOP", args.top)
    for r in rows[: args.top]:
        print(f" - {r['file']} | score={r['score']} | notes={r['total_notes']} | nps={r['notes_per_sec']} | poly={r['polyphony_avg']} | silence={r['silence_ratio']}")


if __name__ == "__main__":
    main()