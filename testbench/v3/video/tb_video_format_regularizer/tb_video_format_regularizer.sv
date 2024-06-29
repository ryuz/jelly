
`timescale 1ns / 1ps
`default_nettype none


module tb_video_format_regularizer();
    
    initial begin
        $dumpfile("tb_video_format_regularizer.vcd");
        $dumpvars(0, tb_video_format_regularizer);
    
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
        
    parameter   type            width_t         = logic [15:0]  ;
    parameter   type            height_t        = logic [15:0]  ;
    parameter   type            index_t         = logic [0:0]   ;
    parameter   type            frame_timer_t   = logic [31:0]  ;
    parameter   type            timer_t         = logic [31:0]  ;
    parameter   type            regadr_t        = logic [7:0]   ;

    parameter   bit             S_REGS          = 1;
    parameter   bit             M_REGS          = 1;

    parameter                   CORE_ID         = 32'h527a_1220;
    parameter                   CORE_VERSION    = 32'h0001_0000;

    parameter   bit     [1:0]   INIT_CTL_CONTROL      = 2'b00;
    parameter   bit             INIT_CTL_SKIP         = 1;
    parameter   bit             INIT_CTL_FRM_TIMER_EN = 0;
    parameter   frame_timer_t   INIT_CTL_FRM_TIMEOUT  = 1000000;
    parameter   width_t         INIT_PARAM_WIDTH      = 256;
    parameter   height_t        INIT_PARAM_HEIGHT     = 256;
    parameter                   INIT_PARAM_FILL       = 24'h0000ff;
    parameter   timer_t         INIT_PARAM_TIMEOUT    = 0;


    jelly3_axi4s_if
            #(
                .USER_BITS      (1),
                .DATA_BITS      (24)
            )
        i_axi4s_src
            (
                .aresetn        (axi4s_aresetn),
                .aclk           (axi4s_aclk)
            );


    jelly3_axi4s_if
            #(
                .USER_BITS      (1),
                .DATA_BITS      (24)
            )
        i_axi4s_dst
            (
                .aresetn        (axi4s_aresetn),
                .aclk           (axi4s_aclk)
            );

    jelly3_axi4l_if
            #(
                .ADDR_BITS      (32),
                .DATA_BITS      (32)
            )
        i_axi4l
            (
                .aresetn        (axi4l_aresetn  ),
                .aclk           (axi4l_aclk     ),
                .aclken         (1'b1           )
            );




    logic                   aclken = 1'b1;
    width_t                 out_param_width;
    height_t                out_param_height;

    jelly3_video_format_regularizer
            #(
                .width_t                (width_t              ),
                .height_t               (height_t             ),
                .index_t                (index_t              ),
                .frame_timer_t          (frame_timer_t        ),
                .timer_t                (timer_t              ),
                .regadr_t               (regadr_t             ),
                .S_REGS                 (S_REGS               ),
                .M_REGS                 (M_REGS               ),
                .CORE_ID                (CORE_ID              ),
                .CORE_VERSION           (CORE_VERSION         ),
                .INIT_CTL_CONTROL       (INIT_CTL_CONTROL     ),
                .INIT_CTL_SKIP          (INIT_CTL_SKIP        ),
                .INIT_CTL_FRM_TIMER_EN  (INIT_CTL_FRM_TIMER_EN),
                .INIT_CTL_FRM_TIMEOUT   (INIT_CTL_FRM_TIMEOUT ),
                .INIT_PARAM_WIDTH       (INIT_PARAM_WIDTH     ),
                .INIT_PARAM_HEIGHT      (INIT_PARAM_HEIGHT    ),
                .INIT_PARAM_FILL        (INIT_PARAM_FILL      ),
                .INIT_PARAM_TIMEOUT     (INIT_PARAM_TIMEOUT   )
            )
        u_video_format_regularizer
            (
                .aclken             ,
                .s_axi4s            (i_axi4s_src.s),
                .m_axi4s            (i_axi4s_dst.m),
                .s_axi4l            (i_axi4l),
                .out_param_width    ,
                .out_param_height
            );
    

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
        
        /*
        #200000;
        $display("disable");
        u_axi4l_accessor.write(ADR_CTL_CONTROL, 0, 4'b1111);
        u_axi4l_accessor.read(ADR_CTL_STATUS,    rdata);
        
        #200000;
        $display("enable");
        u_axi4l_accessor.write(ADR_CTL_CONTROL, 1, 4'b1111);
        u_axi4l_accessor.read(ADR_CTL_STATUS,    rdata);
        
        // frame timeout
        #200000;
        $display("frame timeout");
        u_axi4l_accessor.write(ADR_CTL_FRM_TIMEOUT,     100000, 4'b1111);
        u_axi4l_accessor.write(ADR_CTL_FRM_TIMER_EN,         1, 4'b1111);
        u_axi4l_accessor.write(ADR_PARAM_FILL,      32'hff0000, 4'b1111);
        u_axi4l_accessor.write(ADR_CTL_CONTROL,              3, 4'b1111);

        #1000000;
        u_axi4l_accessor.write(ADR_PARAM_FILL,      32'h0000ff, 4'b1111);
        u_axi4l_accessor.write(ADR_CTL_CONTROL,              3, 4'b1111);
        */
    end

endmodule


`default_nettype wire


// end of file
