"""Preproc plugin: generate stimulus + expected results for tb_top.

Runs once per test before compile/sim. Picks a sequence based on the
test's `TEST` plusarg, expands it through `spec/demo_tiny_alu/tiny_alu_model.py`
(the Python golden), and writes a single `vectors.txt` file containing
both stimulus and expected results.

Output format (one line per cycle):
    op,a,b,y,zf,cf,nf,vf

`tb_top.sv` reads the file, drives (op, a, b) one row per clock, and
compares the registered DUT outputs against (y, zf, cf, nf, vf) on the
following cycle. The path to `vectors.txt` is passed in via the new
`VECTORS` plusarg.

Variables provided by rtl_buddy: `logger`, `test_cfg`, `root_cfg`,
`suite_dir`, `artifact_dir`, `__file__`. See `rb docs show
concepts/plugins`.
"""

from __future__ import annotations

import random
import sys
from pathlib import Path

# Locate the golden model relative to suite_dir so this works regardless
# of cwd at runtime.
_SPEC_DIR = Path(suite_dir).resolve().parents[1] / "spec" / "demo_tiny_alu"  # noqa: F821
sys.path.insert(0, str(_SPEC_DIR))
from tiny_alu_model import AluModel, OP_ADD, OP_SUB, OP_XOR, OP_NOP  # noqa: E402


def _seq_basic() -> list[tuple[int, int, int]]:
    return [(i, 0x12, 0x34) for i in range(8)]


def _seq_ops_sweep() -> list[tuple[int, int, int]]:
    return [(i, (i * 11) & 0xFF, (i * 7 + 3) & 0xFF) for i in range(8)]


def _seq_flags() -> list[tuple[int, int, int]]:
    return [
        (OP_ADD, 0x7F, 0x01),  # V-ADD
        (OP_ADD, 0xFF, 0x01),  # C-ADD, Z=1
        (OP_SUB, 0x00, 0x01),  # C-SUB
        (OP_SUB, 0x80, 0x01),  # V-SUB
        (OP_SUB, 0x00, 0x7F),  # N=1
        (OP_XOR, 0x5A, 0x5A),  # Z=1
        (OP_NOP, 0xAA, 0x55),  # NOP
    ]


def _seq_random(seed: int, n: int) -> list[tuple[int, int, int]]:
    r = random.Random(seed)
    return [(r.randrange(0, 8), r.randrange(0, 256), r.randrange(0, 256)) for _ in range(n)]


_BUILDERS = {
    "basic":     lambda _seed, _n: _seq_basic(),
    "ops_sweep": lambda _seed, _n: _seq_ops_sweep(),
    "flags":     lambda _seed, _n: _seq_flags(),
    "random":    _seq_random,
}


def _plusarg(cfg, key: str, default):
    val = cfg.get_plusarg(key) if hasattr(cfg, "get_plusarg") else None
    if val is None:
        return default
    try:
        return int(val)
    except (TypeError, ValueError):
        return val


def _build_vectors(cfg) -> list[tuple]:
    test = cfg.get_plusarg("TEST") or cfg.get_name()
    seed = int(_plusarg(cfg, "SEED", 1))
    cycles = int(_plusarg(cfg, "CYCLES", 256))
    builder = _BUILDERS.get(str(test))
    if builder is None:
        raise ValueError(f"preproc: unknown TEST={test!r}, expected one of {sorted(_BUILDERS)}")
    stim = builder(seed, cycles)
    return [(op, a, b, *AluModel.compute(op, a, b).as_tuple()) for (op, a, b) in stim]


vectors = _build_vectors(test_cfg)  # noqa: F821
out_path = Path(artifact_dir) / "vectors.txt"  # noqa: F821
out_path.parent.mkdir(parents=True, exist_ok=True)
with out_path.open("w") as f:
    f.write("# op,a,b,y,zf,cf,nf,vf\n")
    for row in vectors:
        f.write(",".join(str(x) for x in row) + "\n")

# Pass the absolute path through to tb_top.sv via plusarg
test_cfg.set_plusarg("VECTORS", str(out_path))  # noqa: F821

logger.info("preproc: wrote %d vectors to %s", len(vectors), out_path)  # noqa: F821
