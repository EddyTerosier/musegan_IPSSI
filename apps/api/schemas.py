from __future__ import annotations
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Any, Dict, List

class RunCreate(BaseModel):
    name: str = Field(default="run", min_length=1, max_length=200)
    scoring_json: str = Field(default="reports/metrics/scoring.json")
    midi_dir: str = Field(default="reports/samples/midi_batch")
    figures_dir: str = Field(default="reports/figures")
    best_of_dir: str = Field(default="reports/samples/best_of")
    top: int = Field(default=3, ge=1, le=20)

class RunOut(BaseModel):
    id: int
    created_at: datetime
    name: str
    scoring_json: str
    midi_dir: str
    figures_dir: str
    best_of_dir: str
    summary: Dict[str, Any]

class FileOut(BaseModel):
    name: str
    rel_path: str
    size_bytes: int
