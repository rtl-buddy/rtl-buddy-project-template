# `alu_accel` — Multi-clock APB-mapped ALU Accelerator

The "system-level" demonstrator. Composes:

- [`design/sandbox/alu.sv`](../../design/sandbox/alu.sv) — the leaf compute
- [`design/apb/`](../../design/apb/) — APB SV interface
- [`design/common/`](../../design/common/) — `ip_cdc_sync`, `ip_cdc_handshake`, `ip_async_fifo`
- [`alu_accel_csr.rdl`](alu_accel_csr.rdl) — PeakRDL CSR description (compiled to SV by the design-side regen script)
- [`design/alu_accel/`](../../design/alu_accel/) — compute wrapper + multi-clock top

## Clock domains

| Clock     | Used by                                                        |
|-----------|----------------------------------------------------------------|
| `apb_clk` | APB bus, `alu_accel_csr` (peakrdl-generated), FIFO write side |
| `cclk`    | `alu_accel_compute` (drives the alu), FIFO read side           |

CSR-direct commands cross via `ip_cdc_handshake`. Streaming pushes go
through `ip_async_fifo`. Result + flags return via a second
`ip_cdc_handshake`. The `SRC` bit and `FIFO_EMPTY/BUSY` flags cross via
single-bit `ip_cdc_sync` instances.

## Software protocol

### Mode 0 — CSR-direct

```
write op.OP        ← opcode
write operand_a.A  ← A
write operand_b.B  ← B
write ctrl.GO=1    ← single-cycle launch pulse (self-clearing)
poll  status.BUSY  ← wait for 0
read  result.Y, flags.{ZF,CF,NF,VF}
```

### Mode 1 — FIFO stream

```
write ctrl.SRC=1                                    ← select FIFO source
loop:
  poll status.FIFO_FULL=0
  write fifo_push = {PUSH=1, OP, A, B}              ← single push
end loop
poll status.FIFO_EMPTY=1 && status.BUSY=0           ← drained
read result.Y, flags.{ZF,CF,NF,VF}                  ← last result
```

## Coverage targets

See [`specs.yaml`](specs.yaml). Verification: [`verif/alu_accel/`](../../verif/alu_accel/).
