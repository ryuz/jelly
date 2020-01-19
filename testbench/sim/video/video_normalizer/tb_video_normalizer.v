
`timescale 1ns / 1ps
`default_nettype none


module tb_video_normalizer();
    localparam RATE  = 10.0;
    
    initial begin
        $dumpfile("tb_video_normalizer.vcd");
        $dumpvars(0, tb_video_normalizer);
    
    #10000000
        $finish;
    end
    
    
    reg     clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;
    
    reg     reset = 1'b1;
    initial begin
        #(RATE*100);
        @(posedge clk)  reset <= 1'b0;
    end
    
    
    reg     timeout_busy = 0;
    initial begin
        #(RATE*5000)    timeout_busy = 1'b1;
        #(RATE*100)     timeout_busy = 1'b0;
    end
    
    localparam  FRAME_NUM = 10;
    
    localparam  X_NUM = 128*2;
    localparam  Y_NUM = 128/2;

//  localparam  X_NUM = 128/2;
//  localparam  Y_NUM = 128*2;
    
//  localparam  X_NUM = 128;
//  localparam  Y_NUM = 128;

//  localparam  X_NUM = 128*2;
//  localparam  Y_NUM = 128;

//  localparam  X_NUM = 128/2;
//  localparam  Y_NUM = 128;

//  localparam  X_NUM = 128;
//  localparam  Y_NUM = 128/2;

//  localparam  X_NUM = 128/2;
//  localparam  Y_NUM = 128/2;

//  localparam  X_NUM = 128;
//  localparam  Y_NUM = 128*2;

//  localparam  X_NUM = 128*2;
//  localparam  Y_NUM = 128*2;

    
    
    
    parameter   WB_ADR_WIDTH       = 8;
    parameter   WB_DAT_WIDTH       = 32;
    parameter   WB_SEL_WIDTH       = (WB_DAT_WIDTH / 8);
    
    parameter   TUSER_WIDTH        = 1;
    parameter   TDATA_WIDTH        = 24;
    parameter   X_WIDTH            = 12;
    parameter   Y_WIDTH            = 12;
    parameter   TIMER_WIDTH        = 32;
    parameter   S_SLAVE_REGS       = 1;
    parameter   S_MASTER_REGS      = 1;
    parameter   M_SLAVE_REGS       = 1;
    parameter   M_MASTER_REGS      = 1;
    
    parameter   INIT_CONTROL       = 2'b11;
    parameter   INIT_PARAM_WIDTH   = X_NUM;
    parameter   INIT_PARAM_HEIGHT  = Y_NUM;
    parameter   INIT_PARAM_FILL    = 24'h00ff00;
    parameter   INIT_PARAM_TIMEOUT = 64;
    
    wire                        aresetn = ~reset;
    wire                        aclk    = clk;
    reg                         aclken  = 1;
    
    wire                        s_wb_rst_i = reset;
    wire                        s_wb_clk_i = clk;
    wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i;
    wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i;
    wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o;
    wire                        s_wb_we_i;
    wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i;
    wire                        s_wb_stb_i;
    wire                        s_wb_ack_o;
    
    wire    [TUSER_WIDTH-1:0]   s_axi4s_tuser;
    wire                        s_axi4s_tlast;
    wire    [TDATA_WIDTH-1:0]   s_axi4s_tdata;
    wire                        s_axi4s_tvalid;
    wire                        s_axi4s_tready;
    
    wire    [TUSER_WIDTH-1:0]   m_axi4s_tuser;
    wire                        m_axi4s_tlast;
    wire    [TDATA_WIDTH-1:0]   m_axi4s_tdata;
    wire                        m_axi4s_tvalid;
    reg                         m_axi4s_tready = 1;
    
    always @(posedge aclk) begin
        m_axi4s_tready <= {$random()};
    end
    
    
    // model
    jelly_axi4s_master_model
            #(
                .AXI4S_DATA_WIDTH   (TDATA_WIDTH),
                .X_NUM              (128),
                .Y_NUM              (128),
                .PPM_FILE           ("lena_128x128.ppm"),
                .BUSY_RATE          (50),
                .RANDOM_SEED        (0)
            )
        i_axi4s_master_model
            (
                .aresetn            (aresetn),
                .aclk               (aclk),
                
                .m_axi4s_tuser      (s_axi4s_tuser),
                .m_axi4s_tlast      (s_axi4s_tlast),
                .m_axi4s_tdata      (s_axi4s_tdata),
                .m_axi4s_tvalid     (s_axi4s_tvalid),
                .m_axi4s_tready     (s_axi4s_tready & !timeout_busy)
            );
    
    
    // core
    jelly_video_normalizer
            #(
                .WB_ADR_WIDTH       (WB_ADR_WIDTH),
                .WB_DAT_WIDTH       (WB_DAT_WIDTH),
                .WB_SEL_WIDTH       (WB_SEL_WIDTH),
                
                .TUSER_WIDTH        (TUSER_WIDTH),
                .TDATA_WIDTH        (TDATA_WIDTH),
                .X_WIDTH            (X_WIDTH),
                .Y_WIDTH            (Y_WIDTH),
                .TIMER_WIDTH        (TIMER_WIDTH),
                .S_SLAVE_REGS       (S_SLAVE_REGS),
                .S_MASTER_REGS      (S_MASTER_REGS),
                .M_SLAVE_REGS       (M_SLAVE_REGS),
                .M_MASTER_REGS      (M_MASTER_REGS),
                
                .INIT_CONTROL       (INIT_CONTROL),
                .INIT_PARAM_WIDTH   (INIT_PARAM_WIDTH),
                .INIT_PARAM_HEIGHT  (INIT_PARAM_HEIGHT),
                .INIT_PARAM_FILL    (INIT_PARAM_FILL),
                .INIT_PARAM_TIMEOUT (INIT_PARAM_TIMEOUT)
            )
        i_video_normalizer
            (
                .aresetn            (aresetn),
                .aclk               (aclk),
                .aclken             (aclken),
                
                .s_wb_rst_i         (s_wb_rst_i),
                .s_wb_clk_i         (s_wb_clk_i),
                .s_wb_adr_i         (s_wb_adr_i),
                .s_wb_dat_i         (s_wb_dat_i),
                .s_wb_dat_o         (s_wb_dat_o),
                .s_wb_we_i          (s_wb_we_i),
                .s_wb_sel_i         (s_wb_sel_i),
                .s_wb_stb_i         (s_wb_stb_i),
                .s_wb_ack_o         (s_wb_ack_o),
                
                .s_axi4s_tuser      (s_axi4s_tuser),
                .s_axi4s_tlast      (s_axi4s_tlast),
                .s_axi4s_tdata      (s_axi4s_tdata),
                .s_axi4s_tvalid     (s_axi4s_tvalid & !timeout_busy),
                .s_axi4s_tready     (s_axi4s_tready),
                
                .m_axi4s_tuser      (m_axi4s_tuser),
                .m_axi4s_tlast      (m_axi4s_tlast),
                .m_axi4s_tdata      (m_axi4s_tdata),
                .m_axi4s_tvalid     (m_axi4s_tvalid),
                .m_axi4s_tready     (m_axi4s_tready)
            );
    
    
    // dump
    integer     fp_img;
    initial begin
         fp_img = $fopen("out_img.ppm", "w");
         $fdisplay(fp_img, "P3");
         $fdisplay(fp_img, "%d %d", X_NUM, Y_NUM*FRAME_NUM);
         $fdisplay(fp_img, "255");
    end
    
    always @(posedge clk) begin
        if ( !reset && m_axi4s_tvalid && m_axi4s_tready ) begin
             $fdisplay(fp_img, "%d %d %d", m_axi4s_tdata[0*8 +: 8], m_axi4s_tdata[1*8 +: 8], m_axi4s_tdata[2*8 +: 8]);
        end
    end
    
    integer frame_count = 0;
    always @(posedge clk) begin
        if ( !reset && m_axi4s_tuser[0] && m_axi4s_tvalid && m_axi4s_tready ) begin
            $display("frame : %d", frame_count);
            frame_count = frame_count + 1;
            if ( frame_count > FRAME_NUM+1 ) begin
                $finish();
            end
        end
    end
    
    /*
    integer fp;
    initial fp = $fopen("out.txt", "w");
    always @(posedge clk) begin
        if (!reset && aclken && m_axi4s_tvalid && m_axi4s_tready ) begin
            $fdisplay(fp, "%b %b %h", m_axi4s_tuser, m_axi4s_tlast, m_axi4s_tdata);
        end
    end
    */
    
    
    
    
    
    
    // ----------------------------------
    //  WISHBONE master
    // ----------------------------------
    
    wire                            wb_rst_i = s_wb_rst_i;
    wire                            wb_clk_i = s_wb_clk_i;
    reg     [WB_ADR_WIDTH-1:0]      wb_adr_o;
    wire    [WB_DAT_WIDTH-1:0]      wb_dat_i = s_wb_dat_o;
    reg     [WB_DAT_WIDTH-1:0]      wb_dat_o;
    reg                             wb_we_o;
    reg     [WB_SEL_WIDTH-1:0]      wb_sel_o;
    reg                             wb_stb_o = 0;
    wire                            wb_ack_i = s_wb_ack_o;
    
    assign s_wb_adr_i = wb_adr_o;
    assign s_wb_dat_i = wb_dat_o;
    assign s_wb_we_i  = wb_we_o;
    assign s_wb_sel_i = wb_sel_o;
    assign s_wb_stb_i = wb_stb_o;
    
    
    reg     [WB_DAT_WIDTH-1:0]      reg_wb_dat;
    reg                             reg_wb_ack;
    always @(posedge wb_clk_i) begin
        if ( ~wb_we_o & wb_stb_o & wb_ack_i ) begin
            reg_wb_dat <= wb_dat_i;
        end
        reg_wb_ack <= wb_ack_i;
    end
    
    
    task wb_write(
                input [31:0]    adr,
                input [31:0]    dat,
                input [3:0]     sel
            );
    begin
        $display("WISHBONE_WRITE(adr:%h dat:%h sel:%b)", adr, dat, sel);
        @(negedge wb_clk_i);
            wb_adr_o = (adr >> 2);
            wb_dat_o = dat;
            wb_sel_o = sel;
            wb_we_o  = 1'b1;
            wb_stb_o = 1'b1;
        @(negedge wb_clk_i);
            while ( reg_wb_ack == 1'b0 ) begin
                @(negedge wb_clk_i);
            end
            wb_adr_o = {WB_ADR_WIDTH{1'bx}};
            wb_dat_o = {WB_DAT_WIDTH{1'bx}};
            wb_sel_o = {WB_SEL_WIDTH{1'bx}};
            wb_we_o  = 1'bx;
            wb_stb_o = 1'b0;
    end
    endtask
    
    task wb_read(
                input [31:0]    adr
            );
    begin
        @(negedge wb_clk_i);
            wb_adr_o = (adr >> 2);
            wb_dat_o = {WB_DAT_WIDTH{1'bx}};
            wb_sel_o = {WB_SEL_WIDTH{1'b1}};
            wb_we_o  = 1'b0;
            wb_stb_o = 1'b1;
        @(negedge wb_clk_i);
            while ( reg_wb_ack == 1'b0 ) begin
                @(negedge wb_clk_i);
            end
            wb_adr_o = {WB_ADR_WIDTH{1'bx}};
            wb_dat_o = {WB_DAT_WIDTH{1'bx}};
            wb_sel_o = {WB_SEL_WIDTH{1'bx}};
            wb_we_o  = 1'bx;
            wb_stb_o = 1'b0;
            $display("WISHBONE_READ(adr:%h dat:%h)", adr, reg_wb_dat);
    end
    endtask
    
    
    initial begin
        #(RATE*200);
        $display("start");
        wb_read(32'h00000000);
        wb_read(32'h00000004);
        wb_read(32'h00000008);
        wb_read(32'h0000000c);
        wb_read(32'h00000020);
        wb_read(32'h00000024);
        wb_read(32'h00000028);
        wb_read(32'h0000002c);
        
        
        #(RATE*100);
        $display("enable");
        wb_write(32'h00000000, 1, 4'b1111);
        wb_read(32'h00000000);
        wb_read(32'h00000004);
        
        #1000000;
        $display("disable");
        wb_write(32'h00000000, 0, 4'b1111);
        wb_read(32'h00000000);
        wb_read(32'h00000004);
        
        #2000000;
        $display("enable");
        wb_write(32'h00000000, 1, 4'b1111);
        wb_read(32'h00000000);
        wb_read(32'h00000004);
        
        // frame timeout
        #1000000;
        $display("frame timeout");
        wb_write(32'h00000014, 100000, 4'b1111);
        wb_write(32'h00000010, 1,      4'b1111);
        wb_write(32'h00000028, 24'hff0000, 4'b1111);
        wb_write(32'h00000000, 3, 4'b1111);
        #10000;
        timeout_busy = 1;
        #1000000;
        timeout_busy = 0;
        wb_write(32'h00000028, 24'h0000ff, 4'b1111);
        wb_write(32'h00000000, 3, 4'b1111);
    end
    
    
endmodule


`default_nettype wire


// end of file
