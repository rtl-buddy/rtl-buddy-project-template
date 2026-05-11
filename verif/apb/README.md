# `verif/apb/` — APB Interface Smoke Suite

Compile/elaboration smoke for [`design/apb/apb_intf.sv`](../../design/apb/apb_intf.sv).
Confirms the modport contract works and exercises the four headline
coverage IDs (`APB-IF-WRITE/READ/STALL/PSLVERR`).

The interface gets full protocol coverage through use in
[`verif/demo_alu_accel/`](../demo_alu_accel/). This suite stands alone so the APB
IP is self-described (spec + testplan + tests).

```bash
(cd verif/apb && uv run rb test smoke)
```
