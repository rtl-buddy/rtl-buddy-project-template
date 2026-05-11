"""Golden reference model for the sandbox tiny ALU.

This is the executable form of `spec/demo_sandbox/README.md`. It is the
single source of truth shared by the SV/LVM scoreboard (via Python-side
result comparison post-sim) and the cocotb cosim suite (live).

Pure Python, no rtl_buddy or cocotb dependencies."""

from __future__ import annotations

from dataclasses import dataclass

OP_ADD = 0
OP_SUB = 1
OP_AND = 2
OP_OR  = 3
OP_XOR = 4
OP_SHL = 5
OP_SHR = 6
OP_NOP = 7

OP_NAMES = {
    OP_ADD: "ADD", OP_SUB: "SUB", OP_AND: "AND", OP_OR: "OR",
    OP_XOR: "XOR", OP_SHL: "SHL", OP_SHR: "SHR", OP_NOP: "NOP",
}


@dataclass(frozen=True)
class AluResult:
    y: int
    zf: int
    cf: int
    nf: int
    vf: int

    def as_tuple(self) -> tuple[int, int, int, int, int]:
        return (self.y, self.zf, self.cf, self.nf, self.vf)


class AluModel:
    """8-bit ALU reference. compute() returns the value the DUT will
    register one cycle after `op/a/b` are sampled."""

    W = 8
    MASK = 0xFF
    SIGN = 0x80

    @classmethod
    def compute(cls, op: int, a: int, b: int) -> AluResult:
        a &= cls.MASK
        b &= cls.MASK
        cf = 0
        vf = 0
        if op == OP_ADD:
            full = a + b
            y = full & cls.MASK
            cf = (full >> cls.W) & 1
            vf = int((a & cls.SIGN) == (b & cls.SIGN) and (y & cls.SIGN) != (a & cls.SIGN))
        elif op == OP_SUB:
            full = (a - b) & ((1 << (cls.W + 1)) - 1)
            y = full & cls.MASK
            cf = int(a < b)
            vf = int((a & cls.SIGN) != (b & cls.SIGN) and (y & cls.SIGN) != (a & cls.SIGN))
        elif op == OP_AND:
            y = a & b
        elif op == OP_OR:
            y = a | b
        elif op == OP_XOR:
            y = a ^ b
        elif op == OP_SHL:
            y = (a << (b & 0x7)) & cls.MASK
        elif op == OP_SHR:
            y = a >> (b & 0x7)
        elif op == OP_NOP:
            y = 0
        else:
            raise ValueError(f"unknown op={op}")
        zf = int(y == 0)
        nf = (y >> (cls.W - 1)) & 1
        return AluResult(y=y, zf=zf, cf=cf, nf=nf, vf=vf)

    @staticmethod
    def reset_state() -> AluResult:
        return AluResult(y=0, zf=1, cf=0, nf=0, vf=0)
