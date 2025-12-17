from __future__ import annotations

from datetime import datetime
from sqlalchemy import Integer, String, DateTime, Text
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base

class Run(Base):
    __tablename__ = "runs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    name: Mapped[str] = mapped_column(String(200), default="run", nullable=False)

    scoring_json: Mapped[str] = mapped_column(String(500), nullable=False)
    midi_dir: Mapped[str] = mapped_column(String(500), nullable=False)
    figures_dir: Mapped[str] = mapped_column(String(500), nullable=False)
    best_of_dir: Mapped[str] = mapped_column(String(500), nullable=False)

    summary_json: Mapped[str] = mapped_column(Text, default="{}", nullable=False)
