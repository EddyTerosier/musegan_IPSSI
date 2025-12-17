import argparse
from pathlib import Path
import numpy as np
import pretty_midi


def build_midi(sample, out_path, thresh, tempo, beat_resolution, min_steps,
               lowest_pitch, programs, is_drums):
    seconds_per_step = (60.0 / tempo) / beat_resolution
    min_dur = min_steps * seconds_per_step

    pr = sample.reshape(-1, 84, 5)  # (time, pitches, tracks)
    pr_bin = (pr > thresh).astype(np.uint8)

    pm = pretty_midi.PrettyMIDI(initial_tempo=tempo)

    for t in range(5):
        inst = pretty_midi.Instrument(program=programs[t], is_drum=bool(is_drums[t]))
        roll = pr_bin[:, :, t] > 0

        for pitch_idx in range(roll.shape[1]):
            on = False
            start = 0
            for i in range(roll.shape[0]):
                if roll[i, pitch_idx] and not on:
                    on = True
                    start = i
                if on and (i == roll.shape[0] - 1 or not roll[i + 1, pitch_idx]):
                    end = i + 1
                    inst.notes.append(pretty_midi.Note(
                        velocity=90,
                        pitch=lowest_pitch + pitch_idx,
                        start=start * seconds_per_step,
                        end=end * seconds_per_step
                    ))
                    on = False

        inst.notes = [n for n in inst.notes if (n.end - n.start) >= min_dur]
        pm.instruments.append(inst)

    pm.write(str(out_path))
    return sum(len(i.notes) for i in pm.instruments)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--npy", required=True)
    ap.add_argument("--outdir", required=True)
    ap.add_argument("--n", type=int, default=10)
    ap.add_argument("--thresh", type=float, default=0.6)
    ap.add_argument("--tempo", type=int, default=100)
    ap.add_argument("--beat_resolution", type=int, default=12)
    ap.add_argument("--min_steps", type=int, default=2)
    args = ap.parse_args()

    x = np.load(args.npy)
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    lowest_pitch = 24
    programs = [0, 0, 25, 33, 48]
    is_drums = [1, 0, 0, 0, 0]

    n = min(args.n, x.shape[0])
    for i in range(n):
        out = outdir / f"sample_{i:02d}.mid"
        notes = build_midi(
            x[i], out,
            thresh=args.thresh,
            tempo=args.tempo,
            beat_resolution=args.beat_resolution,
            min_steps=args.min_steps,
            lowest_pitch=lowest_pitch,
            programs=programs,
            is_drums=is_drums,
        )
        print(out.name, "notes=", notes)

    print("[OK] outdir:", outdir)


if __name__ == "__main__":
    main()
