# `verif/demo_tiny_alu_sc/` — SystemC Cosim Suite

The SystemC peer of [`verif/demo_tiny_alu/`](../demo_tiny_alu/) and
[`verif/demo_tiny_alu_cocotb/`](../demo_tiny_alu_cocotb/). Same DUT
([`design/demo_tiny_alu/demo_tiny_alu.sv`](../../design/demo_tiny_alu/demo_tiny_alu.sv)),
different driver — `sc_main()` instantiates the Verilator-generated
`Vdemo_tiny_alu` as an `sc_module`, drives it through `sc_signal<uint32_t>`
ports, and self-checks against an in-line C++ reference for eight directed
opcode vectors.

## How it works

`tests.yaml` declares the testbench with a nested `systemc:` block:

```yaml
testbenches:
  - name: tb_alu_sc
    toplevel: demo_tiny_alu
    filelist: []          # SV sources are pulled from the model's filelist
    systemc:
      sc_main: sc_main.cpp
      cflags: ["-std=c++17"]
```

The presence of `systemc:` flips `rb test` into Verilator's `--sc --exe
--build` cosim path (the same pattern that `cocotb:` uses to flip into
the cocotb path). `cfg-systemc.home` in [`../../root_config.yaml`](../../root_config.yaml)
points at the SystemC install root — `$SYSTEMC_HOME` is used as a
fallback.

## Run it

```sh
cd verif/demo_tiny_alu_sc
uv run rb --machine test basic_sc
# → artefacts/basic_sc/run-0001/{test.log,test.err,test.randseed}
# → log contains the 8 ALU opcode vectors with PASS/FAIL markers
# → exit 0 on PASS (matches the SV and cocotb suites' contract)
```

## Prerequisites

1. **Verilator** with SystemC support — most distributions ship this; if
   you build from source, `--sc` is on by default.
2. **SystemC install** — Accellera reference distribution. Build with
   `cmake -DENABLE_PTHREADS=ON ..` on macOS arm64 to avoid the QuickThreads
   `__sanitizer_*` link error (the CMake variable name is `ENABLE_PTHREADS`,
   not `SC_USE_PTHREADS`).
3. **Compiler ABI parity** — the `g++` used to build the cosim binary must
   match the one used to build `libsystemc.a` (libstdc++ vs libc++, GCC vs
   clang version). Pin it via `cfg-systemc.cxx` in `root_config.yaml`.
4. **`$SYSTEMC_HOME` exported** (or override `cfg-systemc.home` in
   `root_config.yaml`). The block ships enabled with `home: ${SYSTEMC_HOME}`;
   `rb test` only fails when the env var is unset *and* you actually run
   a SystemC test, so clones that never touch SystemC are unaffected.

## Why a SystemC peer

`tb_top.sv` (LVM) covers reset / FSM corners with SV constructs. The
cocotb peer runs Python-side randomised stimulus with a live golden. This
SystemC peer demonstrates the third workflow: a C++ harness suitable for
binding to TLM-2.0 reference models, AXI initiators, or pre-existing
SystemC VIP — the use-cases where SV or Python harnesses are awkward.

All three flows go through `rb test` / `rb regression` and produce
identical artefact layouts.
