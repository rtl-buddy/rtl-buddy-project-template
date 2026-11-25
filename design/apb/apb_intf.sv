// apb_intf — AMBA APB4 SystemVerilog interface
//
// See spec/apb/README.md and ARM IHI 0024C.
// Carries the full APB4 signal set including PPROT and PSTRB.

// Timescale matches demo_tiny_alu.sv: slang enforces LRM 3.14.2.3 (mixed
// presence of `timescale across design elements in one compilation unit is
// an error), and this file is compiled alongside it for CDC lint.
`timescale 1ns/10ps

interface apb_intf #(
  parameter int ADDR_W = 32,
  parameter int DATA_W = 32
)(
  input logic clk,      // PCLK
  input logic rst_n     // PRESETn (active-low)
);

  localparam int STRB_W = DATA_W / 8;

  /* verilator lint_off UNDRIVEN */
  logic [ADDR_W-1:0]  paddr;
  logic [2:0]         pprot;
  logic               psel;
  logic               penable;
  logic               pwrite;
  logic [DATA_W-1:0]  pwdata;
  logic [STRB_W-1:0]  pstrb;
  /* verilator lint_on UNDRIVEN */
  logic               pready;
  logic [DATA_W-1:0]  prdata;
  logic               pslverr;

  modport manager (
    input  clk, rst_n,
    output paddr, pprot, psel, penable, pwrite, pwdata, pstrb,
    input  pready, prdata, pslverr
  );

  modport subordinate (
    input  clk, rst_n,
    input  paddr, pprot, psel, penable, pwrite, pwdata, pstrb,
    output pready, prdata, pslverr
  );

  modport monitor (
    input  clk, rst_n,
    input  paddr, pprot, psel, penable, pwrite, pwdata, pstrb,
    input  pready, prdata, pslverr
  );

endinterface
