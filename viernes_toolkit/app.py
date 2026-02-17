from __future__ import annotations

from .actions import HANDLERS, option_generic
from .config import load_menu
from .system import validate_access
from .terminal_ui import choose_option


def run() -> None:
    validate_access()
    menu = load_menu()

    while True:
        selected = choose_option("Viernes Toolkit CLI (Python)", menu)
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
                option_generic(f"{option_id} ({selected['label']})")
        except KeyboardInterrupt:
            print("\nOperación cancelada por usuario.")
        except Exception as exc:
            print(f"Error no controlado: {exc}")

        input("\nPresiona Enter para regresar al menú...")
