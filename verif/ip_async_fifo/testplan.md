# ip_async_fifo Testplan

| Test    | Stimulus                                                       | Coverage targets                                            |
|---------|----------------------------------------------------------------|-------------------------------------------------------------|
| `smoke` | wclk:rclk = 2:3 ns; push DEPTH+4 entries with delayed drain     | `AFIFO-PUSH`, `AFIFO-POP`, `AFIFO-FULL`, `AFIFO-EMPTY`, `AFIFO-ORDER` |

## Pass criteria

1. All pushed entries are popped in order with bit-exact match.
2. `wr_full` asserts during the burst (push exceeds DEPTH while drain is delayed).
3. `rd_empty` asserts at end of test after final pop.
4. LVM `nerr == 0`.
