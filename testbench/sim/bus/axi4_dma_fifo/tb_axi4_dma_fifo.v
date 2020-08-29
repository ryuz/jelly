
`timescale 1ns / 1ps
`default_nettype none


module tb_axi4_dma_fifo();
    localparam RATE      = 1000.0 / 150.3;
    localparam AXI4_RATE = 1000.0 / 200.0;
    
    initial begin
        $dumpfile("tb_axi4_dma_fifo.vcd");
        $dumpvars(0, tb_axi4_dma_fifo);
        
        #1000000;
            $finish;
    end

    reg     reset = 1'b1;
    initial #(RATE*100)     reset = 1'b0;
    
    reg     clk = 1'b1;
    always #(RATE/2.0)      clk = ~clk;
    
    
    wire    aresetn = ~reset;
    
    reg     aclk = 1'b1;
    always #(AXI4_RATE/2.0) aclk = ~aclk;
    
    
    
    localparam  RAND_BUSY = 1;
    
    
    // -----------------------------------------
    //  Core
    // -----------------------------------------
    
    parameter   ASYNC                    = 1;
    parameter   UNIT_WIDTH               = 8;
    parameter   S_DATA_SIZE              = 2;    // 0:8bit, 1:16bit, 2:32bit ...
    
    parameter   AXI4_ID_WIDTH            = 6;
    parameter   AXI4_ADDR_WIDTH          = 32;
    parameter   AXI4_DATA_SIZE           = 2;   // 0:8bit, 1:16bit, 2:32bit ...
    parameter   AXI4_DATA_WIDTH          = (8 << AXI4_DATA_SIZE);
    parameter   AXI4_STRB_WIDTH          = (1 << AXI4_DATA_SIZE);
    parameter   AXI4_LEN_WIDTH           = 8;
    parameter   AXI4_QOS_WIDTH           = 4;
    parameter   AXI4_AWID                = {AXI4_ID_WIDTH{1'b0}};
    parameter   AXI4_AWSIZE              = AXI4_DATA_SIZE;
    parameter   AXI4_AWBURST             = 2'b01;
    parameter   AXI4_AWLOCK              = 1'b0;
    parameter   AXI4_AWCACHE             = 4'b0001;
    parameter   AXI4_AWPROT              = 3'b000;
    parameter   AXI4_AWQOS               = 0;
    parameter   AXI4_AWREGION            = 4'b0000;
    
    parameter   BYPASS_ADDR_OFFSET       = 0;
    parameter   BYPASS_ALIGN             = 0;
    parameter   AXI4_ALIGN               = 12;
    
    parameter   PARAM_ADDR_WIDTH         = AXI4_ADDR_WIDTH;
    parameter   PARAM_SIZE_WIDTH         = 32;
    parameter   PARAM_SIZE_OFFSET        = 1'b0;
    parameter   PARAM_AWLEN_WIDTH        = AXI4_LEN_WIDTH;
    parameter   PARAM_WSTRB_WIDTH        = AXI4_STRB_WIDTH;
    parameter   PARAM_TIMEOUT_WIDTH      = 8;
    
    parameter   S_DATA_WIDTH             = (UNIT_WIDTH << S_DATA_SIZE);
    
    
    reg                                     enable = 1;
    wire                                    busy;
    
    reg     [PARAM_ADDR_WIDTH-1:0]          param_addr    = 32'h0000000;
    reg     [PARAM_SIZE_WIDTH-1:0]          param_size    = 32'h0001000;
    reg     [PARAM_AWLEN_WIDTH-1:0]         param_awlen   = 8'h0f;
    reg     [PARAM_WSTRB_WIDTH-1:0]         param_wstrb   = {PARAM_WSTRB_WIDTH{1'b1}};
    reg     [PARAM_TIMEOUT_WIDTH-1:0]       param_timeout = 8'h0f;
    
    reg     [S_DATA_WIDTH-1:0]              s_data;
    reg                                     s_valid;
    wire                                    s_ready;
    
    wire    [AXI4_ID_WIDTH-1:0]             m_axi4_awid;
    wire    [AXI4_ADDR_WIDTH-1:0]           m_axi4_awaddr;
    wire    [AXI4_LEN_WIDTH-1:0]            m_axi4_awlen;
    wire    [2:0]                           m_axi4_awsize;
    wire    [1:0]                           m_axi4_awburst;
    wire    [0:0]                           m_axi4_awlock;
    wire    [3:0]                           m_axi4_awcache;
    wire    [2:0]                           m_axi4_awprot;
    wire    [AXI4_QOS_WIDTH-1:0]            m_axi4_awqos;
    wire    [3:0]                           m_axi4_awregion;
    wire                                    m_axi4_awvalid;
    wire                                    m_axi4_awready;
    wire    [AXI4_DATA_WIDTH-1:0]           m_axi4_wdata;
    wire    [AXI4_STRB_WIDTH-1:0]           m_axi4_wstrb;
    wire                                    m_axi4_wlast;
    wire                                    m_axi4_wvalid;
    wire                                    m_axi4_wready;
    wire    [AXI4_ID_WIDTH-1:0]             m_axi4_bid;
    wire    [1:0]                           m_axi4_bresp;
    wire                                    m_axi4_bvalid;
    wire                                    m_axi4_bready;
    
    jelly_axi4_dma_fifo_writer
            #(
                .S_DATA_SIZE            (S_DATA_SIZE),
                .AXI4_ID_WIDTH          (AXI4_ID_WIDTH),
                .AXI4_ADDR_WIDTH        (AXI4_ADDR_WIDTH),
                .AXI4_DATA_SIZE         (AXI4_DATA_SIZE),
                .AXI4_DATA_WIDTH        (AXI4_DATA_WIDTH),
                .AXI4_STRB_WIDTH        (AXI4_STRB_WIDTH),
                .AXI4_LEN_WIDTH         (AXI4_LEN_WIDTH),
                .AXI4_QOS_WIDTH         (AXI4_QOS_WIDTH),
                .AXI4_AWID              (AXI4_AWID),
                .AXI4_AWSIZE            (AXI4_AWSIZE),
                .AXI4_AWBURST           (AXI4_AWBURST),
                .AXI4_AWLOCK            (AXI4_AWLOCK),
                .AXI4_AWCACHE           (AXI4_AWCACHE),
                .AXI4_AWPROT            (AXI4_AWPROT),
                .AXI4_AWQOS             (AXI4_AWQOS),
                .AXI4_AWREGION          (AXI4_AWREGION),
                .AXI4_ALIGN             (AXI4_ALIGN)
            )
        i_axi4_dma_fifo_writer
            (
                .aresetn                (~reset),
                .aclk                   (aclk),
                
                .enable                 (enable),
                .busy                   (busy),
                
                .param_addr             (param_addr),
                .param_size             (param_size),
                .param_awlen            (param_awlen),
                .param_wstrb            (param_wstrb),
                .param_timeout          (param_timeout),
                
                .s_reset                (reset),
                .s_clk                  (clk),
                .s_data                 (s_data ),
                .s_valid                (s_valid),
                .s_ready                (s_ready),
                
                .write_permit_size      (),
                .write_permit_valid     (0),
                
                .write_complete_size    (),
                .write_complete_valid   (),
                
                
                .m_axi4_awid            (m_axi4_awid),
                .m_axi4_awaddr          (m_axi4_awaddr),
                .m_axi4_awlen           (m_axi4_awlen),
                .m_axi4_awsize          (m_axi4_awsize),
                .m_axi4_awburst         (m_axi4_awburst),
                .m_axi4_awlock          (m_axi4_awlock),
                .m_axi4_awcache         (m_axi4_awcache),
                .m_axi4_awprot          (m_axi4_awprot),
                .m_axi4_awqos           (m_axi4_awqos),
                .m_axi4_awregion        (m_axi4_awregion),
                .m_axi4_awvalid         (m_axi4_awvalid),
                .m_axi4_awready         (m_axi4_awready),
                .m_axi4_wdata           (m_axi4_wdata),
                .m_axi4_wstrb           (m_axi4_wstrb),
                .m_axi4_wlast           (m_axi4_wlast),
                .m_axi4_wvalid          (m_axi4_wvalid),
                .m_axi4_wready          (m_axi4_wready),
                .m_axi4_bid             (m_axi4_bid),
                .m_axi4_bresp           (m_axi4_bresp),
                .m_axi4_bvalid          (m_axi4_bvalid),
                .m_axi4_bready          (m_axi4_bready)
            );
    
    
    
    always @(posedge clk) begin
        if ( reset ) begin
            s_data  <= 0;
            s_valid <= 1'b0;
        end
        else begin
            if ( s_valid & s_ready ) begin
                s_data <= s_data + 1;
            end
            
            if ( !s_valid || s_ready ) begin
                if ( s_data >= 32'h100-1 ) begin
                    s_valid <= 0;
                    enable <= 0;
                end
                else begin
                    s_valid <= RAND_BUSY ? {$random()} : 1'b1;
                end
            end
        end
    end
    
    
    
    // ---------------------------------
    //  dummy memory model
    // ---------------------------------
    
    jelly_axi4_slave_model
            #(
                .AXI_ID_WIDTH           (AXI4_ID_WIDTH),
                .AXI_ADDR_WIDTH         (AXI4_ADDR_WIDTH),
                .AXI_QOS_WIDTH          (AXI4_QOS_WIDTH),
                .AXI_LEN_WIDTH          (AXI4_LEN_WIDTH),
                .AXI_DATA_SIZE          (AXI4_DATA_SIZE),
                .AXI_DATA_WIDTH         (AXI4_DATA_WIDTH),
                .AXI_STRB_WIDTH         (AXI4_DATA_WIDTH/8),
                .MEM_WIDTH              (24),
                
                .READ_DATA_ADDR         (1),
                
                .WRITE_LOG_FILE         ("axi4_write.txt"),
                .READ_LOG_FILE          ("axi4_read.txt"),
                
                .AW_DELAY               (RAND_BUSY ? 64 : 0),
                .AR_DELAY               (RAND_BUSY ? 64 : 0),
                
                .AW_FIFO_PTR_WIDTH      (RAND_BUSY ? 4 : 0),
                .W_FIFO_PTR_WIDTH       (RAND_BUSY ? 4 : 0),
                .B_FIFO_PTR_WIDTH       (RAND_BUSY ? 4 : 0),
                .AR_FIFO_PTR_WIDTH      (0),
                .R_FIFO_PTR_WIDTH       (0),
                
                .AW_BUSY_RATE           (RAND_BUSY ? 80 : 0),
                .W_BUSY_RATE            (RAND_BUSY ? 80 : 0),
                .B_BUSY_RATE            (RAND_BUSY ? 80 : 0),
                .AR_BUSY_RATE           (0),
                .R_BUSY_RATE            (0)
            )
        i_axi4_slave_model
            (
                .aresetn                (aresetn),
                .aclk                   (aclk),
                
                .s_axi4_awid            (m_axi4_awid),
                .s_axi4_awaddr          (m_axi4_awaddr),
                .s_axi4_awlen           (m_axi4_awlen),
                .s_axi4_awsize          (m_axi4_awsize),
                .s_axi4_awburst         (m_axi4_awburst),
                .s_axi4_awlock          (m_axi4_awlock),
                .s_axi4_awcache         (m_axi4_awcache),
                .s_axi4_awprot          (m_axi4_awprot),
                .s_axi4_awqos           (m_axi4_awqos),
                .s_axi4_awvalid         (m_axi4_awvalid),
                .s_axi4_awready         (m_axi4_awready),
                .s_axi4_wdata           (m_axi4_wdata),
                .s_axi4_wstrb           (m_axi4_wstrb),
                .s_axi4_wlast           (m_axi4_wlast),
                .s_axi4_wvalid          (m_axi4_wvalid),
                .s_axi4_wready          (m_axi4_wready),
                .s_axi4_bid             (m_axi4_bid),
                .s_axi4_bresp           (m_axi4_bresp),
                .s_axi4_bvalid          (m_axi4_bvalid),
                .s_axi4_bready          (m_axi4_bready),
                .s_axi4_arid            (),
                .s_axi4_araddr          (),
                .s_axi4_arlen           (),
                .s_axi4_arsize          (),
                .s_axi4_arburst         (),
                .s_axi4_arlock          (),
                .s_axi4_arcache         (),
                .s_axi4_arprot          (),
                .s_axi4_arqos           (),
                .s_axi4_arvalid         (1'b0),
                .s_axi4_arready         (),
                .s_axi4_rid             (),
                .s_axi4_rdata           (),
                .s_axi4_rresp           (),
                .s_axi4_rlast           (),
                .s_axi4_rvalid          (),
                .s_axi4_rready          (1'b0)
            );
    
    
    
endmodule


`default_nettype wire


// end of file
