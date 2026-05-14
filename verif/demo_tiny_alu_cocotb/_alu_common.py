"""Shared helpers for the sandbox cocotb cosim tests."""

from __future__ import annotations

import sys
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

_SPEC_DIR = Path(__file__).resolve().parents[2] / "spec" / "demo_tiny_alu"
sys.path.insert(0, str(_SPEC_DIR))
from tiny_alu_model import AluModel, OP_NAMES  # noqa: E402,F401


async def reset_and_clock(dut, period_ns: int = 2):
    cocotb.start_soon(Clock(dut.clk, period_ns, units="ns").start())
    dut.rst.value = 1
    dut.op.value = 7
    dut.a.value = 0
    dut.b.value = 0
    for _ in range(4):
        await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)


def _check(dut, op: int, a: int, b: int) -> str | None:
    ref = AluModel.compute(op, a, b)
    got = (
        int(dut.y.value),
        int(dut.zf.value),
        int(dut.cf.value),
        int(dut.nf.value),
        int(dut.vf.value),
    )
    if got != ref.as_tuple():
        return (f"op={OP_NAMES.get(op, op)} a={a:#x} b={b:#x} "
                f"dut={got} ref={ref.as_tuple()}")
    return None


async def drive(dut, stimuli: list[tuple[int, int, int]]):
    """Drive (op,a,b) sequence; check the previous sample one cycle later
    to match the DUT's registered output."""
    prev: tuple[int, int, int] | None = None
    mismatches: list[str] = []
    for op, a, b in stimuli:
        dut.op.value = op
        dut.a.value = a
        dut.b.value = b
        await RisingEdge(dut.clk)
        if prev is not None:
            err = _check(dut, *prev)
            if err:
                mismatches.append(err)
        prev = (op, a, b)
    await RisingEdge(dut.clk)
    if prev is not None:
        err = _check(dut, *prev)
        if err:
            mismatches.append(err)
    assert not mismatches, "cosim mismatches:\n  " + "\n  ".join(mismatches)
