
`timescale 1 ns / 1 ps

module design_1
   (fan_en,
    m_axi4l_araddr,
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
    m_axi4l_wvalid,
    out_clk,
    out_reset);
  output [0:0]fan_en;
  output [39:0]m_axi4l_araddr;
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
  output out_clk;
  output [0:0]out_reset;

  wire [0:0]fan_en;
  wire [39:0]m_axi4l_araddr;
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
  wire out_clk;
  wire [0:0]out_reset;

    reg     clk;
    reg     reset;

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

    assign out_clk = clk;
    assign fan_en = 1'b0;
    assign out_reset = reset;

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



endmodule
