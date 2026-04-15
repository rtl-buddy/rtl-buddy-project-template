# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

# test_tb_top.py (simple)

import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def my_first_test(dut):
    """Try accessing the design."""

    dut.coco_v.value = 0
    dut.coco_d.value = 15

    for _ in range(5):
        dut.u.value = 0
        await Timer(1, unit="ns")
        dut.u.value = 1
        await Timer(1, unit="ns")

    cocotb.log.info("u is %s", dut.u.value)
    assert dut.u.value == 1


# test_tb_top.py (extended)

import cocotb
from cocotb.triggers import FallingEdge, Timer


async def generate_clock(dut):
    """Generate clock pulses."""

    for _ in range(10):
        dut.coco_clk.value = 0
        await Timer(1, unit="ns")
        dut.coco_clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def my_second_test(dut):
    """Try accessing the design."""

    dut.coco_v.value = 1
    dut.coco_d.value = 8

    cocotb.log.info("coco_clk starting soon")
    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    await Timer(1, unit="ns")  # wait a bit
    cocotb.log.info("coco_clk started 1 ns ago")
    await FallingEdge(dut.coco_clk)  # wait for falling edge/"negedge"

    cocotb.log.info("u is %s", dut.u.value)
    assert dut.u.value == 1

    await Timer(5, unit="ns")  # wait a bit

    # synchronize to end of dut.main test thread
    await FallingEdge(dut.main_run)
