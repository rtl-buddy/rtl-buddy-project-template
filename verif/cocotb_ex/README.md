# Cocotb Example

This suite demonstrates the `rtl_buddy` cocotb integration. The testbench entry
in `tests.yaml` uses `toplevel:` and `cocotb.module`, so `rb test` compiles the
RTL with Verilator VPI support, runs the Python cocotb test module, and parses
`cocotb_results.xml` into the normal `rtl_buddy` pass/fail result.

Before running, make sure the project environment is available:

```bash
uv sync --locked --python 3.11
```

## Run via `rtl_buddy`

From this directory:

```bash
uv run rb test basic
```

From the repository root:

```bash
uv run rb regression
```
