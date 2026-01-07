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
                
                input   var logic   [3:0]   push_sw             ,
                input   var logic   [3:0]   dip_sw              ,
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
    

    // -----------------------------
    //  HUB-75E
    // -----------------------------

    logic   hub75e_a;
    logic   hub75e_b;
    logic   hub75e_c;
    logic   hub75e_d;
    logic   hub75e_e;

    logic   hub75e_oe;
    logic   hub75e_lat;
    logic   hub75e_cke;

    logic   hub75e_r1;
    logic   hub75e_g1;
    logic   hub75e_b1;
    logic   hub75e_r2;
    logic   hub75e_g2;
    logic   hub75e_b2;

    assign pmod_d[0] = hub75e_g1    ;
    assign pmod_d[1] = 1'b0         ;
    assign pmod_d[2] = hub75e_g2    ;
    assign pmod_d[3] = hub75e_e     ;
    assign pmod_d[4] = hub75e_r1    ;
    assign pmod_d[5] = hub75e_b1    ;
    assign pmod_d[6] = hub75e_r2    ;
    assign pmod_d[7] = hub75e_b2    ;

    assign pmod_e[0] = hub75e_b     ;
    assign pmod_e[1] = hub75e_d     ;
    assign pmod_e[2] = hub75e_lat   ;
    assign pmod_e[3] = 1'b0         ;
    assign pmod_e[4] = hub75e_a     ;
    assign pmod_e[5] = hub75e_c     ;
    assign pmod_e[6] = hub75e_cke   ;
    assign pmod_e[7] = hub75e_oe    ;


    /*
    logic   [1:0]   pre     ;
    logic   [30:0]  count   ;
    always_ff @(posedge clk) begin
        pre <= pre + 1;
        if ( pre == 0 ) begin
            count <= count + 1;
        end
    end

    assign hub75e_cke = pre[1];
//  assign hub75e_cke = dip_sw[0] && count[0];
//  assign hub75e_oe  = !dip_sw[0] || (count[5:0] <= count[11:6]);
    assign hub75e_oe  = !dip_sw[0] || (count[5:0] == 4);
    assign hub75e_lat = dip_sw[0] && (count[5:0] == '1);

    assign hub75e_a = count[6]  && !push_sw[0];
    assign hub75e_b = count[7]  && !push_sw[1];
    assign hub75e_c = count[8]  && !push_sw[2];
    assign hub75e_d = count[9]  && !push_sw[3];
    assign hub75e_e = count[10] && dip_sw[1];

    logic [5:0] color;
//  assign color = count[5:0] + count[11:6];
    assign color = count[5:0] + count[11:6] + count[25:20];

    assign hub75e_r1 = color[0];
    assign hub75e_g1 = color[1];
    assign hub75e_b1 = color[2];
    assign hub75e_r2 = color[3];
    assign hub75e_g2 = color[4];
    assign hub75e_b2 = color[5];
    */


    hub75_driver
            #(
                .CLK_DIV        (4              ),
                .DISP_BITS      (16             ),
                .N              (2              ),
                .WIDTH          (64             ),
                .HEIGHT         (32             ),
                .SEL_BITS       (5              ),
                .DATA_BITS      (8              ),
                .RAM_TYPE       ("block"        ),
                .READMEMH       (1              ),
                .READMEM_FILE   ("../../../image.hex")
            )
        u_hub75_driver
            (
                .reset          (1'b0           ),
                .clk            (clk            ),
                
                .enable         (dip_sw[0]      ),
                .disp           (16             ),

                .hub75_cke      (hub75e_cke     ),
                .hub75_oe_n     (hub75e_oe      ),
                .hub75_lat      (hub75e_lat     ),
                .hub75_sel      ({
                                    hub75e_e,
                                    hub75e_d,
                                    hub75e_c,
                                    hub75e_b,
                                    hub75e_a
                                }),
                .hub75_r        ({hub75e_r2, hub75e_r1}),
                .hub75_g        ({hub75e_g2, hub75e_g1}),
                .hub75_b        ({hub75e_b2, hub75e_b1}),

                .mem_clk        (clk        ),
                .mem_we         ('0         ),
                .mem_addr       ('0         ),
                .mem_r          ('0         ),
                .mem_g          ('0         ),
                .mem_b          ('0         )
            );



    // -----------------------------
    //  ZynqMP PS
    // -----------------------------

    logic   [25:0]  clk_count;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            clk_count <= 0;
        end
        else begin
            clk_count <= clk_count + 1;
        end
    end
    
//  assign led[2:0] = '0;
//  assign led[3]   = clk_count[25];

    assign led = push_sw;
    
endmodule



`default_nettype wire


// end of file
