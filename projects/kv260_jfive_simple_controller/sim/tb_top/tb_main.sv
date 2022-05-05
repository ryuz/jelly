
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

    kv260_jfive_simple_controller
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



endmodule


`default_nettype wire


// end of file
