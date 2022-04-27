
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire                        reset,
            input   wire                        clk
        );

    localparam  int             S_WB_ADR_WIDTH   = 16;
    localparam  int             S_WB_DAT_WIDTH   = 32;
    localparam  int             S_WB_SEL_WIDTH   = S_WB_DAT_WIDTH/8;

    localparam  bit     [31:0]  M_WB_DECODE_MASK = 32'hff00_0000;
    localparam  bit     [31:0]  M_WB_DECODE_ADDR = 32'hf000_0000;
    localparam  int             M_WB_ADR_WIDTH   = 24;

    localparam  bit     [31:0]  TCM_DECODE_MASK  = 32'hff00_0000;
    localparam  bit     [31:0]  TCM_DECODE_ADDR  = 32'h8000_0000;
    localparam  int             TCM_ADDR_OFFSET  = 1 << (S_WB_ADR_WIDTH - 1);
    localparam  int             TCM_SIZE         = 64*1024;
    localparam  bit             TCM_READMEMH     = 1'b1;
    localparam                  TCM_READMEM_FIlE = "../mem.hex";

    localparam  int             PC_WIDTH         = 32;
    localparam  bit     [31:0]  INIT_PC_ADDR     = 32'h8000_0000;
    localparam  bit             INIT_CTL_RESET   = 1'b1;

    localparam  bit             SIMULATION       = 1'b1;
    localparam  bit             LOG_EXE_ENABLE   = 1'b1;
    localparam  string          LOG_EXE_FILE     = "jfive_exe_log.txt";
    localparam  bit             LOG_MEM_ENABLE   = 1'b1;
    localparam  string          LOG_MEM_FILE     = "jfive_mem_log.txt";

    logic                           cke = 1'b1;
    always @(posedge clk) begin
//        cke <= $urandom_range(1);
    end


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
    
    jelly2_jfive_micro_controller
            #(
                .S_WB_ADR_WIDTH     (S_WB_ADR_WIDTH),
                .S_WB_DAT_WIDTH     (S_WB_DAT_WIDTH),
                .S_WB_SEL_WIDTH     (S_WB_SEL_WIDTH),
                .M_WB_DECODE_MASK   (M_WB_DECODE_MASK),
                .M_WB_DECODE_ADDR   (M_WB_DECODE_ADDR),
                .M_WB_ADR_WIDTH     (M_WB_ADR_WIDTH),
                .TCM_DECODE_MASK    (TCM_DECODE_MASK),
                .TCM_DECODE_ADDR    (TCM_DECODE_ADDR),
                .TCM_ADDR_OFFSET    (TCM_ADDR_OFFSET),
                .TCM_SIZE           (TCM_SIZE),
                .TCM_READMEMH       (TCM_READMEMH    ),
                .TCM_READMEM_FIlE   (TCM_READMEM_FIlE),
                .PC_WIDTH           (PC_WIDTH),
                .INIT_PC_ADDR       (INIT_PC_ADDR),
                .INIT_CTL_RESET     (INIT_CTL_RESET),
                .SIMULATION         (SIMULATION),
                .LOG_EXE_ENABLE     (LOG_EXE_ENABLE),
                .LOG_EXE_FILE       (LOG_EXE_FILE),
                .LOG_MEM_ENABLE     (LOG_MEM_ENABLE),
                .LOG_MEM_FILE       (LOG_MEM_FILE)
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
                .m_wb_ack_i
            );
    
    int     ex_count = 0;
    always_ff @(posedge clk) begin
        if ( !reset && i_jfive_micro_controller.i_jfive_micro_core.cke ) begin
            ex_count <= ex_count +  i_jfive_micro_controller.i_jfive_micro_core.ex_valid;
        end
    end
    
    
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


    always @(posedge clk) begin
        if ( !reset && cke ) begin
            if ( m_wb_stb_o && m_wb_we_o && m_wb_ack_i ) begin
                if ( {m_wb_adr_o, 2'b00} == 26'h0000100 ) begin
                    $write("%c", m_wb_dat_o[7:0]);
                end
                else begin
                    $display("write: %h %08x %b", m_wb_adr_o, m_wb_dat_o, m_wb_sel_o);
                end
            end
        end
    end

    bit     rand_ack;
    always @(posedge clk) begin
        rand_ack <= $urandom_range(1);
    end

    assign m_wb_ack_i = m_wb_stb_o & rand_ack;

endmodule


`default_nettype wire


// end of file
