from __future__ import annotations

from getpass import getpass
from pathlib import Path
import re
import subprocess

from .system import append_usage, clean_text, run_cmd

GETIP_VIERNES = Path("/mnt/gv2/users/GNW/getip_viernes")
DBCONSULT_CANDIDATES = [
    Path("/mnt/gv2/users/GNW/gnw/tools/toolsgnw/dbconsult.sh"),
    Path("/home/MW23090133/gnw/tools/toolsgnw/dbconsult.sh"),
]
LEGACY_SCRIPTS = [
    Path("./viernesLastVersion2026.sh"),
    Path("./viernes-1.2prop9Abril.sh"),
]


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
    print("Seleccione script legado:")
    valid = [p for p in LEGACY_SCRIPTS if p.exists()]
    for i, path in enumerate(valid, start=1):
        print(f"{i}) {path}")
    if not valid:
        print("No hay scripts legados disponibles.")
        return

    idx = int(_input("Opción: ") or "1") - 1
    if idx < 0 or idx >= len(valid):
        print("Opción inválida")
        return

    append_usage("Legacy Launcher", "", "")
    subprocess.run(["bash", str(valid[idx])], check=False)


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
