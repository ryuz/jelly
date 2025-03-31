
`timescale 1 ns / 1 ps

module design_1
   (M_AXI_HPM0_FPD_0_araddr,
    M_AXI_HPM0_FPD_0_arburst,
    M_AXI_HPM0_FPD_0_arcache,
    M_AXI_HPM0_FPD_0_arid,
    M_AXI_HPM0_FPD_0_arlen,
    M_AXI_HPM0_FPD_0_arlock,
    M_AXI_HPM0_FPD_0_arprot,
    M_AXI_HPM0_FPD_0_arqos,
    M_AXI_HPM0_FPD_0_arready,
    M_AXI_HPM0_FPD_0_arsize,
    M_AXI_HPM0_FPD_0_aruser,
    M_AXI_HPM0_FPD_0_arvalid,
    M_AXI_HPM0_FPD_0_awaddr,
    M_AXI_HPM0_FPD_0_awburst,
    M_AXI_HPM0_FPD_0_awcache,
    M_AXI_HPM0_FPD_0_awid,
    M_AXI_HPM0_FPD_0_awlen,
    M_AXI_HPM0_FPD_0_awlock,
    M_AXI_HPM0_FPD_0_awprot,
    M_AXI_HPM0_FPD_0_awqos,
    M_AXI_HPM0_FPD_0_awready,
    M_AXI_HPM0_FPD_0_awsize,
    M_AXI_HPM0_FPD_0_awuser,
    M_AXI_HPM0_FPD_0_awvalid,
    M_AXI_HPM0_FPD_0_bid,
    M_AXI_HPM0_FPD_0_bready,
    M_AXI_HPM0_FPD_0_bresp,
    M_AXI_HPM0_FPD_0_bvalid,
    M_AXI_HPM0_FPD_0_rdata,
    M_AXI_HPM0_FPD_0_rid,
    M_AXI_HPM0_FPD_0_rlast,
    M_AXI_HPM0_FPD_0_rready,
    M_AXI_HPM0_FPD_0_rresp,
    M_AXI_HPM0_FPD_0_rvalid,
    M_AXI_HPM0_FPD_0_wdata,
    M_AXI_HPM0_FPD_0_wlast,
    M_AXI_HPM0_FPD_0_wready,
    M_AXI_HPM0_FPD_0_wstrb,
    M_AXI_HPM0_FPD_0_wvalid,
    pl_clk0_0,
    pl_resetn0_0);
  output [39:0]M_AXI_HPM0_FPD_0_araddr;
  output [1:0]M_AXI_HPM0_FPD_0_arburst;
  output [3:0]M_AXI_HPM0_FPD_0_arcache;
  output [15:0]M_AXI_HPM0_FPD_0_arid;
  output [7:0]M_AXI_HPM0_FPD_0_arlen;
  output M_AXI_HPM0_FPD_0_arlock;
  output [2:0]M_AXI_HPM0_FPD_0_arprot;
  output [3:0]M_AXI_HPM0_FPD_0_arqos;
  input M_AXI_HPM0_FPD_0_arready;
  output [2:0]M_AXI_HPM0_FPD_0_arsize;
  output [15:0]M_AXI_HPM0_FPD_0_aruser;
  output M_AXI_HPM0_FPD_0_arvalid;
  output [39:0]M_AXI_HPM0_FPD_0_awaddr;
  output [1:0]M_AXI_HPM0_FPD_0_awburst;
  output [3:0]M_AXI_HPM0_FPD_0_awcache;
  output [15:0]M_AXI_HPM0_FPD_0_awid;
  output [7:0]M_AXI_HPM0_FPD_0_awlen;
  output M_AXI_HPM0_FPD_0_awlock;
  output [2:0]M_AXI_HPM0_FPD_0_awprot;
  output [3:0]M_AXI_HPM0_FPD_0_awqos;
  input M_AXI_HPM0_FPD_0_awready;
  output [2:0]M_AXI_HPM0_FPD_0_awsize;
  output [15:0]M_AXI_HPM0_FPD_0_awuser;
  output M_AXI_HPM0_FPD_0_awvalid;
  input [15:0]M_AXI_HPM0_FPD_0_bid;
  output M_AXI_HPM0_FPD_0_bready;
  input [1:0]M_AXI_HPM0_FPD_0_bresp;
  input M_AXI_HPM0_FPD_0_bvalid;
  input [127:0]M_AXI_HPM0_FPD_0_rdata;
  input [15:0]M_AXI_HPM0_FPD_0_rid;
  input M_AXI_HPM0_FPD_0_rlast;
  output M_AXI_HPM0_FPD_0_rready;
  input [1:0]M_AXI_HPM0_FPD_0_rresp;
  input M_AXI_HPM0_FPD_0_rvalid;
  output [127:0]M_AXI_HPM0_FPD_0_wdata;
  output M_AXI_HPM0_FPD_0_wlast;
  input M_AXI_HPM0_FPD_0_wready;
  output [15:0]M_AXI_HPM0_FPD_0_wstrb;
  output M_AXI_HPM0_FPD_0_wvalid;
  output pl_clk0_0;
  output pl_resetn0_0;

  wire [39:0]M_AXI_HPM0_FPD_0_araddr;
  wire [1:0]M_AXI_HPM0_FPD_0_arburst;
  wire [3:0]M_AXI_HPM0_FPD_0_arcache;
  wire [15:0]M_AXI_HPM0_FPD_0_arid;
  wire [7:0]M_AXI_HPM0_FPD_0_arlen;
  wire M_AXI_HPM0_FPD_0_arlock;
  wire [2:0]M_AXI_HPM0_FPD_0_arprot;
  wire [3:0]M_AXI_HPM0_FPD_0_arqos;
  wire M_AXI_HPM0_FPD_0_arready;
  wire [2:0]M_AXI_HPM0_FPD_0_arsize;
  wire [15:0]M_AXI_HPM0_FPD_0_aruser;
  wire M_AXI_HPM0_FPD_0_arvalid;
  wire [39:0]M_AXI_HPM0_FPD_0_awaddr;
  wire [1:0]M_AXI_HPM0_FPD_0_awburst;
  wire [3:0]M_AXI_HPM0_FPD_0_awcache;
  wire [15:0]M_AXI_HPM0_FPD_0_awid;
  wire [7:0]M_AXI_HPM0_FPD_0_awlen;
  wire M_AXI_HPM0_FPD_0_awlock;
  wire [2:0]M_AXI_HPM0_FPD_0_awprot;
  wire [3:0]M_AXI_HPM0_FPD_0_awqos;
  wire M_AXI_HPM0_FPD_0_awready;
  wire [2:0]M_AXI_HPM0_FPD_0_awsize;
  wire [15:0]M_AXI_HPM0_FPD_0_awuser;
  wire M_AXI_HPM0_FPD_0_awvalid;
  wire [15:0]M_AXI_HPM0_FPD_0_bid;
  wire M_AXI_HPM0_FPD_0_bready;
  wire [1:0]M_AXI_HPM0_FPD_0_bresp;
  wire M_AXI_HPM0_FPD_0_bvalid;
  wire [127:0]M_AXI_HPM0_FPD_0_rdata;
  wire [15:0]M_AXI_HPM0_FPD_0_rid;
  wire M_AXI_HPM0_FPD_0_rlast;
  wire M_AXI_HPM0_FPD_0_rready;
  wire [1:0]M_AXI_HPM0_FPD_0_rresp;
  wire M_AXI_HPM0_FPD_0_rvalid;
  wire [127:0]M_AXI_HPM0_FPD_0_wdata;
  wire M_AXI_HPM0_FPD_0_wlast;
  wire M_AXI_HPM0_FPD_0_wready;
  wire [15:0]M_AXI_HPM0_FPD_0_wstrb;
  wire M_AXI_HPM0_FPD_0_wvalid;
  wire pl_clk0_0;
  wire pl_resetn0_0;


    // top から force するための信号
    logic         aresetn ;
    logic         aclk    ;
    logic [39:0]  awaddr  ;
    logic [2:0]   awprot  ;
    logic         awvalid ;
    logic         awready ;
    logic [127:0] wdata   ;
    logic [15:0]  wstrb   ;
    logic         wvalid  ;
    logic         wready  ;
    logic [1:0]   bresp   ;
    logic         bvalid  ;
    logic         bready  ;
    logic [39:0]  araddr  ;
    logic [2:0]   arprot  ;
    logic         arvalid ;
    logic         arready ;
    logic [127:0] rdata   ;
    logic [1:0]   rresp   ;
    logic         rvalid  ;
    logic         rready  ;

    assign M_AXI_HPM0_FPD_0_araddr  = araddr  ;
    assign M_AXI_HPM0_FPD_0_arburst = '0      ;
    assign M_AXI_HPM0_FPD_0_arcache = '0      ;
    assign M_AXI_HPM0_FPD_0_arid    = '0      ;
    assign M_AXI_HPM0_FPD_0_arlen   = '0      ;
    assign M_AXI_HPM0_FPD_0_arlock  = '0      ;
    assign M_AXI_HPM0_FPD_0_arprot  = arprot  ;
    assign M_AXI_HPM0_FPD_0_arqos   = '0      ;
    assign M_AXI_HPM0_FPD_0_arsize  = '0      ;
    assign M_AXI_HPM0_FPD_0_aruser  = '0      ;
    assign M_AXI_HPM0_FPD_0_arvalid = arvalid ;
    assign M_AXI_HPM0_FPD_0_awaddr  = awaddr  ;
    assign M_AXI_HPM0_FPD_0_awburst = '0      ;
    assign M_AXI_HPM0_FPD_0_awcache = '0      ;
    assign M_AXI_HPM0_FPD_0_awid    = '0      ;
    assign M_AXI_HPM0_FPD_0_awlen   = '0      ;
    assign M_AXI_HPM0_FPD_0_awlock  = '0      ;
    assign M_AXI_HPM0_FPD_0_awprot  = awprot  ;
    assign M_AXI_HPM0_FPD_0_awqos   = '0      ;
    assign M_AXI_HPM0_FPD_0_awsize  = '0      ;
    assign M_AXI_HPM0_FPD_0_awuser  = '0      ;
    assign M_AXI_HPM0_FPD_0_awvalid = awvalid ;
    assign M_AXI_HPM0_FPD_0_bready  = bready  ;
    assign M_AXI_HPM0_FPD_0_rready  = rready  ;
    assign M_AXI_HPM0_FPD_0_wdata   = wdata   ;
    assign M_AXI_HPM0_FPD_0_wlast   = '0      ;
    assign M_AXI_HPM0_FPD_0_wstrb   = wstrb   ;
    assign M_AXI_HPM0_FPD_0_wvalid  = wvalid  ;
    assign pl_clk0_0                = aclk    ;
    assign pl_resetn0_0             = aresetn ;

    assign arready = M_AXI_HPM0_FPD_0_arready ;
    assign awready = M_AXI_HPM0_FPD_0_awready ;
    assign bresp   = M_AXI_HPM0_FPD_0_bresp   ;
    assign bvalid  = M_AXI_HPM0_FPD_0_bvalid  ;
    assign rdata   = M_AXI_HPM0_FPD_0_rdata   ;
    assign rresp   = M_AXI_HPM0_FPD_0_rresp   ;
    assign rvalid  = M_AXI_HPM0_FPD_0_rvalid  ;
    assign wready  = M_AXI_HPM0_FPD_0_wready  ;

endmodule
