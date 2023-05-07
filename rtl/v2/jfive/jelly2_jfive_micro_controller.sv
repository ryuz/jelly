
`timescale 1ns / 1ps
`default_nettype none


module jelly2_jfive_micro_controller
        #(
            parameter   int                             S_WB_ADR_WIDTH   = 16,
            parameter   int                             S_WB_DAT_WIDTH   = 32,
            parameter   int                             S_WB_SEL_WIDTH   = S_WB_DAT_WIDTH/8,
            parameter   bit     [S_WB_ADR_WIDTH-1:0]    S_WB_TCM_ADR     = S_WB_ADR_WIDTH'(1 << (S_WB_ADR_WIDTH - 1)),

            parameter   bit     [31:0]                  M_WB_DECODE_MASK = 32'hf000_0000,
            parameter   bit     [31:0]                  M_WB_DECODE_ADDR = 32'h1000_0000,
            parameter   int                             M_WB_ADR_WIDTH   = 24,

            parameter   bit     [31:0]                  TCM_DECODE_MASK  = 32'hff00_0000,
            parameter   bit     [31:0]                  TCM_DECODE_ADDR  = 32'h8000_0000,
            parameter   int                             TCM_SIZE         = 8192,
            parameter                                   TCM_RAM_TYPE     = "block",
            parameter                                   TCM_RAM_MODE     = "NO_CHANGE",
            parameter   bit                             TCM_READMEMH     = 1'b0,
            parameter                                   TCM_READMEM_FIlE = "",

            parameter   int                             PC_WIDTH         = 32,
            parameter   bit     [31:0]                  INIT_PC_ADDR     = 32'h8000_0000,
            parameter   bit                             INIT_CTL_RESET   = 1'b1,

            parameter                                   DEVICE           = "ULTRASCALE",

            parameter   bit                             SIMULATION       = 1'b0,
            parameter   bit                             LOG_EXE_ENABLE   = 1'b0,
            parameter   string                          LOG_EXE_FILE     = "jfive_exe_log.txt",
            parameter   bit                             LOG_MEM_ENABLE   = 1'b0,
            parameter   string                          LOG_MEM_FILE     = "jfive_mem_log.txt"
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,

            input   wire    [S_WB_ADR_WIDTH-1:0]    s_wb_adr_i,
            output  reg     [S_WB_DAT_WIDTH-1:0]    s_wb_dat_o,
            input   wire    [S_WB_DAT_WIDTH-1:0]    s_wb_dat_i,
            input   wire    [S_WB_SEL_WIDTH-1:0]    s_wb_sel_i,
            input   wire                            s_wb_we_i,
            input   wire                            s_wb_stb_i,
            output  reg                             s_wb_ack_o,

            output  reg     [M_WB_ADR_WIDTH-1:0]    m_wb_adr_o,
            input   wire    [31:0]                  m_wb_dat_i,
            output  reg     [31:0]                  m_wb_dat_o,
            output  reg     [3:0]                   m_wb_sel_o,
            output  reg                             m_wb_we_o,
            output  reg                             m_wb_stb_o,
            input   wire                            m_wb_ack_i
        );


    // ---------------------------------------------
    //  parameters
    // ---------------------------------------------

    localparam int      TCM_MEM_SIZE   = (TCM_SIZE + 3) / 4;
    localparam int      TCM_ADDR_WIDTH = $clog2(TCM_MEM_SIZE);



    // ---------------------------------------------
    //  control register
    // ---------------------------------------------
    
    localparam   ADR_CORE_ID      = 'h0;
    localparam   ADR_CORE_VERSION = 'h1;
    localparam   ADR_CORE_DATE    = 'h2;
    localparam   ADR_MEM_OFFSET   = 'h4;
    localparam   ADR_MEM_SIZE     = 'h5;
    localparam   ADR_CTL_RESET    = 'h8;

    logic       reg_reset;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_reset  <= INIT_CTL_RESET;
        end
        else if ( cke ) begin
            if ( s_wb_stb_i && s_wb_we_i ) begin
                if (  s_wb_adr_i == S_WB_ADR_WIDTH'(ADR_CTL_RESET) && s_wb_sel_i[0] ) begin
                    reg_reset <= s_wb_dat_i[0];
                end
            end
        end
    end

    always_comb begin
        case ( int'(s_wb_adr_i) )
        ADR_CORE_ID:        s_wb_dat_o = S_WB_DAT_WIDTH'(32'hffff_8724);
        ADR_CORE_VERSION:   s_wb_dat_o = S_WB_DAT_WIDTH'(32'h0001_0000);
        ADR_CORE_DATE:      s_wb_dat_o = S_WB_DAT_WIDTH'(32'h2022_0226);
        ADR_MEM_OFFSET:     s_wb_dat_o = S_WB_DAT_WIDTH'(S_WB_TCM_ADR);
        ADR_MEM_SIZE:       s_wb_dat_o = S_WB_DAT_WIDTH'(TCM_SIZE);
        ADR_CTL_RESET:      s_wb_dat_o = S_WB_DAT_WIDTH'(reg_reset);
        default:            s_wb_dat_o = '0;
        endcase
    end

    always_comb s_wb_ack_o = s_wb_stb_i;



    // ---------------------------------------------
    //  CPU Core
    // ---------------------------------------------

    logic       core_reset;
   always_ff @(posedge clk) begin
        if ( reset ) begin
            core_reset <= 1'b1;
        end
        else if ( cke ) begin
            core_reset <= reg_reset;
        end
    end

    wire    core_cke = cke && !(m_wb_stb_o && !m_wb_ack_i);

    logic                            itcm_en;
    logic    [TCM_ADDR_WIDTH-1:0]    itcm_addr;
    logic    [31:0]                  itcm_rdata;

    logic                            dtcm_en;
    logic    [TCM_ADDR_WIDTH-1:0]    dtcm_addr;
    logic    [3:0]                   dtcm_wsel;
    logic    [31:0]                  dtcm_wdata;
    logic    [31:0]                  dtcm_rdata;
    
    logic                            mmio_en;
    logic                            mmio_re;
    logic                            mmio_we;
    logic    [1:0]                   mmio_size;
    logic    [M_WB_ADR_WIDTH+2-1:0]  mmio_addr;
    logic    [3:0]                   mmio_sel;
    logic    [3:0]                   mmio_rsel;
    logic    [3:0]                   mmio_wsel;
    logic    [31:0]                  mmio_wdata;
    logic    [31:0]                  mmio_rdata;

    jelly2_jfive_micro_core
            #(
                .PC_WIDTH           (PC_WIDTH),
                .INIT_PC_ADDR       (INIT_PC_ADDR),
                .TCM_ADDR_WIDTH     (TCM_ADDR_WIDTH),
                .TCM_DECODE_MASK    (TCM_DECODE_MASK),
                .TCM_DECODE_ADDR    (TCM_DECODE_ADDR),
                .MMIO_ADDR_WIDTH    (M_WB_ADR_WIDTH + 2),
                .MMIO_DECODE_MASK   (M_WB_DECODE_MASK),
                .MMIO_DECODE_ADDR   (M_WB_DECODE_ADDR),
                .DEVICE             (DEVICE),
                .SIMULATION         (SIMULATION),
                .LOG_EXE_ENABLE     (LOG_EXE_ENABLE),
                .LOG_EXE_FILE       (LOG_EXE_FILE),
                .LOG_MEM_ENABLE     (LOG_MEM_ENABLE),
                .LOG_MEM_FILE       (LOG_MEM_FILE)
            )
        i_jfive_micro_core
            (
                .reset              (core_reset),
                .clk,
                .cke                (core_cke),

                .itcm_en,
                .itcm_addr,
                .itcm_rdata,

                .dtcm_en,
                .dtcm_addr,
                .dtcm_wsel,
                .dtcm_wdata,
                .dtcm_rdata,
                
                .mmio_en,
                .mmio_re,
                .mmio_we,
                .mmio_size,
                .mmio_addr,
                .mmio_sel,
                .mmio_rsel,
                .mmio_wsel,
                .mmio_wdata,
                .mmio_rdata
            );


    // ---------------------------------------------
    //  TCM(Tightly Coupled Memory)
    // ---------------------------------------------

    logic                           mem_itcm_en;
    logic   [TCM_ADDR_WIDTH-1:0]    mem_itcm_addr;
    logic   [3:0]                   mem_itcm_wsel = '0;
    logic   [31:0]                  mem_itcm_wdata;
    logic   [31:0]                  mem_itcm_rdata;

    jelly2_ram_dualport
            #(
                .ADDR_WIDTH         (TCM_ADDR_WIDTH),
                .DATA_WIDTH         (32),
                .WE_WIDTH           (4),
                .WORD_WIDTH         (8),
                .MEM_SIZE           (TCM_MEM_SIZE),
                .RAM_TYPE           (TCM_RAM_TYPE),
                .DOUT_REGS0         (0),
                .DOUT_REGS1         (0),
                .MODE0              (TCM_RAM_MODE),
                .MODE1              (TCM_RAM_MODE),

                .FILLMEM            (0),
                .FILLMEM_DATA       (0),
                .READMEMB           (0),
                .READMEMH           (TCM_READMEMH),
                .READMEM_FIlE       (TCM_READMEM_FIlE)
            )
        i_ram_dualport
            (
                .port0_clk          (clk),
                .port0_en           (mem_itcm_en & core_cke),
                .port0_regcke       (1'b0),
                .port0_we           (mem_itcm_wsel),
                .port0_addr         (mem_itcm_addr),
                .port0_din          (mem_itcm_wdata),
                .port0_dout         (mem_itcm_rdata),

                .port1_clk          (clk),
                .port1_en           (dtcm_en & core_cke),
                .port1_regcke       (1'b0),
                .port1_we           (dtcm_wsel),
                .port1_addr         (dtcm_addr),
                .port1_din          (dtcm_wdata),
                .port1_dout         (dtcm_rdata)
            );

    // WISHBONE (write only)
    logic                           wb_tcm_en;
    logic   [3:0]                   wb_tcm_wsel;
    logic   [TCM_ADDR_WIDTH-1:0]    wb_tcm_addr;
    logic   [31:0]                  wb_tcm_wdata;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            wb_tcm_en    <= 1'b0;
            wb_tcm_wsel  <= '0;
            wb_tcm_addr  <= 'x;
            wb_tcm_wdata <= 'x;
        end
        else if ( cke ) begin
            wb_tcm_en    <= 1'b0;
            wb_tcm_wsel  <= '0;
            wb_tcm_addr  <= 'x;
            wb_tcm_wdata <= 'x;
            if ( s_wb_stb_i && s_wb_we_i && s_wb_sel_i != '0 && (s_wb_adr_i >= S_WB_TCM_ADR) ) begin
                wb_tcm_en    <= 1'b1;
                wb_tcm_wsel  <= s_wb_sel_i[3:0];
                wb_tcm_addr  <= TCM_ADDR_WIDTH'(s_wb_adr_i - S_WB_TCM_ADR);
                wb_tcm_wdata <= s_wb_dat_i[31:0];
            end
        end
    end

    always_comb mem_itcm_en    = wb_tcm_en || itcm_en;
    always_comb mem_itcm_wsel  = wb_tcm_wsel;
    always_comb mem_itcm_addr  = wb_tcm_en ? wb_tcm_addr  : itcm_addr;
    always_comb mem_itcm_wdata = wb_tcm_wdata;
    always_comb itcm_rdata     = mem_itcm_rdata;



    // ---------------------------------------------
    //  Memory Mapped I/O (WISHBONE)
    // ---------------------------------------------

    always_comb m_wb_adr_o = M_WB_ADR_WIDTH'(mmio_addr >> 2);
    always_comb m_wb_dat_o = mmio_wdata;
    always_comb m_wb_sel_o = mmio_sel;
    always_comb m_wb_we_o  = mmio_we;
    always_comb m_wb_stb_o = mmio_en;

    always_ff @(posedge clk) begin
        if ( core_cke ) begin
           mmio_rdata <= m_wb_dat_i;
        end
    end
    
endmodule


`default_nettype wire


// end of file
