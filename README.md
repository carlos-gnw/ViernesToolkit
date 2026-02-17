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

## Versión de un solo archivo

Si tu servidor requiere un despliegue en un único archivo, usa:

```bash
python3 viernes_cli_single.py
```

Este script incluye en el mismo archivo la configuración, UI, acciones y utilidades.
Mantiene enlaces/rutas a dependencias externas del entorno (por ejemplo `getip_viernes`,
`dbconsult.sh` y scripts legacy) para conservar compatibilidad operativa.

Además, para mantener **cobertura funcional completa** respecto al script Bash legado,
las opciones no implementadas de forma nativa se ejecutan automáticamente en el backend
legacy, preseleccionando la opción elegida desde el menú Python.


### Vistas de ejecución (preview)

Para ver cómo se verá el programa en consola (incluyendo título ASCII y menú agrupado):

```bash
python3 viernes_cli_single.py --preview-ui
```

Y para una vista compacta del menú:

```bash
python3 viernes_cli_single.py --print-menu
```


## Troubleshooting

### Error: `SyntaxError: future feature annotations is not defined`

Ese error aparece cuando se ejecuta el script con una versión de Python que no soporta
`from __future__ import annotations` (típicamente Python 3.6 o menor).

Soluciones:

- Ejecuta con una versión más nueva de Python (recomendado 3.8+).
- Usa el archivo actualizado `viernes_cli_single.py`, que ya se ajustó para mayor compatibilidad.
- Verifica que el nombre del archivo sea correcto al ejecutar:

```bash
python3 viernes_cli_single.py
```
