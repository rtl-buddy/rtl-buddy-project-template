// View-only stub for the rb hub / rtl-buddy-view hierarchy. The real
// design is the axi_2x2 wrapper next door; this stub is what the
// VIEWER sees so the AXI overlay's (master_path, slave_path) pairs
// have edges to attach to.
//
// Each AXI bundle is modelled as a child instance under ``dut`` —
// matching the axi-bundles.yaml master/slave paths
// (system.dut → system.dut.in0 / .in1 / .out0 / .out1).
//
// This stub is consumed only by `rtl-buddy-view` to emit `view.json`
// for the SPA. It does not participate in simulation.

module axi_port_stub();
endmodule

module axi_2x2_view_dut();
  axi_port_stub in0  ();
  axi_port_stub in1  ();
  axi_port_stub out0 ();
  axi_port_stub out1 ();
endmodule

module system();
  axi_2x2_view_dut dut ();
endmodule
