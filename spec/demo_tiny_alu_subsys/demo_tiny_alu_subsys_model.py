"""System-level golden reference for the demo_tiny_alu_subsys block.

Wraps `tiny_alu_model.AluModel` with the simple semantics of the
accelerator: each accepted (op, a, b) eventually emits one
`AluResult` regardless of whether it came in via the CSR-direct path
or the streaming FIFO. Used by the demo_tiny_alu_subsys build_report (post-run
replay) and by the cocotb suite when added.

Pure Python. No rtl_buddy / cocotb dependencies."""

from __future__ import annotations

import sys
from pathlib import Path

# Reuse the sandbox golden — single source of truth for ALU op semantics
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "sandbox"))
from tiny_alu_model import AluModel, AluResult, OP_NAMES  # noqa: F401,E402


def replay(ops: list[tuple[int, int, int]]) -> list[AluResult]:
    return [AluModel.compute(op, a, b) for (op, a, b) in ops]
