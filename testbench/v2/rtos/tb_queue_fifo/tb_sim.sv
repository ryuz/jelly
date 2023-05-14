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
                .*
            );
    
    

    /*

    // ----------------------------------
    //  WISHBONE master
    // ----------------------------------
    
    localparam  WB_DAT_SIZE  = 3;
    localparam  WB_ADR_WIDTH = 40 - WB_DAT_SIZE;
    localparam  WB_DAT_WIDTH = (8 << WB_DAT_SIZE);
    localparam  WB_SEL_WIDTH = (1 << WB_DAT_SIZE);
    
    // force connect to top-net
    wire                            wb_rst_i = i_top.wb_peri_rst_i;
    wire                            wb_clk_i = i_top.wb_peri_clk_i;
    reg     [WB_ADR_WIDTH-1:0]      wb_adr_o;
    wire    [WB_DAT_WIDTH-1:0]      wb_dat_i = i_top.wb_peri_dat_o;
    reg     [WB_DAT_WIDTH-1:0]      wb_dat_o;
    reg                             wb_we_o;
    reg     [WB_SEL_WIDTH-1:0]      wb_sel_o;
    reg                             wb_stb_o = 0;
    wire                            wb_ack_i = i_top.wb_peri_ack_o;
    
    initial begin
        force i_top.wb_peri_adr_i = wb_adr_o;
        force i_top.wb_peri_dat_i = wb_dat_o;
        force i_top.wb_peri_we_i  = wb_we_o;
        force i_top.wb_peri_sel_i = wb_sel_o;
        force i_top.wb_peri_stb_i = wb_stb_o;
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
    
    localparam  ADR_DMA0        = 32'h000000;
    localparam  ADR_DMA1        = 32'h000100;
    localparam  ADR_LED         = 32'h001000;
    localparam  ADR_TIM         = 32'h002000;
    
    localparam  REG_DMA_STATUS  = 0;
    localparam  REG_DMA_WSTART  = 1;
    localparam  REG_DMA_RSTART  = 2;
    localparam  REG_DMA_ADDR    = 3;
    localparam  REG_DMA_WDATA0  = 4;
    localparam  REG_DMA_WDATA1  = 5;
    localparam  REG_DMA_RDATA0  = 6;
    localparam  REG_DMA_RDATA1  = 7;
    localparam  REG_DMA_ID      = 8;
    
    localparam  REG_TIM_CONTROL = 2'b00;
    localparam  REG_TIM_COMPARE = 2'b01;
    localparam  REG_TIM_COUNTER = 2'b11;
    
    
    initial begin
    @(negedge wb_rst_i);
    
    #10000;
        $display(" --- dma0 --- ");
        wb_read (ADR_DMA0 + REG_DMA_ID); // CORE_ID
        
        $display(" --- dma1 --- ");
        wb_read (ADR_DMA1 + REG_DMA_ID); // CORE_ID
        
        wb_read (ADR_DMA1 + REG_DMA_WDATA0);
        wb_write(ADR_DMA1 + REG_DMA_WDATA0, 64'h0123456789abcdef, 8'h0f);
        wb_read (ADR_DMA1 + REG_DMA_WDATA0);
        wb_write(ADR_DMA1 + REG_DMA_WDATA0, 64'h01234567FFFFFFFF, 8'hf0);
        wb_read (ADR_DMA1 + REG_DMA_WDATA0);
        
        $display("write start");
        wb_write(ADR_DMA1 + REG_DMA_WDATA0, 64'h0123456789abcdef, 8'hff);
        wb_write(ADR_DMA1 + REG_DMA_WDATA1, 64'hfedcba9876543210, 8'hff);
        wb_write(ADR_DMA1 + REG_DMA_ADDR,   64'h0000_0100, 8'hff);
        wb_write(ADR_DMA1 + REG_DMA_WSTART, 64'h0000_0001, 8'hff);
    #10000;
    
        wb_write(ADR_DMA0 + REG_DMA_ADDR,   64'h0000_0100, 8'hff);
        wb_write(ADR_DMA0 + REG_DMA_RSTART, 64'h0000_0001, 8'hff);
        wb_read (ADR_DMA0 + REG_DMA_STATUS);
        
    #10000;
        wb_read (ADR_DMA0 + REG_DMA_STATUS);
        wb_read (ADR_DMA0 + REG_DMA_RDATA0);
        wb_read (ADR_DMA0 + REG_DMA_RDATA1);
    
    
    #10000;
        $display(" --- led --- ");
        wb_read (ADR_LED);
        wb_write(ADR_LED, 1, 8'hff);
    #10000;
        wb_write(ADR_LED, 0, 8'hff);
        
        
    #10000;
        $display(" --- timer --- ");
        wb_write(ADR_TIM + REG_TIM_COMPARE, 1000-1, 8'hff);
        wb_write(ADR_TIM + REG_TIM_CONTROL, 1000-1, 8'hff);
    #11000;
        wb_read (ADR_TIM + REG_TIM_CONTROL);    // clear
        
    #10000;
        wb_read (ADR_TIM + REG_TIM_CONTROL);    // clear
        
    #10000;
        $finish();
        
    end
    */
    
endmodule


`default_nettype wire


// end of file
