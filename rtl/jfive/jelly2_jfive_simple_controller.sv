
`timescale 1ns / 1ps
`default_nettype none

// RISC-V(RV32I 3 stage pipelines)
module jelly2_jfive_simple_controller
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
            parameter   int                             TCM_SIZE         = 4096,
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
            output  wire    [S_WB_DAT_WIDTH-1:0]    s_wb_dat_o,
            input   wire    [S_WB_DAT_WIDTH-1:0]    s_wb_dat_i,
            input   wire    [S_WB_SEL_WIDTH-1:0]    s_wb_sel_i,
            input   wire                            s_wb_we_i,
            input   wire                            s_wb_stb_i,
            output  wire                            s_wb_ack_o,

            output  wire    [M_WB_ADR_WIDTH-1:0]    m_wb_adr_o,
            input   wire    [31:0]                  m_wb_dat_i,
            output  wire    [31:0]                  m_wb_dat_o,
            output  wire    [3:0]                   m_wb_sel_o,
            output  wire                            m_wb_we_o,
            output  wire                            m_wb_stb_o,
            input   wire                            m_wb_ack_i
        );


    // ---------------------------------------------
    //  parameters
    // ---------------------------------------------

    localparam int      TCM_MEM_SIZE   = (TCM_SIZE + 3) / 4;
    localparam int      TCM_ADDR_WIDTH = $clog2(TCM_MEM_SIZE);

    localparam int      IBUS_ADDR_WIDTH = TCM_ADDR_WIDTH + 2;
    localparam int      DBUS_ADDR_WIDTH = 32;

    logic   wb_mem;
    assign wb_mem = (s_wb_adr_i >= S_WB_ADR_WIDTH'(S_WB_TCM_ADR));


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
        else begin
            if ( !wb_mem && s_wb_stb_i && s_wb_we_i ) begin
                if (  s_wb_adr_i == S_WB_ADR_WIDTH'(ADR_CTL_RESET) && s_wb_sel_i[0] ) begin
                    reg_reset <= s_wb_dat_i[0];
                end
            end
        end
    end

    assign s_wb_dat_o = (s_wb_adr_i == S_WB_ADR_WIDTH'(ADR_CORE_ID))      ? S_WB_DAT_WIDTH'(32'hffff_8723) :
                        (s_wb_adr_i == S_WB_ADR_WIDTH'(ADR_CORE_VERSION)) ? S_WB_DAT_WIDTH'(32'h0001_0000) :
                        (s_wb_adr_i == S_WB_ADR_WIDTH'(ADR_CORE_DATE))    ? S_WB_DAT_WIDTH'(32'h2022_0226) :
                        (s_wb_adr_i == S_WB_ADR_WIDTH'(ADR_MEM_OFFSET))   ? S_WB_DAT_WIDTH'(S_WB_TCM_ADR)  :
                        (s_wb_adr_i == S_WB_ADR_WIDTH'(ADR_MEM_SIZE))     ? S_WB_DAT_WIDTH'(TCM_SIZE)      :
                        (s_wb_adr_i == S_WB_ADR_WIDTH'(ADR_CTL_RESET))    ? S_WB_DAT_WIDTH'(reg_reset)     :
                        '0;

    assign s_wb_ack_o = s_wb_stb_i;



    // ---------------------------------------------
    //  CPU Core
    // ---------------------------------------------

    logic       core_reset;
   always_ff @(posedge clk) begin
        if ( reset ) begin
            core_reset <= 1'b1;
        end
        else begin
            core_reset <= reg_reset;
        end
    end

    wire    core_cke = cke && !(m_wb_stb_o && !m_wb_ack_i);


    logic   [IBUS_ADDR_WIDTH-1:0]   ibus_addr;
    logic   [31:0]                  ibus_rdata;

    logic   [DBUS_ADDR_WIDTH-1:0]   dbus_addr;
    logic                           dbus_rd;
    logic                           dbus_wr;
    logic   [3:0]                   dbus_sel;
    logic   [31:0]                  dbus_wdata;
    logic   [31:0]                  dbus_rdata;

    jelly2_jfive_simple_core
            #(
                .IBUS_ADDR_WIDTH    (IBUS_ADDR_WIDTH),
                .DBUS_ADDR_WIDTH    (DBUS_ADDR_WIDTH),
                .PC_WIDTH           (PC_WIDTH),
                .INIT_PC_ADDR       (INIT_PC_ADDR),
                .DEVICE             (DEVICE),
                .SIMULATION         (SIMULATION),
                .LOG_EXE_ENABLE     (LOG_EXE_ENABLE),
                .LOG_EXE_FILE       (LOG_EXE_FILE),
                .LOG_MEM_ENABLE     (LOG_MEM_ENABLE),
                .LOG_MEM_FILE       (LOG_MEM_FILE)
            )
        i_jfive_simple_core
            (
                .reset              (core_reset),
                .clk                (clk),
                .cke                (core_cke),

                .ibus_addr,
                .ibus_rdata,

                .dbus_addr,
                .dbus_rd,
                .dbus_wr,
                .dbus_sel,
                .dbus_wdata,
                .dbus_rdata
            );


    // ---------------------------------------------
    //  Memory
    // ---------------------------------------------

    logic                           tcm_ibus_wb;
    logic   [TCM_ADDR_WIDTH-1:0]    tcm_ibus_addr;
    logic   [3:0]                   tcm_ibus_we;
    logic   [31:0]                  tcm_ibus_wdata;
    logic   [31:0]                  tcm_ibus_rdata;

    logic                           tcm_dbus_valid;
    logic   [TCM_ADDR_WIDTH-1:0]    tcm_dbus_addr;
    logic   [3:0]                   tcm_dbus_we;
    logic   [31:0]                  tcm_dbus_wdata;
    logic   [31:0]                  tcm_dbus_rdata;

    jelly2_ram_dualport
            #(
                .ADDR_WIDTH         (TCM_ADDR_WIDTH),
                .DATA_WIDTH         (32),
                .WE_WIDTH           (4),
                .WORD_WIDTH         (8),
                .MEM_SIZE           (TCM_SIZE),
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
                .port0_en           (cke),
                .port0_regcke       (cke),
                .port0_we           (tcm_ibus_we),
                .port0_addr         (tcm_ibus_addr),
                .port0_din          (tcm_ibus_wdata),
                .port0_dout         (tcm_ibus_rdata),

                .port1_clk          (clk),
                .port1_en           (cke),
                .port1_regcke       (cke),
                .port1_we           (tcm_dbus_we),
                .port1_addr         (tcm_dbus_addr),
                .port1_din          (tcm_dbus_wdata),
                .port1_dout         (tcm_dbus_rdata)
            );

    // ibus
    assign tcm_ibus_wb    = wb_mem && s_wb_stb_i && s_wb_we_i;
    assign tcm_ibus_addr  = tcm_ibus_wb ? s_wb_adr_i[TCM_ADDR_WIDTH-1:0] : TCM_ADDR_WIDTH'(ibus_addr >> 2);
    assign tcm_ibus_we    = tcm_ibus_wb ? s_wb_sel_i[3:0]                : 4'b0000;
    assign tcm_ibus_wdata = s_wb_dat_i[31:0];
    assign ibus_rdata     = tcm_ibus_rdata;

    // dbus
    assign tcm_dbus_valid = (dbus_addr & TCM_DECODE_MASK) == TCM_DECODE_ADDR;
    assign tcm_dbus_addr  = TCM_ADDR_WIDTH'(dbus_addr >> 2);
    assign tcm_dbus_we    = (tcm_dbus_valid & dbus_wr) ? 4'(dbus_sel << dbus_addr[1:0]) : 4'd0;
    assign tcm_dbus_wdata = 32'(dbus_wdata << (dbus_addr[1:0] * 8));



    // ---------------------------------------------
    //  WISHBONE
    // ---------------------------------------------

    logic   wb_valid;
    assign wb_valid   = (dbus_addr & M_WB_DECODE_MASK) == M_WB_DECODE_ADDR;

    assign m_wb_adr_o = M_WB_ADR_WIDTH'(dbus_addr >> 2);
    assign m_wb_dat_o = 32'(dbus_wdata << (dbus_addr[1:0] * 8));
    assign m_wb_sel_o = 4'(dbus_sel << dbus_addr[1:0]);
    assign m_wb_we_o  = dbus_wr;
    assign m_wb_stb_o = wb_valid && (dbus_wr | dbus_rd);

    logic   [31:0]  wb_rdata;
    always_ff @(posedge clk) begin
        wb_rdata <= m_wb_dat_i;
    end


    // ---------------------------------------------
    //  read
    // ---------------------------------------------

    logic   rd_mem_valid;
    logic   rd_wb_valid;
    always_ff @(posedge clk) begin
        rd_mem_valid <= tcm_dbus_valid;
        rd_wb_valid  <= wb_valid;
    end

    logic   [1:0]   dbus_shift;
    always_ff @(posedge clk) begin
        dbus_shift <= dbus_addr[1:0];
    end

    assign dbus_rdata = rd_mem_valid  ? 32'(tcm_dbus_rdata >> (dbus_shift * 8)) :
                        rd_wb_valid   ? 32'(wb_rdata       >> (dbus_shift * 8)) :
                        'x;

endmodule


`default_nettype wire


// end of file
