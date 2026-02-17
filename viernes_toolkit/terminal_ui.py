from __future__ import annotations

import curses
from typing import Sequence


def _draw(stdscr: curses.window, title: str, items: Sequence[dict], index: int) -> None:
    stdscr.clear()
    h, w = stdscr.getmaxyx()
    stdscr.addstr(1, 2, title, curses.A_BOLD)
    stdscr.addstr(2, 2, "Usa ↑/↓ para navegar, Enter para seleccionar, q para salir.")

    y = 4
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
