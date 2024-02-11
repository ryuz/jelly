
`timescale 1ns / 1ps
`default_nettype none


module tb_axi4_write_nd();
    
    initial begin
        $dumpfile("tb_axi4_write_nd.vcd");
        $dumpvars(0, tb_axi4_write_nd);
    
    #100000
        $finish;
    end
    

    // -----------------------------
    //  reset & clock
    // -----------------------------

    localparam RATE100  = 10.0;
    localparam RATE250  =  5.0;

    logic   reset = 1'b1;
    initial #(RATE100*100)  reset = 1'b0;

    logic   clk100 = 1'b1;
    always #(RATE100/2.0)  clk100 = ~clk100;
    
    logic   clk250 = 1'b1;
    always #(RATE250/2.0)  clk250 = ~clk250;


    // -----------------------------
    //  target
    // -----------------------------
    parameter   int                             N                   = 3;
    parameter   bit                             AWASYNC             = 1;
    parameter   bit                             WASYNC              = 1;
    parameter   bit                             BASYNC              = 1;
    parameter   int                             BYTE_WIDTH          = 8;
    parameter   bit                             BYPASS_GATE         = 1;
    parameter   bit                             BYPASS_ALIGN        = 0;
    parameter   bit                             WDETECTOR_ENABLE    = 1;
    parameter   bit                             ALLOW_UNALIGNED     = 0;
    parameter   bit                             HAS_WSTRB           = 1;
    parameter   bit                             HAS_WFIRST          = 0;
    parameter   bit                             HAS_WLAST           = 0;
    parameter   int                             AXI4_ID_WIDTH       = 6;
    parameter   int                             AXI4_ADDR_WIDTH     = 32;
//    parameter   int                             AXI4_DATA_SIZE   = 2;    // 0:8bit, 1:16bit, 2:32bit ...
//    parameter   int                             AXI4_DATA_WIDTH  = (BYTE_WIDTH << AXI4_DATA_SIZE);
    parameter   int                             AXI4_DATA_WIDTH     = 128;
    parameter   int                             AXI4_DATA_SIZE      = $clog2(AXI4_DATA_WIDTH / BYTE_WIDTH);
    parameter   int                             AXI4_STRB_WIDTH     = AXI4_DATA_WIDTH / BYTE_WIDTH;
    parameter   int                             AXI4_LEN_WIDTH      = 8;
    parameter   int                             AXI4_QOS_WIDTH      = 4;
    parameter   bit     [AXI4_ID_WIDTH-1:0]     AXI4_AWID           = {AXI4_ID_WIDTH{1'b0}};
    parameter   bit     [2:0]                   AXI4_AWSIZE         = 3'(AXI4_DATA_SIZE);
    parameter   bit     [1:0]                   AXI4_AWBURST        = 2'b01;
    parameter   bit     [0:0]                   AXI4_AWLOCK         = 1'b0;
    parameter   bit     [3:0]                   AXI4_AWCACHE        = 4'b0001;
    parameter   bit     [2:0]                   AXI4_AWPROT         = 3'b000;
    parameter   bit     [AXI4_QOS_WIDTH-1:0]    AXI4_AWQOS          = 0;
    parameter   bit     [3:0]                   AXI4_AWREGION       = 4'b0000;
    parameter   int                             AXI4_ALIGN          = 12;  // 2^12 = 4k
    parameter   int                             S_WDATA_WIDTH       = 32;
    parameter   int                             S_WSTRB_WIDTH       = S_WDATA_WIDTH / BYTE_WIDTH;
    parameter   int                             S_AWSTEP_WIDTH      = AXI4_ADDR_WIDTH;
    parameter   int                             S_AWLEN_WIDTH       = AXI4_ADDR_WIDTH;
    parameter   bit                             S_AWLEN_OFFSET      = 1'b1;
    parameter   int                             CAPACITY_WIDTH      = S_AWLEN_WIDTH;   // 内部キューイング
    parameter   bit                             CONVERT_S_REGS      = 0;
    parameter   int                             WFIFO_PTR_WIDTH     = 9;
    parameter                                   WFIFO_RAM_TYPE      = "block";
    parameter   bit                             WFIFO_LOW_DEALY     = 0;
    parameter   bit                             WFIFO_DOUT_REGS     = 1;
    parameter   bit                             WFIFO_S_REGS        = 0;
    parameter   bit                             WFIFO_M_REGS        = 1;
    parameter   int                             AWFIFO_PTR_WIDTH    = 4;
    parameter                                   AWFIFO_RAM_TYPE     = "distributed";
    parameter   bit                             AWFIFO_LOW_DEALY    = 1;
    parameter   bit                             AWFIFO_DOUT_REGS    = 0;
    parameter   bit                             AWFIFO_S_REGS       = 0;
    parameter   bit                             AWFIFO_M_REGS       = 0;
    parameter   int                             BFIFO_PTR_WIDTH     = 4;
    parameter                                   BFIFO_RAM_TYPE      = "distributed";
    parameter   bit                             BFIFO_LOW_DEALY     = 0;
    parameter   bit                             BFIFO_DOUT_REGS     = 0;
    parameter   bit                             BFIFO_S_REGS        = 0;
    parameter   bit                             BFIFO_M_REGS        = 0;
    parameter   int                             SWFIFOPTR_WIDTH     = 4;
    parameter                                   SWFIFORAM_TYPE      = "distributed";
    parameter   bit                             SWFIFOLOW_DEALY     = 1;
    parameter   bit                             SWFIFODOUT_REGS     = 0;
    parameter   bit                             SWFIFOS_REGS        = 0;
    parameter   bit                             SWFIFOM_REGS        = 0;
    parameter   int                             MBFIFO_PTR_WIDTH    = 4;
    parameter                                   MBFIFO_RAM_TYPE     = "distributed";
    parameter   bit                             MBFIFO_LOW_DEALY    = 1;
    parameter   bit                             MBFIFO_DOUT_REGS    = 0;
    parameter   bit                             MBFIFO_S_REGS       = 0;
    parameter   bit                             MBFIFO_M_REGS       = 0;
    parameter   int                             WDATFIFO_PTR_WIDTH  = 4;
    parameter   bit                             WDATFIFO_DOUT_REGS  = 0;
    parameter                                   WDATFIFO_RAM_TYPE   = "distributed";
    parameter   bit                             WDATFIFO_LOW_DEALY  = 1;
    parameter   bit                             WDATFIFO_S_REGS     = 0;
    parameter   bit                             WDATFIFO_M_REGS     = 0;
    parameter   bit                             WDAT_S_REGS         = 0;
    parameter   bit                             WDAT_M_REGS         = 1;
    parameter   int                             BACKFIFO_PTR_WIDTH  = 4;
    parameter   bit                             BACKFIFO_DOUT_REGS  = 0;
    parameter                                   BACKFIFO_RAM_TYPE   = "distributed";
    parameter   bit                             BACKFIFO_LOW_DEALY  = 1;
    parameter   bit                             BACKFIFO_S_REGS     = 0;
    parameter   bit                             BACKFIFO_M_REGS     = 0;
    parameter   bit                             BACK_S_REGS         = 0;
    parameter   bit                             BACK_M_REGS         = 1;

    logic                               endian;
    logic                               s_awresetn;
    logic                               s_awclk;
    logic   [AXI4_ADDR_WIDTH-1:0]       s_awaddr;
    logic   [AXI4_LEN_WIDTH-1:0]        s_awlen_max;
    logic   [N-1:0][S_AWSTEP_WIDTH-1:0] s_awstep;
    logic   [N-1:0][S_AWLEN_WIDTH-1:0]  s_awlen;
    logic                               s_awvalid;
    logic                               s_awready;
    logic                               s_wresetn;
    logic                               s_wclk;
    logic   [S_WDATA_WIDTH-1:0]         s_wdata;
    logic   [S_WSTRB_WIDTH-1:0]         s_wstrb;
    logic   [N-1:0]                     s_wfirst;
    logic   [N-1:0]                     s_wlast;
    logic                               s_wvalid;
    logic                               s_wready;
    logic                               wskip;
    logic   [N-1:0]                     wdetect_first;
    logic   [N-1:0]                     wdetect_last;
    logic                               wpadding_en;
    logic   [S_WDATA_WIDTH-1:0]         wpadding_data;
    logic   [S_WSTRB_WIDTH-1:0]         wpadding_strb;
    logic                               s_bresetn;
    logic                               s_bclk;
    logic   [N-1:0]                     s_bfirst;
    logic   [N-1:0]                     s_blast;
    logic                               s_bvalid;
    logic                               s_bready;
    logic                               m_aresetn;
    logic                               m_aclk;
    logic   [AXI4_ID_WIDTH-1:0]         m_axi4_awid;
    logic   [AXI4_ADDR_WIDTH-1:0]       m_axi4_awaddr;
    logic   [AXI4_LEN_WIDTH-1:0]        m_axi4_awlen;
    logic   [2:0]                       m_axi4_awsize;
    logic   [1:0]                       m_axi4_awburst;
    logic   [0:0]                       m_axi4_awlock;
    logic   [3:0]                       m_axi4_awcache;
    logic   [2:0]                       m_axi4_awprot;
    logic   [AXI4_QOS_WIDTH-1:0]        m_axi4_awqos;
    logic   [3:0]                       m_axi4_awregion;
    logic                               m_axi4_awvalid;
    logic                               m_axi4_awready;
    logic   [AXI4_DATA_WIDTH-1:0]       m_axi4_wdata;
    logic   [AXI4_STRB_WIDTH-1:0]       m_axi4_wstrb;
    logic                               m_axi4_wlast;
    logic                               m_axi4_wvalid;
    logic                               m_axi4_wready;
    logic   [AXI4_ID_WIDTH-1:0]         m_axi4_bid;
    logic   [1:0]                       m_axi4_bresp;
    logic                               m_axi4_bvalid;
    logic                               m_axi4_bready;

  
    jelly2_axi4_write_nd
            #(
                .N                      (N                     ),
                .AWASYNC                (AWASYNC               ),
                .WASYNC                 (WASYNC                ),
                .BASYNC                 (BASYNC                ),
                .BYTE_WIDTH             (BYTE_WIDTH            ),
                .BYPASS_GATE            (BYPASS_GATE           ),
                .BYPASS_ALIGN           (BYPASS_ALIGN          ),
                .WDETECTOR_ENABLE       (WDETECTOR_ENABLE      ),
                .ALLOW_UNALIGNED        (ALLOW_UNALIGNED       ),
                .HAS_WSTRB              (HAS_WSTRB             ),
                .HAS_WFIRST             (HAS_WFIRST            ),
                .HAS_WLAST              (HAS_WLAST             ),
                .AXI4_ID_WIDTH          (AXI4_ID_WIDTH         ),
                .AXI4_ADDR_WIDTH        (AXI4_ADDR_WIDTH       ),
                .AXI4_DATA_SIZE         (AXI4_DATA_SIZE        ),
                .AXI4_DATA_WIDTH        (AXI4_DATA_WIDTH       ),
                .AXI4_STRB_WIDTH        (AXI4_STRB_WIDTH       ),
                .AXI4_LEN_WIDTH         (AXI4_LEN_WIDTH        ),
                .AXI4_QOS_WIDTH         (AXI4_QOS_WIDTH        ),
                .AXI4_AWID              (AXI4_AWID             ),
                .AXI4_AWSIZE            (AXI4_AWSIZE           ),
                .AXI4_AWBURST           (AXI4_AWBURST          ),
                .AXI4_AWLOCK            (AXI4_AWLOCK           ),
                .AXI4_AWCACHE           (AXI4_AWCACHE          ),
                .AXI4_AWPROT            (AXI4_AWPROT           ),
                .AXI4_AWQOS             (AXI4_AWQOS            ),
                .AXI4_AWREGION          (AXI4_AWREGION         ),
                .AXI4_ALIGN             (AXI4_ALIGN            ),
                .S_WDATA_WIDTH          (S_WDATA_WIDTH         ),
                .S_WSTRB_WIDTH          (S_WSTRB_WIDTH         ),
                .S_AWSTEP_WIDTH         (S_AWSTEP_WIDTH        ),
                .S_AWLEN_WIDTH          (S_AWLEN_WIDTH         ),
                .S_AWLEN_OFFSET         (S_AWLEN_OFFSET        ),
                .CAPACITY_WIDTH         (CAPACITY_WIDTH        ),
                .CONVERT_S_REGS         (CONVERT_S_REGS        ),
                .WFIFO_PTR_WIDTH        (WFIFO_PTR_WIDTH       ),
                .WFIFO_RAM_TYPE         (WFIFO_RAM_TYPE        ),
                .WFIFO_LOW_DEALY        (WFIFO_LOW_DEALY       ),
                .WFIFO_DOUT_REGS        (WFIFO_DOUT_REGS       ),
                .WFIFO_S_REGS           (WFIFO_S_REGS          ),
                .WFIFO_M_REGS           (WFIFO_M_REGS          ),
                .AWFIFO_PTR_WIDTH       (AWFIFO_PTR_WIDTH      ),
                .AWFIFO_RAM_TYPE        (AWFIFO_RAM_TYPE       ),
                .AWFIFO_LOW_DEALY       (AWFIFO_LOW_DEALY      ),
                .AWFIFO_DOUT_REGS       (AWFIFO_DOUT_REGS      ),
                .AWFIFO_S_REGS          (AWFIFO_S_REGS         ),
                .AWFIFO_M_REGS          (AWFIFO_M_REGS         ),
                .BFIFO_PTR_WIDTH        (BFIFO_PTR_WIDTH       ),
                .BFIFO_RAM_TYPE         (BFIFO_RAM_TYPE        ),
                .BFIFO_LOW_DEALY        (BFIFO_LOW_DEALY       ),
                .BFIFO_DOUT_REGS        (BFIFO_DOUT_REGS       ),
                .BFIFO_S_REGS           (BFIFO_S_REGS          ),
                .BFIFO_M_REGS           (BFIFO_M_REGS          ),
                .SWFIFOPTR_WIDTH        (SWFIFOPTR_WIDTH       ),
                .SWFIFORAM_TYPE         (SWFIFORAM_TYPE        ),
                .SWFIFOLOW_DEALY        (SWFIFOLOW_DEALY       ),
                .SWFIFODOUT_REGS        (SWFIFODOUT_REGS       ),
                .SWFIFOS_REGS           (SWFIFOS_REGS          ),
                .SWFIFOM_REGS           (SWFIFOM_REGS          ),
                .MBFIFO_PTR_WIDTH       (MBFIFO_PTR_WIDTH      ),
                .MBFIFO_RAM_TYPE        (MBFIFO_RAM_TYPE       ),
                .MBFIFO_LOW_DEALY       (MBFIFO_LOW_DEALY      ),
                .MBFIFO_DOUT_REGS       (MBFIFO_DOUT_REGS      ),
                .MBFIFO_S_REGS          (MBFIFO_S_REGS         ),
                .MBFIFO_M_REGS          (MBFIFO_M_REGS         ),
                .WDATFIFO_PTR_WIDTH     (WDATFIFO_PTR_WIDTH    ),
                .WDATFIFO_DOUT_REGS     (WDATFIFO_DOUT_REGS    ),
                .WDATFIFO_RAM_TYPE      (WDATFIFO_RAM_TYPE     ),
                .WDATFIFO_LOW_DEALY     (WDATFIFO_LOW_DEALY    ),
                .WDATFIFO_S_REGS        (WDATFIFO_S_REGS       ),
                .WDATFIFO_M_REGS        (WDATFIFO_M_REGS       ),
                .WDAT_S_REGS            (WDAT_S_REGS           ),
                .WDAT_M_REGS            (WDAT_M_REGS           ),
                .BACKFIFO_PTR_WIDTH     (BACKFIFO_PTR_WIDTH    ),
                .BACKFIFO_DOUT_REGS     (BACKFIFO_DOUT_REGS    ),
                .BACKFIFO_RAM_TYPE      (BACKFIFO_RAM_TYPE     ),
                .BACKFIFO_LOW_DEALY     (BACKFIFO_LOW_DEALY    ),
                .BACKFIFO_S_REGS        (BACKFIFO_S_REGS       ),
                .BACKFIFO_M_REGS        (BACKFIFO_M_REGS       ),
                .BACK_S_REGS            (BACK_S_REGS           ),
                .BACK_M_REGS            (BACK_M_REGS           )
            )
        u_axi4_write_nd
            (
                .endian,
                                
                .s_awresetn,
                .s_awclk,
                .s_awaddr,
                .s_awlen_max,
                .s_awstep,       // step0は無視(1固定、つまり連続アクセスのみ)
                .s_awlen,
                .s_awvalid,
                .s_awready,
                
                .s_wresetn,
                .s_wclk,
                .s_wdata,
                .s_wstrb,
                .s_wfirst, 
                .s_wlast,
                .s_wvalid,
                .s_wready,
                
                .wskip,
                .wdetect_first,
                .wdetect_last,
                .wpadding_en,
                .wpadding_data,
                .wpadding_strb,
                
                .s_bresetn,
                .s_bclk,
                .s_bfirst,
                .s_blast,
                .s_bvalid,
                .s_bready,
                
                .m_aresetn,
                .m_aclk,
                .m_axi4_awid,
                .m_axi4_awaddr,
                .m_axi4_awlen,
                .m_axi4_awsize,
                .m_axi4_awburst,
                .m_axi4_awlock,
                .m_axi4_awcache,
                .m_axi4_awprot,
                .m_axi4_awqos,
                .m_axi4_awregion,
                .m_axi4_awvalid,
                .m_axi4_awready,
                .m_axi4_wdata,
                .m_axi4_wstrb,
                .m_axi4_wlast,
                .m_axi4_wvalid,
                .m_axi4_wready,
                .m_axi4_bid,
                .m_axi4_bresp,
                .m_axi4_bvalid,
                .m_axi4_bready
            );
    
    assign s_awresetn = ~reset     ;
    assign s_awclk    = clk100     ;
    assign s_wresetn  = ~reset     ;
    assign s_wclk     = clk250     ;
    assign s_bresetn  = ~reset     ;
    assign s_bclk     = clk250     ;

    assign m_aresetn  = ~reset     ;
    assign m_aclk     = clk250     ;


    // -----------------------------
    //  test
    // -----------------------------

    assign endian = 1'b0;

    always_ff @(posedge s_awclk) begin
        if ( ~s_awresetn ) begin
            s_awaddr    <= 32'h00000000;
//            s_awlen     <= 10'h000;
            s_awvalid   <= 1'b0;
        end
        else begin
            if ( !s_awvalid || s_awready ) begin
                s_awaddr    <= 32'h000a_0000; // {16'd0, 16'($random())};
//                s_awlen     <= 10'($random()); // 10'h000;
                s_awvalid   <= 1'($random());
            end
        end
    end
    assign s_awlen_max = 8'd127;

    assign s_awstep[0] = S_AWSTEP_WIDTH'(1);
    assign s_awstep[1] = S_AWSTEP_WIDTH'(256);
    assign s_awstep[2] = S_AWSTEP_WIDTH'(8192);

    assign s_awlen[0] = S_AWLEN_WIDTH'(15);
    assign s_awlen[1] = S_AWLEN_WIDTH'(15);
    assign s_awlen[2] = S_AWLEN_WIDTH'(7);


    always_ff @(posedge s_wclk) begin
        if ( ~s_wresetn ) begin
            s_wdata     <= 32'h00000000;
            s_wstrb     <= 4'h0;
            s_wfirst    <= '0;
            s_wlast     <= '0;
            s_wvalid    <= 1'b0;
        end
        else begin
            if ( !s_wvalid || s_wready ) begin
                s_wdata     <= s_wdata + 1;//32'($random());
                s_wstrb     <= 4'($random());
                s_wfirst    <= '1;
                s_wlast     <= '1;
                s_wvalid    <= 1'($random());
            end
        end
    end

    always_ff @(posedge s_bclk) begin
        if ( ~s_bresetn ) begin
            s_bready <= 1'b0;
        end
        else begin
            s_bready <= 1'($random());
        end
    end


    // -----------------------------
    //  model
    // -----------------------------

    jelly2_axi4_slave_model
            #(
                    .AXI_ID_WIDTH           (AXI4_ID_WIDTH      ),
                    .AXI_ADDR_WIDTH         (AXI4_ADDR_WIDTH    ),
                    .AXI_QOS_WIDTH          (AXI4_QOS_WIDTH     ),
                    .AXI_LEN_WIDTH          (AXI4_LEN_WIDTH     ),
                    .AXI_DATA_SIZE          (AXI4_DATA_SIZE     ),
                    .AXI_DATA_WIDTH         (AXI4_DATA_WIDTH    ),
                    .AXI_STRB_WIDTH         (AXI4_STRB_WIDTH    ),
            //      .MEM_WIDTH              (16),
            //      .MEM_SIZE               (1 << MEM_WIDTH),
            //      .READ_DATA_ADDR         (0),      // リード結果をアドレスとする
                    .WRITE_LOG_FILE         ("axi4_write_log.txt"),
            //      .READ_LOG_FILE          (""),
                    .AW_DELAY               (0),
                    .AR_DELAY               (0),
                    .AW_FIFO_PTR_WIDTH      (0),
                    .W_FIFO_PTR_WIDTH       (0),
                    .B_FIFO_PTR_WIDTH       (0),
                    .AR_FIFO_PTR_WIDTH      (0),
                    .R_FIFO_PTR_WIDTH       (0),
                    .AW_BUSY_RATE           (0),
                    .W_BUSY_RATE            (0),
                    .B_BUSY_RATE            (0),
                    .AR_BUSY_RATE           (0),
                    .R_BUSY_RATE            (0),
                    .AW_BUSY_RAND           (0),
                    .W_BUSY_RAND            (1),
                    .B_BUSY_RAND            (2),
                    .AR_BUSY_RAND           (3),
                    .R_BUSY_RAND            (4)
            )
        u_axi4_slave_model
            (
                .aresetn            (m_aresetn      ),
                .aclk               (m_aclk         ),
                .aclken             (1'b1           ),

                .s_axi4_awid        (m_axi4_awid    ),
                .s_axi4_awaddr      (m_axi4_awaddr  ),
                .s_axi4_awlen       (m_axi4_awlen   ),
                .s_axi4_awsize      (m_axi4_awsize  ),
                .s_axi4_awburst     (m_axi4_awburst ),
                .s_axi4_awlock      (m_axi4_awlock  ),
                .s_axi4_awcache     (m_axi4_awcache ),
                .s_axi4_awprot      (m_axi4_awprot  ),
                .s_axi4_awqos       (m_axi4_awqos   ),
                .s_axi4_awvalid     (m_axi4_awvalid ),
                .s_axi4_awready     (m_axi4_awready ),
                .s_axi4_wdata       (m_axi4_wdata   ),
                .s_axi4_wstrb       (m_axi4_wstrb   ),
                .s_axi4_wlast       (m_axi4_wlast   ),
                .s_axi4_wvalid      (m_axi4_wvalid  ),
                .s_axi4_wready      (m_axi4_wready  ),
                .s_axi4_bid         (m_axi4_bid     ),
                .s_axi4_bresp       (m_axi4_bresp   ),
                .s_axi4_bvalid      (m_axi4_bvalid  ),
                .s_axi4_bready      (m_axi4_bready  ),

                .s_axi4_arid        (),
                .s_axi4_araddr      (),
                .s_axi4_arlen       (),
                .s_axi4_arsize      (),
                .s_axi4_arburst     (),
                .s_axi4_arlock      (),
                .s_axi4_arcache     (),
                .s_axi4_arprot      (),
                .s_axi4_arqos       (),
                .s_axi4_arvalid     (1'b0),
                .s_axi4_arready     (),
                .s_axi4_rid         (),
                .s_axi4_rdata       (),
                .s_axi4_rresp       (),
                .s_axi4_rlast       (),
                .s_axi4_rvalid      (),
                .s_axi4_rready      (1'b0)
            );

endmodule


`default_nettype wire


// end of file
