"""Sandbox DV report builder.

Walks `artefacts/<test>/` produced by an `rb regression` / `rb test`
run and emits a per-test markdown report plus a roll-up
`report/index.md`. Each report visualizes the test outcome against
its declared objective and embeds a Surfer waveform PNG captured in
headless mode.

This script does **not** verify correctness — checking is handled
inside the simulator: `verif/demo_tiny_alu/preproc.py` expands stimulus
through `spec/demo_tiny_alu/tiny_alu_model.py` (the Python golden) and the
SV testbench compares per-cycle. The PASS/FAIL line in
`<artefacts>/<test>/test.log` is the authoritative signal.

Run from the suite directory after a regression:

    cd verif/demo_tiny_alu
    uv run rb -M debug regression -c ../../regression.yaml
    uv run python build_report.py
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
SUITE_DIR = Path(__file__).resolve().parent
ARTEFACTS = SUITE_DIR / "artefacts"
REPORT_DIR = SUITE_DIR / "report"

SURFER_LAYOUT = SUITE_DIR / "tb_top.surfer"
SURFER_BIN = shutil.which("surfer")

PASS_RE = re.compile(r"^PASS\b")
FAIL_RE = re.compile(r"^FAIL\b")
NERR_RE = re.compile(r"\(nerr=\s*(\d+)")


@dataclass
class TestOutcome:
    name: str
    status: str               # "PASS" | "FAIL" | "UNKNOWN"
    note: str
    log_tail: list[str]
    fst: Path | None
    screenshot: Path | None


def _find(root: Path, name: str) -> Path | None:
    if not root.exists():
        return None
    for p in root.rglob(name):
        return p
    return None


def _read_status(test_dir: Path) -> tuple[str, str, list[str]]:
    log = _find(test_dir, "test.log")
    if not log:
        return ("UNKNOWN", "test.log missing", [])
    lines = log.read_text(errors="replace").splitlines()
    tail = lines[-12:]
    for line in reversed(lines):
        if PASS_RE.match(line):
            return ("PASS", line.strip(), tail)
        if FAIL_RE.match(line):
            m = NERR_RE.search(line)
            note = line.strip() if not m else f"FAIL (nerr={m.group(1)})"
            return ("FAIL", note, tail)
    return ("UNKNOWN", "no PASS/FAIL line in test.log", tail)


def _capture_waveform(test: str, fst: Path) -> Path | None:
    if not (SURFER_BIN and SURFER_LAYOUT.exists()):
        return None
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    png = REPORT_DIR / f"{test}.png"
    cmd_file = REPORT_DIR / f"{test}.cmds"
    cmd_file.write_text(SURFER_LAYOUT.read_text() + f"\nexport_wave {png} 1600 600\n")
    try:
        subprocess.run(
            [SURFER_BIN, "--headless", "-c", str(cmd_file), str(fst)],
            check=True, capture_output=True, timeout=60,
        )
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return None
    return png if png.exists() else None


def collect(test_name: str) -> TestOutcome:
    test_dir = ARTEFACTS / test_name
    status, note, tail = _read_status(test_dir)
    fst = _find(test_dir, "dump.fst")
    png = _capture_waveform(test_name, fst) if fst else None
    return TestOutcome(test_name, status, note, tail, fst, png)


def render_test(o: TestOutcome, desc: str, covers: list[str]) -> Path:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    out = REPORT_DIR / f"{o.name}.md"
    lines = [
        f"# {o.name} — {o.status}",
        "",
        f"**Objective:** {desc}",
        "",
        f"- Status: **{o.status}** — {o.note}",
        f"- Coverage targets: {', '.join(f'`{c}`' for c in covers) if covers else '_none declared_'}",
        f"- FST waveform: `{o.fst}`" if o.fst else "- FST waveform: _missing_",
        "",
    ]
    if o.screenshot:
        lines += [f"![{o.name} waveform]({o.screenshot.name})", ""]
    elif SURFER_BIN is None:
        lines += ["_Surfer not on PATH — skipped headless capture._", ""]
    elif o.fst is None:
        lines += ["_No FST waveform captured (test did not run in a trace-enabled mode)._", ""]
    if o.log_tail:
        lines += ["## test.log tail", "", "```"] + o.log_tail + ["```", ""]
    out.write_text("\n".join(lines))
    return out


def render_index(rows: list[tuple[TestOutcome, str, list[str]]]) -> Path:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    out = REPORT_DIR / "index.md"
    body = ["| Test | Status | Objective | Coverage IDs |", "|---|---|---|---|"]
    for o, desc, covers in rows:
        body.append(
            f"| [{o.name}]({o.name}.md) | {o.status} | {desc} | "
            f"{', '.join(f'`{c}`' for c in covers) if covers else '—'} |"
        )
    out.write_text("# Sandbox DV Report\n\n" + "\n".join(body) + "\n")
    return out


def main() -> int:
    cfg = yaml.safe_load((SUITE_DIR / "tests.yaml").read_text())
    rows: list[tuple[TestOutcome, str, list[str]]] = []
    for t in cfg.get("tests", []):
        outcome = collect(t["name"])
        render_test(outcome, t.get("desc", ""), t.get("covers", []) or [])
        rows.append((outcome, t.get("desc", ""), t.get("covers", []) or []))
        print(f"{outcome.name}: {outcome.status}")
    print(f"index: {render_index(rows)}")
    return 0 if all(o.status == "PASS" for o, *_ in rows) else 1


if __name__ == "__main__":
    sys.exit(main())
