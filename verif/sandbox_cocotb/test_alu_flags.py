"""cocotb cosim — directed flag corners (C, V for ADD/SUB)."""

from __future__ import annotations

import cocotb

from _alu_common import drive, reset_and_clock
from sandbox_model import OP_ADD, OP_SUB


@cocotb.test()
async def cocotb_flags(dut):
    await reset_and_clock(dut)
    stim = [
        (OP_ADD, 0x7F, 0x01),  # V-ADD
        (OP_ADD, 0xFF, 0x01),  # C-ADD, Z=1
        (OP_SUB, 0x00, 0x01),  # C-SUB
        (OP_SUB, 0x80, 0x01),  # V-SUB
        (OP_SUB, 0x00, 0x7F),  # N=1
    ]
    await drive(dut, stim)
