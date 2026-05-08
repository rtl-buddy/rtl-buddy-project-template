# `ip_cdc_sync` — Multi-flop Level Synchronizer

A `STAGES`-deep flip-flop chain that synchronizes a foreign-domain bit
into `clk`. Standard CDC primitive; `STAGES=2` is the typical safe
default for low-MTBF requirements.

## Parameters

| Parameter  | Default | Notes                                       |
|------------|---------|---------------------------------------------|
| `WIDTH`    | 1       | use one instance per bit; do **not** use width >1 for a logically-coherent vector — see `ip_cdc_handshake` for vectors |
| `STAGES`   | 2       | minimum 2; 3 for very tight MTBF budgets    |
| `RST_VAL`  | `'0`    | reset value                                 |

## Ports

| Dir | Width   | Signal  | Notes                                         |
|-----|---------|---------|-----------------------------------------------|
| in  | 1       | `clk`   | destination clock                             |
| in  | 1       | `rst_n` | sync reset in destination domain              |
| in  | `WIDTH` | `d`     | foreign-domain input — must be a clean signal |
| out | `WIDTH` | `q`     | synced output, valid in `clk`                 |

## Coverage

See [`specs.yaml`](specs.yaml). Exercised standalone in
[`verif/ip_cdc_sync/`](../../verif/ip_cdc_sync/) and via instantiation
inside `ip_cdc_handshake` and `alu_accel_top`.
