// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuz 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_sim();
    
    initial begin
        $dumpfile("tb_sim.vcd");
        $dumpvars(1, tb_sim);
        
    #10000000
        $finish;
    end
    

    // ---------------------------------
    //  clock & reset
    // ---------------------------------

    localparam RATE50  = 1000.0/50.00;
    localparam RATE100 = 1000.0/100.00;
    localparam RATE200 = 1000.0/200.00;
    localparam RATE250 = 1000.0/250.00;
 
    reg			reset = 1;
    initial #100 reset = 0;

    reg			clk50 = 1'b1;
    always #(RATE50/2.0) clk50 <= ~clk50;

    reg			clk100 = 1'b1;
    always #(RATE100/2.0) clk100 <= ~clk100;

    reg			clk200 = 1'b1;
    always #(RATE200/2.0) clk200 <= ~clk200;

    reg			clk250 = 1'b1;
    always #(RATE250/2.0) clk250 <= ~clk250;

    
    // ---------------------------------
    //  main
    // ---------------------------------

    parameter   WB_ADR_WIDTH        = 29;
    parameter   WB_DAT_WIDTH        = 32;
    parameter   WB_SEL_WIDTH        = (WB_DAT_WIDTH / 8);
    
    logic   [WB_ADR_WIDTH-1:0]      s_wb_adr_i;
    logic   [WB_DAT_WIDTH-1:0]      s_wb_dat_o;
    logic   [WB_DAT_WIDTH-1:0]      s_wb_dat_i;
    logic   [WB_SEL_WIDTH-1:0]      s_wb_sel_i;
    logic                           s_wb_we_i;
    logic                           s_wb_stb_i;
    logic                           s_wb_ack_o;

    tb_main
            #(
                .WB_ADR_WIDTH   (WB_ADR_WIDTH),
                .WB_DAT_WIDTH   (WB_DAT_WIDTH)
            )
        i_tb_main
            (
                .reset,
                .clk50,
                .clk100,
                .clk200,
                .clk250,

                .s_wb_peri_adr_i    (s_wb_adr_i),
                .s_wb_peri_dat_o    (s_wb_dat_o),
                .s_wb_peri_dat_i    (s_wb_dat_i),
                .s_wb_peri_sel_i    (s_wb_sel_i),
                .s_wb_peri_we_i     (s_wb_we_i),
                .s_wb_peri_stb_i    (s_wb_stb_i),
                .s_wb_peri_ack_o    (s_wb_ack_o)
            );
    
    
    // ----------------------------------
    //  WISHBONE master
    // ----------------------------------
        
    wire                            wb_rst_i = reset;
    wire                            wb_clk_i = clk250;
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
    

`include "jelly/JellyRegs.vh"
    
    initial begin
    #1000;
        $display("start");

    #40000;
        $finish();
    end
    
    
endmodule


`default_nettype wire


// end of file
