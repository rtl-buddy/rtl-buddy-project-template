# APB Testplan

Compile + smoke for the APB SystemVerilog interface
([`design/apb/apb_intf.sv`](../../design/apb/apb_intf.sv)). Real APB
protocol coverage closes through [`verif/demo_alu_accel/`](../demo_alu_accel/);
this suite exists so the IP block stands on its own with a runnable
test, modport contract, and named coverage.

## Tests

| Test    | Stimulus                                      | Coverage targets                                              |
|---------|-----------------------------------------------|---------------------------------------------------------------|
| `smoke` | write + read + 1-cycle stall + pslverr at 0xF0| `APB-IF-WRITE`, `APB-IF-READ`, `APB-IF-STALL`, `APB-IF-PSLVERR`|

## Pass criteria

1. Modport contract compiles cleanly under Verilator (lint-clean).
2. Manager-side `apb_write`/`apb_read` tasks complete for normal addresses.
3. Read at `0xF0` reports `pslverr=1` (stub error response).
4. LVM `nerr == 0` at end of test.
