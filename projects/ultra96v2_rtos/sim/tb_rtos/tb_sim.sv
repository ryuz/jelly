// ---------------------------------------------------------------------------
//
//                                  Copyright (C) 2015-2020 by Ryuz
//                                  https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_sim();
    localparam RATE = 1000.0/200.0;
    
    initial begin
        $dumpfile("tb_sim.vcd");
        $dumpvars(0, tb_sim);
        
    #1000000
        $finish;
    end
    
    logic     reset = 1'b1;
    initial #(RATE*10) reset <= 1'b0;

    logic     clk = 1'b1;
    always  #(RATE/2.0) clk  = ~clk;
    


    // ----------------------------------
    //  main
    // ----------------------------------
    
    parameter int   WB_ADR_WIDTH = 16;
    parameter int   WB_DAT_WIDTH = 32;
    parameter int   WB_SEL_WIDTH = WB_DAT_WIDTH/8;

    logic   [WB_ADR_WIDTH-1:0]  s_wb_adr_i;
    logic   [WB_DAT_WIDTH-1:0]  s_wb_dat_i;
    logic   [WB_DAT_WIDTH-1:0]  s_wb_dat_o;
    logic                       s_wb_we_i;
    logic   [WB_SEL_WIDTH-1:0]  s_wb_sel_i;
    logic                       s_wb_stb_i;
    logic                       s_wb_ack_o;

    tb_sim_main
        i_sim_main
            (
                .*
            );
    
    


    // ----------------------------------
    //  WISHBONE master
    // ----------------------------------
    
    // force connect to top-net
    wire                            wb_rst_i = reset;
    wire                            wb_clk_i = clk;
    reg     [WB_ADR_WIDTH-1:0]      wb_adr_o;
    wire    [WB_DAT_WIDTH-1:0]      wb_dat_i = s_wb_dat_o;
    reg     [WB_DAT_WIDTH-1:0]      wb_dat_o;
    reg                             wb_we_o;
    reg     [WB_SEL_WIDTH-1:0]      wb_sel_o;
    reg                             wb_stb_o = 0;
    wire                            wb_ack_i = s_wb_ack_o;
    
    initial begin
        force s_wb_adr_i = wb_adr_o;
        force s_wb_dat_i = wb_dat_o;
        force s_wb_we_i  = wb_we_o;
        force s_wb_sel_i = wb_sel_o;
        force s_wb_stb_i = wb_stb_o;
    end
    
    
    
    reg     [WB_DAT_WIDTH-1:0]      reg_wb_dat;
    reg                             reg_wb_ack;
    always @(posedge wb_clk_i) begin
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
    //  Simulation
    // ----------------------------------
    
    initial begin
    @(negedge wb_rst_i);
    
    #10000;
        $display(" --- start --- ");
        wb_read (0);
        wb_write(0, 1, 8'hff);
        
    #10000;
        $finish();
        
    end
    
endmodule


`default_nettype wire


// end of file
