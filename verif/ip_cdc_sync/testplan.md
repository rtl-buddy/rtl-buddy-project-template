# ip_cdc_sync Testplan

| Test    | Stimulus                                               | Coverage targets                              |
|---------|--------------------------------------------------------|-----------------------------------------------|
| `smoke` | hold rst_n; release; toggle d 0→1→0 with settling time | `CDCSYNC-RESET`, `CDCSYNC-D-LOW`, `CDCSYNC-D-HIGH`, `CDCSYNC-LATENCY` |

## Pass criteria

1. After `STAGES + 2` cycles, `q` matches the most recent stable `d`.
2. While `rst_n = 0`, `q == RST_VAL`.
3. LVM `nerr == 0`.
