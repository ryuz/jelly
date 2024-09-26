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
        
    #10000000
        $finish;
    end
    
   

    // ---------------------------------
    //  clock & reset
    // ---------------------------------

    localparam RATE    = 1000.0/100.00;

    reg			reset = 1;
    initial #(RATE*100)reset = 0;

    reg			clk = 1'b1;
    always #(RATE/2.0) clk <= ~clk;

    

    // ---------------------------------
    //  main
    // ---------------------------------

    parameter   WB_ADR_WIDTH        = 37;
    parameter   WB_DAT_WIDTH        = 64;
    parameter   WB_SEL_WIDTH        = (WB_DAT_WIDTH / 8);
    
    logic   [WB_ADR_WIDTH-1:0]      s_wb_adr_i;
    logic   [WB_DAT_WIDTH-1:0]      s_wb_dat_o;
    logic   [WB_DAT_WIDTH-1:0]      s_wb_dat_i;
    logic   [WB_SEL_WIDTH-1:0]      s_wb_sel_i;
    logic                           s_wb_we_i;
    logic                           s_wb_stb_i;
    logic                           s_wb_ack_o;

    tb_main
        i_tb_main
            (
                .reset              (reset),
                .clk                (clk),

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
    wire                            wb_clk_i = clk;
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
    


    // ベースアドレス
    localparam  ADR_DMA0   = WB_ADR_WIDTH'(32'h00000) >> 3;
    localparam  ADR_DMA1   = WB_ADR_WIDTH'(32'h00800) >> 3;
    localparam  ADR_LED    = WB_ADR_WIDTH'(32'h08000) >> 3;
    localparam  ADR_TIM    = WB_ADR_WIDTH'(32'h10000) >> 3;

    // レジスタアドレス
    localparam REG_DMA_STATUS  = 0;
    localparam REG_DMA_WSTART  = 1;
    localparam REG_DMA_RSTART  = 2;
    localparam REG_DMA_ADDR    = 3;
    localparam REG_DMA_WDATA0  = 4;
    localparam REG_DMA_WDATA1  = 5;
    localparam REG_DMA_RDATA0  = 6;
    localparam REG_DMA_RDATA1  = 7;
    localparam REG_DMA_CORE_ID = 8;

    localparam REG_TIM_CONTROL = 0;
    localparam REG_TIM_COMPARE = 1;
    localparam REG_TIM_COUNTER = 3;
    
    initial begin
    #1000;
        $display("read DMA id");
        wb_read (ADR_DMA0 + REG_DMA_CORE_ID);
        wb_read (ADR_DMA1 + REG_DMA_CORE_ID);

        $display("write with DMA0");
        wb_write(ADR_DMA0 + REG_DMA_ADDR,   64'h00000000_00000000, 8'hff);
        wb_write(ADR_DMA0 + REG_DMA_WDATA0, 64'hfedcba98_76543210, 8'hff);
        wb_write(ADR_DMA0 + REG_DMA_WDATA1, 64'h01234567_89abcdef, 8'hff);
        wb_write(ADR_DMA0 + REG_DMA_WSTART, 1, 8'hff);
        wb_read(ADR_DMA0 + REG_DMA_STATUS);
        while ( reg_wb_dat != 0 ) begin
            #100;
            wb_read(ADR_DMA0 + REG_DMA_STATUS);
        end

        // DMA1で書き込み
        $display("write with DMA1");
        wb_write(ADR_DMA1 + REG_DMA_ADDR,   64'h00000000_00000100, 8'hff);
        wb_write(ADR_DMA1 + REG_DMA_WDATA0, 64'h55aa55aa_55aa55aa, 8'hff);
        wb_write(ADR_DMA1 + REG_DMA_WDATA1, 64'haa55aa55_aa55aa55, 8'hff);
        wb_write(ADR_DMA1 + REG_DMA_WSTART, 1, 8'hff);
        wb_read(ADR_DMA1 + REG_DMA_STATUS);
        while ( reg_wb_dat != 0 ) begin
            #100;
            wb_read(ADR_DMA1 + REG_DMA_STATUS);
        end

        $display("read with DMA0");
        wb_write(ADR_DMA0 + REG_DMA_ADDR,   64'h00000000_00000000, 8'hff);
        wb_write(ADR_DMA0 + REG_DMA_RSTART, 1, 8'hff);
        wb_read(ADR_DMA0 + REG_DMA_STATUS);
        while ( reg_wb_dat != 0 ) begin
            #100;
            wb_read(ADR_DMA0 + REG_DMA_STATUS);
        end
        wb_read(ADR_DMA0 + REG_DMA_RDATA0);
        wb_read(ADR_DMA0 + REG_DMA_RDATA1);

        $display("read with DMA1");
        wb_write(ADR_DMA1 + REG_DMA_ADDR,   64'h00000000_00000100, 8'hff);
        wb_write(ADR_DMA1 + REG_DMA_RSTART, 1, 8'hff);
        wb_read(ADR_DMA1 + REG_DMA_STATUS);
        while ( reg_wb_dat != 0 ) begin
            #100;
            wb_read(ADR_DMA1 + REG_DMA_STATUS);
        end
        wb_read(ADR_DMA1 + REG_DMA_RDATA0);
        wb_read(ADR_DMA1 + REG_DMA_RDATA1);

    #10000;
        $finish();
    end
    
    
endmodule


`default_nettype wire


// end of file
