from __future__ import annotations
from pathlib import Path

def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]

def safe_resolve_under(base: Path, rel: str) -> Path:
    p = (base / rel).resolve()
    if not str(p).startswith(str(base.resolve())):
        raise ValueError("Path traversal detected")
    return p

def ensure_relative_to_repo(path: Path) -> str:
    root = repo_root().resolve()
    return str(path.resolve().relative_to(root)).replace("\\", "/")
