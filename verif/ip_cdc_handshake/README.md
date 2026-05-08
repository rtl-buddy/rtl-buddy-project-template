# `verif/ip_cdc_handshake/` — Standalone Vector-CDC Suite

Multi-clock smoke for [`ip_cdc_handshake`](../../design/common/ip_cdc_handshake.sv).
Pushes a 6-payload sequence from a 2 ns source clock to a 3 ns
destination clock; scoreboard verifies in-order bit-exact delivery and
that back-pressure actually occurs.

```bash
(cd verif/ip_cdc_handshake && uv run rb test smoke)
```
