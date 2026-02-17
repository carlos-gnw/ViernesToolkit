#!/usr/bin/env python3
"""Viernes Toolkit CLI en un solo archivo.

Incluye toda la lógica de la versión modular Python para facilitar despliegues
con limitantes de servidor.
"""

from __future__ import annotations

import argparse
import csv
import curses
import os
import re
import shlex
import subprocess
from dataclasses import dataclass
from datetime import datetime
from getpass import getpass
from pathlib import Path
from typing import Sequence

# ------------------------- Configuración -------------------------
DEFAULT_LOG_DIR = Path("/mnt/gv2/users/GNW/gnw/viernesLogs")
DEFAULT_LOG_FILE = DEFAULT_LOG_DIR / "viernes_uso.csv"
BLACKLIST = {"MW24070098", "ML17120024"}
BASE_WORKDIR = Path("/opt/test_tools/teton2/nitro-bmc-cli/")

GETIP_VIERNES = Path("/mnt/gv2/users/GNW/getip_viernes")
DBCONSULT_CANDIDATES = [
    Path("/mnt/gv2/users/GNW/gnw/tools/toolsgnw/dbconsult.sh"),
    Path("/home/MW23090133/gnw/tools/toolsgnw/dbconsult.sh"),
]
LEGACY_SCRIPTS = [
    Path("./viernesLastVersion2026.sh"),
    Path("./viernes-1.2prop9Abril.sh"),
]

MENU_ITEMS = [
    {"id": 1, "group": "L11 Tools", "label": "Activar K2V4"},
    {"id": 2, "group": "L11 Tools", "label": "SW Autoconfig"},
    {"id": 3, "group": "L11 Tools", "label": "Rack Information"},
    {"id": 4, "group": "L11 Tools", "label": "PCIe Verification"},
    {"id": 5, "group": "MLA Tools", "label": "Ejecutar UART Tool"},
    {"id": 6, "group": "MLA Tools", "label": "Proxy Cards Check"},
    {"id": 7, "group": "MLA Tools", "label": "Verificación de K2V5 card type"},
    {"id": 8, "group": "MLA Tools", "label": "Limpiar eventos (SEL Clear)"},
    {"id": 9, "group": "MLA Tools", "label": "Mostrar Sensor List"},
    {"id": 10, "group": "MLA Tools", "label": "Sel Clear + VPD"},
    {"id": 11, "group": "MLA Tools", "label": "Imprimir FRU"},
    {"id": 12, "group": "MLA Tools", "label": "Verificar BMC Network"},
    {"id": 13, "group": "MLA Tools", "label": "Clear DHCP + VPD"},
    {"id": 14, "group": "MLA Tools", "label": "Check IPV4 (extend)"},
    {"id": 15, "group": "Power", "label": "BMC Reboot"},
    {"id": 16, "group": "Power", "label": "Sol Activate"},
    {"id": 17, "group": "Debug", "label": "Issue TT2_K2V4_KEG_SYNC"},
    {"id": 18, "group": "Others", "label": "Opinión/Sugerencias de Tools"},
    {"id": 19, "group": "Others", "label": "Node Information | Buscar unidad"},
    {"id": 99, "group": "Compatibilidad", "label": "Legacy Launcher (scripts originales)"},
    {"id": 20, "group": "Sistema", "label": "Salir"},
]

ASCII_TITLE = [
    r" __      ___                           ",
    r" \ \    / (_)            GNW Team      ",
    r"  \ \  / / _  ___ _ __ _ __   ___  ___ ",
    r"   \ \/ / | |/ _ \ '__| '_ \ / _ \/ __|",
    r"    \  /  | |  __/ |  | | | |  __/\__",
    r"     \/   |_|\___|_|  |_| |_|\___||___/ ",
]

ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")


# ------------------------- Utilidades sistema -------------------------
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


# ------------------------- UI terminal -------------------------
def _draw(stdscr: curses.window, title: str, items: Sequence[dict], index: int) -> None:
    stdscr.clear()
    h, w = stdscr.getmaxyx()
    y = 1
    for line in ASCII_TITLE:
        stdscr.addstr(y, 2, line[: max(0, w - 4)], curses.A_BOLD)
        y += 1

    stdscr.addstr(y, 2, title[: max(0, w - 4)], curses.A_BOLD)
    y += 1
    stdscr.addstr(y, 2, "Usa ↑/↓ para navegar, Enter para seleccionar, q para salir.")
    y += 2

    current_group = None
    for i, item in enumerate(items):
        group = item.get("group", "General")
        if group != current_group:
            current_group = group
            stdscr.addstr(y, 2, f"[{group}]", curses.A_UNDERLINE)
            y += 1

        label = f"{item['id']:>2}) {item['label']}"
        if i == index:
            stdscr.addstr(y, 4, label[: max(0, w - 8)], curses.A_REVERSE)
        else:
            stdscr.addstr(y, 4, label[: max(0, w - 8)])
        y += 1

    stdscr.refresh()


def _legacy_script_path() -> Path | None:
    for candidate in LEGACY_SCRIPTS:
        if candidate.exists():
            return candidate
    return None


def option_run_legacy_selected(option_id: int, label: str) -> None:
    legacy = _legacy_script_path()
    if not legacy:
        print("No hay script legacy disponible en rutas conocidas.")
        return

    append_usage(f"{option_id} ({label}) [legacy]", "", "")
    print(f"\nAbriendo backend legacy para ejecutar opción {option_id}: {label}")
    print("(Se preselecciona la opción automáticamente y luego conserva entrada interactiva)")

    cmd = f"(printf '{option_id}\\n'; cat) | bash {shlex.quote(str(legacy))}"
    subprocess.run(["bash", "-lc", cmd], check=False)


def choose_option(title: str, items: Sequence[dict]) -> dict | None:
    def _inner(stdscr: curses.window):
        curses.curs_set(0)
        stdscr.keypad(True)
        idx = 0

        while True:
            _draw(stdscr, title, items, idx)
            key = stdscr.getch()
            if key in (curses.KEY_UP, ord("k")):
                idx = (idx - 1) % len(items)
            elif key in (curses.KEY_DOWN, ord("j")):
                idx = (idx + 1) % len(items)
            elif key in (10, 13, curses.KEY_ENTER):
                return items[idx]
            elif key in (ord("q"), 27):
                return None

    return curses.wrapper(_inner)


# ------------------------- Acciones -------------------------
def _input(prompt: str) -> str:
    return input(prompt).strip()


def _pick_dbconsult() -> Path | None:
    for path in DBCONSULT_CANDIDATES:
        if path.exists():
            return path
    return None


def resolve_k2v4_ip(sn: str) -> str:
    if GETIP_VIERNES.exists():
        out = run_cmd([str(GETIP_VIERNES), sn], cwd=GETIP_VIERNES.parent)
        lines = [clean_text(line) for line in out.stdout.splitlines() if clean_text(line)]
        if len(lines) >= 2:
            return lines[1]
    out = run_cmd(["getip", "--extend", sn])
    match = re.search(r"k2v4_ip\s+([0-9.]+)", clean_text(out.stdout))
    return match.group(1) if match else ""


def option_activate_k2v4() -> None:
    sn = _input("Ingrese el SN de la unidad: ")
    ip = resolve_k2v4_ip(sn)
    if not ip:
        print("Error: No se pudo obtener la IP del K2V4.")
        return

    password = getpass("Ingrese la contraseña para continuar: ")
    if password != "genios":
        print("Error: Contraseña incorrecta.")
        return

    append_usage("1 (Activación de K2V4)", sn, ip)
    payload = '{ actionType = "CardFirmwareEnable", cardFirmwareEnableAction = { targetDevice = "recovery", skipManagedCards = true}}'
    cmd1 = ["coap", "-O65001,0", "-Y", "-m", "PUT", "-c", payload, f"coaps+tcp://{ip}/api-v1/host-action/0/action/1"]
    cmd2 = ["coap", "-O65001,0", "-Y", f"coaps+tcp://{ip}//api-v1/host-action/0/action/1"]

    for cmd in (cmd1, cmd2):
        res = run_cmd(cmd)
        print(res.stdout or res.stderr)
        if res.code != 0:
            print("La operación terminó con error.")
            return


def option_sw_autoconfig() -> None:
    sn_rack = _input("Ingrese el SN del rack: ")
    db = _pick_dbconsult()
    if not db:
        print("No se encontró dbconsult.sh en rutas conocidas.")
        return

    res = run_cmd(["bash", str(db), "--GetDynamicData", f"--usn={sn_rack}", "--value=DYN_POSITION_FIONA", "--name=USN"], cwd=db.parent)
    text = res.stdout
    macs = re.findall(r"ETH0MAC</td><td>([^<]+)", text)
    sns = re.findall(r"CSN</td><td>([^<]+)", text)

    if len(macs) < 2:
        print("No fue posible obtener las MAC de switches.")
        return

    print("Switches detectados:")
    for i, mac in enumerate(macs[:2], start=1):
        ip_res = run_cmd(["getip", "-m", mac])
        ip = clean_text(ip_res.stdout).split()
        ip = ip[2] if len(ip) >= 3 else "N/A"
        sn = sns[i - 1] if i - 1 < len(sns) else "N/A"
        print(f"  SW{i}: SN={sn} MAC={mac} IP={ip}")

    append_usage("2 (SW Autoconfig)", sn_rack, "")
    print("Autoconfig asistida completada (modo informativo).")


def option_legacy_launcher() -> None:
    legacy = _legacy_script_path()
    if not legacy:
        print("No hay scripts legados disponibles.")
        return
    append_usage("Legacy Launcher", "", "")
    subprocess.run(["bash", str(legacy)], check=False)


def option_generic(label: str, command: list[str] | None = None) -> None:
    append_usage(label)
    if not command:
        print("Esta opción quedó modularizada y lista para implementación específica.")
        print("Use 'Legacy Launcher' para ejecución exacta de scripts históricos.")
        return
    res = run_cmd(command)
    print(res.stdout or res.stderr)


HANDLERS = {
    1: option_activate_k2v4,
    2: option_sw_autoconfig,
    99: option_legacy_launcher,
}


# ------------------------- App principal -------------------------
def run() -> None:
    validate_access()
    menu = MENU_ITEMS

    while True:
        selected = choose_option("Viernes Toolkit CLI (Python | Single File)", menu)
        if not selected:
            print("Saliendo...")
            break

        option_id = selected["id"]
        if option_id == 20:
            print("Hasta luego.")
            break

        handler = HANDLERS.get(option_id)
        print("\n" + "=" * 60)
        print(f"Ejecutando opción {option_id}: {selected['label']}")
        print("=" * 60)
        try:
            if handler:
                handler()
            else:
                option_run_legacy_selected(option_id, selected["label"])
        except KeyboardInterrupt:
            print("\nOperación cancelada por usuario.")
        except Exception as exc:
            print(f"Error no controlado: {exc}")

        input("\nPresiona Enter para regresar al menú...")


def render_preview(title: str = "Viernes Toolkit CLI (Python | Single File)") -> str:
    lines: list[str] = []
    lines.extend(ASCII_TITLE)
    lines.append(title)
    lines.append("Usa ↑/↓ para navegar, Enter para seleccionar, q para salir.")
    lines.append("")

    current_group = None
    for item in MENU_ITEMS:
        group = item.get("group", "General")
        if group != current_group:
            current_group = group
            lines.append(f"[{group}]")
        lines.append(f"  {item['id']:>2}) {item['label']}")

    lines.append("")
    lines.append("Nota: En ejecución real, el menú es interactivo con curses.")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Viernes Toolkit CLI (single file)")
    parser.add_argument(
        "--print-menu",
        action="store_true",
        help="Imprime el menú y termina (sin iniciar curses).",
    )
    parser.add_argument(
        "--preview-ui",
        action="store_true",
        help="Muestra una vista previa estática del UI con ASCII title.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.print_menu:
        for item in MENU_ITEMS:
            print(f"{item['id']:>2}) [{item['group']}] {item['label']}")
        return
    if args.preview_ui:
        print(render_preview())
        return
    run()


if __name__ == "__main__":
    main()
