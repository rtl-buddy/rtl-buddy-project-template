# demo_cdc_src_sync — RTL

Synthesizable source-synchronous clock-forwarding chain. See
[`../../spec/demo_cdc_src_sync/README.md`](../../spec/demo_cdc_src_sync/README.md)
for the methodology overview and
[`../../lint/cdc/demo_cdc_src_sync.sdc`](../../lint/cdc/demo_cdc_src_sync.sdc)
for the integration SDC.

## Hierarchy

```text
demo_cdc_src_sync_top
├── u_a   : block_a   (forwards two divide-by-2 clocks to B0/B1)
├── u_b0  : block_b   (forwards a divide-by-2 clock to C0)
├── u_b1  : block_b   (forwards a divide-by-2 clock to C1)
├── u_c0  : block_c
└── u_c1  : block_c
```

Only `ck_a` enters at the top. Each forwarded clock lives on an
internal net (`u_a/clk_out_b0`, etc.) where the system SDC declares
the matching `create_generated_clock`.
