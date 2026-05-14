# Sandbox — Tiny ALU Spec

This is the **authoritative** specification for the sandbox demonstrator
DUT. The Python golden model ([`tiny_alu_model.py`](tiny_alu_model.py)) is
the executable form of this spec; both verification suites consume it.

## 1. Overview

A registered 8-bit ALU with three-bit opcode, supporting eight operations
and four flag outputs. Result and flags appear one cycle after the
operand sample.

## 2. Interface

See [`design/demo_tiny_alu/README.md`](../../design/demo_tiny_alu/README.md).

## 3. Operations

| op | Mnemonic | Result `y`           | Flags affected      |
|----|----------|----------------------|---------------------|
| 0  | ADD      | `(a + b) & 0xFF`     | Z, C=carry, N, V    |
| 1  | SUB      | `(a - b) & 0xFF`     | Z, C=borrow, N, V   |
| 2  | AND      | `a & b`              | Z, N (C=0, V=0)     |
| 3  | OR       | `a \| b`             | Z, N (C=0, V=0)     |
| 4  | XOR      | `a ^ b`              | Z, N (C=0, V=0)     |
| 5  | SHL      | `(a << b[2:0]) & 0xFF` | Z, N (C=0, V=0)   |
| 6  | SHR      | `a >> b[2:0]`        | Z, N (C=0, V=0)     |
| 7  | NOP      | `0`                  | Z=1, others 0       |

## 4. Flag definitions

- **Z** — `y == 0`
- **N** — `y[7]`
- **C** — ADD: unsigned carry-out. SUB: borrow (`a < b` unsigned). 0 otherwise.
- **V** — ADD: signed overflow `(a[7]==b[7]) && (y[7]!=a[7])`.
         SUB: signed overflow `(a[7]!=b[7]) && (y[7]!=a[7])`. 0 otherwise.

## 5. Reset behaviour

Synchronous, active-high. On reset: `y=0, zf=1, cf=nf=vf=0`.

## 6. Functional coverage objectives

Each item below has a stable ID consumed by `specs.yaml` and matched by
covergroup bin names in [`verif/demo_tiny_alu/cov_alu.sv`](../../verif/demo_tiny_alu/cov_alu.sv).

| ID                       | Objective                                                     |
|--------------------------|---------------------------------------------------------------|
| `SAND-FUNC-RESET`        | Outputs match reset values immediately after `rst` deasserts. |
| `SAND-FUNC-OP-ADD`       | At least one ADD with non-zero operands observed.             |
| `SAND-FUNC-OP-SUB`       | At least one SUB observed.                                    |
| `SAND-FUNC-OP-AND`       | At least one AND observed.                                    |
| `SAND-FUNC-OP-OR`        | At least one OR observed.                                     |
| `SAND-FUNC-OP-XOR`       | At least one XOR observed.                                    |
| `SAND-FUNC-OP-SHL`       | At least one SHL observed.                                    |
| `SAND-FUNC-OP-SHR`       | At least one SHR observed.                                    |
| `SAND-FUNC-OP-NOP`       | NOP observed; result is zero.                                 |
| `SAND-FUNC-FLAG-Z`       | `zf` observed both 0 and 1.                                   |
| `SAND-FUNC-FLAG-N`       | `nf` observed both 0 and 1.                                   |
| `SAND-FUNC-FLAG-C-ADD`   | ADD with `cf=1` (carry out).                                  |
| `SAND-FUNC-FLAG-C-SUB`   | SUB with `cf=1` (borrow).                                     |
| `SAND-FUNC-FLAG-V-ADD`   | ADD with signed overflow (`vf=1`).                            |
| `SAND-FUNC-FLAG-V-SUB`   | SUB with signed overflow (`vf=1`).                            |
| `SAND-FUNC-OPERAND-RANGE`| Cross of operand-A bins (zero/low/mid/high/max) × opcode.     |

## 7. Test plan

See [`verif/demo_tiny_alu/testplan.md`](../../verif/demo_tiny_alu/testplan.md) for the
mapping from tests to coverage IDs and pass criteria, and
[`verif/demo_tiny_alu_cocotb/README.md`](../../verif/demo_tiny_alu_cocotb/README.md)
for the cocotb cosim flow that shares the same golden model.
