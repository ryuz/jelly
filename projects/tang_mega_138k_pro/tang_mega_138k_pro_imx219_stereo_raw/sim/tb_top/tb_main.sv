
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic       reset   ,
            input   var logic       clk
        );


    // -----------------------------
    //  top
    // -----------------------------

    logic           uart_rx  ;
    logic           uart_tx  ;
    logic   [5:0]   led_n    ;

    wire            i2c_scl  ;
    wire            i2c_sda  ;
    logic           csi0_rstn;
//  logic   [7:0]   pmod0    ;
    logic   [7:0]   pmod1    ;
    logic   [7:0]   pmod2    ;

    tang_mega_138k_pro_imx219
            #(
                .JFIVE_TCM_READMEM_FIlE ("../mem.hex")
            )
        u_top
            (
                .reset      ,
                .clk        ,

                .uart_rx    ,
                .uart_tx    ,

                .i2c_scl    ,
                .i2c_sda    ,
                .csi0_rstn  ,

                .led_n      ,

            //  .pmod0      ,
                .pmod1      ,
                .pmod2      
            );

    pullup (i2c_scl);
    pullup (i2c_sda);

    assign uart_rx = 1'b1;
    
    logic   [15:0]  wb_adr_o;
    logic   [31:0]  wb_dat_i;
    logic   [31:0]  wb_dat_o;
    logic   [3:0]   wb_sel_o;
    logic           wb_we_o;
    logic           wb_stb_o;
    logic           wb_ack_i;

    assign wb_adr_o = u_top.wb_mcu_adr_o;
    assign wb_dat_i = u_top.wb_mcu_dat_i;
    assign wb_dat_o = u_top.wb_mcu_dat_o;
    assign wb_sel_o = u_top.wb_mcu_sel_o;
    assign wb_we_o  = u_top.wb_mcu_we_o;
    assign wb_stb_o = u_top.wb_mcu_stb_o;
    assign wb_ack_i = u_top.wb_mcu_ack_i;

    always_ff @(posedge clk) begin
        if ( !reset ) begin
            if ( wb_stb_o && wb_we_o && wb_adr_o == 16'h0040 ) begin
                $write("%c", wb_dat_o[7:0]);
            end
        end
    end

    final begin
        $write("\n");
    end



endmodule


`default_nettype wire


// end of file
