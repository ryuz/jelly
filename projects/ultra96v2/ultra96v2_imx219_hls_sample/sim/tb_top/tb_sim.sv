// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuji Fuchikami 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_sim();
    
    initial begin
        $dumpfile("tb_sim.vcd");
        $dumpvars(0, tb_sim);
        
    #1000000
        $finish;
    end
    
    
    parameter   X_NUM = 1024;   // 3280 / 2;
    parameter   Y_NUM = 64;     // 2464 / 2;


    // ---------------------------------
    //  clock & reset
    // ---------------------------------

    localparam RATE100 = 1000.0/100.00;
    localparam RATE200 = 1000.0/200.00;
    localparam RATE250 = 1000.0/250.00;
    localparam RATE133 = 1000.0/133.33;

    reg			reset = 1;
    initial #100 reset = 0;

    reg			clk100 = 1'b1;
    always #(RATE100/2.0) clk100 <= ~clk100;

    reg			clk200 = 1'b1;
    always #(RATE200/2.0) clk200 <= ~clk200;

    reg			clk250 = 1'b1;
    always #(RATE250/2.0) clk250 <= ~clk250;

    initial begin
      force i_tb_sim_main.i_top.i_design_1.reset = reset;
      force i_tb_sim_main.i_top.i_design_1.clk100 = clk100;
      force i_tb_sim_main.i_top.i_design_1.clk200 = clk200;
      force i_tb_sim_main.i_top.i_design_1.clk250 = clk250;
    end

    
    // ---------------------------------
    //  main
    // ---------------------------------
    
    tb_sim_main
            #(
                .X_NUM  (X_NUM),
                .Y_NUM  (Y_NUM)
            )
        i_tb_sim_main
            (
                .reset  (reset),
                .clk    (clk100)
            );
    
    
   
    
    // ----------------------------------
    //  WISHBONE master
    // ----------------------------------
    
    parameter   WB_ADR_WIDTH        = 30;
    parameter   WB_DAT_WIDTH        = 64;
    parameter   WB_SEL_WIDTH        = (WB_DAT_WIDTH / 8);
    
    wire                            wb_rst_i = i_tb_sim_main.i_top.wb_peri_rst_i;
    wire                            wb_clk_i = i_tb_sim_main.i_top.wb_peri_clk_i;
    reg     [WB_ADR_WIDTH-1:0]      wb_adr_o;
    wire    [WB_DAT_WIDTH-1:0]      wb_dat_i = i_tb_sim_main.i_top.wb_peri_dat_o;
    reg     [WB_DAT_WIDTH-1:0]      wb_dat_o;
    reg                             wb_we_o;
    reg     [WB_SEL_WIDTH-1:0]      wb_sel_o;
    reg                             wb_stb_o = 0;
    wire                            wb_ack_i = i_tb_sim_main.i_top.wb_peri_ack_o;
    
    initial begin
        force i_tb_sim_main.i_top.wb_peri_adr_i = wb_adr_o;
        force i_tb_sim_main.i_top.wb_peri_dat_i = wb_dat_o;
        force i_tb_sim_main.i_top.wb_peri_we_i  = wb_we_o;
        force i_tb_sim_main.i_top.wb_peri_sel_i = wb_sel_o;
        force i_tb_sim_main.i_top.wb_peri_stb_i = wb_stb_o;
    end
    
    
    reg     [WB_DAT_WIDTH-1:0]      reg_wb_dat;
    reg                             reg_wb_ack;
    always_ff @(posedge wb_clk_i) begin
        if ( ~wb_we_o & wb_stb_o & wb_ack_i ) begin
            reg_wb_dat <= wb_dat_i;
        end
        reg_wb_ack <= wb_ack_i;
    end
    
    
    task wb_write(
                input [WB_ADR_WIDTH-1:0]    adr,
                input [WB_DAT_WIDTH-1:0]    dat,
                input [WB_SEL_WIDTH:0]      sel
            );
    begin
        $display("WISHBONE_WRITE(adr:%h dat:%h sel:%b)", adr, dat, sel);
        @(negedge wb_clk_i);
            wb_adr_o = adr;
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
                input [WB_ADR_WIDTH-1:0]    adr
            );
    begin
        @(negedge wb_clk_i);
            wb_adr_o = adr;
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
    
    

    localparam ADR_FMTR    = (32'h00100000 >> 3);  // ビデオサイズ正規化
    localparam ADR_DEMOS   = (32'h00200000 >> 3);  // デモザイク
    localparam ADR_COLMAT  = (32'h00210000 >> 3);  // カラーマトリックス
    localparam ADR_GAMMA   = (32'h00220000 >> 3);  // ガンマ補正
    localparam ADR_GAUSS   = (32'h00240000 >> 3);  // ガウシアンフィルタ
    localparam ADR_CANNY   = (32'h00250000 >> 3);  // Cannyフィルタ
    localparam ADR_IMGDMA  = (32'h00260000 >> 3);  // FIFO dma
    localparam ADR_BINDIFF = (32'h00270000 >> 3);  // 前画像との差分バイナライズ
    localparam ADR_SEL     = (32'h002f0000 >> 3);  // 出力切り替え
    localparam ADR_BUFMNG  = (32'h00300000 >> 3);  // Buffer manager
    localparam ADR_BUFALC  = (32'h00310000 >> 3);  // Buffer allocator
    localparam ADR_VDMAW   = (32'h00320000 >> 3);  // Write-DMA
    localparam ADR_VDMAR   = (32'h00340000 >> 3);  // Read-DMA
    localparam ADR_VSGEN   = (32'h00360000 >> 3);  // Video out sync generator
    localparam ADR_HLS     = (32'h00400000 >> 3);

`include "jelly/JellyRegs.vh"
    
    initial begin
    #1000;
        $display("start");

        $display("set FMTR");
        wb_read (ADR_FMTR + `REG_VIDEO_FMTREG_CORE_ID);
        wb_write(ADR_FMTR + `REG_VIDEO_FMTREG_PARAM_WIDTH,  X_NUM, 8'hff);
        wb_write(ADR_FMTR + `REG_VIDEO_FMTREG_PARAM_HEIGHT, Y_NUM, 8'hff);
        wb_write(ADR_FMTR + `REG_VIDEO_FMTREG_CTL_CONTROL,      32'h3, 8'hff);

        $display("set DEMOSIC");
        wb_read (ADR_DEMOS + `REG_IMG_DEMOSAIC_CORE_ID);
        wb_write(ADR_DEMOS + `REG_IMG_DEMOSAIC_PARAM_PHASE,     0, 8'hff);
        wb_write(ADR_DEMOS + `REG_IMG_DEMOSAIC_CTL_CONTROL, 32'h3, 8'hff);

        $display("set write DMA");
        wb_read (ADR_VDMAW + `REG_VDMA_WRITE_CORE_ID);
        wb_write(ADR_VDMAW + `REG_VDMA_WRITE_PARAM_ADDR,              32'h0000000, 8'hff);
        wb_write(ADR_VDMAW + `REG_VDMA_WRITE_PARAM_LINE_STEP,             X_NUM*3, 8'hff);
        wb_write(ADR_VDMAW + `REG_VDMA_WRITE_PARAM_H_SIZE,                X_NUM-1, 8'hff);
        wb_write(ADR_VDMAW + `REG_VDMA_WRITE_PARAM_V_SIZE,                Y_NUM-1, 8'hff);
        wb_write(ADR_VDMAW + `REG_VDMA_WRITE_PARAM_FRAME_STEP,      Y_NUM*X_NUM*3, 8'hff);
        wb_write(ADR_VDMAW + `REG_VDMA_WRITE_PARAM_F_SIZE,                    1-1, 8'hff);
        wb_write(ADR_VDMAW + `REG_VDMA_WRITE_CTL_CONTROL,                       3, 8'hff);  // update & enable

    #200000;
        $display("set HLS");
        wb_write(ADR_HLS + 32'h08, 1, 8'hff);

    #1000000;
        $finish();
    end
    
    
endmodule


`default_nettype wire


// end of file
