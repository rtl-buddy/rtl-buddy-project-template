# demo_alu_accel Testplan

System-level verification of the multi-clock ALU accelerator.

## Tests

| Test          | Stimulus                                                            | Coverage targets                                                                              |
|---------------|---------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| `csr_smoke`   | 4 CSR-direct ops (op/a/b writes + GO pulse), poll BUSY, read result | `ACCEL-CSR-WRITE`, `ACCEL-CSR-READ`, `ACCEL-CSR-DIRECT-OP`, `ACCEL-RESULT-MATCH`, `ACCEL-DONE-INC` |
| `fifo_stream` | SRC=1, push 12 ops (depth 8 → drives FULL), wait drain, read result | `ACCEL-FIFO-PUSH`, `ACCEL-FIFO-FULL`, `ACCEL-FIFO-DRAIN`, `ACCEL-RESULT-MATCH`, `ACCEL-DONE-INC` |

## Pass criteria

For both tests:
1. `result.Y` and `flags.{ZF,CF,NF,VF}` for the most recent op match the
   inline SV reference (mirrors `sandbox_model.AluModel`).
2. `status.DONE_CNT` equals the number of submitted operations.
3. LVM `nerr == 0`.

For `fifo_stream`: `status.FIFO_FULL=1` is observed during the push
burst, and `status.FIFO_EMPTY=1` is observed after drain.

## Clock domains exercised

- `apb_clk = 4 ns` (APB bus + CSR block)
- `cclk    = 6 ns` (demo_alu_accel_compute + alu)

The ratio is incommensurate so CDC corners (`ip_cdc_handshake` for
command and result, `ip_cdc_sync` for SRC/empty/full, `ip_async_fifo`
for streaming) are exercised across many phase relationships.
