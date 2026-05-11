# `design/demo_sandbox/` — Tiny ALU DUT

A small 8-bit ALU used by the sandbox demonstrator suites to exercise
`rtl_buddy`'s spec / coverage / cosim / waveform / reporting flows.

| Port  | Dir | Width | Notes                                       |
|-------|-----|-------|---------------------------------------------|
| `clk` | in  | 1     | rising-edge clock                           |
| `rst` | in  | 1     | sync, active-high                           |
| `op`  | in  | 3     | opcode (see below)                          |
| `a`   | in  | W=8   | operand A                                   |
| `b`   | in  | W=8   | operand B                                   |
| `y`   | out | W=8   | result (registered, 1-cycle latency)        |
| `zf`  | out | 1     | zero flag                                   |
| `cf`  | out | 1     | carry / borrow                              |
| `nf`  | out | 1     | negative (msb of result)                    |
| `vf`  | out | 1     | signed overflow (ADD/SUB only; else 0)      |

## Opcodes

`0:ADD  1:SUB  2:AND  3:OR  4:XOR  5:SHL  6:SHR  7:NOP`

Result and flags appear **one cycle** after the inputs (registered output).

## Cross-references

- Authoritative spec: [`spec/demo_sandbox/`](../../spec/demo_sandbox/)
- Python golden model (single source of truth shared by both verif suites):
  [`spec/demo_sandbox/sandbox_model.py`](../../spec/demo_sandbox/sandbox_model.py)
- SV/LVM verification suite: [`verif/demo_sandbox/`](../../verif/demo_sandbox/)
- cocotb verification suite: [`verif/demo_sandbox_cocotb/`](../../verif/demo_sandbox_cocotb/)
