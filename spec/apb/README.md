# `apb` — AMBA APB4 Interface

Pure SystemVerilog interface used by all CSR blocks in this project to
talk to a host bus. Reference: ARM IHI 0024C.

## Signals

| Direction (manager) | Width      | Signal     | Notes                       |
|---------------------|------------|------------|-----------------------------|
| out                 | `ADDR_W`   | `paddr`    | byte address                |
| out                 | 3          | `pprot`    | privilege/security/data     |
| out                 | 1          | `psel`     | peripheral select           |
| out                 | 1          | `penable`  | access enable               |
| out                 | 1          | `pwrite`   | 1 = write, 0 = read         |
| out                 | `DATA_W`   | `pwdata`   | write data                  |
| out                 | `STRB_W`   | `pstrb`    | byte strobe                 |
| in                  | 1          | `pready`   | transfer complete           |
| in                  | `DATA_W`   | `prdata`   | read data                   |
| in                  | 1          | `pslverr`  | error response              |

`STRB_W = DATA_W / 8`. Defaults: `ADDR_W = 32`, `DATA_W = 32`.

## Modports

- **`manager`** — driven by the bus initiator (CSR bridge, host stub).
- **`subordinate`** — driven by the peripheral (peakrdl-generated CSR block).
- **`monitor`** — read-only view used by scoreboards.

## Behaviour summary

A two-phase access:

1. **Setup** — manager asserts `psel` and address/data. `penable=0`.
2. **Access** — manager asserts `penable`. The subordinate samples
   address/data and asserts `pready` to complete the transfer (may stall
   by deasserting `pready`).

## Coverage targets

See [`specs.yaml`](specs.yaml). The interface itself is exercised end-to-end
through the [`alu_accel`](../alu_accel/) block; `verif/apb/` provides a
compile/elaboration smoke test for the modport contract.
