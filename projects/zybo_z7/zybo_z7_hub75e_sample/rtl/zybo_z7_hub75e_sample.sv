// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//  Ultra96V2 udmabuf test
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------

`timescale 1ns / 1ps
`default_nettype none

module zybo_z7_hub75e_sample
            (
                inout   tri logic   [14:0]  DDR_addr            ,
                inout   tri logic   [2:0]   DDR_ba              ,
                inout   tri logic           DDR_cas_n           ,
                inout   tri logic           DDR_ck_n            ,
                inout   tri logic           DDR_ck_p            ,
                inout   tri logic           DDR_cke             ,
                inout   tri logic           DDR_cs_n            ,
                inout   tri logic   [3:0]   DDR_dm              ,
                inout   tri logic   [31:0]  DDR_dq              ,
                inout   tri logic   [3:0]   DDR_dqs_n           ,
                inout   tri logic   [3:0]   DDR_dqs_p           ,
                inout   tri logic           DDR_odt             ,
                inout   tri logic           DDR_ras_n           ,
                inout   tri logic           DDR_reset_n         ,
                inout   tri logic           DDR_we_n            ,
                inout   tri logic           FIXED_IO_ddr_vrn    ,
                inout   tri logic           FIXED_IO_ddr_vrp    ,
                inout   tri logic   [53:0]  FIXED_IO_mio        ,
                inout   tri logic           FIXED_IO_ps_clk     ,
                inout   tri logic           FIXED_IO_ps_porb    ,
                inout   tri logic           FIXED_IO_ps_srstb   ,
                
                inout   tri logic   [7:0]   pmod_a              ,
                inout   tri logic   [7:0]   pmod_b              ,
                inout   tri logic   [7:0]   pmod_c              ,
                inout   tri logic   [7:0]   pmod_d              ,
                inout   tri logic   [7:0]   pmod_e              ,

                output  var logic   [3:0]   led
            );
    
    
    // -----------------------------
    //  ZynqMP PS
    // -----------------------------
    
    logic           reset = 1'b0;
    logic           clk         ;

    design_1
        u_design_1
            (
                .DDR_addr               (DDR_addr           ),
                .DDR_ba                 (DDR_ba             ),
                .DDR_cas_n              (DDR_cas_n          ),
                .DDR_ck_n               (DDR_ck_n           ),
                .DDR_ck_p               (DDR_ck_p           ),
                .DDR_cke                (DDR_cke            ),
                .DDR_cs_n               (DDR_cs_n           ),
                .DDR_dm                 (DDR_dm             ),
                .DDR_dq                 (DDR_dq             ),
                .DDR_dqs_n              (DDR_dqs_n          ),
                .DDR_dqs_p              (DDR_dqs_p          ),
                .DDR_odt                (DDR_odt            ),
                .DDR_ras_n              (DDR_ras_n          ),
                .DDR_reset_n            (DDR_reset_n        ),
                .DDR_we_n               (DDR_we_n           ),
                .FIXED_IO_ddr_vrn       (FIXED_IO_ddr_vrn   ),
                .FIXED_IO_ddr_vrp       (FIXED_IO_ddr_vrp   ),
                .FIXED_IO_mio           (FIXED_IO_mio       ),
                .FIXED_IO_ps_clk        (FIXED_IO_ps_clk    ),
                .FIXED_IO_ps_porb       (FIXED_IO_ps_porb   ),
                .FIXED_IO_ps_srstb      (FIXED_IO_ps_srstb  ),
                
                .clk                    (clk                )
            );
    
    
    
    
    reg     [25:0]  clk_count;
    always @(posedge clk) begin
        if ( reset ) begin
            clk_count <= 0;
        end
        else begin
            clk_count <= clk_count + 1;
        end
    end
    
    assign led[2:0] = '0;
    assign led[3]   = clk_count[25];
    
    
endmodule



`default_nettype wire


// end of file
