// demo_alu_accel_synth_top — Flat-port synthesis wrapper.
//
// SV interfaces (apb_intf) don't always elaborate through Yosys at the
// synthesis top. This wrapper flattens the APB ports and instantiates a
// local apb_intf, which is then connected to demo_alu_accel_top. Use this
// module as the synthesis top instead of demo_alu_accel_top directly.

module demo_alu_accel_synth_top (
  input  logic        apb_clk,
  input  logic        apb_rst_n,

  // APB4 (manager-side, driven into the subordinate)
  input  logic [31:0] paddr,
  input  logic [2:0]  pprot,
  input  logic        psel,
  input  logic        penable,
  input  logic        pwrite,
  input  logic [31:0] pwdata,
  input  logic [3:0]  pstrb,
  output logic        pready,
  output logic [31:0] prdata,
  output logic        pslverr,

  input  logic        cclk,
  input  logic        crst_n
);

  apb_intf #(.ADDR_W(32), .DATA_W(32)) bus (.clk(apb_clk), .rst_n(apb_rst_n));

  assign bus.paddr   = paddr;
  assign bus.pprot   = pprot;
  assign bus.psel    = psel;
  assign bus.penable = penable;
  assign bus.pwrite  = pwrite;
  assign bus.pwdata  = pwdata;
  assign bus.pstrb   = pstrb;
  assign pready  = bus.pready;
  assign prdata  = bus.prdata;
  assign pslverr = bus.pslverr;

  demo_alu_accel_top u_inner (
    .apb_clk, .apb_rst_n,
    .apb (bus),
    .cclk, .crst_n
  );

endmodule
