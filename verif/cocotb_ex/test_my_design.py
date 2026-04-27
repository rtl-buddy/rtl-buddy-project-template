import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


@cocotb.test()
async def accumulates_valid_data(dut):
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())

    dut.rst_n.value = 0
    dut.valid_i.value = 0
    dut.data_i.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    dut.rst_n.value = 1
    for value in [1, 3, 5]:
        dut.valid_i.value = 1
        dut.data_i.value = value
        await RisingEdge(dut.clk)

    dut.valid_i.value = 0
    dut.data_i.value = 9
    await RisingEdge(dut.clk)

    assert int(dut.count_o.value) == 9
