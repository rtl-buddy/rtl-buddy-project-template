// Memory subsystem: a host (clk_h) writes a single-clock SRAM macro that lives
// in the memory domain (clk_m, asynchronous to clk_h).
//
// The write transaction crosses domains through the req/ack handshake primitive
// (ip_cdc_handshake): the source holds {addr, wdata} stable — src_ready
// back-pressures the host until the destination has captured them — and the
// memory domain receives a single metastability-filtered write strobe with a
// coherent payload. The handshake's (* cdc_handshake *) participants are
// recognised by the CDC analyzer as a sanctioned crossing.
//
// The SRAM (sram_sp) is purely clk_m (no CDC of its own) and is the
// blackbox-for-scale target — see lint/cdc/cdc.yaml::demo_cdc_mem_macro_lint.
module mem_subsys #(parameter AW = 8, DW = 32) (
    input  logic          clk_h,
    input  logic          rst_h_n,
    input  logic          clk_m,
    input  logic          rst_m_n,
    // Host write port (clk_h). Present {addr, wdata} with we_h; the write is
    // accepted on a cycle where we_h & ready_h, after which the handshake
    // holds the payload — the host may change its inputs only once ready_h
    // re-asserts.
    input  logic          we_h,
    input  logic [AW-1:0] addr_h,
    input  logic [DW-1:0] wdata_h,
    output logic          ready_h,
    output logic [DW-1:0] rdata_m
);
  localparam int PW = AW + DW;

  // Cross the write transaction safely: {addr, wdata} are held stable in the
  // source until clk_m captures them, and dst_valid is a single clean write
  // strobe in the memory domain.
  logic          wr_stb_m;
  logic [PW-1:0] wr_payload_m;
  ip_cdc_handshake #(.WIDTH(PW)) u_wr_hs (
    .src_clk   (clk_h),
    .src_rst_n (rst_h_n),
    .src_valid (we_h),
    .src_ready (ready_h),
    .src_data  ({addr_h, wdata_h}),
    .dst_clk   (clk_m),
    .dst_rst_n (rst_m_n),
    .dst_valid (wr_stb_m),
    .dst_data  (wr_payload_m)
  );

  logic [AW-1:0] addr_m;
  logic [DW-1:0] wdata_m;
  assign {addr_m, wdata_m} = wr_payload_m;

  // Single-clock SRAM macro (the blackbox-for-scale target). Written only on
  // the synchronised strobe, with an address/data pair guaranteed coherent.
  sram_sp #(.AW(AW), .DW(DW)) u_sram (
      .clk(clk_m), .ce(1'b1), .we(wr_stb_m), .addr(addr_m), .wdata(wdata_m), .rdata(rdata_m)
  );
endmodule
