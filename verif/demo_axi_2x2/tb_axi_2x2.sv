// Directed testbench for the 2x2 AXI4 crossbar demo. Two
// always_ff-driven traffic generators (one per slave port) issue an
// interleaved stream of writes + reads across both endpoint regions
// so all four AXI bundles see real activity. Two simple combinational
// slave models on the master ports always-accept and ack handshakes.
//
// No pulp axi_test.sv OOP — Verilator-compatible directed SV.
// `dump.fst` is produced when +define+DUMP is passed (lvm_core sets
// up $dumpfile/$dumpvars on the VERILATOR branch).
`include "lvm_core.sv"

`define TB_CLK_PERIOD 5ns

module tb_axi_2x2;

  `LVM_INIT("tb_axi_2x2")

  // ── Geometry ───────────────────────────────────────────────────
  localparam int ADDR_W   = 32;
  localparam int DATA_W   = 32;
  localparam int STRB_W   = DATA_W/8;
  localparam int SLV_ID_W = 4;
  localparam int MST_ID_W = SLV_ID_W + 1;  // xbar widens by clog2(NoSlvPorts)

  // ── Clock + reset ──────────────────────────────────────────────
  logic clk;
  logic rst_n;
  initial clk = 1'b0;
  always #`TB_CLK_PERIOD clk = ~clk;

  // ── Flat AXI signals for all four bundles ──────────────────────
  `define DECL_S_AXI(name, IDW)                                                \
    logic                       s_axi_``name``_awvalid;                        \
    logic                       s_axi_``name``_awready;                        \
    logic [IDW-1:0]             s_axi_``name``_awid;                           \
    logic [ADDR_W-1:0]          s_axi_``name``_awaddr;                         \
    axi_pkg::len_t              s_axi_``name``_awlen;                          \
    axi_pkg::size_t             s_axi_``name``_awsize;                         \
    axi_pkg::burst_t            s_axi_``name``_awburst;                        \
    logic                       s_axi_``name``_awlock;                         \
    axi_pkg::cache_t            s_axi_``name``_awcache;                        \
    axi_pkg::prot_t             s_axi_``name``_awprot;                         \
    axi_pkg::qos_t              s_axi_``name``_awqos;                          \
    axi_pkg::region_t           s_axi_``name``_awregion;                       \
    logic                       s_axi_``name``_awuser;                         \
    logic                       s_axi_``name``_wvalid;                         \
    logic                       s_axi_``name``_wready;                         \
    logic [DATA_W-1:0]          s_axi_``name``_wdata;                          \
    logic [STRB_W-1:0]          s_axi_``name``_wstrb;                          \
    logic                       s_axi_``name``_wlast;                          \
    logic                       s_axi_``name``_wuser;                          \
    logic                       s_axi_``name``_bvalid;                         \
    logic                       s_axi_``name``_bready;                         \
    logic [IDW-1:0]             s_axi_``name``_bid;                            \
    axi_pkg::resp_t             s_axi_``name``_bresp;                          \
    logic                       s_axi_``name``_buser;                          \
    logic                       s_axi_``name``_arvalid;                        \
    logic                       s_axi_``name``_arready;                        \
    logic [IDW-1:0]             s_axi_``name``_arid;                           \
    logic [ADDR_W-1:0]          s_axi_``name``_araddr;                         \
    axi_pkg::len_t              s_axi_``name``_arlen;                          \
    axi_pkg::size_t             s_axi_``name``_arsize;                         \
    axi_pkg::burst_t            s_axi_``name``_arburst;                        \
    logic                       s_axi_``name``_arlock;                         \
    axi_pkg::cache_t            s_axi_``name``_arcache;                        \
    axi_pkg::prot_t             s_axi_``name``_arprot;                         \
    axi_pkg::qos_t              s_axi_``name``_arqos;                          \
    axi_pkg::region_t           s_axi_``name``_arregion;                       \
    logic                       s_axi_``name``_aruser;                         \
    logic                       s_axi_``name``_rvalid;                         \
    logic                       s_axi_``name``_rready;                         \
    logic [IDW-1:0]             s_axi_``name``_rid;                            \
    logic [DATA_W-1:0]          s_axi_``name``_rdata;                          \
    axi_pkg::resp_t             s_axi_``name``_rresp;                          \
    logic                       s_axi_``name``_rlast;                          \
    logic                       s_axi_``name``_ruser;

  `define DECL_M_AXI(name, IDW)                                                \
    logic                       m_axi_``name``_awvalid;                        \
    logic                       m_axi_``name``_awready;                        \
    logic [IDW-1:0]             m_axi_``name``_awid;                           \
    logic [ADDR_W-1:0]          m_axi_``name``_awaddr;                         \
    axi_pkg::len_t              m_axi_``name``_awlen;                          \
    axi_pkg::size_t             m_axi_``name``_awsize;                         \
    axi_pkg::burst_t            m_axi_``name``_awburst;                        \
    logic                       m_axi_``name``_awlock;                         \
    axi_pkg::cache_t            m_axi_``name``_awcache;                        \
    axi_pkg::prot_t             m_axi_``name``_awprot;                         \
    axi_pkg::qos_t              m_axi_``name``_awqos;                          \
    axi_pkg::region_t           m_axi_``name``_awregion;                       \
    logic                       m_axi_``name``_awuser;                         \
    logic                       m_axi_``name``_wvalid;                         \
    logic                       m_axi_``name``_wready;                         \
    logic [DATA_W-1:0]          m_axi_``name``_wdata;                          \
    logic [STRB_W-1:0]          m_axi_``name``_wstrb;                          \
    logic                       m_axi_``name``_wlast;                          \
    logic                       m_axi_``name``_wuser;                          \
    logic                       m_axi_``name``_bvalid;                         \
    logic                       m_axi_``name``_bready;                         \
    logic [IDW-1:0]             m_axi_``name``_bid;                            \
    axi_pkg::resp_t             m_axi_``name``_bresp;                          \
    logic                       m_axi_``name``_buser;                          \
    logic                       m_axi_``name``_arvalid;                        \
    logic                       m_axi_``name``_arready;                        \
    logic [IDW-1:0]             m_axi_``name``_arid;                           \
    logic [ADDR_W-1:0]          m_axi_``name``_araddr;                         \
    axi_pkg::len_t              m_axi_``name``_arlen;                          \
    axi_pkg::size_t             m_axi_``name``_arsize;                         \
    axi_pkg::burst_t            m_axi_``name``_arburst;                        \
    logic                       m_axi_``name``_arlock;                         \
    axi_pkg::cache_t            m_axi_``name``_arcache;                        \
    axi_pkg::prot_t             m_axi_``name``_arprot;                         \
    axi_pkg::qos_t              m_axi_``name``_arqos;                          \
    axi_pkg::region_t           m_axi_``name``_arregion;                       \
    logic                       m_axi_``name``_aruser;                         \
    logic                       m_axi_``name``_rvalid;                         \
    logic                       m_axi_``name``_rready;                         \
    logic [IDW-1:0]             m_axi_``name``_rid;                            \
    logic [DATA_W-1:0]          m_axi_``name``_rdata;                          \
    axi_pkg::resp_t             m_axi_``name``_rresp;                          \
    logic                       m_axi_``name``_rlast;                          \
    logic                       m_axi_``name``_ruser;

  `DECL_S_AXI(in0,  SLV_ID_W)
  `DECL_S_AXI(in1,  SLV_ID_W)
  `DECL_M_AXI(out0, MST_ID_W)
  `DECL_M_AXI(out1, MST_ID_W)

  // ── DUT ────────────────────────────────────────────────────────
  axi_2x2 #(
    .ADDR_W (ADDR_W),
    .DATA_W (DATA_W),
    .ID_W   (SLV_ID_W)
  ) dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .test_en (1'b0),
    .*
  );

  // ── Synchronous master traffic FSM ─────────────────────────────
  // Pure always_ff with NB assigns. Cleanly avoids the
  // initial-block-vs-always_ff sampling race that swallows
  // single-cycle handshakes when drives are issued via blocking
  // assigns in initials.
  //
  // States (per master): IDLE → AW_W → WAIT_B → AR → WAIT_R → IDLE
  // (each transition takes 1 cycle through the xbar). Repeats until
  // NWR writes + NRD reads have completed.

  `define MASTER_FSM(name, NWR, NRD, ID_BASE)                                  \
    typedef enum logic [2:0] {                                                 \
      name``_S_IDLE, name``_S_AW_W, name``_S_WAIT_B,                           \
      name``_S_AR,   name``_S_WAIT_R, name``_S_DONE                            \
    } name``_state_e;                                                          \
    name``_state_e name``_state;                                               \
    int unsigned   name``_w_idx, name``_r_idx;                                 \
                                                                               \
    always_ff @(posedge clk or negedge rst_n) begin                            \
      if (!rst_n) begin                                                        \
        name``_state <= name``_S_IDLE;                                         \
        name``_w_idx <= '0;                                                    \
        name``_r_idx <= '0;                                                    \
        s_axi_``name``_awvalid <= 1'b0;                                        \
        s_axi_``name``_wvalid  <= 1'b0;                                        \
        s_axi_``name``_wlast   <= 1'b0;                                        \
        s_axi_``name``_bready  <= 1'b1;                                        \
        s_axi_``name``_arvalid <= 1'b0;                                        \
        s_axi_``name``_rready  <= 1'b1;                                        \
      end else begin                                                           \
        case (name``_state)                                                    \
          name``_S_IDLE: begin                                                 \
            if (name``_w_idx < NWR) begin                                      \
              s_axi_``name``_awvalid <= 1'b1;                                  \
              s_axi_``name``_awid    <= ID_BASE + name``_w_idx[1:0];           \
              s_axi_``name``_awaddr  <=                                        \
                ((name``_w_idx & 1) ? 32'h1000_0000 : 32'h0000_0000)           \
                | (name``_w_idx << 2);                                         \
              s_axi_``name``_awlen   <= '0;                                    \
              s_axi_``name``_awsize  <= axi_pkg::size_t'($clog2(STRB_W));      \
              s_axi_``name``_awburst <= axi_pkg::BURST_INCR;                   \
              s_axi_``name``_wvalid  <= 1'b1;                                  \
              s_axi_``name``_wdata   <= {ID_BASE, name``_w_idx[27:0]};         \
              s_axi_``name``_wstrb   <= '1;                                    \
              s_axi_``name``_wlast   <= 1'b1;                                  \
              name``_state <= name``_S_AW_W;                                   \
            end else if (name``_r_idx < NRD) begin                             \
              s_axi_``name``_arvalid <= 1'b1;                                  \
              s_axi_``name``_arid    <= ID_BASE + name``_r_idx[1:0];           \
              s_axi_``name``_araddr  <=                                        \
                ((name``_r_idx & 1) ? 32'h1000_0000 : 32'h0000_0000)           \
                | (name``_r_idx << 2);                                         \
              s_axi_``name``_arlen   <= '0;                                    \
              s_axi_``name``_arsize  <= axi_pkg::size_t'($clog2(STRB_W));      \
              s_axi_``name``_arburst <= axi_pkg::BURST_INCR;                   \
              name``_state <= name``_S_AR;                                     \
            end else begin                                                     \
              name``_state <= name``_S_DONE;                                   \
            end                                                                \
          end                                                                  \
          name``_S_AW_W: begin                                                 \
            if (s_axi_``name``_awvalid && s_axi_``name``_awready)              \
              s_axi_``name``_awvalid <= 1'b0;                                  \
            if (s_axi_``name``_wvalid && s_axi_``name``_wready) begin          \
              s_axi_``name``_wvalid <= 1'b0;                                   \
              s_axi_``name``_wlast  <= 1'b0;                                   \
            end                                                                \
            if ((!s_axi_``name``_awvalid                                       \
                  || s_axi_``name``_awready)                                   \
                && (!s_axi_``name``_wvalid                                     \
                     || s_axi_``name``_wready)) begin                          \
              name``_state <= name``_S_WAIT_B;                                 \
            end                                                                \
          end                                                                  \
          name``_S_WAIT_B: begin                                               \
            if (s_axi_``name``_bvalid) begin                                   \
              name``_w_idx <= name``_w_idx + 1;                                \
              name``_state <= name``_S_IDLE;                                   \
            end                                                                \
          end                                                                  \
          name``_S_AR: begin                                                   \
            if (s_axi_``name``_arvalid && s_axi_``name``_arready) begin        \
              s_axi_``name``_arvalid <= 1'b0;                                  \
              name``_state <= name``_S_WAIT_R;                                 \
            end                                                                \
          end                                                                  \
          name``_S_WAIT_R: begin                                               \
            if (s_axi_``name``_rvalid && s_axi_``name``_rlast) begin           \
              name``_r_idx <= name``_r_idx + 1;                                \
              name``_state <= name``_S_IDLE;                                   \
            end                                                                \
          end                                                                  \
          name``_S_DONE: begin                                                 \
            /* idle */                                                         \
          end                                                                  \
          default: name``_state <= name``_S_IDLE;                              \
        endcase                                                                \
      end                                                                      \
    end

  `MASTER_FSM(in0, 128, 128, 4'h1)
  `MASTER_FSM(in1, 128, 128, 4'h2)

  // Tie unused master-side fields to don't-care defaults so the
  // wrapper doesn't see undriven inputs.
  `define MASTER_TIEOFFS(name)                                                  \
    assign s_axi_``name``_awlock   = 1'b0;                                      \
    assign s_axi_``name``_awcache  = '0;                                        \
    assign s_axi_``name``_awprot   = '0;                                        \
    assign s_axi_``name``_awqos    = '0;                                        \
    assign s_axi_``name``_awregion = '0;                                        \
    assign s_axi_``name``_awuser   = 1'b0;                                      \
    assign s_axi_``name``_wstrb    = '1;                                        \
    assign s_axi_``name``_wuser    = 1'b0;                                      \
    assign s_axi_``name``_arlock   = 1'b0;                                      \
    assign s_axi_``name``_arcache  = '0;                                        \
    assign s_axi_``name``_arprot   = '0;                                        \
    assign s_axi_``name``_arqos    = '0;                                        \
    assign s_axi_``name``_arregion = '0;                                        \
    assign s_axi_``name``_aruser   = 1'b0;

  `MASTER_TIEOFFS(in0)
  `MASTER_TIEOFFS(in1)

  // ── Synchronous slave responder ────────────────────────────────
  // Same-cycle ack on aw/w/ar; bvalid stays high until accepted;
  // rvalid stays high until accepted. Read data echoes the address.

  `define SLAVE_MEM(name)                                                       \
    logic [MST_ID_W-1:0] name``_aw_id_q;                                        \
    logic [ADDR_W-1:0]   name``_aw_addr_q;                                      \
    logic                name``_aw_seen;                                        \
    logic                name``_w_last_seen;                                    \
    logic [MST_ID_W-1:0] name``_ar_id_q;                                        \
    logic [ADDR_W-1:0]   name``_ar_addr_q;                                      \
    logic                name``_ar_seen;                                        \
                                                                                \
    assign m_axi_``name``_awready = 1'b1;                                       \
    assign m_axi_``name``_wready  = 1'b1;                                       \
    assign m_axi_``name``_arready = 1'b1;                                       \
                                                                                \
    always_ff @(posedge clk or negedge rst_n) begin                             \
      if (!rst_n) begin                                                         \
        name``_aw_id_q     <= '0;                                               \
        name``_aw_addr_q   <= '0;                                               \
        name``_aw_seen     <= 1'b0;                                             \
        name``_w_last_seen <= 1'b0;                                             \
        m_axi_``name``_bvalid <= 1'b0;                                          \
        m_axi_``name``_bid    <= '0;                                            \
        m_axi_``name``_bresp  <= axi_pkg::RESP_OKAY;                            \
        m_axi_``name``_buser  <= 1'b0;                                          \
      end else begin                                                            \
        if (m_axi_``name``_bvalid && m_axi_``name``_bready) begin               \
          m_axi_``name``_bvalid <= 1'b0;                                        \
          name``_aw_seen        <= 1'b0;                                        \
          name``_w_last_seen    <= 1'b0;                                        \
        end                                                                     \
        if (m_axi_``name``_awvalid && m_axi_``name``_awready) begin             \
          name``_aw_id_q   <= m_axi_``name``_awid;                              \
          name``_aw_addr_q <= m_axi_``name``_awaddr;                            \
          name``_aw_seen   <= 1'b1;                                             \
        end                                                                     \
        if (m_axi_``name``_wvalid && m_axi_``name``_wready                      \
            && m_axi_``name``_wlast) begin                                      \
          name``_w_last_seen <= 1'b1;                                           \
        end                                                                     \
        if ((name``_aw_seen                                                     \
                 || (m_axi_``name``_awvalid && m_axi_``name``_awready))         \
            && (name``_w_last_seen                                              \
                 || (m_axi_``name``_wvalid && m_axi_``name``_wready             \
                     && m_axi_``name``_wlast))                                  \
            && !m_axi_``name``_bvalid) begin                                    \
          m_axi_``name``_bvalid <= 1'b1;                                        \
          m_axi_``name``_bid    <=                                              \
            (m_axi_``name``_awvalid && m_axi_``name``_awready)                  \
              ? m_axi_``name``_awid : name``_aw_id_q;                           \
        end                                                                     \
      end                                                                       \
    end                                                                         \
                                                                                \
    always_ff @(posedge clk or negedge rst_n) begin                             \
      if (!rst_n) begin                                                         \
        name``_ar_id_q   <= '0;                                                 \
        name``_ar_addr_q <= '0;                                                 \
        name``_ar_seen   <= 1'b0;                                               \
        m_axi_``name``_rvalid <= 1'b0;                                          \
        m_axi_``name``_rid    <= '0;                                            \
        m_axi_``name``_rdata  <= '0;                                            \
        m_axi_``name``_rresp  <= axi_pkg::RESP_OKAY;                            \
        m_axi_``name``_rlast  <= 1'b0;                                          \
        m_axi_``name``_ruser  <= 1'b0;                                          \
      end else begin                                                            \
        if (m_axi_``name``_rvalid && m_axi_``name``_rready) begin               \
          m_axi_``name``_rvalid <= 1'b0;                                        \
          m_axi_``name``_rlast  <= 1'b0;                                        \
          name``_ar_seen        <= 1'b0;                                        \
        end                                                                     \
        if (m_axi_``name``_arvalid && m_axi_``name``_arready) begin             \
          name``_ar_id_q   <= m_axi_``name``_arid;                              \
          name``_ar_addr_q <= m_axi_``name``_araddr;                            \
          name``_ar_seen   <= 1'b1;                                             \
        end                                                                     \
        if ((name``_ar_seen                                                     \
                 || (m_axi_``name``_arvalid && m_axi_``name``_arready))         \
            && !m_axi_``name``_rvalid) begin                                    \
          m_axi_``name``_rvalid <= 1'b1;                                        \
          m_axi_``name``_rid    <=                                              \
            (m_axi_``name``_arvalid && m_axi_``name``_arready)                  \
              ? m_axi_``name``_arid : name``_ar_id_q;                           \
          m_axi_``name``_rdata  <=                                              \
            (m_axi_``name``_arvalid && m_axi_``name``_arready)                  \
              ? m_axi_``name``_araddr : name``_ar_addr_q;                       \
          m_axi_``name``_rlast  <= 1'b1;                                        \
        end                                                                     \
      end                                                                       \
    end

  `SLAVE_MEM(out0)
  `SLAVE_MEM(out1)

  // ── Test sequence ──────────────────────────────────────────────
  int cycle_count;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) cycle_count <= '0;
    else        cycle_count <= cycle_count + 1;
  end

  initial begin
    rst_n = 1'b0;
    repeat (10) @(posedge clk);
    rst_n = 1'b1;
    `lvm_rpt_inf(("reset deasserted"));

    repeat (2000) @(posedge clk);

    `lvm_rpt_inf(("simulation done at cycle=%0d (in0 w=%0d r=%0d, in1 w=%0d r=%0d)",
        cycle_count, in0_w_idx, in0_r_idx, in1_w_idx, in1_r_idx));
    $finish(0);
  end

endmodule
