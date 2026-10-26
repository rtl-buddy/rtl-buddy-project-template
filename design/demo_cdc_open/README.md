# demo_cdc_open — RTL

Portable clock-domain-crossing block taken through the **fully open** FPGA
flow: `rb cdc` recognises the crossings as safe, then
`rb fpga tool: openxc7` (Yosys → nextpnr-xilinx → prjxray) implements it for
a 7-series part. The RTL is vendor-neutral — the synchronizers carry only
`(* ASYNC_REG = "TRUE" *)` and `(* keep *)`, no XPM macros and no UNISIM
instantiation — so the identical source elaborates for ASIC and FPGA and
synthesises under both Yosys (`synth_xilinx`) and Vivado.

See [`../../lint/cdc/demo_cdc_open.sdc`](../../lint/cdc/demo_cdc_open.sdc) for
the recognition SDC and
[`../../fpga/demo_cdc_open/`](../../fpga/demo_cdc_open/) for the open
implementation config + top XDC and the step-by-step walkthrough.

## Hierarchy

```text
demo_cdc_open_top                 (clk_a, clk_b — asynchronous)
├── u_reset_sync_a : cdc_open_reset_sync   (async-assert/sync-deassert, clk_a)
├── u_reset_sync_b : cdc_open_reset_sync   (async-assert/sync-deassert, clk_b)
├── u_flag_sync    : cdc_open_sync         (single-bit 2FF, clk_a → clk_b)
├── u_gray_bus     : cdc_open_gray_bus     (multi-bit Gray bus, clk_a → clk_b)
│   └── u_gray_sync : cdc_open_sync        (vector 2FF on the Gray code)
└── u_handshake    : cdc_open_handshake    (req/ack + held payload, clk_a → clk_b)
    ├── u_sync_req  : cdc_open_sync        (req toggle → clk_b)
    └── u_sync_ack  : cdc_open_sync        (ack → clk_a)
```

## Document figures

`rb hier --block-diagram` draws this design as a block diagram. Three options
trim that figure for a spec page (`rtl-buddy-sch >= 0.12.0`):

```bash
# From the project root. Drop parameter rows and the root ports no edge
# lands on:
uv run rb hier demo_cdc_open_top -c design/demo_cdc_open/models.yaml \
  --format dot --block-diagram --params none --prune-flags \
  | dot -Tsvg -o demo_cdc_open_top.svg

# Add clock domains with fixed colours. The domain map comes from the
# `rb cdc --emit-constraints` run in the scoped constraint loop
# (../../fpga/demo_cdc_open/README.md):
uv run rb hier demo_cdc_open_top -c design/demo_cdc_open/models.yaml \
  --format dot --block-diagram --params none --prune-flags \
  --cdc-annotations lint/cdc/artefacts/demo_cdc_open_lint/domain_map.json \
  --clock-colors design/demo_cdc_open/clock-colors.json \
  | dot -Tsvg -o demo_cdc_open_top_clocks.svg
```

- `--params none` removes the `WIDTH`/`STAGES` rows from every box.
- `--prune-flags` drops `clk_a`, `clk_b` and `flag_a`. The clocks reach the
  instances without a drawn edge, and `flag_a` feeds the top-level
  `flag_a_q` flop, which the block diagram does not draw. With the clock
  annotations, `clk_a` stays, because the `clk_a → clk_b` crossing edges
  start there.
- [`clock-colors.json`](clock-colors.json) pins `clk_a` to blue and `clk_b`
  to orange, so every figure of this design colours the domains the same
  way. Without it, the renderer assigns swatches in its own order.

`rb hier` refuses (exit 2) a combination the renderer would ignore, such as
`--params` with `--format tree` or `--clock-colors` without
`--cdc-annotations`.

## Crossing styles demonstrated

| Crossing | Module | Why it is safe |
|----------|--------|----------------|
| Single-bit level | `cdc_open_sync` | 2-flop synchronizer (`ASYNC_REG`) |
| Multi-bit value | `cdc_open_gray_bus` | Gray code — one bit flips per step |
| Multi-bit payload | `cdc_open_handshake` | req/ack handshake, payload held stable |
| Reset deassert | `cdc_open_reset_sync` | async-assert, synchronous-deassert |

All metastability flops live in `cdc_open_sync` / `cdc_open_reset_sync` and
carry the vendor-neutral `ASYNC_REG`/`keep` attributes. The
`(* cdc_handshake *)` marks in `cdc_open_handshake.sv` are a CDC-linter hint
(a plain SV attribute, not a vendor macro — ignored by Yosys and Vivado, so
not a portability concern). `rtl-buddy-cdc >= 0.3.3` reads them to recognise
the held-payload handshake and suppress a CDC-012 data-hold false positive,
which keeps the `frontend: slang` analysis clean — see the
[open FPGA flow README](../../fpga/demo_cdc_open/README.md) for the scoped
generate → audit loop that analysis feeds.
