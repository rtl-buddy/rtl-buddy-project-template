# demo_cdc_open — open FPGA flow

End-to-end demo of taking the portable CDC block in
[`../../design/demo_cdc_open/`](../../design/demo_cdc_open/) through a
**fully open, license-free** FPGA implementation flow, while keeping the
RTL vendor-neutral. Counterpart to the ASIC-leaning demos — this one
exercises the FPGA / CDC path with no proprietary tools.

The flow has three halves:

1. **Recognition** — `rb cdc` (open `rtl-buddy-cdc` backend) reads the
   synchronizer structures + the async SDC and reports every crossing safe.
2. **Generate → audit** — `rb cdc --emit-constraints --scoped` derives the
   per-synchronizer timing exceptions from that verified crossing set (so the
   constraints ride with the IP instead of being hand-written), and
   `rb cdc --check-xdc` confirms the top + generated XDC cover every crossing
   with zero over-waive. See [The scoped constraint loop](#the-scoped-constraint-loop).
3. **Open implementation** — `rb fpga tool: openxc7` runs the block through
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

# 2. Generate + audit the scoped CDC exceptions (no FPGA toolchain needed)
RB="uv run rtl-buddy" bash lint/cdc/check_cdc_xdc.sh

# 3. Open implementation — utilisation + timing as JSON
uv run rb --machine fpga -c fpga/demo_cdc_open/fpga.yaml

# List runs without executing
uv run rb fpga --list -c fpga/demo_cdc_open/fpga.yaml

# As part of the FPGA regression (reglvl-gated)
uv run rb --machine fpga-regression -c fpga_regression.yaml -l 1000
```

## The scoped constraint loop

Rather than hand-author the CDC timing exceptions, they are **generated** from
the same verified crossing set `rb cdc` reports, then **audited** back against
it — generate → audit → implement:

```bash
# Regenerate the scoped IP XDC, verify it is fresh, and audit top + scoped
# (full coverage, zero over-waive). Gated: SKIPs on an rtl_buddy without the
# feature. Also runs in nightly CI.
RB="uv run rtl-buddy" bash lint/cdc/check_cdc_xdc.sh

# Or just regenerate the checked-in scoped XDC by hand:
cd lint/cdc && uv run rb cdc -c cdc.yaml demo_cdc_open_lint \
  --emit-constraints --format xdc --scoped \
  -o ../../fpga/demo_cdc_open/demo_cdc_open_cdc_scoped.xdc
```

- **`demo_cdc_open.xdc`** is the hand-written **top** XDC — clock defs, the
  `set_clock_groups -asynchronous`, and IOSTANDARDs.
- **`demo_cdc_open_cdc_scoped.xdc`** is **generated** (`SCOPED_TO_REF`,
  IP-relative cells): a `set_max_delay -datapath_only` per crossing bounded to
  the destination period, plus `set_bus_skew` on the multi-bit Gray/handshake
  buses. It is a build artefact — regenerate it, never hand-edit it.
- The CDC analysis runs under **`frontend: slang`** (see `lint/cdc/cdc.yaml`):
  scoped emit addresses each synchronizer by its instance path, which only
  survives elaboration under slang — the default yosys frontend `flatten`s it
  away (`rb cdc --emit-constraints --scoped` errors rather than emit over-broad
  `<top>/*` wildcards). Requires `rtl-buddy-cdc[slang] >= 0.3.3` and
  `rtl_buddy >= 6.17.1` (the latter emits Vivado-bindable selectors — rooted
  `[get_cells <rel>/* -filter {IS_SEQUENTIAL}]`).

**Open-flow caveat:** nextpnr-xilinx does not act on `set_max_delay` /
`set_bus_skew` / `set_clock_groups` (it never times unrelated clock domains
against each other), so in the open flow the scoped exceptions are effectively
Vivado-facing documentation — the block routes and meets timing either way
(same `fmax_mhz`). The generate→audit half is the portable, vendor-neutral
value; the exceptions become load-bearing under Vivado.

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
  flow reports it); the demo targets recognise → generate/audit → implement.
- **Vivado / `report_cdc` vendor cross-check** is proprietary and
  demonstrated outside this open template. The generated scoped XDC is where
  the open engine's exceptions would meet Vivado's own analysis.
