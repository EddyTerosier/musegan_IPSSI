import argparse, json
from pathlib import Path
from tqdm import tqdm

def parse_midi(path):
    import pretty_midi
    m = pretty_midi.PrettyMIDI(str(path))
    n_notes = sum(len(i.notes) for i in m.instruments)
    dur = float(m.get_end_time())
    return n_notes, dur

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--samples_dir", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    sdir = Path(a.samples_dir)
    midi_files = sorted(sdir.rglob("*.mid"))
    if not midi_files:
        raise SystemExit(f"Aucun .mid dans {sdir}")

    per = {}
    for f in tqdm(midi_files, desc="Eval"):
        n, dur = parse_midi(f)
        per[str(f.relative_to(sdir))] = {"notes": int(n), "duration_sec": float(round(dur, 3))}

    out = Path(a.out); out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({"n_files": len(per), "files": per}, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[OK] Metrics: {out}")

if __name__ == "__main__":
    main()
