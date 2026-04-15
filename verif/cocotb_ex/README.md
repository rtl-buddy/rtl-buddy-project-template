# Cocotb Example

Before running, make sure the project environment is available. Prefer `uv run ...` from the repo root, or run commands through `.venv/bin/...` after `uv sync`.
This example is not integrated with `rtl_buddy` at the moment.

## Run via `run_verilator.zsh`

To run verilator directly, run the following cmd in this dir:

    source run_verilator.zsh

## Run via Makefile

To run cocotb regression via Makefile flow, run the following cmd in this dir:

    make

## Run via `test_runner`

To run cocotb tests via Python, run the following cmd in this dir:

    python3 test_runner.py
