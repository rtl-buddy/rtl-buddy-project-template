# `verif/demo_alu_accel/` — System-Level Suite

System-level verification of the multi-clock ALU accelerator. Drives
the APB host stub against `demo_alu_accel_top` over two incommensurate
clocks (`apb_clk = 4 ns`, `cclk = 6 ns`) and scoreboards every result
against an inline SV reference that mirrors the sandbox alu spec.

## Why this suite exists

The leaf-level sandbox suites ([`verif/demo_sandbox/`](../sandbox/) and
[`verif/demo_sandbox_cocotb/`](../sandbox_cocotb/)) prove the alu in
isolation. This suite proves the accelerator built up from the IPs:

- [`design/apb/apb_intf.sv`](../../design/apb/apb_intf.sv)
- [`design/common/ip_cdc_sync.sv`](../../design/common/ip_cdc_sync.sv)
- [`design/common/ip_cdc_handshake.sv`](../../design/common/ip_cdc_handshake.sv)
- [`design/common/ip_async_fifo.sv`](../../design/common/ip_async_fifo.sv)
- [`design/demo_alu_accel/demo_alu_accel_csr.sv`](../../design/demo_alu_accel/demo_alu_accel_csr.sv) (PeakRDL-generated)
- [`design/demo_alu_accel/demo_alu_accel_compute.sv`](../../design/demo_alu_accel/demo_alu_accel_compute.sv)
- [`design/demo_alu_accel/demo_alu_accel_top.sv`](../../design/demo_alu_accel/demo_alu_accel_top.sv)

## Tests

```bash
(cd verif/demo_alu_accel && uv run rb test csr_smoke)     # CSR-direct mode
(cd verif/demo_alu_accel && uv run rb test fifo_stream)   # FIFO streaming mode
```

See [`testplan.md`](testplan.md) for objective ↔ coverage ↔ pass-criteria
mapping.
