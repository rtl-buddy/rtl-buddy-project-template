# demo_cdc_src_sync — source-synchronous CDC reference

A small reference design that exercises the source-synchronous CDC
pattern at SoC scope:

```text
    A ──► B0 ──► C0
     └──► B1 ──► C1
```

Each block forwards its clock alongside data through an internal net
(no top-level clock port per block; only ``ck_a`` enters the design).
The system SDC declares each forwarded clock with
``create_generated_clock`` at the internal pin where the clock takes
over — modelling the methodology that the analyzer must understand
to verify partitioned SoCs.

See [`lint/cdc/demo_cdc_src_sync.sdc`](../../lint/cdc/demo_cdc_src_sync.sdc)
for the integration-level constraints and
[`design/demo_cdc_src_sync/demo_cdc_src_sync_top.sv`](../../design/demo_cdc_src_sync/demo_cdc_src_sync_top.sv)
for the RTL.
