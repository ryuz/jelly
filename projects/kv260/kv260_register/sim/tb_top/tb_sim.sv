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
        $dumpvars(0, tb_sim);
        
    #1000000;
        $finish;
    end
    

    // ---------------------------------
    //  clock & reset
    // ---------------------------------

    localparam RATE = 1000.0/100.00;

    logic           reset = 1;
    initial #100 reset = 0;

    logic           clk = 1'b1;
    always #(RATE/2.0) clk <= ~clk;

    

    // ---------------------------------
    //  main
    // ---------------------------------
    
    parameter   WB_ADR_BITS = 38;
    parameter   WB_DAT_BITS = 32;
    parameter   WB_SEL_BITS = (WB_DAT_BITS / 8);

    var logic   [WB_ADR_BITS-1:0]   s_wb_adr_i;
    var logic   [WB_DAT_BITS-1:0]   s_wb_dat_o;
    var logic   [WB_DAT_BITS-1:0]   s_wb_dat_i;
    var logic   [WB_SEL_BITS-1:0]   s_wb_sel_i;
    var logic                       s_wb_we_i;
    var logic                       s_wb_stb_i;
    var logic                       s_wb_ack_o;

    tb_main
            #(
                .WB_ADR_BITS   (WB_ADR_BITS),
                .WB_DAT_BITS   (WB_DAT_BITS)
            )
        i_tb_main
            (
                .reset,
                .clk,
                .s_wb_adr_i,
                .s_wb_dat_o,
                .s_wb_dat_i,
                .s_wb_sel_i,
                .s_wb_we_i,
                .s_wb_stb_i,
                .s_wb_ack_o
            );
    
    
    // ----------------------------------
    //  WISHBONE master
    // ----------------------------------
        
    logic                           wb_rst_i;
    logic                           wb_clk_i;
    logic   [WB_ADR_BITS-1:0]       wb_adr_o;
    logic   [WB_DAT_BITS-1:0]       wb_dat_i;
    logic   [WB_DAT_BITS-1:0]       wb_dat_o;
    logic                           wb_we_o;
    logic   [WB_SEL_BITS-1:0]       wb_sel_o;
    logic                           wb_stb_o = '0;
    logic                           wb_ack_i;

    assign wb_rst_i = reset;
    assign wb_clk_i = clk;
    assign wb_dat_i = s_wb_dat_o;
    assign wb_ack_i = s_wb_ack_o;

    assign s_wb_adr_i = wb_adr_o;
    assign s_wb_dat_i = wb_dat_o;
    assign s_wb_we_i  = wb_we_o;
    assign s_wb_sel_i = wb_sel_o;
    assign s_wb_stb_i = wb_stb_o;
    
    
    logic   [WB_DAT_BITS-1:0]  reg_wb_dat;
    logic                       reg_wb_ack;
    always_ff @(posedge wb_clk_i) begin
        if ( ~wb_we_o & wb_stb_o & wb_ack_i ) begin
            reg_wb_dat <= wb_dat_i;
        end
        reg_wb_ack <= wb_ack_i;
    end
    
    
    task wb_write(
                input [WB_ADR_BITS-1:0]    adr,
                input [WB_DAT_BITS-1:0]    dat,
                input [WB_SEL_BITS-1:0]    sel
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
            wb_adr_o = {WB_ADR_BITS{1'bx}};
            wb_dat_o = {WB_DAT_BITS{1'bx}};
            wb_sel_o = {WB_SEL_BITS{1'bx}};
            wb_we_o  = 1'bx;
            wb_stb_o = 1'b0;
    end
    endtask
    
    task wb_read(
                input [WB_ADR_BITS-1:0]    adr
            );
    begin
        @(negedge wb_clk_i);
            wb_adr_o = adr;
            wb_dat_o = {WB_DAT_BITS{1'bx}};
            wb_sel_o = {WB_SEL_BITS{1'b1}};
            wb_we_o  = 1'b0;
            wb_stb_o = 1'b1;
        @(negedge wb_clk_i);
            while ( reg_wb_ack == 1'b0 ) begin
                @(negedge wb_clk_i);
            end
            wb_adr_o = {WB_ADR_BITS{1'bx}};
            wb_dat_o = {WB_DAT_BITS{1'bx}};
            wb_sel_o = {WB_SEL_BITS{1'bx}};
            wb_we_o  = 1'bx;
            wb_stb_o = 1'b0;
            $display("WISHBONE_READ(adr:%h dat:%h)", adr, reg_wb_dat);
    end
    endtask
    
    
    initial begin
    #1000;
        $display("start");
        
        // read initial value
        $display("read initial value");
        wb_read (0);
        wb_read (1);
        wb_read (2);
        wb_read (3);

        // write test
        $display("write test");
        wb_write(0, 32'h1100_0011, 4'hf);
        wb_write(1, 32'h0022_2200, 4'hf);
        wb_write(2, 32'h3333_0000, 4'hf);
        wb_write(3, 32'h0000_4444, 4'hf);
        wb_read (0);
        wb_read (1);
        wb_read (2);
        wb_read (3);

        // strb test
        $display("strb test");
        wb_write(0, 32'h5500_0000, 4'h8);
        wb_write(1, 32'h0066_0000, 4'h4);
        wb_write(2, 32'h0000_7700, 4'h2);
        wb_write(3, 32'h0066_0088, 4'h1);
        wb_read (0);
        wb_read (1);
        wb_read (2);
        wb_read (3);

    #1000;
        $finish();
    end
    
endmodule


`default_nettype wire


// end of file
