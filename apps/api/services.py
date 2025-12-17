from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List

def load_scoring(scoring_json_path: Path) -> List[Dict[str, Any]]:
    data = json.loads(scoring_json_path.read_text(encoding="utf-8"))
    if isinstance(data, dict) and "files" in data:
        files = data["files"]
        rows = []
        for k, v in files.items():
            dur = float(v.get("duration_sec", 0.0)) or 1.0
            notes = int(v.get("notes", 0))
            rows.append({
                "file": Path(k).name,
                "total_notes": notes,
                "duration_sec": float(v.get("duration_sec", 0.0)),
                "notes_per_sec": notes / dur,
                "score": 0.0,
            })
        return rows
    if not isinstance(data, list):
        raise ValueError("scoring.json invalid format (expected list)")
    return data

def summarize(rows: List[Dict[str, Any]], top: int = 3) -> Dict[str, Any]:
    if not rows:
        return {"top": [], "stats": {}}

    rows_sorted = sorted(rows, key=lambda r: float(r.get("score", 0.0)), reverse=True)
    top_rows = rows_sorted[:top]

    notes = [int(r.get("total_notes", 0)) for r in rows_sorted]
    nps = [float(r.get("notes_per_sec", 0.0)) for r in rows_sorted]
    scores = [float(r.get("score", 0.0)) for r in rows_sorted]

    def _avg(xs): return sum(xs) / len(xs) if xs else 0.0

    return {
        "top": [
            {
                "file": r.get("file"),
                "score": float(r.get("score", 0.0)),
                "total_notes": int(r.get("total_notes", 0)),
                "notes_per_sec": float(r.get("notes_per_sec", 0.0)),
                "polyphony_avg": float(r.get("polyphony_avg", 0.0)),
                "silence_ratio": float(r.get("silence_ratio", 0.0)),
            }
            for r in top_rows
        ],
        "stats": {
            "n_samples": len(rows_sorted),
            "avg_total_notes": round(_avg(notes), 3),
            "avg_notes_per_sec": round(_avg(nps), 3),
            "avg_score": round(_avg(scores), 4),
            "min_score": round(min(scores), 4) if scores else 0.0,
            "max_score": round(max(scores), 4) if scores else 0.0,
        }
    }
