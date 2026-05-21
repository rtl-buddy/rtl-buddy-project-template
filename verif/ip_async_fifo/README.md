# `verif/ip_async_fifo/` — Standalone Async-FIFO Suite

Dual-clock smoke for [`ip_async_fifo`](../../design/common/ip_async_fifo.sv).
Pushes DEPTH+4 entries while delaying the drain so the FIFO actually
hits `wr_full`, then drains and verifies in-order delivery.

```bash
(cd verif/ip_async_fifo && uv run rb test smoke)
```
