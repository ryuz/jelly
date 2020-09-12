
`timescale 1ns / 1ps
`default_nettype none


module tb_axi4_dma_read();
    localparam AR_RATE   = 1000.0 / 123.0;
    localparam R_RATE    = 1000.0 / 133.0;
    localparam AXI4_RATE = 1000.0 / 200.0;
    
    
    initial begin
        $dumpfile("tb_axi4_dma_read.vcd");
        $dumpvars(0, tb_axi4_dma_read);
        
        #100000;
            $finish;
    end
    
    
    reg     s_arresetn = 1'b0;
    initial #(AR_RATE*100)      s_arresetn = 1'b1;
    
    reg     s_arclk = 1'b1;
    always #(AR_RATE/2.0)       s_arclk = ~s_arclk;
    
    reg     s_rresetn = 1'b0;
    initial #(R_RATE*100)       s_rresetn = 1'b1;
    
    reg     s_rclk = 1'b1;
    always #(R_RATE/2.0)        s_rclk = ~s_rclk;
    
    
    reg     m_aresetn = 1'b0;
    initial #(AXI4_RATE*100)    m_aresetn = 1'b1;
    
    reg     m_aclk = 1'b1;
    always #(AXI4_RATE/2.0)     m_aclk = ~m_aclk;
    
    
    
    localparam  RAND_BUSY = 0;
    
    
    
    // -----------------------------------------
    //  Core
    // -----------------------------------------
    
    parameter   ARASYNC              = 1;
    parameter   RASYNC               = 1;
    parameter   BYTE_WIDTH           = 8;
    
    parameter   AXI4_ID_WIDTH        = 6;
    parameter   AXI4_ADDR_WIDTH      = 49;
    parameter   AXI4_DATA_SIZE       = 4;    // 0:8bit; 1:16bit; 2:32bit ...
    parameter   AXI4_DATA_WIDTH      = (BYTE_WIDTH << AXI4_DATA_SIZE);
    parameter   AXI4_LEN_WIDTH       = 8;
    parameter   AXI4_QOS_WIDTH       = 4;
    parameter   AXI4_ARID            = {AXI4_ID_WIDTH{1'b0}};
    parameter   AXI4_ARSIZE          = AXI4_DATA_SIZE;
    parameter   AXI4_ARBURST         = 2'b01;
    parameter   AXI4_ARLOCK          = 1'b0;
    parameter   AXI4_ARCACHE         = 4'b0001;
    parameter   AXI4_ARPROT          = 3'b000;
    parameter   AXI4_ARQOS           = 0;
    parameter   AXI4_ARREGION        = 4'b0000;
    
    parameter   BYPASS_ALIGN         = 0;
    parameter   AXI4_ALIGN           = 12;
    
    parameter   S_ARADDR_WIDTH       = AXI4_ADDR_WIDTH;
    parameter   S_RDATA_SIZE         = 2;    // 0:8bit; 1:16bit; 2:32bit ...
    parameter   S_RDATA_WIDTH        = (BYTE_WIDTH << S_RDATA_SIZE);
    parameter   S_ARLEN_WIDTH        = 32;
    parameter   S_ARLEN_SIZE         = S_RDATA_SIZE;
    parameter   S_ARLEN_OFFSET       = 1'b1;
    
    parameter   ARFIFO_PTR_WIDTH     = 4;
    parameter   ARFIFO_RAM_TYPE      = "distributed";
    parameter   ARFIFO_LOW_DEALY     = 1;
    parameter   ARFIFO_DOUT_REGS     = 0;
    parameter   ARFIFO_S_REGS        = 1;
    parameter   ARFIFO_M_REGS        = 1;
    
    parameter   RFIFO_PTR_WIDTH      = 9;
    parameter   RFIFO_RAM_TYPE       = "block";
    parameter   RFIFO_LOW_DEALY      = 0;
    parameter   RFIFO_DOUT_REGS      = 1;
    parameter   RFIFO_S_REGS         = 1;
    parameter   RFIFO_M_REGS         = 1;
    
    parameter   RCMD_FIFO_PTR_WIDTH  = 4;
    parameter   RCMD_FIFO_RAM_TYPE   = "distributed";
    parameter   RCMD_FIFO_LOW_DEALY  = 1;
    parameter   RCMD_FIFO_DOUT_REGS  = 0;
    parameter   RCMD_FIFO_S_REGS     = 0;
    parameter   RCMD_FIFO_M_REGS     = 1;
    
    reg                                 endian = 0;
    
    reg     [S_ARADDR_WIDTH-1:0]        s_araddr;
    reg     [S_ARLEN_WIDTH-1:0]         s_arlen;
    reg     [AXI4_LEN_WIDTH-1:0]        s_arlen_max;
    reg                                 s_arvalid;
    wire                                s_arready;
    
    wire                                s_rlast;
    wire    [S_RDATA_WIDTH-1:0]         s_rdata;
    wire                                s_rvalid;
    reg                                 s_rready;
    
    wire    [AXI4_ID_WIDTH-1:0]         m_axi4_arid;
    wire    [AXI4_ADDR_WIDTH-1:0]       m_axi4_araddr;
    wire    [AXI4_LEN_WIDTH-1:0]        m_axi4_arlen;
    wire    [2:0]                       m_axi4_arsize;
    wire    [1:0]                       m_axi4_arburst;
    wire    [0:0]                       m_axi4_arlock;
    wire    [3:0]                       m_axi4_arcache;
    wire    [2:0]                       m_axi4_arprot;
    wire    [AXI4_QOS_WIDTH-1:0]        m_axi4_arqos;
    wire    [3:0]                       m_axi4_arregion;
    wire                                m_axi4_arvalid;
    wire                                m_axi4_arready;
    wire    [AXI4_ID_WIDTH-1:0]         m_axi4_rid;
    wire    [AXI4_DATA_WIDTH-1:0]       m_axi4_rdata;
    wire    [1:0]                       m_axi4_rresp;
    wire                                m_axi4_rlast;
    wire                                m_axi4_rvalid;
    wire                                m_axi4_rready;
    
    
    jelly_axi4_dma_read
            #(
                .ARASYNC                (ARASYNC),
                .RASYNC                 (RASYNC),
                .BYTE_WIDTH             (BYTE_WIDTH),
                .AXI4_ID_WIDTH          (AXI4_ID_WIDTH),
                .AXI4_ADDR_WIDTH        (AXI4_ADDR_WIDTH),
                .AXI4_DATA_SIZE         (AXI4_DATA_SIZE),
                .AXI4_DATA_WIDTH        (AXI4_DATA_WIDTH),
                .AXI4_LEN_WIDTH         (AXI4_LEN_WIDTH),
                .AXI4_QOS_WIDTH         (AXI4_QOS_WIDTH),
                .AXI4_ARID              (AXI4_ARID),
                .AXI4_ARSIZE            (AXI4_ARSIZE),
                .AXI4_ARBURST           (AXI4_ARBURST),
                .AXI4_ARLOCK            (AXI4_ARLOCK),
                .AXI4_ARCACHE           (AXI4_ARCACHE),
                .AXI4_ARPROT            (AXI4_ARPROT),
                .AXI4_ARQOS             (AXI4_ARQOS),
                .AXI4_ARREGION          (AXI4_ARREGION),
                .BYPASS_ALIGN           (BYPASS_ALIGN),
                .AXI4_ALIGN             (AXI4_ALIGN),
                .S_RDATA_SIZE           (S_RDATA_SIZE),
                .S_RDATA_WIDTH          (S_RDATA_WIDTH),
                .S_ARADDR_WIDTH         (S_ARADDR_WIDTH),
                .S_ARLEN_WIDTH          (S_ARLEN_WIDTH),
                .S_ARLEN_SIZE           (S_ARLEN_SIZE),
                .S_ARLEN_OFFSET         (S_ARLEN_OFFSET),
                .ARFIFO_PTR_WIDTH       (ARFIFO_PTR_WIDTH),
                .ARFIFO_RAM_TYPE        (ARFIFO_RAM_TYPE),
                .ARFIFO_LOW_DEALY       (ARFIFO_LOW_DEALY),
                .ARFIFO_DOUT_REGS       (ARFIFO_DOUT_REGS),
                .ARFIFO_S_REGS          (ARFIFO_S_REGS),
                .ARFIFO_M_REGS          (ARFIFO_M_REGS),
                .RFIFO_PTR_WIDTH        (RFIFO_PTR_WIDTH),
                .RFIFO_RAM_TYPE         (RFIFO_RAM_TYPE),
                .RFIFO_LOW_DEALY        (RFIFO_LOW_DEALY),
                .RFIFO_DOUT_REGS        (RFIFO_DOUT_REGS),
                .RFIFO_S_REGS           (RFIFO_S_REGS),
                .RFIFO_M_REGS           (RFIFO_M_REGS),
                .RCMD_FIFO_PTR_WIDTH    (RCMD_FIFO_PTR_WIDTH),
                .RCMD_FIFO_RAM_TYPE     (RCMD_FIFO_RAM_TYPE),
                .RCMD_FIFO_LOW_DEALY    (RCMD_FIFO_LOW_DEALY),
                .RCMD_FIFO_DOUT_REGS    (RCMD_FIFO_DOUT_REGS),
                .RCMD_FIFO_S_REGS       (RCMD_FIFO_S_REGS),
                .RCMD_FIFO_M_REGS       (RCMD_FIFO_M_REGS)
            )
        i_axi4_dma_read
            (
                .endian                 (endian),
                
                .s_arresetn             (s_arresetn),
                .s_arclk                (s_arclk),
                .s_araddr               (s_araddr),
                .s_arlen                (s_arlen),
                .s_arlen_max            (s_arlen_max),
                .s_arvalid              (s_arvalid),
                .s_arready              (s_arready),
                
                .s_rresetn              (s_rresetn),
                .s_rclk                 (s_rclk),
                .s_rlast                (s_rlast),
                .s_rdata                (s_rdata),
                .s_rvalid               (s_rvalid),
                .s_rready               (s_rready),
                
                .m_aresetn              (m_aresetn),
                .m_aclk                 (m_aclk),
                .m_axi4_arid            (m_axi4_arid),
                .m_axi4_araddr          (m_axi4_araddr),
                .m_axi4_arlen           (m_axi4_arlen),
                .m_axi4_arsize          (m_axi4_arsize),
                .m_axi4_arburst         (m_axi4_arburst),
                .m_axi4_arlock          (m_axi4_arlock),
                .m_axi4_arcache         (m_axi4_arcache),
                .m_axi4_arprot          (m_axi4_arprot),
                .m_axi4_arqos           (m_axi4_arqos),
                .m_axi4_arregion        (m_axi4_arregion),
                .m_axi4_arvalid         (m_axi4_arvalid),
                .m_axi4_arready         (m_axi4_arready),
                .m_axi4_rid             (m_axi4_rid),
                .m_axi4_rdata           (m_axi4_rdata),
                .m_axi4_rresp           (m_axi4_rresp),
                .m_axi4_rlast           (m_axi4_rlast),
                .m_axi4_rvalid          (m_axi4_rvalid),
                .m_axi4_rready          (m_axi4_rready)
            );
    
    always @(posedge s_arclk) begin
        if ( ~s_arresetn ) begin
            s_araddr    <= 0;
            s_arlen     <= 1024-1;
            s_arlen_max <= 15;
            s_arvalid   <= 1'b1;
        end
        else begin
            if ( s_arvalid && s_arready ) begin
                s_arvalid <= 0;
            end
        end
    end
    
    always @(posedge s_rclk) begin
        if ( ~s_rresetn ) begin
            s_rready <= 0;
        end
        else begin
            s_rready <= 1;
        end
    end
    
    
    integer fp;
    initial begin
        fp = $fopen("out.txt", "w");
    end
    
    always @(posedge s_rclk) begin
        if ( ~s_rresetn ) begin
        end
        else begin
            if ( s_rvalid && s_rready ) begin
                $fdisplay(fp, "%h %b", s_rdata, s_rlast);
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
                .aresetn                (m_aresetn),
                .aclk                   (m_aclk),
                
                .s_axi4_awid            (),
                .s_axi4_awaddr          (),
                .s_axi4_awlen           (),
                .s_axi4_awsize          (),
                .s_axi4_awburst         (),
                .s_axi4_awlock          (),
                .s_axi4_awcache         (),
                .s_axi4_awprot          (),
                .s_axi4_awqos           (),
                .s_axi4_awvalid         (1'b0),
                .s_axi4_awready         (),
                .s_axi4_wdata           (),
                .s_axi4_wstrb           (),
                .s_axi4_wlast           (),
                .s_axi4_wvalid          (1'b0),
                .s_axi4_wready          (),
                .s_axi4_bid             (),
                .s_axi4_bresp           (),
                .s_axi4_bvalid          (),
                .s_axi4_bready          (1'b0),
                .s_axi4_arid            (m_axi4_arid),
                .s_axi4_araddr          (m_axi4_araddr),
                .s_axi4_arlen           (m_axi4_arlen),
                .s_axi4_arsize          (m_axi4_arsize),
                .s_axi4_arburst         (m_axi4_arburst),
                .s_axi4_arlock          (m_axi4_arlock),
                .s_axi4_arcache         (m_axi4_arcache),
                .s_axi4_arprot          (m_axi4_arprot),
                .s_axi4_arqos           (m_axi4_arqos),
                .s_axi4_arvalid         (m_axi4_arvalid),
                .s_axi4_arready         (m_axi4_arready),
                .s_axi4_rid             (m_axi4_rid),
                .s_axi4_rdata           (m_axi4_rdata),
                .s_axi4_rresp           (m_axi4_rresp),
                .s_axi4_rlast           (m_axi4_rlast),
                .s_axi4_rvalid          (m_axi4_rvalid),
                .s_axi4_rready          (m_axi4_rready)
            );
    
    
    
endmodule


`default_nettype wire


// end of file
