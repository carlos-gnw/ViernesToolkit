# Viernes Toolkit CLI (Python)

Migración del toolkit a una CLI modular en Python estándar (sin dependencias externas).

## Ejecutar

```bash
python3 viernes_cli.py
```

## Características

- Menú navegable con flechas (↑/↓) y Enter vía `curses`.
- Arquitectura modular (`config`, `terminal_ui`, `actions`, `system`, `app`).
- Configuración de menú en archivo externo JSON (`data/menu.json`).
- Registro de uso en CSV.
- Compatibilidad mediante `Legacy Launcher` para correr scripts originales.

## Estructura

- `viernes_cli.py`: punto de entrada.
- `viernes_toolkit/app.py`: orquestación principal.
- `viernes_toolkit/terminal_ui.py`: menú interactivo.
- `viernes_toolkit/actions.py`: acciones de negocio.
- `viernes_toolkit/system.py`: utilidades del sistema.
- `data/menu.json`: definición externa del menú.
