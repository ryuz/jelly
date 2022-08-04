
`timescale 1ns / 1ps
`default_nettype none


module tb_sim();
    localparam RATE = 10.0;
    
    initial begin
        $dumpfile("tb_sim.vcd");
        $dumpvars(0, tb_sim);
        
    #2000000
        $finish();
    end

    reg     reset = 1'b1;
    always #(RATE*100)  reset = 1'b0;

    reg     clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;
    

    // -----------------------------
    //  main
    // -----------------------------

    parameter int   WB_ADR_WIDTH = 37;
    parameter int   WB_DAT_WIDTH = 64;
    parameter int   WB_SEL_WIDTH = WB_DAT_WIDTH/8;
    
    // force connect to top-net
    logic   [WB_ADR_WIDTH-1:0]  s_wb_adr_i;
    logic   [WB_DAT_WIDTH-1:0]  s_wb_dat_o;
    logic   [WB_DAT_WIDTH-1:0]  s_wb_dat_i;
    logic   [WB_SEL_WIDTH-1:0]  s_wb_sel_i;
    logic                       s_wb_we_i;
    logic                       s_wb_stb_i;
    logic                       s_wb_ack_o;

    tb_main
            #(
                .WB_ADR_WIDTH   (WB_ADR_WIDTH),
                .WB_DAT_WIDTH   (WB_DAT_WIDTH)
            )
        i_main
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

    // force connect to top-net
    logic                       wb_rst_i;
    logic                       wb_clk_i;
    logic   [WB_ADR_WIDTH-1:0]  wb_adr_o;
    logic   [WB_DAT_WIDTH-1:0]  wb_dat_i;
    logic   [WB_DAT_WIDTH-1:0]  wb_dat_o;
    logic                       wb_we_o;
    logic   [WB_SEL_WIDTH-1:0]  wb_sel_o;
    logic                       wb_stb_o = '0;
    logic                       wb_ack_i;
    
    assign wb_rst_i = reset;
    assign wb_clk_i = clk;
    assign wb_dat_i = s_wb_dat_o;
    assign wb_ack_i = s_wb_ack_o;

    initial begin
        force s_wb_adr_i = wb_adr_o;
        force s_wb_dat_i = wb_dat_o;
        force s_wb_we_i  = wb_we_o;
        force s_wb_sel_i = wb_sel_o;
        force s_wb_stb_i = wb_stb_o;
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

    logic   [31:0]  mem     [0:2048];

    initial begin
        $readmemh("../../../app/jfive/mem.hex", mem);

    #100;
        $display(" --- start --- ");
        wb_read (29'h0000_0000 + 0);
        wb_read (29'h0000_0000 + 1);
        wb_read (29'h0000_0000 + 2);
        wb_read (29'h0000_0000 + 3);
        wb_read (29'h0000_0000 + 4);
        wb_read (29'h0000_0000 + 5);
        wb_write(29'ha000_0000 + 8, 1, 4'hf);

        for ( int i = 0; i < 2048; ++i ) begin
            wb_write(29'h0000_0000 + 32'h8000 + i, mem[i], 4'hf);
        end
    #100;
        wb_write(29'ha000_0000 + 8, 0, 4'hf);

    #200000;
        $finish();
    end

endmodule


`default_nettype wire


// end of file
