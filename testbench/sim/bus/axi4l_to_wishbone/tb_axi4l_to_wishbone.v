
`timescale 1ns / 1ps
`default_nettype none


module tb_axi4l_to_wishbone();
    localparam RATE  = 1000.0 / 100.0;
    
    initial begin
        $dumpfile("tb_axi4l_to_wishbone.vcd");
        $dumpvars(0, tb_axi4l_to_wishbone);
        
        #1000000;
            $finish;
    end
    
    reg     aresetn = 1'b0;
    initial #(RATE*100)    aresetn = 1'b1;
    
    reg     aclk = 1'b1;
    always #(RATE/2.0)     aclk = ~aclk;
    
    parameter   AXI4L_ADDR_WIDTH = 32;
    parameter   AXI4L_DATA_SIZE  = 2;                       // 0:8bit, 1:16bit, 2:32bit ...
    parameter   AXI4L_DATA_WIDTH = (8 << AXI4L_DATA_SIZE);
    parameter   AXI4L_STRB_WIDTH = (1 << AXI4L_DATA_SIZE);
    
    wire    [AXI4L_ADDR_WIDTH-1:0]                  axi4l_awaddr;
    wire    [2:0]                                   axi4l_awprot = 0;
    wire                                            axi4l_awvalid;
    wire                                            axi4l_awready;
    wire    [AXI4L_STRB_WIDTH-1:0]                  axi4l_wstrb;
    wire    [AXI4L_DATA_WIDTH-1:0]                  axi4l_wdata;
    wire                                            axi4l_wvalid;
    wire                                            axi4l_wready;
    wire    [1:0]                                   axi4l_bresp;
    wire                                            axi4l_bvalid;
    wire                                            axi4l_bready;
    wire    [AXI4L_ADDR_WIDTH-1:0]                  axi4l_araddr;
    wire    [2:0]                                   axi4l_arprot = 0;
    wire                                            axi4l_arvalid;
    wire                                            axi4l_arready;
    wire    [AXI4L_DATA_WIDTH-1:0]                  axi4l_rdata;
    wire    [1:0]                                   axi4l_rresp;
    wire                                            axi4l_rvalid;
    wire                                            axi4l_rready;
    
    wire                                            wb_rst_o;
    wire                                            wb_clk_o;
    wire    [AXI4L_ADDR_WIDTH-1:AXI4L_DATA_SIZE]    wb_adr_o;
    wire    [AXI4L_DATA_WIDTH-1:0]                  wb_dat_o;
    wire    [AXI4L_DATA_WIDTH-1:0]                  wb_dat_i;
    wire                                            wb_we_o;
    wire    [AXI4L_STRB_WIDTH-1:0]                  wb_sel_o;
    wire                                            wb_stb_o;
    wire                                            wb_ack_i;
    
    jelly_axi4l_to_wishbone
            #(
                .AXI4L_ADDR_WIDTH       (AXI4L_ADDR_WIDTH),
                .AXI4L_DATA_SIZE        (AXI4L_DATA_SIZE)
            )
        i_axi4l_to_wishbone
            (
                .s_axi4l_aresetn        (aresetn),
                .s_axi4l_aclk           (aclk),
                .s_axi4l_awaddr         (axi4l_awaddr),
                .s_axi4l_awprot         (axi4l_awprot),
                .s_axi4l_awvalid        (axi4l_awvalid),
                .s_axi4l_awready        (axi4l_awready),
                .s_axi4l_wstrb          (axi4l_wstrb),
                .s_axi4l_wdata          (axi4l_wdata),
                .s_axi4l_wvalid         (axi4l_wvalid),
                .s_axi4l_wready         (axi4l_wready),
                .s_axi4l_bresp          (axi4l_bresp),
                .s_axi4l_bvalid         (axi4l_bvalid),
                .s_axi4l_bready         (axi4l_bready),
                .s_axi4l_araddr         (axi4l_araddr),
                .s_axi4l_arprot         (axi4l_arprot),
                .s_axi4l_arvalid        (axi4l_arvalid),
                .s_axi4l_arready        (axi4l_arready),
                .s_axi4l_rdata          (axi4l_rdata),
                .s_axi4l_rresp          (axi4l_rresp),
                .s_axi4l_rvalid         (axi4l_rvalid),
                .s_axi4l_rready         (axi4l_rready),
                
                .m_wb_rst_o             (wb_rst_o),
                .m_wb_clk_o             (wb_clk_o),
                .m_wb_adr_o             (wb_adr_o),
                .m_wb_dat_o             (wb_dat_o),
                .m_wb_dat_i             (wb_dat_i),
                .m_wb_we_o              (wb_we_o),
                .m_wb_sel_o             (wb_sel_o),
                .m_wb_stb_o             (wb_stb_o),
                .m_wb_ack_i             (wb_ack_i)
            );
    
    
    reg     [AXI4L_ADDR_WIDTH-1:0]                  reg_axi4l_awaddr;
    reg                                             reg_axi4l_awvalid;
    reg     [AXI4L_STRB_WIDTH-1:0]                  reg_axi4l_wstrb;
    reg     [AXI4L_DATA_WIDTH-1:0]                  reg_axi4l_wdata;
    reg                                             reg_axi4l_wvalid;
    reg                                             reg_axi4l_bready;
    reg     [AXI4L_ADDR_WIDTH-1:0]                  reg_axi4l_araddr;
    reg                                             reg_axi4l_arvalid;
    reg                                             reg_axi4l_rready;
    
    always @(posedge aclk) begin
        if ( ~aresetn ) begin
            reg_axi4l_awaddr  <= 0;
            reg_axi4l_awvalid <= 0;
            reg_axi4l_wstrb   <= 0;
            reg_axi4l_wdata   <= 0;
            reg_axi4l_wvalid  <= 0;
            reg_axi4l_bready  <= 0;
            reg_axi4l_araddr  <= 0;
            reg_axi4l_arvalid <= 0;
            reg_axi4l_rready  <= 0;
        end
        else begin
            if ( !axi4l_awvalid || axi4l_awready ) begin
                reg_axi4l_awvalid <= ({$random()} % 4 == 0);
            end
            
            if ( !axi4l_wvalid || axi4l_wready ) begin
                reg_axi4l_wvalid <= ({$random()} % 4 == 0);
            end
            
            reg_axi4l_bready <= ({$random()} % 4 == 0);
            
            if ( axi4l_awvalid && axi4l_awready ) begin
                reg_axi4l_awaddr <= reg_axi4l_awaddr + (1 << AXI4L_DATA_SIZE);
            end
            
            if ( axi4l_wvalid && axi4l_wready ) begin
                reg_axi4l_wstrb <= reg_axi4l_wstrb + 1;
                reg_axi4l_wdata <= reg_axi4l_wdata + 1;
            end
            
            
            
            if ( !axi4l_arvalid || axi4l_arready ) begin
                reg_axi4l_arvalid <= ({$random()} % 8 == 0);
            end
            
            reg_axi4l_rready <= ({$random()} % 4 == 0);
            
            if ( axi4l_arvalid && axi4l_arready ) begin
                reg_axi4l_araddr <= reg_axi4l_araddr + (1 << AXI4L_DATA_SIZE);
            end
        end
    end
    
    
    assign axi4l_awaddr  = reg_axi4l_awaddr;
    assign axi4l_awvalid = reg_axi4l_awvalid;
    assign axi4l_wstrb   = reg_axi4l_wstrb;
    assign axi4l_wdata   = reg_axi4l_wdata;
    assign axi4l_wvalid  = reg_axi4l_wvalid;
    assign axi4l_bready  = reg_axi4l_bready;
    assign axi4l_araddr  = reg_axi4l_araddr;
    assign axi4l_arvalid = reg_axi4l_arvalid;
    assign axi4l_rready  = reg_axi4l_rready;
    
    reg    [AXI4L_DATA_WIDTH-1:0]   reg_wb_dat_i;
    reg                             reg_wb_ack_i;
    always @(posedge wb_clk_o) begin
        if ( wb_rst_o ) begin
            reg_wb_dat_i <= 0;
            reg_wb_ack_i <= 0;
        end
        else begin
            if ( wb_stb_o && wb_ack_i && ~wb_we_o ) begin
                reg_wb_dat_i <= reg_wb_dat_i + 1;
            end
            reg_wb_ack_i <= {$random()};
        end
    end
    
    assign wb_dat_i = reg_wb_dat_i;
    assign wb_ack_i = wb_stb_o & reg_wb_ack_i;
    
    
    integer count_aw   = 0;
    integer count_w    = 0;
    integer count_b    = 0;
    integer count_ar   = 0;
    integer count_r    = 0;
    integer count_wb_w = 0;
    integer count_wb_r = 0;
    always @(posedge aclk) begin
        if ( ~aresetn ) begin
        end
        else begin
            if ( axi4l_awvalid && axi4l_awready )   count_aw <= count_aw + 1;
            if ( axi4l_wvalid  && axi4l_wready  )   count_w  <= count_w  + 1;
            if ( axi4l_bvalid  && axi4l_bready  )   count_b  <= count_b  + 1;
            if ( axi4l_arvalid && axi4l_arready )   count_ar <= count_ar + 1;
            if ( axi4l_rvalid  && axi4l_rready  )   count_r  <= count_r  + 1;
            
            if ( wb_stb_o && wb_ack_i && wb_we_o  ) count_wb_w <= count_wb_w + 1;
            if ( wb_stb_o && wb_ack_i && !wb_we_o ) count_wb_r <= count_wb_r + 1;
        end
    end
    
endmodule


`default_nettype wire


// end of file
