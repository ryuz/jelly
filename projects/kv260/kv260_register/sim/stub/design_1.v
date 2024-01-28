
`timescale 1 ns / 1 ps

module design_1
   (m_axi4l_aclk,
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
    m_axi4l_wvalid,
    fan_en);
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
  output fan_en;

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
  wire fan_en;

  assign fan_en = 1'b0;

endmodule
