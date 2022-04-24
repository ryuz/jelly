
`timescale 1ns / 1ps
`default_nettype none


module jelly2_jfive_micro_controller
        #(
            parameter   int                     S_WB_ADR_WIDTH   = 16,
            parameter   int                     S_WB_DAT_WIDTH   = 32,
            parameter   int                     S_WB_SEL_WIDTH   = S_WB_DAT_WIDTH/8,
            parameter   int                     M_WB_ADR_WIDTH   = 24,
            parameter   int                     MMIO_ADR_WIDTH   = 16,

            parameter   int                     MEM_ADDR_OFFSET  = 1 << (S_WB_ADR_WIDTH - 1),

            parameter   bit     [31:0]          MEM_DECODE_MASK  = 32'hff00_0000,
            parameter   bit     [31:0]          MEM_DECODE_ADDR  = 32'h8000_0000,
            parameter   bit     [31:0]          WB_DECODE_MASK   = 32'hff00_0000,
            parameter   bit     [31:0]          WB_DECODE_ADDR   = 32'hf000_0000,
            parameter   bit     [31:0]          MMIO_DECODE_MASK = 32'hff00_0000,
            parameter   bit     [31:0]          MMIO_DECODE_ADDR = 32'hff00_0000,
            
            parameter   int                     MEM_SIZE         = 16384,
            parameter   bit                     MEM_READMEMH     = 1'b1,
            parameter                           MEM_READMEM_FIlE = "",

            parameter   bit     [31:0]          RESET_PC_ADDR    = 32'h8000_0000,
            parameter   bit                     INIT_CTL_RESET   = 1'b1,

            parameter   bit                     SIMULATION        = 1'b0,
            parameter   bit                     TRACE_EXEC_ENABLE = 1'b0,
            parameter   string                  TRACE_EXEC_FILE   = "jfive_trace_exec.txt",
            parameter   bit                     TRACE_DBUS_ENABLE = 1'b0,
            parameter   string                  TRACE_DBUS_FILE   = "jfive_trace_dbus.txt"
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
            input   wire                            m_wb_ack_i,

            output  wire                            mmio_wr,
            output  wire                            mmio_rd,
            output  wire    [MMIO_ADR_WIDTH-1:0]    mmio_addr,
            output  wire    [3:0]                   mmio_sel,
            output  wire    [31:0]                  mmio_wdata,
            input   wire    [31:0]                  mmio_rdata
        );

    // ---------------------------------------------
    //  parameters
    // ---------------------------------------------

    localparam int      RAM_SIZE       = (MEM_SIZE + 3) / 4;
    localparam int      RAM_ADDR_WIDTH = $clog2(RAM_SIZE);

    localparam int      IBUS_ADDR_WIDTH = RAM_ADDR_WIDTH + 2;
    localparam int      DBUS_ADDR_WIDTH = 32;
    localparam int      PC_WIDTH        = 32;

    logic   wb_mem;
    assign wb_mem = (s_wb_adr_i >= S_WB_ADR_WIDTH'(MEM_ADDR_OFFSET));


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

    assign s_wb_dat_o = (s_wb_adr_i == S_WB_ADR_WIDTH'(ADR_CORE_ID))      ? S_WB_DAT_WIDTH'(32'hffff_8723)   :
                        (s_wb_adr_i == S_WB_ADR_WIDTH'(ADR_CORE_VERSION)) ? S_WB_DAT_WIDTH'(32'h0001_0000)   :
                        (s_wb_adr_i == S_WB_ADR_WIDTH'(ADR_CORE_DATE))    ? S_WB_DAT_WIDTH'(32'h2022_0226)   :
                        (s_wb_adr_i == S_WB_ADR_WIDTH'(ADR_MEM_OFFSET))   ? S_WB_DAT_WIDTH'(MEM_ADDR_OFFSET) :
                        (s_wb_adr_i == S_WB_ADR_WIDTH'(ADR_MEM_SIZE))     ? S_WB_DAT_WIDTH'(MEM_SIZE)        :
                        (s_wb_adr_i == S_WB_ADR_WIDTH'(ADR_CTL_RESET))    ? S_WB_DAT_WIDTH'(reg_reset)       :
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

    wire    core_cke = cke; //  && !(m_wb_stb_o && !m_wb_ack_i);

    logic                           ibus_en;
    logic   [IBUS_ADDR_WIDTH-1:0]   ibus_addr;
    logic   [31:0]                  ibus_rdata;

    logic                           dbus_en;
    logic                           dbus_re;
    logic                           dbus_we;
    logic   [1:0]                   dbus_size;
    logic   [31:0]                  dbus_addr;
    logic   [3:0]                   dbus_sel;
    logic   [3:0]                   dbus_rsel;
    logic   [3:0]                   dbus_wsel;
    logic   [31:0]                  dbus_wdata;
    logic   [31:0]                  dbus_rdata;

    jelly2_jfive_micro_core
            #(
                .IBUS_ADDR_WIDTH    (IBUS_ADDR_WIDTH),
                .DBUS_ADDR_WIDTH    (32),
                .PC_WIDTH           (PC_WIDTH),
                .RESET_PC_ADDR      (RESET_PC_ADDR),
                .SIMULATION         (SIMULATION),
                .TRACE_EXEC_ENABLE  (TRACE_EXEC_ENABLE),
                .TRACE_EXEC_FILE    (TRACE_EXEC_FILE),
                .TRACE_DBUS_ENABLE  (TRACE_DBUS_ENABLE),
                .TRACE_DBUS_FILE    (TRACE_DBUS_FILE)
            )
        i_jfive_micro_core
            (
                .reset,
                .clk,
                .cke                (core_cke),

                .ibus_en,
                .ibus_addr,
                .ibus_rdata,

                .dbus_en,
                .dbus_re,
                .dbus_we,
                .dbus_size,
                .dbus_addr,
                .dbus_sel,
                .dbus_rsel,
                .dbus_wsel,
                .dbus_wdata,
                .dbus_rdata
            );


    // ---------------------------------------------
    //  Memory
    // ---------------------------------------------

    logic                           mem_ibus_en;
    logic                           mem_ibus_wb;
    logic   [RAM_ADDR_WIDTH-1:0]    mem_ibus_addr;
    logic   [3:0]                   mem_ibus_we;
    logic   [31:0]                  mem_ibus_wdata;
    logic   [31:0]                  mem_ibus_rdata;

    logic                           mem_dbus_valid;
    logic   [RAM_ADDR_WIDTH-1:0]    mem_dbus_addr;
    logic   [3:0]                   mem_dbus_we;
    logic   [31:0]                  mem_dbus_wdata;
    logic   [31:0]                  mem_dbus_rdata;

    jelly2_ram_dualport
            #(
                .ADDR_WIDTH         (RAM_ADDR_WIDTH),
                .DATA_WIDTH         (32),
                .WE_WIDTH           (4),
                .WORD_WIDTH         (8),
                .MEM_SIZE           (RAM_SIZE),
                .RAM_TYPE           ("block"),
                .DOUT_REGS0         (0),
                .DOUT_REGS1         (0),
                .MODE0              ("WRITE_FIRST"),
                .MODE1              ("WRITE_FIRST"),

                .FILLMEM            (0),
                .FILLMEM_DATA       (0),
                .READMEMB           (0),
                .READMEMH           (MEM_READMEMH),
                .READMEM_FIlE       (MEM_READMEM_FIlE)
            )
        i_ram_dualport
            (
                .port0_clk          (clk),
                .port0_en           (ibus_en),
                .port0_regcke       (1'b0),
                .port0_we           (mem_ibus_we),
                .port0_addr         (mem_ibus_addr),
                .port0_din          (mem_ibus_wdata),
                .port0_dout         (mem_ibus_rdata),

                .port1_clk          (clk),
                .port1_en           (cke),
                .port1_regcke       (1'b0),
                .port1_we           (mem_dbus_we),
                .port1_addr         (mem_dbus_addr),
                .port1_din          (mem_dbus_wdata),
                .port1_dout         (mem_dbus_rdata)
            );

    // ibus
    assign mem_ibus_en    = ibus_en;
    assign mem_ibus_wb    = wb_mem && s_wb_stb_i && s_wb_we_i;
    assign mem_ibus_addr  = mem_ibus_wb ? s_wb_adr_i[RAM_ADDR_WIDTH-1:0] : RAM_ADDR_WIDTH'(ibus_addr >> 2);
    assign mem_ibus_we    = mem_ibus_wb ? s_wb_sel_i[3:0]                : 4'b0000;
    assign mem_ibus_wdata = s_wb_dat_i[31:0];
    assign ibus_rdata     = mem_ibus_rdata;

    // dbus
    assign mem_dbus_valid = dbus_en && (dbus_addr & MEM_DECODE_MASK) == MEM_DECODE_ADDR;
    assign mem_dbus_addr  = RAM_ADDR_WIDTH'(dbus_addr >> 2);
    assign mem_dbus_we    = mem_dbus_valid ? dbus_wsel : '0;
    assign mem_dbus_wdata = dbus_wdata;



    // ---------------------------------------------
    //  WISHBONE
    // ---------------------------------------------

    logic   wb_valid;
    assign wb_valid   = dbus_en && (dbus_addr & WB_DECODE_MASK) == WB_DECODE_ADDR;

    assign m_wb_adr_o = M_WB_ADR_WIDTH'(dbus_addr >> 2);
    assign m_wb_dat_o = dbus_wdata;
    assign m_wb_sel_o = dbus_sel;
    assign m_wb_we_o  = dbus_we;
    assign m_wb_stb_o = dbus_en & wb_valid;

    logic   [31:0]  wb_rdata;
    always_ff @(posedge clk) begin
        wb_rdata <= m_wb_dat_i;
    end


    // ---------------------------------------------
    //  Memory mapped I/O
    // ---------------------------------------------

    logic   mmio_valid;
    assign mmio_valid = dbus_en && (dbus_addr & MMIO_DECODE_MASK) == MMIO_DECODE_ADDR;

    assign mmio_wr    = dbus_we & mmio_valid;
    assign mmio_rd    = dbus_re & mmio_valid;
    assign mmio_addr  = MMIO_ADR_WIDTH'(dbus_addr);
    assign mmio_sel   = dbus_sel;
    assign mmio_wdata = dbus_wdata;



    // ---------------------------------------------
    //  read
    // ---------------------------------------------

    logic   rd_mem_valid;
    logic   rd_wb_valid;
    logic   rd_mmio_valid;
    always_ff @(posedge clk) begin
        rd_mem_valid  <= mem_dbus_valid;
        rd_wb_valid   <= wb_valid;
        rd_mmio_valid <= mmio_valid;
    end

    assign dbus_rdata = rd_mem_valid  ? mem_dbus_rdata :
                        rd_wb_valid   ? wb_rdata       :
                        rd_mmio_valid ? mmio_rdata     :
                        'x;

endmodule


`default_nettype wire


// end of file
