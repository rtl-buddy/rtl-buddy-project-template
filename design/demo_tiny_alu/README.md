# `design/demo_tiny_alu/` — Tiny ALU DUT

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

## Model elaboration

[`models.yaml`](models.yaml) is both the model definition and the home of its
optional named elaboration profiles. The `smoke` profile checks the default
width; `wide` overrides `W` and is deferred to regression level 1.

```bash
uv run rb elab demo_tiny_alu -c design/demo_tiny_alu/models.yaml
uv run rb elab demo_tiny_alu --profile smoke -c design/demo_tiny_alu/models.yaml
uv run rb elab-regression -c elab_regression.yaml -l 1
```

## Cross-references

- Authoritative spec: [`spec/demo_tiny_alu/`](../../spec/demo_tiny_alu/)
- Python golden model (single source of truth shared by both verif suites):
  [`spec/demo_tiny_alu/tiny_alu_model.py`](../../spec/demo_tiny_alu/tiny_alu_model.py)
- SV/LVM verification suite: [`verif/demo_tiny_alu/`](../../verif/demo_tiny_alu/)
- cocotb verification suite: [`verif/demo_tiny_alu_cocotb/`](../../verif/demo_tiny_alu_cocotb/)
