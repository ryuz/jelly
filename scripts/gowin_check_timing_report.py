#!/usr/bin/env python3
"""Check Gowin timing report.

This tool is intentionally quiet:
- Prints only when timing is not converged.
- Prints nothing for converged or parse/missing-file cases.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


LABEL_SETUP = "Numbers of Setup Violated Endpoints"
LABEL_HOLD = "Numbers of Hold Violated Endpoints"

# ANSI color used only for unconverged warning.
C_RESET = "\033[0m"
C_YELLOW = "\033[33;1m"
C_GREEN = "\033[32;1m"


def parse_violated_endpoints(html_text: str, label: str) -> int | None:
    # The Gowin report uses a label <td> followed by another <td> with the value.
    pattern = re.compile(
        rf"<td[^>]*>\s*{re.escape(label)}\s*</td>\s*<td[^>]*>\s*([0-9]+)\s*</td>",
        re.IGNORECASE | re.DOTALL,
    )
    m = pattern.search(html_text)
    if not m:
        return None
    return int(m.group(1))


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        return 2

    report_path = Path(argv[1])
    if not report_path.is_file():
        return 2

    try:
        text = report_path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return 2

    setup = parse_violated_endpoints(text, LABEL_SETUP)
    hold = parse_violated_endpoints(text, LABEL_HOLD)

    if setup is None or hold is None:
        return 2

    if setup > 0 or hold > 0:
        print(
            f"{C_YELLOW}[TIMING CHECK] WARNING: timing not converged "
            f"(setup_violated_endpoints={setup}, hold_violated_endpoints={hold}){C_RESET}"
        )
        return 1

#   print(f"{C_GREEN}[TIMING CHECK] OK: timing converged{C_RESET}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
