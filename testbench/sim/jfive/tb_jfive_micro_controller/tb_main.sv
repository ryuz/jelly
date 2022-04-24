
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire                        reset,
            input   wire                        clk
        );

    parameter   int                     S_WB_ADR_WIDTH   = 16;
    parameter   int                     S_WB_DAT_WIDTH   = 32;
    parameter   int                     S_WB_SEL_WIDTH   = S_WB_DAT_WIDTH/8;
    parameter   int                     M_WB_ADR_WIDTH   = 24;
    parameter   int                     MMIO_ADR_WIDTH   = 16;

    parameter   bit     [31:0]          MEM_DECODE_MASK  = 32'hff00_0000;
    parameter   bit     [31:0]          MEM_DECODE_ADDR  = 32'h8000_0000;
    parameter   bit     [31:0]          WB_DECODE_MASK   = 32'hff00_0000;
    parameter   bit     [31:0]          WB_DECODE_ADDR   = 32'hf000_0000;
    parameter   bit     [31:0]          MMIO_DECODE_MASK = 32'hff00_0000;
    parameter   bit     [31:0]          MMIO_DECODE_ADDR = 32'hff00_0000;

    parameter   int                     MEM_SIZE         = 16384;
    parameter   bit                     MEM_READMEMH     = 1'b1;
    parameter                           MEM_READMEM_FIlE = "../mem.hex";

    parameter   bit     [31:0]          RESET_PC_ADDR    = 32'h8000_0000;
    parameter   bit                     INIT_CTL_RESET   = 1'b0;


    logic                           cke = 1'b1;

    logic   [S_WB_ADR_WIDTH-1:0]    s_wb_adr_i;
    logic   [S_WB_DAT_WIDTH-1:0]    s_wb_dat_o;
    logic   [S_WB_DAT_WIDTH-1:0]    s_wb_dat_i;
    logic   [3:0]                   s_wb_sel_i;
    logic                           s_wb_we_i;
    logic                           s_wb_stb_i;
    logic                           s_wb_ack_o;

    logic   [M_WB_ADR_WIDTH-1:0]    m_wb_adr_o;
    logic   [31:0]                  m_wb_dat_i;
    logic   [31:0]                  m_wb_dat_o;
    logic   [3:0]                   m_wb_sel_o;
    logic                           m_wb_we_o;
    logic                           m_wb_stb_o;
    logic                           m_wb_ack_i;

    logic                           mmio_wr;
    logic                           mmio_rd;
    logic   [MMIO_ADR_WIDTH-1:0]    mmio_addr;
    logic   [3:0]                   mmio_sel;
    logic   [31:0]                  mmio_wdata;
    logic   [31:0]                  mmio_rdata;
    
    jelly2_jfive_simple_controller
            #(
                .S_WB_ADR_WIDTH     (S_WB_ADR_WIDTH),
                .S_WB_DAT_WIDTH     (S_WB_DAT_WIDTH),
                .S_WB_SEL_WIDTH     (S_WB_SEL_WIDTH),
                .M_WB_ADR_WIDTH     (M_WB_ADR_WIDTH),
                .MMIO_ADR_WIDTH     (MMIO_ADR_WIDTH),
                .MEM_DECODE_MASK    (MEM_DECODE_MASK),
                .MEM_DECODE_ADDR    (MEM_DECODE_ADDR),
                .WB_DECODE_MASK     (WB_DECODE_MASK),
                .WB_DECODE_ADDR     (WB_DECODE_ADDR),
                .MMIO_DECODE_MASK   (MMIO_DECODE_MASK),
                .MMIO_DECODE_ADDR   (MMIO_DECODE_ADDR),
                .MEM_SIZE           (MEM_SIZE),
                .MEM_READMEMH       (MEM_READMEMH),
                .MEM_READMEM_FIlE   (MEM_READMEM_FIlE),
                .RESET_PC_ADDR      (RESET_PC_ADDR),
                .INIT_CTL_RESET     (INIT_CTL_RESET)
            )
        i_jfive_simple_controller
            (
                .reset,
                .clk,
                .cke,

                .s_wb_adr_i,
                .s_wb_dat_o,
                .s_wb_dat_i,
                .s_wb_sel_i,
                .s_wb_we_i,
                .s_wb_stb_i,
                .s_wb_ack_o,

                .m_wb_adr_o,
                .m_wb_dat_i,
                .m_wb_dat_o,
                .m_wb_sel_o,
                .m_wb_we_o,
                .m_wb_stb_o,
                .m_wb_ack_i,

                .mmio_wr,
                .mmio_rd,
                .mmio_addr,
                .mmio_sel,
                .mmio_wdata,
                .mmio_rdata
            );



    
    always @(posedge clk) begin
        if ( !reset && mmio_wr ) begin
            $display("write: %h %10d %b", mmio_addr, $signed(mmio_wdata), mmio_sel);
        end
    end

    always @(posedge clk) begin
        if ( !reset ) begin
            if ( m_wb_stb_o && m_wb_we_o && m_wb_sel_o[0] && {m_wb_adr_o, 2'b00} == 32'hff000100 ) begin
                $display("%c", m_wb_dat_o[7:0]);
            end
        end
    end
    assign m_wb_ack_i = m_wb_stb_o;

endmodule


`default_nettype wire


// end of file
