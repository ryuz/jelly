
`timescale 1 ns / 1 ps


module design_1
   (core_clk,
    core_reset,
    fan_en,
    m_axi4_aclk,
    m_axi4_araddr,
    m_axi4_arburst,
    m_axi4_arcache,
    m_axi4_aresetn,
    m_axi4_arid,
    m_axi4_arlen,
    m_axi4_arlock,
    m_axi4_arprot,
    m_axi4_arqos,
    m_axi4_arready,
    m_axi4_arregion,
    m_axi4_arsize,
    m_axi4_aruser,
    m_axi4_arvalid,
    m_axi4_awaddr,
    m_axi4_awburst,
    m_axi4_awcache,
    m_axi4_awid,
    m_axi4_awlen,
    m_axi4_awlock,
    m_axi4_awprot,
    m_axi4_awqos,
    m_axi4_awready,
    m_axi4_awregion,
    m_axi4_awsize,
    m_axi4_awuser,
    m_axi4_awvalid,
    m_axi4_bid,
    m_axi4_bready,
    m_axi4_bresp,
    m_axi4_bvalid,
    m_axi4_rdata,
    m_axi4_rid,
    m_axi4_rlast,
    m_axi4_rready,
    m_axi4_rresp,
    m_axi4_rvalid,
    m_axi4_wdata,
    m_axi4_wlast,
    m_axi4_wready,
    m_axi4_wstrb,
    m_axi4_wvalid,
    m_axi4l_aclk,
    m_axi4l_araddr,
    m_axi4l_aresetn,
    m_axi4l_arprot,
    m_axi4l_arready,
    m_axi4l_arvalid,
    m_axi4l_awaddr,
    m_axi4l_awprot,
    m_axi4l_awready,
    m_axi4l_awvalid,
    m_axi4l_bready,
    m_axi4l_bresp,
    m_axi4l_bvalid,
    m_axi4l_rdata,
    m_axi4l_rready,
    m_axi4l_rresp,
    m_axi4l_rvalid,
    m_axi4l_wdata,
    m_axi4l_wready,
    m_axi4l_wstrb,
    m_axi4l_wvalid);
  output core_clk;
  output [0:0]core_reset;
  output [0:0]fan_en;
  output m_axi4_aclk;
  output [39:0]m_axi4_araddr;
  output [1:0]m_axi4_arburst;
  output [3:0]m_axi4_arcache;
  output [0:0]m_axi4_aresetn;
  output [15:0]m_axi4_arid;
  output [7:0]m_axi4_arlen;
  output [0:0]m_axi4_arlock;
  output [2:0]m_axi4_arprot;
  output [3:0]m_axi4_arqos;
  input [0:0]m_axi4_arready;
  output [3:0]m_axi4_arregion;
  output [2:0]m_axi4_arsize;
  output [15:0]m_axi4_aruser;
  output [0:0]m_axi4_arvalid;
  output [39:0]m_axi4_awaddr;
  output [1:0]m_axi4_awburst;
  output [3:0]m_axi4_awcache;
  output [15:0]m_axi4_awid;
  output [7:0]m_axi4_awlen;
  output [0:0]m_axi4_awlock;
  output [2:0]m_axi4_awprot;
  output [3:0]m_axi4_awqos;
  input [0:0]m_axi4_awready;
  output [3:0]m_axi4_awregion;
  output [2:0]m_axi4_awsize;
  output [15:0]m_axi4_awuser;
  output [0:0]m_axi4_awvalid;
  input [15:0]m_axi4_bid;
  output [0:0]m_axi4_bready;
  input [1:0]m_axi4_bresp;
  input [0:0]m_axi4_bvalid;
  input [31:0]m_axi4_rdata;
  input [15:0]m_axi4_rid;
  input [0:0]m_axi4_rlast;
  output [0:0]m_axi4_rready;
  input [1:0]m_axi4_rresp;
  input [0:0]m_axi4_rvalid;
  output [31:0]m_axi4_wdata;
  output [0:0]m_axi4_wlast;
  input [0:0]m_axi4_wready;
  output [3:0]m_axi4_wstrb;
  output [0:0]m_axi4_wvalid;
  output m_axi4l_aclk;
  output [39:0]m_axi4l_araddr;
  output [0:0]m_axi4l_aresetn;
  output [2:0]m_axi4l_arprot;
  input m_axi4l_arready;
  output m_axi4l_arvalid;
  output [39:0]m_axi4l_awaddr;
  output [2:0]m_axi4l_awprot;
  input m_axi4l_awready;
  output m_axi4l_awvalid;
  output m_axi4l_bready;
  input [1:0]m_axi4l_bresp;
  input m_axi4l_bvalid;
  input [31:0]m_axi4l_rdata;
  output m_axi4l_rready;
  input [1:0]m_axi4l_rresp;
  input m_axi4l_rvalid;
  output [31:0]m_axi4l_wdata;
  input m_axi4l_wready;
  output [3:0]m_axi4l_wstrb;
  output m_axi4l_wvalid;

  wire core_clk;
  wire [0:0]core_reset;
  wire [0:0]fan_en;
  wire m_axi4_aclk;
  wire [39:0]m_axi4_araddr;
  wire [1:0]m_axi4_arburst;
  wire [3:0]m_axi4_arcache;
  wire [0:0]m_axi4_aresetn;
  wire [15:0]m_axi4_arid;
  wire [7:0]m_axi4_arlen;
  wire [0:0]m_axi4_arlock;
  wire [2:0]m_axi4_arprot;
  wire [3:0]m_axi4_arqos;
  wire [0:0]m_axi4_arready;
  wire [3:0]m_axi4_arregion;
  wire [2:0]m_axi4_arsize;
  wire [15:0]m_axi4_aruser;
  wire [0:0]m_axi4_arvalid;
  wire [39:0]m_axi4_awaddr;
  wire [1:0]m_axi4_awburst;
  wire [3:0]m_axi4_awcache;
  wire [15:0]m_axi4_awid;
  wire [7:0]m_axi4_awlen;
  wire [0:0]m_axi4_awlock;
  wire [2:0]m_axi4_awprot;
  wire [3:0]m_axi4_awqos;
  wire [0:0]m_axi4_awready;
  wire [3:0]m_axi4_awregion;
  wire [2:0]m_axi4_awsize;
  wire [15:0]m_axi4_awuser;
  wire [0:0]m_axi4_awvalid;
  wire [15:0]m_axi4_bid;
  wire [0:0]m_axi4_bready;
  wire [1:0]m_axi4_bresp;
  wire [0:0]m_axi4_bvalid;
  wire [31:0]m_axi4_rdata;
  wire [15:0]m_axi4_rid;
  wire [0:0]m_axi4_rlast;
  wire [0:0]m_axi4_rready;
  wire [1:0]m_axi4_rresp;
  wire [0:0]m_axi4_rvalid;
  wire [31:0]m_axi4_wdata;
  wire [0:0]m_axi4_wlast;
  wire [0:0]m_axi4_wready;
  wire [3:0]m_axi4_wstrb;
  wire [0:0]m_axi4_wvalid;
  wire m_axi4l_aclk;
  wire [39:0]m_axi4l_araddr;
  wire [0:0]m_axi4l_aresetn;
  wire [2:0]m_axi4l_arprot;
  wire m_axi4l_arready;
  wire m_axi4l_arvalid;
  wire [39:0]m_axi4l_awaddr;
  wire [2:0]m_axi4l_awprot;
  wire m_axi4l_awready;
  wire m_axi4l_awvalid;
  wire m_axi4l_bready;
  wire [1:0]m_axi4l_bresp;
  wire m_axi4l_bvalid;
  wire [31:0]m_axi4l_rdata;
  wire m_axi4l_rready;
  wire [1:0]m_axi4l_rresp;
  wire m_axi4l_rvalid;
  wire [31:0]m_axi4l_wdata;
  wire m_axi4l_wready;
  wire [3:0]m_axi4l_wstrb;
  wire m_axi4l_wvalid;


    reg     reset;
    reg     clk;
    reg     aclk;

    reg     [39:0]  axi4l_awaddr    ;
    reg     [2:0]   axi4l_awprot    ;
    reg             axi4l_awvalid   ;
    wire            axi4l_awready   ;
    reg     [31:0]  axi4l_wdata     ;
    reg     [3:0]   axi4l_wstrb     ;
    reg             axi4l_wvalid    ;
    wire            axi4l_wready    ;
    wire    [1:0]   axi4l_bresp     ;
    wire            axi4l_bvalid    ;
    reg             axi4l_bready    ;
    reg     [39:0]  axi4l_araddr    ;
    reg     [2:0]   axi4l_arprot    ;
    reg             axi4l_arvalid   ;
    wire            axi4l_arready   ;
    wire    [31:0]  axi4l_rdata     ;
    wire    [1:0]   axi4l_rresp     ;
    wire            axi4l_rvalid    ;
    reg             axi4l_rready    ;

    reg   [15:0]    axi4_awid       ;
    reg   [39:0]    axi4_awaddr     ;
    reg   [1:0]     axi4_awburst    ;
    reg   [3:0]     axi4_awcache    ;
    reg   [7:0]     axi4_awlen      ;
    reg   [0:0]     axi4_awlock     ;
    reg   [2:0]     axi4_awprot     ;
    reg   [3:0]     axi4_awqos      ;
    reg   [3:0]     axi4_awregion   ;
    reg   [2:0]     axi4_awsize     ;
    reg   [15:0]    axi4_awuser     ;
    reg   [0:0]     axi4_awvalid    ;
    wire  [0:0]     axi4_awready    ;
    reg   [0:0]     axi4_wlast      ;
    reg   [31:0]    axi4_wdata      ;
    reg   [3:0]     axi4_wstrb      ;
    reg   [0:0]     axi4_wvalid     ;
    wire  [0:0]     axi4_wready     ;
    wire  [15:0]    axi4_bid        ;
    wire  [1:0]     axi4_bresp      ;
    wire  [0:0]     axi4_bvalid     ;
    reg   [0:0]     axi4_bready     ;
    reg   [39:0]    axi4_araddr     ;
    reg   [1:0]     axi4_arburst    ;
    reg   [3:0]     axi4_arcache    ;
    reg   [15:0]    axi4_arid       ;
    reg   [7:0]     axi4_arlen      ;
    reg   [0:0]     axi4_arlock     ;
    reg   [2:0]     axi4_arprot     ;
    reg   [3:0]     axi4_arqos      ;
    reg   [3:0]     axi4_arregion   ;
    reg   [2:0]     axi4_arsize     ;
    reg   [15:0]    axi4_aruser     ;
    reg   [0:0]     axi4_arvalid    ;
    wire  [0:0]     axi4_arready    ;
    wire  [15:0]    axi4_rid        ;
    wire  [31:0]    axi4_rdata      ;
    wire  [0:0]     axi4_rlast      ;
    wire  [1:0]     axi4_rresp      ;
    wire  [0:0]     axi4_rvalid     ;
    reg   [0:0]     axi4_rready     ;


    assign fan_en = 1'b0;
    assign core_reset = reset;
    assign core_clk   = clk;

    assign m_axi4l_aresetn = ~reset         ;
    assign m_axi4l_aclk    = aclk           ;

    assign m_axi4l_awaddr  = axi4l_awaddr   ;
    assign m_axi4l_awprot  = axi4l_awprot   ;
    assign m_axi4l_awvalid = axi4l_awvalid  ;
    assign m_axi4l_wdata   = axi4l_wdata    ;
    assign m_axi4l_wstrb   = axi4l_wstrb    ;
    assign m_axi4l_wvalid  = axi4l_wvalid   ;
    assign m_axi4l_bready  = axi4l_bready   ;
    assign m_axi4l_araddr  = axi4l_araddr   ;
    assign m_axi4l_arprot  = axi4l_arprot   ;
    assign m_axi4l_arvalid = axi4l_arvalid  ;
    assign m_axi4l_rready  = axi4l_rready   ;
    
    assign axi4l_awready  = m_axi4l_awready ;
    assign axi4l_wready   = m_axi4l_wready  ;
    assign axi4l_bresp    = m_axi4l_bresp   ;
    assign axi4l_bvalid   = m_axi4l_bvalid  ;
    assign axi4l_arready  = m_axi4l_arready ;
    assign axi4l_rdata    = m_axi4l_rdata   ;
    assign axi4l_rresp    = m_axi4l_rresp   ;
    assign axi4l_rvalid   = m_axi4l_rvalid  ;


    assign m_axi4_aresetn = ~reset         ;
    assign m_axi4_aclk    = aclk           ;

    assign m_axi4_awid     = axi4_awid     ;
    assign m_axi4_awaddr   = axi4_awaddr   ;
    assign m_axi4_awburst  = axi4_awburst  ;
    assign m_axi4_awcache  = axi4_awcache  ;
    assign m_axi4_awlen    = axi4_awlen    ;
    assign m_axi4_awlock   = axi4_awlock   ;
    assign m_axi4_awprot   = axi4_awprot   ;
    assign m_axi4_awqos    = axi4_awqos    ;
    assign m_axi4_awregion = axi4_awregion ;
    assign m_axi4_awsize   = axi4_awsize   ;
    assign m_axi4_awuser   = axi4_awuser   ;
    assign m_axi4_awvalid  = axi4_awvalid  ;
    assign m_axi4_wlast    = axi4_wlast    ;
    assign m_axi4_wdata    = axi4_wdata    ;
    assign m_axi4_wstrb    = axi4_wstrb    ;
    assign m_axi4_wvalid   = axi4_wvalid   ;
    assign m_axi4_bready   = axi4_bready   ;
    assign m_axi4_araddr   = axi4_araddr   ;
    assign m_axi4_arburst  = axi4_arburst  ;
    assign m_axi4_arcache  = axi4_arcache  ;
    assign m_axi4_arid     = axi4_arid     ;
    assign m_axi4_arlen    = axi4_arlen    ;
    assign m_axi4_arlock   = axi4_arlock   ;
    assign m_axi4_arprot   = axi4_arprot   ;
    assign m_axi4_arqos    = axi4_arqos    ;
    assign m_axi4_arregion = axi4_arregion ;
    assign m_axi4_arsize   = axi4_arsize   ;
    assign m_axi4_aruser   = axi4_aruser   ;
    assign m_axi4_arvalid  = axi4_arvalid  ;
    assign m_axi4_rready   = axi4_rready   ;

    assign axi4_awready    = m_axi4_awready;
    assign axi4_wready     = m_axi4_wready ;
    assign axi4_bid        = m_axi4_bid    ;
    assign axi4_bresp      = m_axi4_bresp  ;
    assign axi4_bvalid     = m_axi4_bvalid ;
    assign axi4_arready    = m_axi4_arready;
    assign axi4_rid        = m_axi4_rid    ;
    assign axi4_rdata      = m_axi4_rdata  ;
    assign axi4_rlast      = m_axi4_rlast  ;
    assign axi4_rresp      = m_axi4_rresp  ;
    assign axi4_rvalid     = m_axi4_rvalid ;

endmodule
