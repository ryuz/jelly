
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(
            parameter   WB_ADR_WIDTH = 37,
            parameter   WB_DAT_WIDTH = 64,
            parameter   WB_SEL_WIDTH = WB_DAT_WIDTH / 8
        )
        (
            input   wire                        reset,
            input   wire                        clk,

            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_we_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o
        );


    // -----------------------------
    //  top
    // -----------------------------

    wire    [7:0]   pmod;

    kv260_jfive_micro_controller
            #(
                .SIMULATION         (1'b1),
                .LOG_EXE_ENABLE     (1'b1),
                .LOG_MEM_ENABLE     (1'b1)
            )
        i_top
            (
                .pmod       (pmod)
            );
    

    // -----------------------------
    //  force
    // -----------------------------

    always_comb force i_top.i_design_1.reset = reset;
    always_comb force i_top.i_design_1.clk   = clk;

    always_comb force i_top.i_design_1.wb_adr_i =  s_wb_adr_i;
    always_comb force i_top.i_design_1.wb_dat_i =  s_wb_dat_i;
    always_comb force i_top.i_design_1.wb_sel_i =  s_wb_sel_i;
    always_comb force i_top.i_design_1.wb_we_i  =  s_wb_we_i;
    always_comb force i_top.i_design_1.wb_stb_i =  s_wb_stb_i;
    assign s_wb_dat_o = i_top.i_design_1.wb_dat_o;
    assign s_wb_ack_o = i_top.i_design_1.wb_ack_o;



    // -----------------------------
    //  debug
    // -----------------------------

    logic   [15:0]                  wb_mc_adr_o;
    logic   [31:0]                  wb_mc_dat_i;
    logic   [31:0]                  wb_mc_dat_o;
    logic   [3:0]                   wb_mc_sel_o;
    logic                           wb_mc_we_o;
    logic                           wb_mc_stb_o;
    logic                           wb_mc_ack_i;

    assign wb_mc_adr_o = i_top.wb_mc_adr_o;
    assign wb_mc_dat_i = i_top.wb_mc_dat_i;
    assign wb_mc_dat_o = i_top.wb_mc_dat_o;
    assign wb_mc_sel_o = i_top.wb_mc_sel_o;
    assign wb_mc_we_o  = i_top.wb_mc_we_o;
    assign wb_mc_stb_o = i_top.wb_mc_stb_o;
    assign wb_mc_ack_i = i_top.wb_mc_ack_i;

    always @(posedge clk) begin
        if ( !reset ) begin
            if ( wb_mc_stb_o && wb_mc_we_o && wb_mc_adr_o == 16'h0040 ) begin
                $write("%c", wb_mc_dat_o[7:0]);
            end
        end
    end

    final begin
        $write("\n");
    end


    wire [31:0] x0  = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[0 ];
    wire [31:0] x1  = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[1 ];
    wire [31:0] x2  = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[2 ];
    wire [31:0] x3  = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[3 ];
    wire [31:0] x4  = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[4 ];
    wire [31:0] x5  = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[5 ];
    wire [31:0] x6  = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[6 ];
    wire [31:0] x7  = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[7 ];
    wire [31:0] x8  = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[8 ];
    wire [31:0] x9  = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[9 ];
    wire [31:0] x10 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[10];
    wire [31:0] x11 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[11];
    wire [31:0] x12 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[12];
    wire [31:0] x13 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[13];
    wire [31:0] x14 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[14];
    wire [31:0] x15 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[15];
    wire [31:0] x16 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[16];
    wire [31:0] x17 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[17];
    wire [31:0] x18 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[18];
    wire [31:0] x19 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[19];
    wire [31:0] x20 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[20];
    wire [31:0] x21 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[21];
    wire [31:0] x22 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[22];
    wire [31:0] x23 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[23];
    wire [31:0] x24 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[24];
    wire [31:0] x25 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[25];
    wire [31:0] x26 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[26];
    wire [31:0] x27 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[27];
    wire [31:0] x28 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[28];
    wire [31:0] x29 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[29];
    wire [31:0] x30 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[30];
    wire [31:0] x31 = i_top.i_jfive_micro_controller.i_jfive_micro_core.i_register_file.loop_ram[0].i_ram_dualport.mem[31];

endmodule


`default_nettype wire


// end of file
