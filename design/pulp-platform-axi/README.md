# pulp-platform AXI interconnect example

Vendored AXI4 interconnect IP from
[`pulp-platform/axi`](https://github.com/pulp-platform/axi), wired into the
template as a worked example of how to integrate third-party RTL with
`rtl_buddy` and Verilator.

## Layout

```
design/pulp-platform-axi/
  pp_axi.f             — full AXI src filelist (Bender compile order)
  axi_common_cells.f   — common_cells subset required by axi (25 files)
  pp_axi.vlt           — Verilator lint waivers scoped to vendor code
  models.yaml          — pp_axi model entry for rtl_buddy

verif/pulp-platform-axi/
  tb_axi_fifo_simple.sv  — Verilator-compatible directed testbench for axi_fifo_intf
  tb_top.sv              — elaboration-only wrapper for axi_synth_bench
  tests.yaml             — axi_fifo_simple + synth_bench tests

vendor/pulp-platform/
  axi/                   — submodule
  common_cells/          — submodule
  common_verification/   — submodule (sim-only utilities)
```

## Why this layout

- `axi_common_cells.f` is a curated subset of common_cells in dependency-level
  order. It excludes `tech_cells_generic` (not needed for the axi subset) and
  `common_verification` (sim-only).
- `pp_axi.vlt` waives Verilator warnings that are inherent to the vendor code
  (GENUNNAMED, SYNCASYNCNET, UNDRIVEN, ASCRANGE, UNOPTFLAT, UNSIGNED, IMPLICIT)
  but only inside `*/pulp-platform/*`. Your own RTL stays under full lint.

## Tests

```bash
# Quick functional check: directed FIFO test, all 11 checks pass
cd verif/pulp-platform-axi
uv run rb test axi_fifo_simple

# Elaboration sweep: every adapter variant in axi_synth_bench
uv run rb test synth_bench
```

`synth_bench` defines `SYNTHESIS=1` to silence vendor sim-only initial-block
assumptions (e.g. `axi_to_detailed_mem` `$fatal` at t=0) that fire for some
parameter combinations in the synth bench. The test verifies clean elaboration
of every adapter variant, not run-time behaviour.

## Verilator limitation: `tb_axi_fifo` (vendor OOP test)

The vendor `tb_axi_fifo` in `vendor/pulp-platform/axi/test/tb_axi_fifo.sv` uses
`axi_test.sv` OOP classes (nested class type parameters such as
`rand_id_queue #(.data_t(axi_driver_t::ax_beat_t))`). Verilator cannot resolve
nested class types as type parameters, so that test requires a full-OOP
simulator (Questa/VCS). It is omitted from `tests.yaml` for this Verilator-first
template; `tb_axi_fifo_simple.sv` is a directed alternative that exercises
`axi_fifo_intf` over the `AXI_BUS` interface directly.

## Setup

After cloning, initialise the vendor submodules once:

```bash
git submodule update --init --recursive
```
