# Vistas de ejecución - Viernes CLI single-file

## 1) Vista previa de interfaz completa (ASCII + menú)

```bash
python3 viernes_cli_single.py --preview-ui
```

```text
 __      ___                           
 \ \    / (_)            GNW Team      
  \ \  / / _  ___ _ __ _ __   ___  ___ 
   \ \/ / | |/ _ \ '__| '_ \ / _ \/ __|
    \  /  | |  __/ |  | | | |  __/\__
     \/   |_|\___|_|  |_| |_|\___||___/ 
Viernes Toolkit CLI (Python | Single File)
Usa ↑/↓ para navegar, Enter para seleccionar, q para salir.

[L11 Tools]
   1) Activar K2V4
   2) SW Autoconfig
   3) Rack Information
   4) PCIe Verification
[MLA Tools]
   5) Ejecutar UART Tool
   6) Proxy Cards Check
   7) Verificación de K2V5 card type
   8) Limpiar eventos (SEL Clear)
   9) Mostrar Sensor List
  10) Sel Clear + VPD
  11) Imprimir FRU
  12) Verificar BMC Network
  13) Clear DHCP + VPD
  14) Check IPV4 (extend)
[Power]
  15) BMC Reboot
  16) Sol Activate
[Debug]
  17) Issue TT2_K2V4_KEG_SYNC
[Others]
  18) Opinión/Sugerencias de Tools
  19) Node Information | Buscar unidad
[Compatibilidad]
  99) Legacy Launcher (scripts originales)
[Sistema]
  20) Salir

Nota: En ejecución real, el menú es interactivo con curses.
```

## 2) Vista compacta de menú

```bash
python3 viernes_cli_single.py --print-menu
```

```text
 1) [L11 Tools] Activar K2V4
 2) [L11 Tools] SW Autoconfig
 3) [L11 Tools] Rack Information
 4) [L11 Tools] PCIe Verification
 5) [MLA Tools] Ejecutar UART Tool
 6) [MLA Tools] Proxy Cards Check
 7) [MLA Tools] Verificación de K2V5 card type
 8) [MLA Tools] Limpiar eventos (SEL Clear)
 9) [MLA Tools] Mostrar Sensor List
10) [MLA Tools] Sel Clear + VPD
11) [MLA Tools] Imprimir FRU
12) [MLA Tools] Verificar BMC Network
13) [MLA Tools] Clear DHCP + VPD
14) [MLA Tools] Check IPV4 (extend)
15) [Power] BMC Reboot
16) [Power] Sol Activate
17) [Debug] Issue TT2_K2V4_KEG_SYNC
18) [Others] Opinión/Sugerencias de Tools
19) [Others] Node Information | Buscar unidad
99) [Compatibilidad] Legacy Launcher (scripts originales)
20) [Sistema] Salir
```
