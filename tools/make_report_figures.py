import argparse
from pathlib import Path
import json
import shutil

import matplotlib.pyplot as plt


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--scoring_json", default="reports/metrics/scoring.json")
    ap.add_argument("--midi_dir", default="reports/samples/midi_batch")
    ap.add_argument("--out_dir", default="reports/figures")
    ap.add_argument("--best_of_dir", default="reports/samples/best_of")
    ap.add_argument("--top", type=int, default=3)
    args = ap.parse_args()

    scoring_path = Path(args.scoring_json)
    data = json.loads(scoring_path.read_text(encoding="utf-8"))

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    notes = [d["total_notes"] for d in data]
    nps = [d["notes_per_sec"] for d in data]
    scores = [d["score"] for d in data]

    # 1) Histogramme total_notes
    plt.figure()
    plt.hist(notes, bins=8)
    plt.xlabel("Total notes")
    plt.ylabel("Count")
    plt.title("Distribution — Total notes per sample")
    p1 = out_dir / "hist_total_notes.png"
    plt.savefig(p1, dpi=160, bbox_inches="tight")
    plt.close()

    # 2) Histogramme notes_per_sec
    plt.figure()
    plt.hist(nps, bins=8)
    plt.xlabel("Notes per second")
    plt.ylabel("Count")
    plt.title("Distribution — Notes/sec per sample")
    p2 = out_dir / "hist_notes_per_sec.png"
    plt.savefig(p2, dpi=160, bbox_inches="tight")
    plt.close()

    # 3) Scatter score vs notes/sec (bonus très utile pour le rapport)
    plt.figure()
    plt.scatter(nps, scores)
    plt.xlabel("Notes per second")
    plt.ylabel("Score")
    plt.title("Score vs Notes/sec")
    p3 = out_dir / "scatter_score_vs_nps.png"
    plt.savefig(p3, dpi=160, bbox_inches="tight")
    plt.close()

    # 4) Best-of: copie des top MIDIs
    midi_dir = Path(args.midi_dir)
    best_dir = Path(args.best_of_dir)
    best_dir.mkdir(parents=True, exist_ok=True)

    top = data[: args.top]
    copied = []
    for i, row in enumerate(top, 1):
        src = midi_dir / row["file"]
        if src.exists():
            dst = best_dir / f"TOP{i:02d}_{row['file']}"
            shutil.copy2(src, dst)
            copied.append(dst.name)

    print("[OK] Figures:", p1, p2, p3)
    print("[OK] Best-of:", best_dir)
    for c in copied:
        print(" -", c)


if __name__ == "__main__":
    main()