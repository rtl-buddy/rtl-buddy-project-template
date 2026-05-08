"""Sandbox DV report builder.

Walks `artefacts/<test>/` produced by an `rb regression`/`rb test` run,
replays each test's transaction log through the Python golden model
(`spec/sandbox/sandbox_model.py`), captures a Surfer screenshot of the
test waveform in headless mode, and emits a per-test markdown report
plus a roll-up `report/index.md`.

Run from the suite directory after a regression:

    cd verif/sandbox
    uv run rb -M debug regression -c ../../regression.yaml
    uv run python build_report.py

Custom rtl_buddy postproc plugins are not yet supported (see
`rb docs show concepts/plugins`), so this is invoked manually.
"""

from __future__ import annotations

import csv
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SUITE_DIR = Path(__file__).resolve().parent
ARTEFACTS = SUITE_DIR / "artefacts"
REPORT_DIR = SUITE_DIR / "report"

# Make the spec module importable regardless of where this script is run from
sys.path.insert(0, str(REPO_ROOT / "spec" / "sandbox"))
from sandbox_model import AluModel, OP_NAMES  # noqa: E402

SURFER_LAYOUT = SUITE_DIR / "tb_top.surfer"
SURFER_BIN = shutil.which("surfer")


@dataclass
class ReplayResult:
    test: str
    txns: int
    mismatches: list[str]
    fst_path: Path | None
    screenshot: Path | None

    @property
    def passed(self) -> bool:
        return not self.mismatches


def replay(test_dir: Path, test_name: str) -> ReplayResult:
    txn_log = _find(test_dir, "txn.log")
    fst = _find(test_dir, "dump.fst")
    screenshot = REPORT_DIR / f"{test_name}.png"
    mismatches: list[str] = []
    txns = 0
    if not txn_log:
        return ReplayResult(test_name, 0, ["txn.log missing"], fst, None)
    with txn_log.open() as f:
        reader = csv.reader(line for line in f if not line.startswith("#"))
        for row in reader:
            if len(row) != 9:
                continue
            cycle, op, a, b, y, zf, cf, nf, vf = (int(x) for x in row)
            txns += 1
            ref = AluModel.compute(op, a, b)
            got = (y, zf, cf, nf, vf)
            if got != ref.as_tuple():
                mismatches.append(
                    f"cycle={cycle} op={OP_NAMES.get(op, op)} a={a:#x} b={b:#x} "
                    f"dut={got} ref={ref.as_tuple()}"
                )

    if fst and SURFER_BIN and SURFER_LAYOUT.exists():
        REPORT_DIR.mkdir(parents=True, exist_ok=True)
        cmd_file = REPORT_DIR / f"{test_name}.cmds"
        cmd_file.write_text(
            SURFER_LAYOUT.read_text()
            + f"\nexport_wave {screenshot} 1600 600\n"
        )
        try:
            subprocess.run(
                [SURFER_BIN, "--headless", "-c", str(cmd_file), str(fst)],
                check=True, capture_output=True, timeout=60,
            )
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            mismatches.append(f"surfer headless capture failed: {e}")
            screenshot = None

    return ReplayResult(test_name, txns, mismatches, fst,
                        screenshot if screenshot and screenshot.exists() else None)


def _find(root: Path, name: str) -> Path | None:
    if not root.exists():
        return None
    for p in root.rglob(name):
        return p
    return None


def render_test(r: ReplayResult, covers: list[str]) -> Path:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    out = REPORT_DIR / f"{r.test}.md"
    status = "PASS" if r.passed else "FAIL"
    lines = [
        f"# {r.test} — {status}",
        "",
        f"- Transactions replayed against Python golden: **{r.txns}**",
        f"- Mismatches vs `sandbox_model.py`: **{len(r.mismatches)}**",
        f"- Spec coverage targets: {', '.join(f'`{c}`' for c in covers) if covers else '_none declared_'}",
        f"- FST waveform: `{r.fst_path}`" if r.fst_path else "- FST waveform: _missing_",
        "",
    ]
    if r.screenshot:
        rel = r.screenshot.name
        lines += [f"![{r.test} waveform]({rel})", ""]
    elif SURFER_BIN is None:
        lines += ["_Surfer not on PATH — skipped headless capture._", ""]
    if r.mismatches:
        lines += ["## Divergences", "", "```"] + r.mismatches[:32] + ["```", ""]
    out.write_text("\n".join(lines))
    return out


def render_index(results: list[tuple[ReplayResult, list[str]]]) -> Path:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    out = REPORT_DIR / "index.md"
    rows = ["| Test | Status | Txns | Coverage IDs |", "|---|---|---|---|"]
    for r, covers in results:
        rows.append(
            f"| [{r.test}]({r.test}.md) | "
            f"{'PASS' if r.passed else 'FAIL'} | "
            f"{r.txns} | "
            f"{', '.join(f'`{c}`' for c in covers) if covers else '—'} |"
        )
    out.write_text("# Sandbox DV Report\n\n" + "\n".join(rows) + "\n")
    return out


def main() -> int:
    import yaml
    tests_yaml = SUITE_DIR / "tests.yaml"
    cfg = yaml.safe_load(tests_yaml.read_text())
    results: list[tuple[ReplayResult, list[str]]] = []
    for t in cfg.get("tests", []):
        name = t["name"]
        covers = t.get("covers", []) or []
        test_dir = ARTEFACTS / name
        r = replay(test_dir, name)
        render_test(r, covers)
        results.append((r, covers))
        print(f"{name}: {'PASS' if r.passed else 'FAIL'} ({r.txns} txns)")
    idx = render_index(results)
    print(f"index: {idx}")
    return 0 if all(r.passed for r, _ in results) else 1


if __name__ == "__main__":
    sys.exit(main())
