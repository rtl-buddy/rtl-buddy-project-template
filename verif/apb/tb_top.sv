// Minimal APB interface smoke test.
//
// Instantiates `apb_intf`, drives the manager side from an initial block
// and a subordinate-side stub that exercises stall + pslverr. Confirms
// the modport contract compiles and runs end-to-end. Real APB protocol
// coverage closes through verif/alu_accel/.

`include "lvm_core.sv"

module tb_top;
  `LVM_INIT("apb_smoke")

  logic clk;
  logic rst_n;

  apb_intf #(.ADDR_W(8), .DATA_W(32)) bus (.clk, .rst_n);

  // Subordinate stub: 4-entry register file, 1-cycle stall, pslverr on addr 0xF0
  logic [31:0] mem [4];
  logic        stall_q;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bus.pready  <= 1'b0;
      bus.prdata  <= '0;
      bus.pslverr <= 1'b0;
      stall_q     <= 1'b0;
      for (int i = 0; i < 4; i++) mem[i] <= '0;
    end else begin
      bus.pready  <= 1'b0;
      bus.pslverr <= 1'b0;
      if (bus.psel && bus.penable && !bus.pready) begin
        // 1-cycle stall first time, then complete
        if (!stall_q) begin
          stall_q <= 1'b1;
        end else begin
          stall_q <= 1'b0;
          bus.pready <= 1'b1;
          if (bus.paddr == 8'hF0) begin
            bus.pslverr <= 1'b1;
          end else if (bus.pwrite) begin
            mem[bus.paddr[3:2]] <= bus.pwdata;
          end else begin
            bus.prdata <= mem[bus.paddr[3:2]];
          end
        end
      end
    end
  end

  // Manager-side stimulus
  task automatic apb_write(input [7:0] addr, input [31:0] data);
    @(negedge clk);
    bus.paddr   = addr;
    bus.pwdata  = data;
    bus.pwrite  = 1'b1;
    bus.pstrb   = 4'hF;
    bus.psel    = 1'b1;
    bus.penable = 1'b0;
    @(negedge clk);
    bus.penable = 1'b1;
    do @(negedge clk); while (!bus.pready);
    bus.psel    = 1'b0;
    bus.penable = 1'b0;
  endtask

  task automatic apb_read(input [7:0] addr, output [31:0] data, output bit err);
    @(negedge clk);
    bus.paddr   = addr;
    bus.pwrite  = 1'b0;
    bus.psel    = 1'b1;
    bus.penable = 1'b0;
    @(negedge clk);
    bus.penable = 1'b1;
    do @(negedge clk); while (!bus.pready);
    data = bus.prdata;
    err  = bus.pslverr;
    bus.psel    = 1'b0;
    bus.penable = 1'b0;
  endtask

  // Cover labels — match APB-IF-* IDs from specs.yaml
  bit cov_write, cov_read, cov_stall, cov_pslverr;
  always @(posedge clk) begin
    if (bus.psel && bus.penable && bus.pready &&  bus.pwrite) cov_write   <= 1'b1;
    if (bus.psel && bus.penable && bus.pready && !bus.pwrite) cov_read    <= 1'b1;
    if (bus.psel && bus.penable && !bus.pready)               cov_stall   <= 1'b1;
    if (bus.psel && bus.penable && bus.pslverr)               cov_pslverr <= 1'b1;
  end
  APB_IF_WRITE:   cover property (@(posedge clk) cov_write);
  APB_IF_READ:    cover property (@(posedge clk) cov_read);
  APB_IF_STALL:   cover property (@(posedge clk) cov_stall);
  APB_IF_PSLVERR: cover property (@(posedge clk) cov_pslverr);

  initial begin
    logic [31:0] data;
    bit          err;
    bus.psel    = 1'b0;
    bus.penable = 1'b0;
    bus.pwrite  = 1'b0;
    bus.paddr   = '0;
    bus.pwdata  = '0;
    bus.pstrb   = '0;
    bus.pprot   = '0;
    clk   = 1'b0;
    rst_n = 1'b0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;

    apb_write(8'h00, 32'hDEAD_BEEF);
    apb_read (8'h00, data, err);
    if (data !== 32'hDEAD_BEEF) `lvm_rpt_err(("read mismatch %h", data));

    apb_read (8'hF0, data, err);
    if (!err) `lvm_rpt_err(("expected pslverr at 0xF0"));

    repeat (4) @(posedge clk);
    $finish(0);
  end

  always #500ps clk = ~clk;
endmodule
