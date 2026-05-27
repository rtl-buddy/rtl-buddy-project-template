// Directed testbench for the 2x2 AXI4 crossbar demo. Two
// always_ff-driven traffic generators (one per slave port) issue an
// interleaved stream of writes + reads. A phase machine periodically
// steers both masters at the same target so the xbar is forced to
// serialise the bursts, and each slave model injects synthetic
// ready-stalls + B/R response delay so the waveform shows real
// back-pressure rather than zero-latency acks.
//
// Phase schedule (cycle_count):
//   WARMUP  [   0 ..  299]  — masters alternate targets, ramp.
//   HOT_T0  [ 300 .. 1099]  — both masters target out0 (slave 0).
//   MIXED   [1100 .. 1899]  — alternating, offset between masters.
//   HOT_T1  [1900 .. 2699]  — both masters target out1 (slave 1).
//   DRAIN   [2700 .. ----]  — masters stop issuing, in-flight drains.
//
// Slave stall personalities:
//   out0 — low-latency, short/frequent ready dips, ~few-cycle B/R delay.
//   out1 — higher-latency, aggressive W stalls, longer B/R delay.
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

  // ── Clock, reset, free-running cycle counter ──────────────────
  logic clk;
  logic rst_n;
  int unsigned cycle_count;
  initial clk = 1'b0;
  always #`TB_CLK_PERIOD clk = ~clk;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) cycle_count <= '0;
    else        cycle_count <= cycle_count + 1;
  end

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

  // ── Phase machine ─────────────────────────────────────────────
  typedef enum logic [2:0] {
    PHASE_WARMUP,
    PHASE_HOT_T0,
    PHASE_MIXED,
    PHASE_HOT_T1,
    PHASE_DRAIN
  } phase_e;

  phase_e current_phase;
  always_comb begin
    if      (cycle_count <  300) current_phase = PHASE_WARMUP;
    else if (cycle_count < 1100) current_phase = PHASE_HOT_T0;
    else if (cycle_count < 1900) current_phase = PHASE_MIXED;
    else if (cycle_count < 2700) current_phase = PHASE_HOT_T1;
    else                          current_phase = PHASE_DRAIN;
  end

  logic in0_issue_en, in1_issue_en;
  always_comb begin
    in0_issue_en = (current_phase != PHASE_DRAIN);
    in1_issue_en = (current_phase != PHASE_DRAIN);
  end

  // Per-master AW / AR target base addresses; declared here so the
  // MASTER_FSM macros can read them in S_IDLE. Their values are driven
  // by the always_comb block placed *after* the macro invocations,
  // because they depend on per-master w_idx / r_idx counters that the
  // macros declare.
  logic [31:0] in0_aw_base, in1_aw_base;
  logic [31:0] in0_ar_base, in1_ar_base;

  // Mix burst lengths: most txns are single-beat, ~1-in-5 are 4-beat
  // (awlen=3), ~1-in-11 are 8-beat (awlen=7). Keeps the W and R streams
  // long enough that the slave ready-stalls have multiple beats to
  // back-pressure against.
  function automatic logic [7:0] pick_burst_len(input int unsigned idx);
    if ((idx % 11) == 0) return 8'd7;
    if ((idx % 5)  == 0) return 8'd3;
    return 8'd0;
  endfunction

  // ── Synchronous master traffic FSM ─────────────────────────────
  // States (per master):
  //   IDLE   → AW_W      (issue AW + first W beat)
  //   AW_W   → WAIT_B    (after AW acked and W_LAST acked)
  //   WAIT_B → AR        (after B acked; sets up AR for matching idx)
  //   AR     → WAIT_R    (after AR acked)
  //   WAIT_R → IDLE      (after R_LAST acked; w/r_idx both incremented)
  //
  // IDLE_GATE is an external signal; when false the FSM holds in IDLE
  // (used by the phase machine to drain at end-of-test).

  `define MASTER_FSM(name, ID_BASE, IDLE_GATE)                                  \
    typedef enum logic [2:0] {                                                  \
      name``_S_IDLE, name``_S_AW_W, name``_S_WAIT_B,                            \
      name``_S_AR,   name``_S_WAIT_R                                            \
    } name``_state_e;                                                           \
    name``_state_e name``_state;                                                \
    int unsigned   name``_w_idx, name``_r_idx;                                  \
    logic [7:0]    name``_aw_len_q;                                             \
    logic [7:0]    name``_w_beat_cnt;                                           \
                                                                                \
    always_ff @(posedge clk or negedge rst_n) begin                             \
      if (!rst_n) begin                                                         \
        name``_state      <= name``_S_IDLE;                                     \
        name``_w_idx      <= '0;                                                \
        name``_r_idx      <= '0;                                                \
        name``_aw_len_q   <= '0;                                                \
        name``_w_beat_cnt <= '0;                                                \
        s_axi_``name``_awvalid <= 1'b0;                                         \
        s_axi_``name``_wvalid  <= 1'b0;                                         \
        s_axi_``name``_wlast   <= 1'b0;                                         \
        s_axi_``name``_bready  <= 1'b1;                                         \
        s_axi_``name``_arvalid <= 1'b0;                                         \
        s_axi_``name``_rready  <= 1'b1;                                         \
      end else begin                                                            \
        case (name``_state)                                                     \
          name``_S_IDLE: begin                                                  \
            if (IDLE_GATE) begin                                                \
              s_axi_``name``_awvalid <= 1'b1;                                   \
              s_axi_``name``_awid    <= ID_BASE + name``_w_idx[1:0];            \
              s_axi_``name``_awaddr  <= name``_aw_base | (name``_w_idx << 5);   \
              s_axi_``name``_awlen   <= pick_burst_len(name``_w_idx);           \
              s_axi_``name``_awsize  <= axi_pkg::size_t'($clog2(STRB_W));       \
              s_axi_``name``_awburst <= axi_pkg::BURST_INCR;                    \
              s_axi_``name``_wvalid  <= 1'b1;                                   \
              s_axi_``name``_wdata   <= {ID_BASE, name``_w_idx[27:0]};          \
              s_axi_``name``_wstrb   <= '1;                                     \
              s_axi_``name``_wlast   <= (pick_burst_len(name``_w_idx) == 8'd0); \
              name``_aw_len_q   <= pick_burst_len(name``_w_idx);                \
              name``_w_beat_cnt <= 8'd0;                                        \
              name``_state <= name``_S_AW_W;                                    \
            end                                                                 \
          end                                                                   \
          name``_S_AW_W: begin                                                  \
            if (s_axi_``name``_awvalid && s_axi_``name``_awready)               \
              s_axi_``name``_awvalid <= 1'b0;                                   \
            if (s_axi_``name``_wvalid && s_axi_``name``_wready) begin           \
              if (name``_w_beat_cnt == name``_aw_len_q) begin                   \
                s_axi_``name``_wvalid <= 1'b0;                                  \
                s_axi_``name``_wlast  <= 1'b0;                                  \
              end else begin                                                    \
                name``_w_beat_cnt <= name``_w_beat_cnt + 8'd1;                  \
                s_axi_``name``_wdata <= s_axi_``name``_wdata + 32'h1;           \
                s_axi_``name``_wlast <=                                         \
                  ((name``_w_beat_cnt + 8'd1) == name``_aw_len_q);              \
              end                                                               \
            end                                                                 \
            if ((!s_axi_``name``_awvalid || s_axi_``name``_awready)             \
                && (s_axi_``name``_wvalid && s_axi_``name``_wready              \
                     && (name``_w_beat_cnt == name``_aw_len_q))) begin          \
              name``_state <= name``_S_WAIT_B;                                  \
            end                                                                 \
          end                                                                   \
          name``_S_WAIT_B: begin                                                \
            if (s_axi_``name``_bvalid) begin                                    \
              name``_w_idx <= name``_w_idx + 1;                                 \
              s_axi_``name``_arvalid <= 1'b1;                                   \
              s_axi_``name``_arid    <= ID_BASE + name``_r_idx[1:0];            \
              s_axi_``name``_araddr  <= name``_ar_base | (name``_r_idx << 5);   \
              s_axi_``name``_arlen   <= pick_burst_len(name``_r_idx);           \
              s_axi_``name``_arsize  <= axi_pkg::size_t'($clog2(STRB_W));       \
              s_axi_``name``_arburst <= axi_pkg::BURST_INCR;                    \
              name``_state <= name``_S_AR;                                      \
            end                                                                 \
          end                                                                   \
          name``_S_AR: begin                                                    \
            if (s_axi_``name``_arvalid && s_axi_``name``_arready) begin         \
              s_axi_``name``_arvalid <= 1'b0;                                   \
              name``_state <= name``_S_WAIT_R;                                  \
            end                                                                 \
          end                                                                   \
          name``_S_WAIT_R: begin                                                \
            if (s_axi_``name``_rvalid && s_axi_``name``_rlast) begin            \
              name``_r_idx <= name``_r_idx + 1;                                 \
              name``_state <= name``_S_IDLE;                                    \
            end                                                                 \
          end                                                                   \
          default: name``_state <= name``_S_IDLE;                               \
        endcase                                                                 \
      end                                                                       \
    end

  `MASTER_FSM(in0, 4'h1, in0_issue_en)
  `MASTER_FSM(in1, 4'h2, in1_issue_en)

  // Per-master target base address selection. During HOT_T0 / HOT_T1
  // both masters point at the same slave so the xbar must serialise
  // the streams; in WARMUP / MIXED / DRAIN the masters alternate, with
  // an inverted toggle on in1 so the round-robin tends to collide
  // rather than be perfectly anti-phased.
  always_comb begin
    case (current_phase)
      PHASE_HOT_T0: begin
        in0_aw_base = 32'h0000_0000;
        in1_aw_base = 32'h0000_0000;
        in0_ar_base = 32'h0000_0000;
        in1_ar_base = 32'h0000_0000;
      end
      PHASE_HOT_T1: begin
        in0_aw_base = 32'h1000_0000;
        in1_aw_base = 32'h1000_0000;
        in0_ar_base = 32'h1000_0000;
        in1_ar_base = 32'h1000_0000;
      end
      default: begin
        in0_aw_base = in0_w_idx[0] ? 32'h1000_0000 : 32'h0000_0000;
        in1_aw_base = in1_w_idx[0] ? 32'h0000_0000 : 32'h1000_0000;
        in0_ar_base = in0_r_idx[0] ? 32'h1000_0000 : 32'h0000_0000;
        in1_ar_base = in1_r_idx[0] ? 32'h0000_0000 : 32'h1000_0000;
      end
    endcase
  end

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

  // ── Synchronous slave responder with synthetic stalls ──────────
  // awready / wready / arready are gated by per-channel "stall every
  // STALL_P cycles for STALL_S cycles" patterns, derived from the
  // shared cycle_count. After the slave has captured a full write
  // (aw + w_last) the bvalid assertion is delayed by B_D cycles; reads
  // assert rvalid R_D cycles after the AR handshake. R bursts walk a
  // beat counter so multi-beat reads return arlen+1 beats with rlast
  // on the last beat. AW / AR acceptance is gated by the in-flight
  // flag so the slave stays single-threaded per direction.
  `define SLAVE_MEM(name, AW_P, AW_S, W_P, W_S, AR_P, AR_S, B_D, R_D)           \
    logic [MST_ID_W-1:0] name``_aw_id_q;                                        \
    logic [ADDR_W-1:0]   name``_aw_addr_q;                                      \
    logic                name``_aw_seen;                                        \
    logic                name``_w_last_seen;                                    \
    logic [3:0]          name``_b_delay_cnt;                                    \
    logic                name``_b_pending;                                      \
    logic [MST_ID_W-1:0] name``_ar_id_q;                                        \
    logic [ADDR_W-1:0]   name``_ar_addr_q;                                      \
    logic [7:0]          name``_ar_len_q;                                       \
    logic                name``_ar_seen;                                        \
    logic [7:0]          name``_r_beat_cnt;                                     \
    logic [3:0]          name``_r_delay_cnt;                                    \
                                                                                \
    wire name``_aw_stall = ((cycle_count % AW_P) < AW_S);                       \
    wire name``_w_stall  = ((cycle_count % W_P)  < W_S);                        \
    wire name``_ar_stall = ((cycle_count % AR_P) < AR_S);                       \
                                                                                \
    assign m_axi_``name``_awready = ~name``_aw_stall && ~name``_aw_seen;        \
    assign m_axi_``name``_wready  = ~name``_w_stall;                            \
    assign m_axi_``name``_arready = ~name``_ar_stall && ~name``_ar_seen;        \
                                                                                \
    always_ff @(posedge clk or negedge rst_n) begin                             \
      if (!rst_n) begin                                                         \
        name``_aw_id_q     <= '0;                                               \
        name``_aw_addr_q   <= '0;                                               \
        name``_aw_seen     <= 1'b0;                                             \
        name``_w_last_seen <= 1'b0;                                             \
        name``_b_pending   <= 1'b0;                                             \
        name``_b_delay_cnt <= '0;                                               \
        m_axi_``name``_bvalid <= 1'b0;                                          \
        m_axi_``name``_bid    <= '0;                                            \
        m_axi_``name``_bresp  <= axi_pkg::RESP_OKAY;                            \
        m_axi_``name``_buser  <= 1'b0;                                          \
      end else begin                                                            \
        if (m_axi_``name``_bvalid && m_axi_``name``_bready) begin               \
          m_axi_``name``_bvalid <= 1'b0;                                        \
          name``_aw_seen        <= 1'b0;                                        \
          name``_w_last_seen    <= 1'b0;                                        \
          name``_b_pending      <= 1'b0;                                        \
          name``_b_delay_cnt    <= '0;                                          \
        end                                                                     \
        if (m_axi_``name``_awvalid && m_axi_``name``_awready) begin             \
          name``_aw_id_q   <= m_axi_``name``_awid;                              \
          name``_aw_addr_q <= m_axi_``name``_awaddr;                            \
          name``_aw_seen   <= 1'b1;                                             \
        end                                                                     \
        if (m_axi_``name``_wvalid && m_axi_``name``_wready                       \
            && m_axi_``name``_wlast) begin                                      \
          name``_w_last_seen <= 1'b1;                                           \
        end                                                                     \
        if (!m_axi_``name``_bvalid && !name``_b_pending                         \
            && (name``_aw_seen                                                  \
                  || (m_axi_``name``_awvalid && m_axi_``name``_awready))        \
            && (name``_w_last_seen                                              \
                  || (m_axi_``name``_wvalid && m_axi_``name``_wready             \
                      && m_axi_``name``_wlast))) begin                          \
          name``_b_pending   <= 1'b1;                                           \
          name``_b_delay_cnt <= '0;                                             \
        end                                                                     \
        if (name``_b_pending && !m_axi_``name``_bvalid) begin                   \
          if (name``_b_delay_cnt >= B_D) begin                                  \
            m_axi_``name``_bvalid <= 1'b1;                                      \
            m_axi_``name``_bid    <= name``_aw_id_q;                            \
          end else begin                                                        \
            name``_b_delay_cnt <= name``_b_delay_cnt + 4'd1;                    \
          end                                                                   \
        end                                                                     \
      end                                                                       \
    end                                                                         \
                                                                                \
    always_ff @(posedge clk or negedge rst_n) begin                             \
      if (!rst_n) begin                                                         \
        name``_ar_id_q     <= '0;                                               \
        name``_ar_addr_q   <= '0;                                               \
        name``_ar_len_q    <= '0;                                               \
        name``_ar_seen     <= 1'b0;                                             \
        name``_r_beat_cnt  <= '0;                                               \
        name``_r_delay_cnt <= '0;                                               \
        m_axi_``name``_rvalid <= 1'b0;                                          \
        m_axi_``name``_rid    <= '0;                                            \
        m_axi_``name``_rdata  <= '0;                                            \
        m_axi_``name``_rresp  <= axi_pkg::RESP_OKAY;                            \
        m_axi_``name``_rlast  <= 1'b0;                                          \
        m_axi_``name``_ruser  <= 1'b0;                                          \
      end else begin                                                            \
        if (m_axi_``name``_arvalid && m_axi_``name``_arready) begin             \
          name``_ar_id_q     <= m_axi_``name``_arid;                            \
          name``_ar_addr_q   <= m_axi_``name``_araddr;                          \
          name``_ar_len_q    <= m_axi_``name``_arlen;                           \
          name``_ar_seen     <= 1'b1;                                           \
          name``_r_beat_cnt  <= '0;                                             \
          name``_r_delay_cnt <= '0;                                             \
        end                                                                     \
        if (m_axi_``name``_rvalid && m_axi_``name``_rready) begin               \
          if (m_axi_``name``_rlast) begin                                       \
            m_axi_``name``_rvalid <= 1'b0;                                      \
            m_axi_``name``_rlast  <= 1'b0;                                      \
            name``_ar_seen        <= 1'b0;                                      \
          end else begin                                                        \
            name``_r_beat_cnt <= name``_r_beat_cnt + 8'd1;                      \
            m_axi_``name``_rdata <= m_axi_``name``_rdata + 32'h1;               \
            m_axi_``name``_rlast <=                                             \
              ((name``_r_beat_cnt + 8'd1) == name``_ar_len_q);                  \
          end                                                                   \
        end                                                                     \
        if (name``_ar_seen && !m_axi_``name``_rvalid) begin                     \
          if (name``_r_delay_cnt >= R_D) begin                                  \
            m_axi_``name``_rvalid <= 1'b1;                                      \
            m_axi_``name``_rid    <= name``_ar_id_q;                            \
            m_axi_``name``_rdata  <= name``_ar_addr_q;                          \
            m_axi_``name``_rlast  <= (name``_ar_len_q == 8'd0);                 \
          end else begin                                                        \
            name``_r_delay_cnt <= name``_r_delay_cnt + 4'd1;                    \
          end                                                                   \
        end                                                                     \
      end                                                                       \
    end

  // out0: low-latency target with short, frequent ready dips.
  //       AW stalls 1-in-7, W stalls 2-in-11, AR stalls 1-in-9,
  //       B+R response delay 2 / 1 cycles.
  `SLAVE_MEM(out0, 7, 1, 11, 2, 9, 1, 2, 1)
  // out1: slower target. AW stalls 3-in-13, W stalls 3-in-8 (heavy on
  //       write-data — bursts feel this), AR stalls 2-in-11, B+R
  //       response delay 5 / 3 cycles.
  `SLAVE_MEM(out1, 13, 3, 8, 3, 11, 2, 5, 3)

  // ── Test sequence ──────────────────────────────────────────────
  initial begin
    rst_n = 1'b0;
    repeat (10) @(posedge clk);
    rst_n = 1'b1;
    `lvm_rpt_inf(("reset deasserted"));

    // Run through warm-up + HOT_T0 + MIXED + HOT_T1 + drain. The phase
    // machine gates new issuance at cycle 2700; another 500 cycles is
    // plenty for the longest in-flight burst-plus-stalls to drain.
    repeat (3200) @(posedge clk);

    `lvm_rpt_inf(("simulation done at cycle=%0d (in0 w=%0d r=%0d, in1 w=%0d r=%0d)",
        cycle_count, in0_w_idx, in0_r_idx, in1_w_idx, in1_r_idx));
    $finish(0);
  end

endmodule
