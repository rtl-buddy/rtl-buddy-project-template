# ip_cdc_handshake Testplan

| Test    | Stimulus                                                                  | Coverage targets                                                |
|---------|---------------------------------------------------------------------------|-----------------------------------------------------------------|
| `smoke` | src_clk:dst_clk = 2:3 ns; push 6 payloads back-to-back; scoreboard queue | `HSCDC-XFER`, `HSCDC-DATA-MATCH`, `HSCDC-BACKPRESSURE`, `HSCDC-MULTI-XFER` |

## Pass criteria

1. All 6 payloads observed at `dst_valid` in order with bit-exact match.
2. `src_ready` deasserts at least once during the burst (back-pressure
   path is real, not always-idle).
3. LVM `nerr == 0`.
