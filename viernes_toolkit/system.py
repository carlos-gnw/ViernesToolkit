from __future__ import annotations

import csv
import os
import re
import subprocess
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

from .config import BASE_WORKDIR, BLACKLIST, DEFAULT_LOG_FILE

ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")


@dataclass
class CommandResult:
    code: int
    stdout: str
    stderr: str


def current_user() -> str:
    for cmd in (["logname"], ["whoami"]):
        try:
            out = subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL).strip()
            if out:
                return out
        except Exception:
            pass
    return os.getenv("USER", "unknown")


def validate_access() -> None:
    user = current_user()
    if user in BLACKLIST:
        raise PermissionError(f"Acceso denegado para el usuario '{user}'.")


def run_cmd(cmd: list[str], cwd: Path | None = None, timeout: int = 90) -> CommandResult:
    proc = subprocess.run(
        cmd,
        cwd=str(cwd or BASE_WORKDIR),
        text=True,
        capture_output=True,
        timeout=timeout,
    )
    return CommandResult(proc.returncode, proc.stdout, proc.stderr)


def clean_text(value: str) -> str:
    return ANSI_RE.sub("", value).strip()


def append_usage(option: str, sn: str = "", ip: str = "") -> None:
    now = datetime.now()
    log_file = DEFAULT_LOG_FILE
    log_file.parent.mkdir(parents=True, exist_ok=True)
    new_file = not log_file.exists()

    with log_file.open("a", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        if new_file:
            writer.writerow(["Fecha", "Hora", "Usuario", "Opcion", "SN", "IP", "Cluster"])
        writer.writerow(
            [
                now.strftime("%Y-%m-%d"),
                now.strftime("%H:%M:%S"),
                current_user(),
                option,
                sn,
                ip,
                os.uname().nodename,
            ]
        )
