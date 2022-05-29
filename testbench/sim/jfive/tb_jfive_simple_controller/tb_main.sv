
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire                        reset,
            input   wire                        clk
        );

    localparam   int                             S_WB_ADR_WIDTH   = 16;
    localparam   int                             S_WB_DAT_WIDTH   = 32;
    localparam   int                             S_WB_SEL_WIDTH   = S_WB_DAT_WIDTH/8;
    localparam   bit     [S_WB_ADR_WIDTH-1:0]    S_WB_TCM_ADR     = S_WB_ADR_WIDTH'(1 << (S_WB_ADR_WIDTH - 1));
    localparam   bit     [31:0]                  M_WB_DECODE_MASK = 32'hf000_0000;
    localparam   bit     [31:0]                  M_WB_DECODE_ADDR = 32'h1000_0000;
    localparam   int                             M_WB_ADR_WIDTH   = 24;
    localparam   bit     [31:0]                  TCM_DECODE_MASK  = 32'hff00_0000;
    localparam   bit     [31:0]                  TCM_DECODE_ADDR  = 32'h8000_0000;
    localparam   int                             TCM_SIZE         = 65536;
    localparam                                   TCM_RAM_TYPE     = "block";
    localparam                                   TCM_RAM_MODE     = "NO_CHANGE";
    localparam   bit                             TCM_READMEMH     = 1'b1;
    localparam                                   TCM_READMEM_FIlE = "../mem.hex";
    localparam   int                             PC_WIDTH         = 32;
    localparam   bit     [31:0]                  INIT_PC_ADDR     = 32'h8000_0000;
    localparam   bit                             INIT_CTL_RESET   = 1'b0;
    localparam                                   DEVICE           = "RTL"; // "ULTRASCALE";
    localparam   bit                             SIMULATION       = 1'b1;
    localparam   bit                             LOG_EXE_ENABLE   = 1'b1;
    localparam   string                          LOG_EXE_FILE     = "jfive_exe_log.txt";
    localparam   bit                             LOG_MEM_ENABLE   = 1'b1;
    localparam   string                          LOG_MEM_FILE     = "jfive_mem_log.txt";


    logic                           cke = 1'b1;

    logic   [S_WB_ADR_WIDTH-1:0]    s_wb_adr_i;
    logic   [S_WB_DAT_WIDTH-1:0]    s_wb_dat_o;
    logic   [S_WB_DAT_WIDTH-1:0]    s_wb_dat_i;
    logic   [3:0]                   s_wb_sel_i;
    logic                           s_wb_we_i;
    logic                           s_wb_stb_i = 0;
    logic                           s_wb_ack_o;

    logic   [M_WB_ADR_WIDTH-1:0]    m_wb_adr_o;
    logic   [31:0]                  m_wb_dat_i;
    logic   [31:0]                  m_wb_dat_o;
    logic   [3:0]                   m_wb_sel_o;
    logic                           m_wb_we_o;
    logic                           m_wb_stb_o;
    logic                           m_wb_ack_i;
    
    jelly2_jfive_simple_controller
            #(
                .S_WB_ADR_WIDTH     (S_WB_ADR_WIDTH),
                .S_WB_DAT_WIDTH     (S_WB_DAT_WIDTH),
                .S_WB_SEL_WIDTH     (S_WB_SEL_WIDTH),
                .S_WB_TCM_ADR       (S_WB_TCM_ADR),
                .M_WB_DECODE_MASK   (M_WB_DECODE_MASK),
                .M_WB_DECODE_ADDR   (M_WB_DECODE_ADDR),
                .M_WB_ADR_WIDTH     (M_WB_ADR_WIDTH),
                .TCM_DECODE_MASK    (TCM_DECODE_MASK),
                .TCM_DECODE_ADDR    (TCM_DECODE_ADDR),
                .TCM_SIZE           (TCM_SIZE),
                .TCM_RAM_TYPE       (TCM_RAM_TYPE),
                .TCM_RAM_MODE       (TCM_RAM_MODE),
                .TCM_READMEMH       (TCM_READMEMH),
                .TCM_READMEM_FIlE   (TCM_READMEM_FIlE),
                .PC_WIDTH           (PC_WIDTH),
                .INIT_PC_ADDR       (INIT_PC_ADDR),
                .INIT_CTL_RESET     (INIT_CTL_RESET),
                .DEVICE             (DEVICE),
                .SIMULATION         (SIMULATION),
                .LOG_EXE_ENABLE     (LOG_EXE_ENABLE),
                .LOG_EXE_FILE       (LOG_EXE_FILE),
                .LOG_MEM_ENABLE     (LOG_MEM_ENABLE),
                .LOG_MEM_FILE       (LOG_MEM_FILE)
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
                .m_wb_ack_i
            );

    assign m_wb_dat_i = 32'hf1e2d3c4;

    logic   ack_rand;
    always_ff @(posedge clk) begin
        ack_rand <= 1'($urandom_range(1));
    end

    assign m_wb_ack_i = m_wb_stb_o & ack_rand;
    
    always_ff @(posedge clk) begin
        if ( !reset && m_wb_stb_o && m_wb_we_o && m_wb_ack_i ) begin
            if ( m_wb_adr_o == 0 ) begin
                $write("%c", m_wb_dat_o[7:0]);
            end
            else begin
                $display("write: %h %10d %b", m_wb_adr_o, $signed(m_wb_dat_o), m_wb_sel_o);
            end
        end
    end

endmodule


`default_nettype wire


// end of file
