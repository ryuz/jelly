
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

    parameter   int                     MEM_SIZE         = 32'h0001_0000;
    parameter   bit                     MEM_READMEMH     = 1'b1;
    parameter                           MEM_READMEM_FIlE = "../mem.hex";

    parameter   bit     [31:0]          RESET_PC_ADDR    = 32'h8000_0000;
    parameter   bit                     INIT_CTL_RESET   = 1'b0;

    parameter   bit                     SIMULATION      = 1'b1;
    parameter   bit                     TRACE_FILE_EN   = 1'b1;
    parameter   string                  TRACE_FILE      = "jfive_trace.txt";

    logic                           cke = 1'b1;

    logic   [S_WB_ADR_WIDTH-1:0]    s_wb_adr_i;
    logic   [S_WB_DAT_WIDTH-1:0]    s_wb_dat_o;
    logic   [S_WB_DAT_WIDTH-1:0]    s_wb_dat_i;
    logic   [3:0]                   s_wb_sel_i;
    logic                           s_wb_we_i;
    logic                           s_wb_stb_i = 1'b0;
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
    
    jelly2_jfive_micro_controller
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
                .INIT_CTL_RESET     (INIT_CTL_RESET),
                .SIMULATION         (SIMULATION),
                .TRACE_FILE_EN      (TRACE_FILE_EN),
                .TRACE_FILE         (TRACE_FILE)
            )
        i_jfive_micro_controller
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
    
    wire [31:0] x0  = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[0 ];
    wire [31:0] x1  = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[1 ];
    wire [31:0] x2  = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[2 ];
    wire [31:0] x3  = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[3 ];
    wire [31:0] x4  = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[4 ];
    wire [31:0] x5  = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[5 ];
    wire [31:0] x6  = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[6 ];
    wire [31:0] x7  = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[7 ];
    wire [31:0] x8  = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[8 ];
    wire [31:0] x9  = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[9 ];
    wire [31:0] x10 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[10];
    wire [31:0] x11 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[11];
    wire [31:0] x12 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[12];
    wire [31:0] x13 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[13];
    wire [31:0] x14 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[14];
    wire [31:0] x15 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[15];
    wire [31:0] x16 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[16];
    wire [31:0] x17 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[17];
    wire [31:0] x18 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[18];
    wire [31:0] x19 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[19];
    wire [31:0] x20 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[20];
    wire [31:0] x21 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[21];
    wire [31:0] x22 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[22];
    wire [31:0] x23 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[23];
    wire [31:0] x24 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[24];
    wire [31:0] x25 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[25];
    wire [31:0] x26 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[26];
    wire [31:0] x27 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[27];
    wire [31:0] x28 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[28];
    wire [31:0] x29 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[29];
    wire [31:0] x30 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[30];
    wire [31:0] x31 = i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[31];

    wire [31:0] zero = x0 ;
    wire [31:0] ra = x1 ;
    wire [31:0] sp = x2 ;
    wire [31:0] gp = x3 ;
    wire [31:0] tp = x4 ;
    wire [31:0] t0 = x5 ;
    wire [31:0] t1 = x6 ;
    wire [31:0] t2 = x7 ;
    wire [31:0] s0 = x8 ;
    wire [31:0] s1 = x9 ;
    wire [31:0] a0 = x10;
    wire [31:0] a1 = x11;
    wire [31:0] a2 = x12;
    wire [31:0] a3 = x13;
    wire [31:0] a4 = x14;
    wire [31:0] a5 = x15;
    wire [31:0] a6 = x16;
    wire [31:0] a7 = x17;
    wire [31:0] s2 = x18;
    wire [31:0] s3 = x19;
    wire [31:0] s4 = x20;
    wire [31:0] s5 = x21;
    wire [31:0] s6 = x22;
    wire [31:0] s7 = x23;
    wire [31:0] s8 = x24;
    wire [31:0] s9 = x25;
    wire [31:0] s10 = x26;
    wire [31:0] s11 = x27;
    wire [31:0] t3 = x28;
    wire [31:0] t4 = x29;
    wire [31:0] t5 = x30;
    wire [31:0] t6 = x31;

    assign mmio_rdata = 32'h81828384;

    
    always @(posedge clk) begin
        if ( !reset && mmio_wr ) begin
//          $display("write: %h %10d %b", mmio_addr, $signed(mmio_wdata), mmio_sel);
            $display("write: %h %08x %b", mmio_addr, $signed(mmio_wdata), mmio_sel);
        end
    end

    always @(posedge clk) begin
        if ( !reset ) begin
            if ( m_wb_stb_o && m_wb_we_o && m_wb_sel_o[0] && {m_wb_adr_o, 2'b00} == 26'h0000100 ) begin
                $write("%c", m_wb_dat_o[7:0]);
            end
        end
    end
    assign m_wb_ack_i = m_wb_stb_o;

endmodule


`default_nettype wire


// end of file
