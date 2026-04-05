
`timescale 1ns / 1ps
`default_nettype none


module tb_dma_video_write();
    
    initial begin
        $dumpfile("tb_dma_video_write.vcd");
        $dumpvars(0, tb_dma_video_write);
    
    #40000000
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

    logic       axi4l_aresetn;
    logic       axi4l_aclk;
    assign axi4l_aresetn = ~reset;
    assign axi4l_aclk    = clk100;

    logic       axi4s_aresetn;
    logic       axi4s_aclk;
    assign axi4s_aresetn = ~reset;
    assign axi4s_aclk    = clk250;


    // -----------------------------
    //  target
    // -----------------------------

    parameter   bit                             AXI4L_ASYNC           = 1;
    parameter   int                             REGADR_BITS           = 8;
    parameter   bit                             AXI4S_ASYNC           = 1;
    parameter   int                             ADDR_BITS             = 32;
    parameter   int                             AXI4_AWID             = 0;
    parameter   bit     [0:0]                   AXI4_AWLOCK           = 1'b0;
    parameter   bit     [3:0]                   AXI4_AWCACHE          = 4'b0001;
    parameter   bit     [2:0]                   AXI4_AWPROT           = 3'b000;
    parameter   int                             AXI4_AWQOS            = 0;
    parameter   bit     [3:0]                   AXI4_AWREGION         = 4'b0000;
    parameter   int                             AXI4_ALIGN            = 12;  // 2^12 = 4k が境;
    parameter   int                             INDEX_BITS            = 1;
    parameter   bit                             SIZE_OFFSET           = 1'b1;
    parameter   int                             H_SIZE_BITS           = 12;
    parameter   int                             V_SIZE_BITS           = 12;
    parameter   int                             F_SIZE_BITS           = 8;
    parameter   int                             LINE_STEP_BITS        = 16;
    parameter   int                             FRAME_STEP_BITS       = 32;
    parameter   bit     [3:0]                   INIT_CTL_CONTROL      = 4'b0000;
    parameter   bit     [0:0]                   INIT_IRQ_ENABLE       = 1'b0;
    parameter   bit     [ADDR_BITS-1:0]         INIT_PARAM_ADDR       = 0;
    parameter   bit     [ADDR_BITS-1:0]         INIT_PARAM_OFFSET     = 0;
    parameter   bit     [7:0]                   INIT_PARAM_AWLEN_MAX  = 0;
    parameter   bit     [H_SIZE_BITS-1:0]       INIT_PARAM_H_SIZE     = 0;
    parameter   bit     [V_SIZE_BITS-1:0]       INIT_PARAM_V_SIZE     = 0;
    parameter   bit     [LINE_STEP_BITS-1:0]    INIT_PARAM_LINE_STEP  = 0;
    parameter   bit     [F_SIZE_BITS-1:0]       INIT_PARAM_F_SIZE     = 0;
    parameter   bit     [FRAME_STEP_BITS-1:0]   INIT_PARAM_FRAME_STEP = 0;
    parameter   bit                             INIT_SKIP_EN          = 1'b1;
    parameter   bit     [2:0]                   INIT_DETECT_FIRST     = 3'b010;
    parameter   bit     [2:0]                   INIT_DETECT_LAST      = 3'b001;
    parameter   bit                             INIT_PADDING_EN       = 1'b1;
    parameter                                   INIT_PADDING_DATA     = '0;
    parameter                                   INIT_PADDING_STRB     = '0;
    parameter                                   CORE_ID               = 32'h527a_0110;
    parameter                                   CORE_VERSION          = 32'h0000_0000;
    parameter   bit                             BYPASS_GATE           = 0;
    parameter   bit                             BYPASS_ALIGN          = 0;
    parameter   bit                             WDETECTOR_CHANGE      = 0;
    parameter   bit                             DETECTOR_ENABLE       = 1;
    parameter   bit                             ALLOW_UNALIGNED       = 1;
    parameter   int                             CAPACITY_BITS         = 32;
    parameter   int                             WFIFO_PTR_BITS        = 9;
    parameter                                   WFIFO_RAM_TYPE        = "block";
    parameter   bit                             WFIFO_LOW_DEALY       = 0;
    parameter   bit                             WFIFO_DOUT_REG        = 1;
    parameter   bit                             WFIFO_S_REG           = 0;
    parameter   bit                             WFIFO_M_REG           = 1;
    parameter   int                             AWFIFO_PTR_BITS       = 4;
    parameter                                   AWFIFO_RAM_TYPE       = "distributed";
    parameter   bit                             AWFIFO_LOW_DEALY      = 1;
    parameter   bit                             AWFIFO_DOUT_REG       = 1;
    parameter   bit                             AWFIFO_S_REG          = 1;
    parameter   bit                             AWFIFO_M_REG          = 1;
    parameter   int                             BFIFO_PTR_BITS        = 4;
    parameter                                   BFIFO_RAM_TYPE        = "distributed";
    parameter   bit                             BFIFO_LOW_DEALY       = 0;
    parameter   bit                             BFIFO_DOUT_REG        = 0;
    parameter   bit                             BFIFO_S_REG           = 0;
    parameter   bit                             BFIFO_M_REG           = 0;
    parameter   int                             SWFIFOPTR_BITS        = 4;
    parameter                                   SWFIFORAM_TYPE        = "distributed";
    parameter   bit                             SWFIFOLOW_DEALY       = 1;
    parameter   bit                             SWFIFODOUT_REG        = 0;
    parameter   bit                             SWFIFOS_REG           = 0;
    parameter   bit                             SWFIFOM_REG           = 0;
    parameter   int                             MBFIFO_PTR_BITS       = 4;
    parameter                                   MBFIFO_RAM_TYPE       = "distributed";
    parameter   bit                             MBFIFO_LOW_DEALY      = 1;
    parameter   bit                             MBFIFO_DOUT_REG       = 0;
    parameter   bit                             MBFIFO_S_REG          = 0;
    parameter   bit                             MBFIFO_M_REG          = 0;
    parameter   int                             WDATFIFO_PTR_BITS     = 4;
    parameter   bit                             WDATFIFO_DOUT_REG     = 0;
    parameter                                   WDATFIFO_RAM_TYPE     = "distributed";
    parameter   bit                             WDATFIFO_LOW_DEALY    = 1;
    parameter   bit                             WDATFIFO_S_REG        = 0;
    parameter   bit                             WDATFIFO_M_REG        = 0;
    parameter   bit                             WDAT_S_REG            = 0;
    parameter   bit                             WDAT_M_REG            = 1;
    parameter   int                             BACKFIFO_PTR_BITS     = 4;
    parameter   bit                             BACKFIFO_DOUT_REG     = 0;
    parameter                                   BACKFIFO_RAM_TYPE     = "distributed";
    parameter   bit                             BACKFIFO_LOW_DEALY    = 1;
    parameter   bit                             BACKFIFO_S_REG        = 0;
    parameter   bit                             BACKFIFO_M_REG        = 0;
    parameter   bit                             BACK_S_REG            = 0;
    parameter   bit                             BACK_M_REG            = 1;
    parameter   bit                             CONVERT_S_REG         = 0;


    logic                       endian;
    logic   [0:0]               out_irq;
    logic                       buffer_request;
    logic                       buffer_release;
    logic    [ADDR_BITS-1:0]    buffer_addr;
    

    jelly3_axi4s_if
            #(
                .USER_BITS      (1      ),
                .DATA_BITS      (32     )
            )
        axi4s
            (
                .aresetn        (~reset ),
                .aclk           (clk250 ),
                .aclken         (1'b1   )
            );

    jelly3_axi4_if
            #(
                .ADDR_BITS      (32     ),
                .DATA_BITS      (128    )
            )
        axi4
            (
                .aresetn        (~reset ),
                .aclk           (clk250 ),
                .aclken         (1'b1   )
            );

    jelly3_axi4l_if
            #(
                .ADDR_BITS      (32     ),
                .DATA_BITS      (64     )
            )
        axi4l
            (
                .aresetn        (~reset ),
                .aclk           (clk100 ),
                .aclken         (1'b1   )
            );
    

    jelly3_dma_video_write
            #(
                .AXI4L_ASYNC            (AXI4L_ASYNC           ),
                .REGADR_BITS            (REGADR_BITS           ),
                .AXI4S_ASYNC            (AXI4S_ASYNC           ),
                .ADDR_BITS              (ADDR_BITS             ),
                .AXI4_AWID              (AXI4_AWID             ),
                .AXI4_AWLOCK            (AXI4_AWLOCK           ),
                .AXI4_AWCACHE           (AXI4_AWCACHE          ),
                .AXI4_AWPROT            (AXI4_AWPROT           ),
                .AXI4_AWQOS             (AXI4_AWQOS            ),
                .AXI4_AWREGION          (AXI4_AWREGION         ),
                .AXI4_ALIGN             (AXI4_ALIGN            ),
                .INDEX_BITS             (INDEX_BITS            ),
                .SIZE_OFFSET            (SIZE_OFFSET           ),
                .H_SIZE_BITS            (H_SIZE_BITS           ),
                .V_SIZE_BITS            (V_SIZE_BITS           ),
                .F_SIZE_BITS            (F_SIZE_BITS           ),
                .LINE_STEP_BITS         (LINE_STEP_BITS        ),
                .FRAME_STEP_BITS        (FRAME_STEP_BITS       ),
                .INIT_CTL_CONTROL       (INIT_CTL_CONTROL      ),
                .INIT_IRQ_ENABLE        (INIT_IRQ_ENABLE       ),
                .INIT_PARAM_ADDR        (INIT_PARAM_ADDR       ),
                .INIT_PARAM_OFFSET      (INIT_PARAM_OFFSET     ),
                .INIT_PARAM_AWLEN_MAX   (INIT_PARAM_AWLEN_MAX  ),
                .INIT_PARAM_H_SIZE      (INIT_PARAM_H_SIZE     ),
                .INIT_PARAM_V_SIZE      (INIT_PARAM_V_SIZE     ),
                .INIT_PARAM_LINE_STEP   (INIT_PARAM_LINE_STEP  ),
                .INIT_PARAM_F_SIZE      (INIT_PARAM_F_SIZE     ),
                .INIT_PARAM_FRAME_STEP  (INIT_PARAM_FRAME_STEP ),
                .INIT_SKIP_EN           (INIT_SKIP_EN          ),
                .INIT_DETECT_FIRST      (INIT_DETECT_FIRST     ),
                .INIT_DETECT_LAST       (INIT_DETECT_LAST      ),
                .INIT_PADDING_EN        (INIT_PADDING_EN       ),
                .INIT_PADDING_DATA      (INIT_PADDING_DATA     ),
                .INIT_PADDING_STRB      (INIT_PADDING_STRB     ),
                .CORE_ID                (CORE_ID               ),
                .CORE_VERSION           (CORE_VERSION          ),
                .BYPASS_GATE            (BYPASS_GATE           ),
                .BYPASS_ALIGN           (BYPASS_ALIGN          ),
                .WDETECTOR_CHANGE       (WDETECTOR_CHANGE      ),
                .DETECTOR_ENABLE        (DETECTOR_ENABLE       ),
                .ALLOW_UNALIGNED        (ALLOW_UNALIGNED       ),
                .CAPACITY_BITS          (CAPACITY_BITS         ),
                .WFIFO_PTR_BITS         (WFIFO_PTR_BITS        ),
                .WFIFO_RAM_TYPE         (WFIFO_RAM_TYPE        ),
                .WFIFO_LOW_DEALY        (WFIFO_LOW_DEALY       ),
                .WFIFO_DOUT_REG         (WFIFO_DOUT_REG        ),
                .WFIFO_S_REG            (WFIFO_S_REG           ),
                .WFIFO_M_REG            (WFIFO_M_REG           ),
                .AWFIFO_PTR_BITS        (AWFIFO_PTR_BITS       ),
                .AWFIFO_RAM_TYPE        (AWFIFO_RAM_TYPE       ),
                .AWFIFO_LOW_DEALY       (AWFIFO_LOW_DEALY      ),
                .AWFIFO_DOUT_REG        (AWFIFO_DOUT_REG       ),
                .AWFIFO_S_REG           (AWFIFO_S_REG          ),
                .AWFIFO_M_REG           (AWFIFO_M_REG          ),
                .BFIFO_PTR_BITS         (BFIFO_PTR_BITS        ),
                .BFIFO_RAM_TYPE         (BFIFO_RAM_TYPE        ),
                .BFIFO_LOW_DEALY        (BFIFO_LOW_DEALY       ),
                .BFIFO_DOUT_REG         (BFIFO_DOUT_REG        ),
                .BFIFO_S_REG            (BFIFO_S_REG           ),
                .BFIFO_M_REG            (BFIFO_M_REG           ),
                .SWFIFOPTR_BITS         (SWFIFOPTR_BITS        ),
                .SWFIFORAM_TYPE         (SWFIFORAM_TYPE        ),
                .SWFIFOLOW_DEALY        (SWFIFOLOW_DEALY       ),
                .SWFIFODOUT_REG         (SWFIFODOUT_REG        ),
                .SWFIFOS_REG            (SWFIFOS_REG           ),
                .SWFIFOM_REG            (SWFIFOM_REG           ),
                .MBFIFO_PTR_BITS        (MBFIFO_PTR_BITS       ),
                .MBFIFO_RAM_TYPE        (MBFIFO_RAM_TYPE       ),
                .MBFIFO_LOW_DEALY       (MBFIFO_LOW_DEALY      ),
                .MBFIFO_DOUT_REG        (MBFIFO_DOUT_REG       ),
                .MBFIFO_S_REG           (MBFIFO_S_REG          ),
                .MBFIFO_M_REG           (MBFIFO_M_REG          ),
                .WDATFIFO_PTR_BITS      (WDATFIFO_PTR_BITS     ),
                .WDATFIFO_DOUT_REG      (WDATFIFO_DOUT_REG     ),
                .WDATFIFO_RAM_TYPE      (WDATFIFO_RAM_TYPE     ),
                .WDATFIFO_LOW_DEALY     (WDATFIFO_LOW_DEALY    ),
                .WDATFIFO_S_REG         (WDATFIFO_S_REG        ),
                .WDATFIFO_M_REG         (WDATFIFO_M_REG        ),
                .WDAT_S_REG             (WDAT_S_REG            ),
                .WDAT_M_REG             (WDAT_M_REG            ),
                .BACKFIFO_PTR_BITS      (BACKFIFO_PTR_BITS     ),
                .BACKFIFO_DOUT_REG      (BACKFIFO_DOUT_REG     ),
                .BACKFIFO_RAM_TYPE      (BACKFIFO_RAM_TYPE     ),
                .BACKFIFO_LOW_DEALY     (BACKFIFO_LOW_DEALY    ),
                .BACKFIFO_S_REG         (BACKFIFO_S_REG        ),
                .BACKFIFO_M_REG         (BACKFIFO_M_REG        ),
                .BACK_S_REG             (BACK_S_REG            ),
                .BACK_M_REG             (BACK_M_REG            ),
                .CONVERT_S_REG          (CONVERT_S_REG         )
            )
        u_dma_video_write
            (
                .endian,

                .s_axi4s                (axi4s.s),
                .m_axi4                 (axi4.mw),

                .s_axi4l                (axi4l.s),
                .out_irq,
                
                .buffer_request,
                .buffer_release,
                .buffer_addr
            );
    

    jelly3_model_axi4_s
            #(
                .MEM_ADDR_BITS      (16                   ),
                .READ_DATA_ADDR     (0                    ),
                .WRITE_LOG_FILE     ("axi4_write_log.txt" ),
                .READ_LOG_FILE      (""                   ),
                .AW_DELAY           (0                    ),
                .AR_DELAY           (0                    ),
                .AW_FIFO_PTR_BITS   (0                    ),
                .W_FIFO_PTR_BITS    (0                    ),
                .B_FIFO_PTR_BITS    (0                    ),
                .AR_FIFO_PTR_BITS   (0                    ),
                .R_FIFO_PTR_BITS    (0                    ),
                .AW_BUSY_RATE       (0                    ),
                .W_BUSY_RATE        (0                    ),
                .B_BUSY_RATE        (0                    ),
                .AR_BUSY_RATE       (0                    ),
                .R_BUSY_RATE        (0                    ),
                .AW_RAND_SEED       (0                    ),
                .W_RAND_SEED        (1                    ),
                .B_RAND_SEED        (2                    ),
                .AR_RAND_SEED       (3                    ),
                .R_RAND_SEED        (4                    )
            )
        u_model_axi4_s
            (
                .s_axi4             (axi4                 )
            );


    /*

    // -----------------------------
    //  model
    // -----------------------------
    int     cycle_count = 0;
    always_ff @(posedge axi4s_aclk) cycle_count <= cycle_count + 1'b1;
    
    wire    timeout_busy = (cycle_count >= 300000 && cycle_count <= 500000);
    

    localparam  FRAME_NUM = 3;
    
    localparam  IMG_WIDTH  = 256;
    localparam  IMG_HEIGHT = 256;

    // master
    jelly3_model_axi4s_m
            #(
                .IMG_WIDTH          (IMG_WIDTH-11),
                .IMG_HEIGHT         (IMG_HEIGHT/2),
                .FILE_NAME          ("../Mandrill_256x256.ppm"),
                .FILE_IMG_WIDTH     (256),
                .FILE_IMG_HEIGHT    (256),
                .BUSY_RATE          (50),
                .RANDOM_SEED        (123)
            )
        u_model_axi4s_m
            (
                .aclken             (1'b1           ),
                .enable             (1'b1           ),
                .busy               (               ),

                .m_axi4s            (i_axi4s_src.m  ),
                .out_x              (               ),
                .out_y              (               ),
                .out_f              (               )
            );

    // slave
    always_ff @(posedge axi4l_aclk) begin
        i_axi4s_dst.tready <= 1'($random());
    end
    
    

    // -----------------------------
    //  dump
    // -----------------------------

    integer     fp_img;
    initial begin
         fp_img = $fopen("out_img.ppm", "w");
         $fdisplay(fp_img, "P3");
         $fdisplay(fp_img, "%d %d", IMG_WIDTH, IMG_HEIGHT*FRAME_NUM);
         $fdisplay(fp_img, "255");
    end
    
    always_ff @(posedge axi4s_aclk) begin
        if ( axi4s_aresetn && i_axi4s_dst.tvalid && i_axi4s_dst.tready ) begin
             $fdisplay(fp_img, "%d %d %d", i_axi4s_dst.tdata[0*8 +: 8], i_axi4s_dst.tdata[1*8 +: 8], i_axi4s_dst.tdata[2*8 +: 8]);
        end
    end
    
    integer frame_count = 0;
    always_ff @(posedge axi4s_aclk) begin
        if ( axi4s_aresetn && i_axi4s_dst.tuser[0] && i_axi4s_dst.tvalid && i_axi4s_dst.tready ) begin
            $display("frame : %d", frame_count);
            frame_count = frame_count + 1;
            if ( frame_count > FRAME_NUM+1 ) begin
                $finish();
            end
        end
    end
    


    // -----------------------------
    //  access
    // -----------------------------

    localparam type axi4l_addr_t = logic [i_axi4l.ADDR_BITS-1:0];
    localparam type axi4l_data_t = logic [i_axi4l.DATA_BITS-1:0];

    localparam  axi4l_addr_t    ADR_CORE_ID            = axi4l_addr_t'('h00) * (i_axi4l.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_CORE_VERSION       = axi4l_addr_t'('h01) * (i_axi4l.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_CTL_CONTROL        = axi4l_addr_t'('h04) * (i_axi4l.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_CTL_STATUS         = axi4l_addr_t'('h05) * (i_axi4l.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_CTL_INDEX          = axi4l_addr_t'('h07) * (i_axi4l.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_CTL_SKIP           = axi4l_addr_t'('h08) * (i_axi4l.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_CTL_FRM_TIMER_EN   = axi4l_addr_t'('h0a) * (i_axi4l.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_CTL_FRM_TIMEOUT    = axi4l_addr_t'('h0b) * (i_axi4l.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_PARAM_WIDTH        = axi4l_addr_t'('h10) * (i_axi4l.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_PARAM_HEIGHT       = axi4l_addr_t'('h11) * (i_axi4l.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_PARAM_FILL         = axi4l_addr_t'('h12) * (i_axi4l.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_PARAM_TIMEOUT      = axi4l_addr_t'('h13) * (i_axi4l.DATA_BITS/8);

    jelly3_axi4l_accessor
            #(
                .RAND_RATE_AW   (0),
                .RAND_RATE_W    (0),
                .RAND_RATE_B    (0),
                .RAND_RATE_AR   (0),
                .RAND_RATE_R    (0)
            )
        u_axi4l_accessor
            (
                .m_axi4l        (i_axi4l.m)
            );

    initial begin
        axi4l_data_t    rdata;
        
        #(RATE100*200);
        $display("start");
        u_axi4l_accessor.read(ADR_CORE_ID,          rdata);
        u_axi4l_accessor.read(ADR_CORE_VERSION,     rdata);
        u_axi4l_accessor.read(ADR_CTL_CONTROL,      rdata);
        u_axi4l_accessor.read(ADR_CTL_STATUS,       rdata);
        u_axi4l_accessor.read(ADR_CTL_INDEX,        rdata);
        u_axi4l_accessor.read(ADR_CTL_SKIP,         rdata);
        u_axi4l_accessor.read(ADR_CTL_FRM_TIMER_EN, rdata);
        u_axi4l_accessor.read(ADR_CTL_FRM_TIMEOUT,  rdata);
        u_axi4l_accessor.read(ADR_PARAM_WIDTH,      rdata);
        u_axi4l_accessor.read(ADR_PARAM_HEIGHT,     rdata);
        u_axi4l_accessor.read(ADR_PARAM_FILL,       rdata);
        u_axi4l_accessor.read(ADR_PARAM_TIMEOUT,    rdata);
                
        #(RATE100*100);
        $display("enable");

        u_axi4l_accessor.write(ADR_PARAM_WIDTH,  IMG_WIDTH,  4'b1111);
        u_axi4l_accessor.write(ADR_PARAM_HEIGHT, IMG_HEIGHT, 4'b1111);
        u_axi4l_accessor.write(ADR_PARAM_TIMEOUT, 1000, 4'b1111);
        u_axi4l_accessor.write(ADR_CTL_FRM_TIMEOUT,     100000, 4'b1111);
        u_axi4l_accessor.write(ADR_CTL_FRM_TIMER_EN,         1, 4'b1111);
        u_axi4l_accessor.write(ADR_CTL_CONTROL, 1, 4'b1111);
        u_axi4l_accessor.read(ADR_CTL_STATUS,    rdata);

    end

    */

endmodule


`default_nettype wire


// end of file
