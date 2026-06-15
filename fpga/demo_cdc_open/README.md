# demo_cdc_open — open FPGA flow

End-to-end demo of taking the portable CDC block in
[`../../design/demo_cdc_open/`](../../design/demo_cdc_open/) through a
**fully open, license-free** FPGA implementation flow, while keeping the
RTL vendor-neutral. Counterpart to the ASIC-leaning demos — this one
exercises the FPGA / CDC path with no proprietary tools.

The flow has two halves:

1. **Recognition** — `rb cdc` (open `rtl-buddy-cdc` backend) reads the
   synchronizer structures + the async SDC and reports every crossing safe.
2. **Open implementation** — `rb fpga tool: openxc7` runs the block through
   **Yosys → nextpnr-xilinx → prjxray** for a free Artix-7 part
   (`xc7a35tcsg324-1`, Arty A7-35), producing structured
   utilisation/timing as machine-mode JSON.

No Vivado, no license server, no vendor-specific RTL (no XPM, no UNISIM) —
see the design README for the portability story.

## Prerequisites

The open toolchain (optional — runs SKIP cleanly when absent):

- `yosys` and `nextpnr-xilinx` on `PATH`.
- A nextpnr chipdb for the part, located via `$CHIPDB/<part>.bin` (set
  `CHIPDB` to the directory holding `xc7a35tcsg324-1.bin`) or pinned with
  `tool_overrides.openxc7.chipdb` in `fpga.yaml`.
- prjxray (`fasm2frames`, `xc7frames2bit`) and `$PRJXRAY_DB_DIR` — only
  needed for `--bitstream`.

Install via the [openXC7 toolchain installer](https://github.com/openXC7/toolchain-installer),
or — in this template's reference environment — `make openxc7` in the
shared tools repo, which builds the chain and exports `CHIPDB` /
`PRJXRAY_DB_DIR`. `rb tool-check` reports `yosys`, `nextpnr-xilinx`, and
`prjxray` individually.

## Steps

```bash
# 1. Recognition — crossings reported safe (no FPGA toolchain needed)
uv run rb --machine cdc demo_cdc_open_lint -c lint/cdc/cdc.yaml

# 2. Open implementation — utilisation + timing as JSON
uv run rb --machine fpga -c fpga/demo_cdc_open/fpga.yaml

# List runs without executing
uv run rb fpga --list -c fpga/demo_cdc_open/fpga.yaml

# As part of the FPGA regression (reglvl-gated)
uv run rb --machine fpga-regression -c fpga_regression.yaml -l 1000
```

## Reading the result

The machine JSON carries the open flow's metric subset: `lut`/`ff`/`bram`/
`dsp` utilisation, `fmax_mhz`, `wns_ns`, `timing_met`, and `failing_paths`.
Metrics the open flow cannot produce (power, DRC, TNS/WHS) are simply
absent — never fabricated. Because `clk_a`/`clk_b` are declared
asynchronous, the CDC paths are excluded from timing and `wns_ns` reflects
the real intra-domain logic.

See the `rb fpga` / openXC7 documentation in the `rtl_buddy` docs
(`concepts/fpga.md`) for the backend details and the timing-closure loop.

## Out of scope

- **Bitstream** is off by default (`--bitstream` adds it where the open
  flow reports it); the demo targets recognise → implement → timing.
- **Scoped-XDC generate + audit** (`rb cdc --emit-constraints` /
  `--check-xdc`) is deferred to a follow-up once those features ship.
- **Vivado / `report_cdc` vendor cross-check** is proprietary and
  demonstrated outside this open template.
