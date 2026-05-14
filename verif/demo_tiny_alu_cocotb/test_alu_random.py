"""cocotb cosim — 256 random ops scoreboarded against tiny_alu_model.py."""

from __future__ import annotations

import os
import random

import cocotb

from _alu_common import drive, reset_and_clock


@cocotb.test()
async def cocotb_random(dut):
    seed = int(os.environ.get("RANDOM_SEED", "1"))
    random.seed(seed)
    await reset_and_clock(dut)
    stim = [(random.randint(0, 7), random.randint(0, 0xFF), random.randint(0, 0xFF))
            for _ in range(256)]
    await drive(dut, stim)
