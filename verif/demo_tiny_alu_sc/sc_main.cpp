// SystemC + Verilator cosim driver for demo_tiny_alu, wired through
// `rb test` (cfg-systemc in root_config + systemc: in tests.yaml).
//
// Mirrors the standalone sandbox at verif/sandbox_systemc/sc_main.cpp but
// is launched through rtl_buddy so artefacts land under artefacts/<test>/
// and exit code (0/non-0) feeds the regression PASS/FAIL contract.

#include <systemc.h>

#include "Vdemo_tiny_alu.h"
#include "verilated.h"

static const char* op_name(unsigned op) {
  switch (op) {
    case 0: return "ADD";
    case 1: return "SUB";
    case 2: return "AND";
    case 3: return "OR ";
    case 4: return "XOR";
    case 5: return "SHL";
    case 6: return "SHR";
    case 7: return "NOP";
    default: return "???";
  }
}

int sc_main(int argc, char* argv[]) {
  // Forward +KEY=VAL plusargs from rtl_buddy's argv to Verilator.
  Verilated::commandArgs(argc, argv);

  // Match Verilator's --timescale 1ns/10ps from the builder config.
  sc_set_time_resolution(10, SC_PS);

  sc_clock clk("clk", 10, SC_NS, 0.5);
  sc_signal<bool> rst;
  sc_signal<uint32_t> op, a, b, y;
  sc_signal<bool> zf, cf, nf, vf;

  Vdemo_tiny_alu dut("dut");
  dut.clk(clk);
  dut.rst(rst);
  dut.op(op);
  dut.a(a);
  dut.b(b);
  dut.y(y);
  dut.zf(zf);
  dut.cf(cf);
  dut.nf(nf);
  dut.vf(vf);

  rst.write(true);
  op.write(0); a.write(0); b.write(0);
  sc_start(20, SC_NS);
  rst.write(false);

  struct Vec { unsigned op, a, b; };
  Vec vecs[] = {
    {0, 0x12, 0x34},
    {1, 0x40, 0x10},
    {2, 0xF0, 0x0F},
    {3, 0xF0, 0x0F},
    {4, 0xAA, 0x55},
    {5, 0x01, 0x04},
    {6, 0x80, 0x02},
    {7, 0xFF, 0xFF},
  };

  int errors = 0;
  for (const auto& v : vecs) {
    op.write(v.op); a.write(v.a); b.write(v.b);
    sc_start(10, SC_NS);
    sc_start(10, SC_NS);
    unsigned got = y.read() & 0xFF;
    unsigned exp;
    switch (v.op) {
      case 0: exp = (v.a + v.b) & 0xFF; break;
      case 1: exp = (v.a - v.b) & 0xFF; break;
      case 2: exp = v.a & v.b; break;
      case 3: exp = v.a | v.b; break;
      case 4: exp = v.a ^ v.b; break;
      case 5: exp = (v.a << (v.b & 0x7)) & 0xFF; break;
      case 6: exp = (v.a >> (v.b & 0x7)) & 0xFF; break;
      default: exp = 0;
    }
    bool pass = (got == exp);
    if (!pass) ++errors;
    std::cout << "[" << op_name(v.op) << "] a=0x" << std::hex << v.a
              << " b=0x" << v.b << " y=0x" << got
              << " exp=0x" << exp
              << " zf=" << zf.read() << " cf=" << cf.read()
              << " nf=" << nf.read() << " vf=" << vf.read()
              << (pass ? "  PASS" : "  FAIL")
              << std::dec << std::endl;
  }

  std::cout << (errors ? "FAILED" : "PASSED")
            << " (" << errors << " errors)" << std::endl;
  return errors ? 1 : 0;
}
