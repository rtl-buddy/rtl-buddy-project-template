# `ip_cdc_handshake` — 4-phase Request/Ack Vector CDC

Transfers a multi-bit payload across two clock domains using a 4-phase
`req`/`ack` handshake plus level synchronizers on the control bits.
Suitable for sporadic, coherent vector transfers where coherence
across the bus matters more than throughput.

## Parameters

| Parameter | Default | Notes                                          |
|-----------|---------|------------------------------------------------|
| `WIDTH`   | 8       | payload width                                  |

## Ports

| Group   | Dir | Signal      | Notes                                      |
|---------|-----|-------------|--------------------------------------------|
| Source  | in  | `src_clk`   | source domain clock                        |
| Source  | in  | `src_rst_n` | source domain sync reset                   |
| Source  | in  | `src_valid` | pulse 1 cycle to launch a transfer         |
| Source  | out | `src_ready` | 1 when no transfer is in flight            |
| Source  | in  | `src_data`  | payload sampled on accepted transfer       |
| Dest    | in  | `dst_clk`   | destination domain clock                   |
| Dest    | in  | `dst_rst_n` | destination domain sync reset              |
| Dest    | out | `dst_valid` | 1-cycle pulse on dst_clk per transfer      |
| Dest    | out | `dst_data`  | payload, valid when `dst_valid=1`          |

## Behaviour

1. Source samples `src_data` and toggles `src_req` when `src_valid &&
   src_ready`.
2. `src_req` is synchronized into the destination domain by a 2-FF
   `ip_cdc_sync` chain.
3. Destination edge-detects the synced `req` and pulses `dst_valid`,
   driving `dst_data` from the held source payload.
4. Destination toggles `dst_ack` to mirror the synced `req`. The ack
   is synchronized back to the source domain to release `src_ready`.

Throughput: ≈ 1 transfer per 4 × max(`src_period`, `dst_period`).

## CDC lint

A structure-only CDC linter flags the protocol-safe paths of this
primitive as false positives, so the three participating registers are
annotated `(* cdc_handshake *)`:

| Register | Rule suppressed | Why it's safe |
|----------|-----------------|---------------|
| `src_req` | CDC-013 (fast→slow toggle event-loss) | source is backpressured (`src_ready = src_req == ack_in_src`) — no event launches until the previous one is acked |
| `src_payload` | CDC-020 (sliced-bus reconvergence) | held stable across the whole req→ack→done window — no lane is sampled mid-flight |
| `dst_data` | CDC-001 (single-stage capture) / CDC-014 (post-capture decode comb) | a single destination register under `dst_valid` is the intended capture, and downstream decode is ordinary datapath |

rtl-buddy-cdc recognises the attribute and stays silent on these paths
(rtl-buddy-cdc#247); older analyzers ignore the unknown attribute. This
lets instances of the primitive lint clean without per-instance waivers.

## Coverage

See [`specs.yaml`](specs.yaml). Exercised standalone in
[`verif/ip_cdc_handshake/`](../../verif/ip_cdc_handshake/) and via
instantiation inside `demo_tiny_alu_subsys_top`.
