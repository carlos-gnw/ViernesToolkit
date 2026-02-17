from __future__ import annotations

from pathlib import Path
import json

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
MENU_FILE = DATA_DIR / "menu.json"

DEFAULT_LOG_DIR = Path("/mnt/gv2/users/GNW/gnw/viernesLogs")
DEFAULT_LOG_FILE = DEFAULT_LOG_DIR / "viernes_uso.csv"

BLACKLIST = {"MW24070098", "ML17120024"}
BASE_WORKDIR = Path("/opt/test_tools/teton2/nitro-bmc-cli/")


def load_menu() -> list[dict]:
    return json.loads(MENU_FILE.read_text(encoding="utf-8"))
