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
    
    tb_sim_main
        i_sim_main
            (
            );
    
    initial begin
        force i_sim_main.i_top.i_design_1.reset = reset;
        force i_sim_main.i_top.i_design_1.clk   = clk;
    end
    


    // ----------------------------------
    //  WISHBONE master
    // ----------------------------------

    parameter int   WB_ADR_WIDTH = 37;
    parameter int   WB_DAT_WIDTH = 64;
    parameter int   WB_SEL_WIDTH = WB_DAT_WIDTH/8;
    
    // force connect to top-net
    logic                       wb_rst_i;
    logic                       wb_clk_i;
    logic   [WB_ADR_WIDTH-1:0]  wb_adr_o;
    logic   [WB_DAT_WIDTH-1:0]  wb_dat_i;
    logic   [WB_DAT_WIDTH-1:0]  wb_dat_o;
    logic                       wb_we_o;
    logic   [WB_SEL_WIDTH-1:0]  wb_sel_o;
    logic                       wb_stb_o = 0;
    logic                       wb_ack_i;
    
    assign wb_rst_i = reset;
    assign wb_clk_i = clk;
    assign wb_dat_i = i_sim_main.i_top.i_design_1.wb_dat_o;
    assign wb_ack_i = i_sim_main.i_top.i_design_1.wb_ack_o;

    initial begin
        force i_sim_main.i_top.i_design_1.wb_adr_i = wb_adr_o;
        force i_sim_main.i_top.i_design_1.wb_dat_i = wb_dat_o;
        force i_sim_main.i_top.i_design_1.wb_we_i  = wb_we_o;
        force i_sim_main.i_top.i_design_1.wb_sel_i = wb_sel_o;
        force i_sim_main.i_top.i_design_1.wb_stb_i = wb_stb_o;
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

    localparam  ADR_HLS = 32'h0000_0000;
    localparam  ADR_LED = 32'h0011_0000;

    localparam  REG_HLS_CORE_ID = 0;
    localparam  REG_HLS_CONTROL = 4;
    localparam  REG_HLS_STATUS  = 5;
    localparam  REG_HLS_A       = 8;
    localparam  REG_HLS_B       = 9;
    localparam  REG_HLS_C       = 10;

    initial begin
    @(negedge wb_rst_i);
    #100;
        wb_read(ADR_HLS+REG_HLS_CORE_ID);
        wb_write(ADR_HLS+REG_HLS_A, 7777, 8'hff);
        wb_write(ADR_HLS+REG_HLS_B, 1111, 8'hff);
        wb_write(ADR_HLS+REG_HLS_CONTROL, 1, 8'hff);
    #400;        
        wb_read(ADR_HLS+REG_HLS_A);
        wb_read(ADR_HLS+REG_HLS_B);
        wb_read(ADR_HLS+REG_HLS_C);

    #1000;
        wb_write(ADR_LED, 0, 8'hff);
        wb_write(ADR_LED, 1, 8'hff);
        wb_write(ADR_LED, 0, 8'hff);
        wb_write(ADR_LED, 1, 8'hff);

    #100;
        $finish();
    end
    
endmodule


`default_nettype wire


// end of file
