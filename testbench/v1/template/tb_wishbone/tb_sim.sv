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
        
    #100000
        $finish;
    end
    

    // ---------------------------------
    //  clock & reset
    // ---------------------------------

    localparam CLK_RATE = 1000.0/100.00;

    reg         reset = 1;
    initial #100 reset = 0;

    reg         clk = 1'b1;
    always #(CLK_RATE/2.0) clk <= ~clk;


    
    // ---------------------------------
    //  main
    // ---------------------------------

    parameter   int WB_ADR_WIDTH        = 16;
    parameter   int WB_DAT_WIDTH        = 32;
    parameter   int WB_SEL_WIDTH        = WB_DAT_WIDTH / 8;
    
    wire                            s_wb_rst_i = reset;
    wire                            s_wb_clk_i = clk;
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
                .WB_DAT_WIDTH   (WB_DAT_WIDTH),
                .WB_SEL_WIDTH   (WB_SEL_WIDTH)
            )
        i_tb_main
            (
                .reset,
                .clk,

                .s_wb_rst_i,
                .s_wb_clk_i,
                .s_wb_adr_i,
                .s_wb_dat_o,
                .s_wb_dat_i,
                .s_wb_sel_i,
                .s_wb_we_i ,
                .s_wb_stb_i,
                .s_wb_ack_o
            );
    
    
    // ----------------------------------
    //  WISHBONE master
    // ----------------------------------
        
    wire                            wb_rst_i = s_wb_rst_i;
    wire                            wb_clk_i = s_wb_clk_i;
    logic   [WB_ADR_WIDTH-1:0]      wb_adr_o;
    logic   [WB_DAT_WIDTH-1:0]      wb_dat_i = s_wb_dat_o;
    logic   [WB_DAT_WIDTH-1:0]      wb_dat_o;
    logic                           wb_we_o;
    logic   [WB_SEL_WIDTH-1:0]      wb_sel_o;
    logic                           wb_stb_o = 0;
    logic                           wb_ack_i = s_wb_ack_o;
    
    assign s_wb_adr_i = wb_adr_o;
    assign s_wb_dat_i = wb_dat_o;
    assign s_wb_we_i  = wb_we_o;
    assign s_wb_sel_i = wb_sel_o;
    assign s_wb_stb_i = wb_stb_o;
    
    
    logic   [WB_DAT_WIDTH-1:0]      reg_wb_dat;
    logic                           reg_wb_ack;
    always_ff @(posedge wb_clk_i) begin
        if ( ~wb_we_o & wb_stb_o & wb_ack_i ) begin
            reg_wb_dat <= wb_dat_i;
        end
        reg_wb_ack <= wb_ack_i;
    end
    
    task wb_write(
                input [WB_ADR_WIDTH-1:0]    adr,
                input [WB_DAT_WIDTH-1:0]    dat,
                input [WB_SEL_WIDTH-1:0]    sel
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
    

    // ----------------------------------
    //  WISHBONE Access
    // ----------------------------------

    initial begin
    #1000;
        $display("Start");
        wb_read (16'h0100);
        wb_write(16'h0200, 32'h12345678, 4'hf);

        $finish();
    end
    
    
endmodule


`default_nettype wire


// end of file
