# `verif/demo_tiny_alu_subsys/` — System-Level Suite

System-level verification of the multi-clock ALU accelerator. Drives
the APB host stub against `demo_tiny_alu_subsys_top` over two incommensurate
clocks (`apb_clk = 4 ns`, `cclk = 6 ns`) and scoreboards every result
against an inline SV reference that mirrors the sandbox alu spec.

## Why this suite exists

The leaf-level tiny ALU suites ([`verif/demo_tiny_alu/`](../demo_tiny_alu/) and
[`verif/demo_tiny_alu_cocotb/`](../demo_tiny_alu_cocotb/)) prove the ALU in
isolation. This suite proves the accelerator built up from the IPs:

- [`design/apb/apb_intf.sv`](../../design/apb/apb_intf.sv)
- [`design/common/ip_cdc_sync.sv`](../../design/common/ip_cdc_sync.sv)
- [`design/common/ip_cdc_handshake.sv`](../../design/common/ip_cdc_handshake.sv)
- [`design/common/ip_async_fifo.sv`](../../design/common/ip_async_fifo.sv)
- [`design/demo_tiny_alu_subsys/demo_tiny_alu_subsys_csr.sv`](../../design/demo_tiny_alu_subsys/demo_tiny_alu_subsys_csr.sv) (PeakRDL-generated)
- [`design/demo_tiny_alu_subsys/demo_tiny_alu_subsys_compute.sv`](../../design/demo_tiny_alu_subsys/demo_tiny_alu_subsys_compute.sv)
- [`design/demo_tiny_alu_subsys/demo_tiny_alu_subsys_top.sv`](../../design/demo_tiny_alu_subsys/demo_tiny_alu_subsys_top.sv)

## Tests

```bash
(cd verif/demo_tiny_alu_subsys && uv run rb test csr_smoke)     # CSR-direct mode
(cd verif/demo_tiny_alu_subsys && uv run rb test fifo_stream)   # FIFO streaming mode
```

See [`testplan.md`](testplan.md) for objective ↔ coverage ↔ pass-criteria
mapping.
