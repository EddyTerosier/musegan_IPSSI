from __future__ import annotations

import json
from typing import List

from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session

from .db import SessionLocal, engine, Base
from .models import Run
from .schemas import RunCreate, RunOut, FileOut
from .utils_paths import repo_root, safe_resolve_under, ensure_relative_to_repo
from .services import load_scoring, summarize
from .runner import run_make

Base.metadata.create_all(bind=engine)

app = FastAPI(title="MuseGAN TP API", version="1.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

ROOT = repo_root()
REPORTS = (ROOT / "reports").resolve()
if REPORTS.exists():
    app.mount("/reports", StaticFiles(directory=str(REPORTS)), name="reports")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def run_to_out(run: Run) -> RunOut:
    try:
        summary = json.loads(run.summary_json or "{}")
    except Exception:
        summary = {}
    return RunOut(
        id=run.id,
        created_at=run.created_at,
        name=run.name,
        scoring_json=run.scoring_json,
        midi_dir=run.midi_dir,
        figures_dir=run.figures_dir,
        best_of_dir=run.best_of_dir,
        summary=summary,
    )

@app.get("/api/health")
def health():
    return {"ok": True}

@app.post("/api/runs/import", response_model=RunOut)
def import_run(payload: RunCreate, db: Session = Depends(get_db)):
    root = repo_root()
    try:
        scoring_path = safe_resolve_under(root, payload.scoring_json)
        midi_dir = safe_resolve_under(root, payload.midi_dir)
        figures_dir = safe_resolve_under(root, payload.figures_dir)
        best_of_dir = safe_resolve_under(root, payload.best_of_dir)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    if not scoring_path.exists():
        raise HTTPException(status_code=404, detail=f"scoring_json introuvable: {payload.scoring_json}")
    if not midi_dir.exists():
        raise HTTPException(status_code=404, detail=f"midi_dir introuvable: {payload.midi_dir}")
    if not figures_dir.exists():
        raise HTTPException(status_code=404, detail=f"figures_dir introuvable: {payload.figures_dir}")
    if not best_of_dir.exists():
        best_of_dir.mkdir(parents=True, exist_ok=True)

    rows = load_scoring(scoring_path)
    summary = summarize(rows, top=payload.top)

    run = Run(
        name=payload.name,
        scoring_json=ensure_relative_to_repo(scoring_path),
        midi_dir=ensure_relative_to_repo(midi_dir),
        figures_dir=ensure_relative_to_repo(figures_dir),
        best_of_dir=ensure_relative_to_repo(best_of_dir),
        summary_json=json.dumps(summary, ensure_ascii=False),
    )
    db.add(run)
    db.commit()
    db.refresh(run)
    return run_to_out(run)

@app.post("/api/generate", response_model=RunOut)
def generate_and_import(
    target: str = "pipeline2",
    name: str = "run_generated",
    scoring_json: str = "reports/metrics/scoring2.json",
    midi_dir: str = "reports/samples/midi_batch2",
    figures_dir: str = "reports/figures/run2",
    best_of_dir: str = "reports/samples/best_of_run2",
    top: int = 3,
    db: Session = Depends(get_db),
):
    """Run `make <target>` then import the produced artifacts as a Run.
    Defaults align with pipeline2 in your Makefile snippet (midi_batch2 + scoring2 + figures/run2).
    """
    root = repo_root()

    res = run_make(root, target=target)
    if res.returncode != 0:
        # include last part of stderr/stdout to help debug without flooding
        tail = (res.stdout + "\n" + res.stderr)[-4000:]
        raise HTTPException(status_code=500, detail=f"make {target} a échoué (rc={res.returncode})\n---\n{tail}")

    payload = RunCreate(
        name=name,
        scoring_json=scoring_json,
        midi_dir=midi_dir,
        figures_dir=figures_dir,
        best_of_dir=best_of_dir,
        top=top,
    )
    return import_run(payload, db)

@app.get("/api/runs", response_model=List[RunOut])
def list_runs(db: Session = Depends(get_db)):
    runs = db.query(Run).order_by(Run.id.desc()).all()
    return [run_to_out(r) for r in runs]

@app.get("/api/runs/{run_id}", response_model=RunOut)
def get_run(run_id: int, db: Session = Depends(get_db)):
    run = db.query(Run).filter(Run.id == run_id).first()
    if not run:
        raise HTTPException(status_code=404, detail="run introuvable")
    return run_to_out(run)

@app.get("/api/runs/{run_id}/files", response_model=List[FileOut])
def list_run_files(run_id: int, kind: str = "best_of", db: Session = Depends(get_db)):
    run = db.query(Run).filter(Run.id == run_id).first()
    if not run:
        raise HTTPException(status_code=404, detail="run introuvable")

    root = repo_root()
    rel = run.best_of_dir if kind == "best_of" else run.midi_dir
    try:
        folder = safe_resolve_under(root, rel)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    if not folder.exists():
        return []

    out: List[FileOut] = []
    for p in sorted(folder.glob("*.mid")):
        rp = ensure_relative_to_repo(p)
        out.append(FileOut(name=p.name, rel_path=rp, size_bytes=p.stat().st_size))
    return out
