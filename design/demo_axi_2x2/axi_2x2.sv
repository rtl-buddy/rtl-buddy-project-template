// 2-slave / 2-master AXI4 crossbar built around pulp-platform's
// axi_xbar. Exposes the four AXI bundles as flat port-prefix signals
// (s_axi_in0_*, s_axi_in1_*, m_axi_out0_*, m_axi_out1_*) so the
// rtl-buddy-axi-profiler's discover stage can pick them up.
//
// Address map (32-bit space):
//   m_axi_out0 = [0x0000_0000, 0x1000_0000)
//   m_axi_out1 = [0x1000_0000, 0x2000_0000)
//
// Outside that range the xbar returns DECERR.
`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "axi/port.svh"

module axi_2x2 #(
  parameter int unsigned ADDR_W = 32,
  parameter int unsigned DATA_W = 32,
  parameter int unsigned ID_W   = 4
) (
  input  logic clk,
  input  logic rst_n,

  // Slave port 0 — external master in0 talks to us as a slave.
  `AXI_S_PORT(in0, logic [ADDR_W-1:0], logic [DATA_W-1:0],
              logic [DATA_W/8-1:0], logic [ID_W-1:0],
              logic, logic, logic, logic, logic)

  // Slave port 1.
  `AXI_S_PORT(in1, logic [ADDR_W-1:0], logic [DATA_W-1:0],
              logic [DATA_W/8-1:0], logic [ID_W-1:0],
              logic, logic, logic, logic, logic)

  // Master port 0 — we drive external slave out0.
  // The ID grows by $clog2(NoSlvPorts) = 1, so 5 bits.
  `AXI_M_PORT(out0, logic [ADDR_W-1:0], logic [DATA_W-1:0],
              logic [DATA_W/8-1:0], logic [ID_W:0],
              logic, logic, logic, logic, logic)

  // Master port 1.
  `AXI_M_PORT(out1, logic [ADDR_W-1:0], logic [DATA_W-1:0],
              logic [DATA_W/8-1:0], logic [ID_W:0],
              logic, logic, logic, logic, logic)

  input logic test_en
);

  localparam int unsigned NoSlvPorts  = 2;
  localparam int unsigned NoMstPorts  = 2;
  localparam int unsigned MstIdWidth  = ID_W + $clog2(NoSlvPorts);
  localparam int unsigned StrbW       = DATA_W / 8;

  typedef logic [ADDR_W-1:0]    addr_t;
  typedef logic [DATA_W-1:0]    data_t;
  typedef logic [StrbW-1:0]     strb_t;
  typedef logic [ID_W-1:0]      slv_id_t;
  typedef logic [MstIdWidth-1:0] mst_id_t;
  typedef logic                 user_t;

  // ── AXI struct typedefs ──────────────────────────────────────────
  `AXI_TYPEDEF_AW_CHAN_T(slv_aw_t, addr_t, slv_id_t, user_t)
  `AXI_TYPEDEF_AW_CHAN_T(mst_aw_t, addr_t, mst_id_t, user_t)
  `AXI_TYPEDEF_W_CHAN_T (w_t,      data_t, strb_t,  user_t)
  `AXI_TYPEDEF_B_CHAN_T (slv_b_t,  slv_id_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T (mst_b_t,  mst_id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(slv_ar_t, addr_t, slv_id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(mst_ar_t, addr_t, mst_id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T (slv_r_t,  data_t, slv_id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T (mst_r_t,  data_t, mst_id_t, user_t)
  `AXI_TYPEDEF_REQ_T (slv_req_t,  slv_aw_t, w_t, slv_ar_t)
  `AXI_TYPEDEF_REQ_T (mst_req_t,  mst_aw_t, w_t, mst_ar_t)
  `AXI_TYPEDEF_RESP_T(slv_resp_t, slv_b_t, slv_r_t)
  `AXI_TYPEDEF_RESP_T(mst_resp_t, mst_b_t, mst_r_t)

  // ── Internal struct arrays for the xbar ──────────────────────────
  slv_req_t  [NoSlvPorts-1:0] slv_reqs;
  slv_resp_t [NoSlvPorts-1:0] slv_resps;
  mst_req_t  [NoMstPorts-1:0] mst_reqs;
  mst_resp_t [NoMstPorts-1:0] mst_resps;

  // Wire flat slave-side ports to internal structs.
  `AXI_ASSIGN_SLAVE_TO_FLAT(in0, slv_reqs[0], slv_resps[0])
  `AXI_ASSIGN_SLAVE_TO_FLAT(in1, slv_reqs[1], slv_resps[1])
  // Wire flat master-side ports to internal structs.
  `AXI_ASSIGN_MASTER_TO_FLAT(out0, mst_reqs[0], mst_resps[0])
  `AXI_ASSIGN_MASTER_TO_FLAT(out1, mst_reqs[1], mst_resps[1])

  // ── Address map ──────────────────────────────────────────────────
  typedef struct packed {
    int unsigned idx;
    logic [31:0] start_addr;
    logic [31:0] end_addr;
  } rule_32_t;

  localparam rule_32_t [1:0] AddrMap = '{
    '{idx: 32'd1, start_addr: 32'h1000_0000, end_addr: 32'h2000_0000},
    '{idx: 32'd0, start_addr: 32'h0000_0000, end_addr: 32'h1000_0000}
  };

  localparam axi_pkg::xbar_cfg_t XbarCfg = '{
    NoSlvPorts:         NoSlvPorts,
    NoMstPorts:         NoMstPorts,
    MaxMstTrans:        4,
    MaxSlvTrans:        4,
    FallThrough:        1'b0,
    LatencyMode:        axi_pkg::CUT_ALL_AX,
    PipelineStages:     0,
    AxiIdWidthSlvPorts: ID_W,
    AxiIdUsedSlvPorts:  ID_W,
    UniqueIds:          1'b0,
    AxiAddrWidth:       ADDR_W,
    AxiDataWidth:       DATA_W,
    NoAddrRules:        NoMstPorts
  };

  axi_xbar #(
    .Cfg            (XbarCfg),
    .ATOPs          (1'b0),
    .Connectivity   ('1),
    .slv_aw_chan_t  (slv_aw_t),
    .mst_aw_chan_t  (mst_aw_t),
    .w_chan_t       (w_t),
    .slv_b_chan_t   (slv_b_t),
    .mst_b_chan_t   (mst_b_t),
    .slv_ar_chan_t  (slv_ar_t),
    .mst_ar_chan_t  (mst_ar_t),
    .slv_r_chan_t   (slv_r_t),
    .mst_r_chan_t   (mst_r_t),
    .slv_req_t      (slv_req_t),
    .slv_resp_t     (slv_resp_t),
    .mst_req_t      (mst_req_t),
    .mst_resp_t     (mst_resp_t),
    .rule_t         (rule_32_t)
  ) i_xbar (
    .clk_i                 (clk),
    .rst_ni                (rst_n),
    .test_i                (test_en),
    .slv_ports_req_i       (slv_reqs),
    .slv_ports_resp_o      (slv_resps),
    .mst_ports_req_o       (mst_reqs),
    .mst_ports_resp_i      (mst_resps),
    .addr_map_i            (AddrMap),
    .en_default_mst_port_i ('0),
    .default_mst_port_i    ('0)
  );

endmodule
