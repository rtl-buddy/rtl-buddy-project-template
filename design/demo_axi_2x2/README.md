# `demo_axi_2x2` — minimal 2×2 AXI4 system

A small wrapper around the [`pulp-platform/axi`](https://github.com/pulp-platform/axi)
`axi_xbar` that exposes two AXI4 masters and two AXI4 slaves through flat ports,
plus a directed Verilator testbench that drives interleaved reads and writes
across both endpoints.

Built on top of `demo_pulp_platform_axi` — the vendor AXI sources are already
present there; this demo only adds the wrapper, the testbench, and the
profiler-visible manifest.

## Layout

```
design/demo_axi_2x2/
  axi_2x2.sv                 — 2x2 axi_xbar wrapper with flat AXI_S/AXI_M ports
  axi_2x2_system_view.sv     — view-only stub (consumed by rtl-buddy-view)
  axi_2x2.f                  — filelist (-F into demo_pulp_platform_axi)
  axi_2x2.axi-bundles.yaml   — 4-bundle manifest (in0/in1/out0/out1) for rb axi-profile
  models.yaml                — rb model entry

verif/demo_axi_2x2/
  tb_axi_2x2.sv              — directed TB: synchronous MASTER_FSM + combinational SLAVE_MEM
  tests.yaml                 — basic_traffic
```

## What it exercises

- **Address map**: `[0x0000_0000, 0x1000_0000) → m0`, `[0x1000_0000, 0x2000_0000) → m1`.
- **Directed traffic**: per-master state machine (IDLE → AW/W → WAIT_B → AR → WAIT_R)
  issues interleaved single-beat and burst (awlen ∈ {0, 3, 7}) writes + reads
  for the duration of the run, sweeping the slave address regions.
- **Phase-driven congestion**: a phase machine steers both masters at the same
  target during HOT_T0 (cycles 300–1099) and HOT_T1 (cycles 1900–2699) so the
  xbar must serialise the streams; WARMUP / MIXED phases alternate targets
  with the masters offset against each other.
- **Synthetic slave stalls**: each slave model drops `awready` / `wready` /
  `arready` on a fixed cycle-count pattern and inserts a per-channel B / R
  response delay. `out0` is the low-latency target (short, frequent dips);
  `out1` is the slow target (aggressive W stalls + multi-cycle response
  latency) — so HOT_T1 surfaces visibly more back-pressure than HOT_T0.
- **FST dump**: `DUMP` define enables a full-design FST waveform — the input to
  `rb axi-profile run` for AXI performance analysis.

## Running

```bash
cd verif/demo_axi_2x2
uv run rb test basic_traffic
```

The first run compiles `pp_axi.f` + the wrapper + the TB; subsequent runs are
incremental. The test runs for a fixed 3,200 cycles (covering all four traffic
phases plus a drain window) and passes as long as no protocol violations fire.

## AXI profiler integration

The `axi_2x2.axi-bundles.yaml` manifest models the wrapper as four bundles
(`in0`, `in1`, `out0`, `out1`) with `master_path: system.dut` and
`slave_path: system.dut.<bundle>`. This matches the hierarchy exposed by
`axi_2x2_system_view.sv` — the view-only stub that `rb hier` / `rtl-buddy-view`
walks to emit `view.json`. The dual-file split (real wrapper for simulation,
stub for view consumption) sidesteps `+incdir+` directives that the
rtl-buddy-view filelist parser can't currently traverse.

Once `rtl-buddy-axi-profiler` is added to the template's dependency set (and
the Python pin bumped to 3.12 to match it), AXI metrics can be produced via:

```bash
# After running the test → FST is at artefacts/basic_traffic/dump.fst
uv run rb axi-profile run \
  -f design/demo_axi_2x2/axi_2x2.f \
  -t axi_2x2 \
  -i verif/demo_axi_2x2/artefacts/basic_traffic/dump.fst \
  -m design/demo_axi_2x2/axi_2x2.axi-bundles.yaml \
  -o axi-perf.json
```

The resulting `axi-perf.json` overlays into rtl-buddy-view's AXI tab; per-bundle
channel utilisation, throughput, and latency percentiles render against the
view hierarchy.
