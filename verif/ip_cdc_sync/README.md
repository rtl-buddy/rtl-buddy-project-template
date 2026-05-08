# `verif/ip_cdc_sync/` — Standalone Synchronizer Suite

Smoke + latency check for [`ip_cdc_sync`](../../design/common/ip_cdc_sync.sv).
Real CDC traffic is also exercised inside `ip_cdc_handshake` and the
system-level [`alu_accel`](../alu_accel/) suite.

```bash
(cd verif/ip_cdc_sync && uv run rb test smoke)
```
