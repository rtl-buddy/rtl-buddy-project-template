# demo_cdc_mem_macro — RTL

Blackbox-for-scale demo: a single-clock SRAM macro (`sram_sp`) written by a
host in another clock domain. The macro is the canonical **blackbox** target —
a hard IP whose (large) array you stub out so the CDC analyzer doesn't walk it
— while the real `clk_h → clk_m` write crossing is preserved and signed off.
See
[`../../lint/cdc/demo_cdc_mem_macro.sdc`](../../lint/cdc/demo_cdc_mem_macro.sdc)
for the integration SDC and the `demo_cdc_mem_macro_lint` analysis in
[`../../lint/cdc/cdc.yaml`](../../lint/cdc/cdc.yaml).

## The write crossing

The write transaction is carried by the req/ack handshake primitive
[`ip_cdc_handshake`](../common/ip_cdc_handshake.sv). The source **holds
`{addr, wdata}` stable** — `src_ready` back-pressures the host until the
destination has captured the payload — and the memory domain receives a single
metastability-filtered write strobe (`dst_valid`) with a coherent address/data
pair, so the SRAM only ever writes a settled word to a settled address. The
handshake's `(* cdc_handshake *)` participants are recognised by the analyzer
as a sanctioned crossing, so the design signs off with **zero violations**.

## Hierarchy

```text
mem_subsys
├── u_wr_hs : ip_cdc_handshake      clk_h → clk_m, holds {addr,wdata} until captured (the safe CDC)
│   └── u_sync_req / u_sync_ack : ip_cdc_sync   (2FF req/ack synchronisers)
└── u_sram : sram_sp               single-clock clk_m SRAM macro — the blackbox target
```

## Blackboxing the macro

`demo_cdc_mem_macro_lint` sets `blackbox: ["sram_sp"]`, forwarded to the
analyzer as `rtl-buddy-cdc lint --blackbox sram_sp`. The macro is single-clock,
so it is **summarised to its port boundary** rather than flattened — its memory
array and read register are removed from the walk:

| | cells walked | flops | crossings | violations |
|---|---|---|---|---|
| flat (macro walked)  | 26 | 11 | 3 | 0 |
| blackbox `sram_sp`   | **20** | **10** | 3 | 0 |

Identical CDC result, with the macro's internals removed — the scaling win (and
the `(1<<AW)`-deep array never enters the netlist at all). A **multi-clock**
module is *not* a valid blackbox target: the analyzer declines it with a
`CDC-BBX` error. Single-clock leaf macros (memory, PLL wrappers, separately
signed-off IP) are the intended case.

## Toolchain requirement

This is a **slang-required** example (issue #21). The `--blackbox` path needs
`rtl-buddy-cdc` ≥ 0.3.0 (rtl-buddy-cdc#259) and `rtl_buddy` with the `blackbox:`
cdc.yaml key (rtl_buddy#318), run with the yosys-slang plugin
(`RTL_BUDDY_SLANG_PLUGIN`). Both are released and pinned here
(`rtl-buddy-cdc[slang]` v0.3.3, `rtl_buddy` 6.15.0).
