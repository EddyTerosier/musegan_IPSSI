from __future__ import annotations

import os
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional


@dataclass
class CmdResult:
    returncode: int
    stdout: str
    stderr: str


def _extend_path(env: dict) -> dict:
    # Assure la présence des outils Git Bash (sh, bash, etc.) pour les scripts appelés par Makefile
    extra = [
        r"C:\Program Files\Git\usr\bin",
        r"C:\Program Files\Git\bin",
        r"C:\ProgramData\chocolatey\bin",
    ]
    path = env.get("PATH", "")
    for p in extra:
        if p not in path and os.path.isdir(p):
            path = path + os.pathsep + p
    env["PATH"] = path
    return env


def _find_make_exe() -> str:
    # Priorité: variable d'env si vous voulez forcer
    forced = os.environ.get("MAKE_EXE")
    if forced and os.path.exists(forced):
        return forced

    found = shutil.which("make")
    if found:
        return found

    # Fallback Chocolatey (souvent présent)
    fallback = r"C:\ProgramData\chocolatey\bin\make.exe"
    return fallback


def run_make(repo_root: Path, target: str) -> CmdResult:
    make_exe = _find_make_exe()
    env = _extend_path(os.environ.copy())

    # Important: exécution directe Windows (pas via bash)
    cmd: List[str] = [make_exe, target]

    p = subprocess.run(
        cmd,
        cwd=str(repo_root),
        capture_output=True,
        text=True,
        env=env,
    )

    return CmdResult(
        returncode=p.returncode,
        stdout=p.stdout or "",
        stderr=p.stderr or "",
    )