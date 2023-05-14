
`timescale 1ns / 1ps
`default_nettype none


module tb_sim();
    localparam WB_RATE  = 1000.0 / 66.6;
    localparam SRC_RATE = 1000.0 / 166.0;
    localparam DST_RATE = 1000.0 / 133.0;
    localparam MEM_RATE = 1000.0 / 200.0;
    
    
    initial begin
        $dumpfile("tb_sim.vcd"); 
        $dumpvars(0, tb_sim);
//      $dumpvars(3, tb_sim);
        
        #1000000;
            $finish;
    end
    
    
    reg     wb_rst_i = 1'b1;
    initial #(WB_RATE*100)      wb_rst_i = 1'b0;
    
    reg     wb_clk_i = 1'b1;
    always #(WB_RATE/2.0)       wb_clk_i = ~wb_clk_i;
    
    
    reg     src_aresetn = 1'b0;
    initial #(SRC_RATE*100)     src_aresetn = 1'b1;
    
    reg     src_aclk = 1'b1;
    always #(SRC_RATE/2.0)      src_aclk = ~src_aclk;
    
    
    reg     dst_aresetn = 1'b0;
    initial #(DST_RATE*100)     dst_aresetn = 1'b1;
    
    reg     dst_aclk = 1'b1;
    always #(DST_RATE/2.0)      dst_aclk = ~dst_aclk;
    
    
    reg     mem_aresetn = 1'b0;
    initial #(MEM_RATE*100)     mem_aresetn = 1'b1;
    
    reg     mem_aclk = 1'b1;
    always #(MEM_RATE/2.0)      mem_aclk = ~mem_aclk;

    // -----------------------------------------
    //  main
    // -----------------------------------------

     
    localparam  int     WB_ADR_WIDTH          = 32;
    localparam  int     WB_DAT_WIDTH          = 32;
    localparam  int     WB_SEL_WIDTH          = (WB_DAT_WIDTH / 8);

    wire                        s_wb_rst_i = wb_rst_i;
    wire                        s_wb_clk_i = wb_clk_i;
    wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i;
    wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i;
    wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o;
    wire                        s_wb_we_i;
    wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i;
    wire                        s_wb_stb_i;
    wire                        s_wb_ack_o;

    tb_main
            #(
                .WB_ADR_WIDTH       (WB_ADR_WIDTH),
                .WB_DAT_WIDTH       (WB_DAT_WIDTH),
                .WB_SEL_WIDTH       (WB_SEL_WIDTH)
            )
        i_tb_main
            (
                .src_aresetn,
                .src_aclk,
                .dst_aresetn,
                .dst_aclk,
                .mem_aresetn,
                .mem_aclk,

                .s_wb_rst_i,
                .s_wb_clk_i,
                .s_wb_adr_i,
                .s_wb_dat_i,
                .s_wb_dat_o,
                .s_wb_we_i,
                .s_wb_sel_i,
                .s_wb_stb_i,
                .s_wb_ack_o
            );
    
    

    // -----------------------------------------
    //  WISHBONE master
    // -----------------------------------------
    
    reg     [WB_ADR_WIDTH-1:0]  wb_adr_o;
    reg     [WB_DAT_WIDTH-1:0]  wb_dat_o;
    wire    [WB_DAT_WIDTH-1:0]  wb_dat_i;
    reg                         wb_we_o;
    reg     [WB_SEL_WIDTH-1:0]  wb_sel_o;
    reg                         wb_stb_o;
    wire                        wb_ack_i;

    assign s_wb_adr_i = wb_adr_o;
    assign s_wb_dat_i = wb_dat_o;
    assign s_wb_we_i  = wb_we_o;
    assign s_wb_sel_i = wb_sel_o;
    assign s_wb_stb_i = wb_stb_o;

    assign wb_dat_i = s_wb_dat_o;
    assign wb_ack_i = s_wb_ack_o;


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
    
    
    
    
    // register address offset
    localparam  ADR_CORE_ID             = 8'h00;
    localparam  ADR_CORE_VERSION        = 8'h01;
    localparam  ADR_CORE_CONFIG         = 8'h03;
    localparam  ADR_CTL_CONTROL         = 8'h04;
    localparam  ADR_CTL_STATUS          = 8'h05;
    localparam  ADR_CTL_INDEX           = 8'h07;
    localparam  ADR_IRQ_ENABLE          = 8'h08;
    localparam  ADR_IRQ_STATUS          = 8'h09;
    localparam  ADR_IRQ_CLR             = 8'h0a;
    localparam  ADR_IRQ_SET             = 8'h0b;
    localparam  ADR_PARAM_ADDR          = 8'h10;
    localparam  ADR_PARAM_AWLEN_MAX     = 8'h11;
    localparam  ADR_PARAM_H_SIZE        = 8'h20;
    localparam  ADR_PARAM_V_SIZE        = 8'h24;
    localparam  ADR_PARAM_LINE_STEP     = 8'h25;
    localparam  ADR_PARAM_F_SIZE        = 8'h28;
    localparam  ADR_PARAM_FRAME_STEP    = 8'h29;
    localparam  ADR_SKIP_EN             = 8'h70;
    localparam  ADR_DETECT_FIRST        = 8'h72;
    localparam  ADR_DETECT_LAST         = 8'h73;
    localparam  ADR_PADDING_EN          = 8'h74;
    localparam  ADR_PADDING_DATA        = 8'h75;
    localparam  ADR_PADDING_STRB        = 8'h76;
    
    localparam  ADR_BUFFER0_REQUEST     = 8'h20;
    localparam  ADR_BUFFER0_RELEASE     = 8'h21;
    localparam  ADR_BUFFER0_ADDR        = 8'h22;
    localparam  ADR_BUFFER0_INDEX       = 8'h23;
    
    initial begin
        #(WB_RATE*200);
        wb_write(32'h0000 + 8'h40, 32'h0001_0000, 8'hff);
        wb_write(32'h0000 + 8'h41, 32'h0002_0000, 8'hff);
        wb_write(32'h0000 + 8'h42, 32'h0003_0000, 8'hff);
        wb_write(32'h0000 + 8'h43, 32'h0004_0000, 8'hff);
        
        
        $display("write start");
        wb_write(32'h0200 + ADR_PARAM_ADDR,      32'h0000_0000, 8'hff);
        wb_write(32'h0200 + ADR_CTL_CONTROL,     32'h0000_0009, 8'hff);
        #10000;
        
        $display("read start");
        wb_write(32'h0300 + ADR_CTL_CONTROL,     32'h0000_0009, 8'hff);   // read CTL_CONTROL
        #10000;
        
        
        $display("buffer resuest & release");
        wb_write(32'h0100 + ADR_BUFFER0_REQUEST, 32'h0000_0001, 8'hff);
        wb_read (32'h0100 + ADR_BUFFER0_ADDR);
        wb_write(32'h0100 + ADR_BUFFER0_RELEASE, 32'h0000_0001, 8'hff);
        #10000;
        
        #100000;
        $display("buffer resuest & release");
        wb_write(32'h0100 + ADR_BUFFER0_REQUEST, 32'h0000_0001, 8'hff);
        wb_read (32'h0100 + ADR_BUFFER0_ADDR);
        wb_write(32'h0100 + ADR_BUFFER0_RELEASE, 32'h0000_0001, 8'hff);
        #100000;
        $display("buffer resuest & release");
        wb_write(32'h0100 + ADR_BUFFER0_REQUEST, 32'h0000_0001, 8'hff);
        wb_read (32'h0100 + ADR_BUFFER0_ADDR);
        wb_write(32'h0100 + ADR_BUFFER0_RELEASE, 32'h0000_0001, 8'hff);
        #100000;
        $display("buffer resuest & release");
        wb_write(32'h0100 + ADR_BUFFER0_REQUEST, 32'h0000_0001, 8'hff);
        wb_read (32'h0100 + ADR_BUFFER0_ADDR);
        wb_write(32'h0100 + ADR_BUFFER0_RELEASE, 32'h0000_0001, 8'hff);

        #10000;
        
        /*
        wb_read(ADR_CORE_ID);
        wb_read(ADR_CORE_VERSION);
        wb_read(ADR_CORE_CONFIG);
        
        wb_write(ADR_PARAM_AWADDR,    32'h0001_0000, 8'hff);
        wb_write(ADR_PARAM_AWLEN_MAX, 32'h0000_000f, 8'hff);
        wb_write(ADR_PARAM_AWLEN0,               31, 8'hff);
        wb_write(ADR_PARAM_AWLEN1,                2, 8'hff);
        wb_write(ADR_PARAM_AWSTEP1,   32'h0001_0100, 8'hff);
        wb_write(ADR_PARAM_AWLEN2,                1, 8'hff);
        wb_write(ADR_PARAM_AWSTEP2,   32'h0001_1000, 8'hff);
        
        wb_write(ADR_CTL_CONTROL,     32'h0000_000b, 8'hff);
        
        #40000;
        
        wb_write(ADR_CTL_CONTROL,     32'h0000_0000, 8'hff);
        */
        
        #1000000;
            $finish();
    end
    
    
endmodule


`default_nettype wire


// end of file
