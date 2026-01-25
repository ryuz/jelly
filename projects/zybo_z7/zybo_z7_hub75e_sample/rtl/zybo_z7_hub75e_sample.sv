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
        #(
            parameter   DEVICE     = "7SERIES"  ,
            parameter   SIMULATION = "false"    ,
            parameter   DEBUG      = "false"    
        )
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
    
    logic           reset           ;
    logic           clk             ;
    logic           axi4l_aresetn   ;
    logic           axi4l_aclk      ;
    logic           axi4_aresetn    ;
    logic           axi4_aclk       ;

    jelly3_axi4l_if
            #(
                .ADDR_BITS  (32             ),
                .DATA_BITS  (32             )
            )
        axi4l
            (
                .aresetn    (axi4l_aresetn  ),
                .aclk       (axi4l_aclk     ),
                .aclken     (1'b1           )
            );

    jelly3_axi4_if
            #(
                .ID_BITS    (12             ),
                .ADDR_BITS  (32             ),
                .DATA_BITS  (32             ),
                .LEN_BITS   (4              )
            )
        axi4
            (
                .aresetn    (axi4l_aresetn  ),
                .aclk       (axi4l_aclk     ),
                .aclken     (1'b1           )
            );

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
                
                .out_reset              (reset              ),
                .out_clk                (clk                ),

                .m_axi4l_aresetn        (axi4l_aresetn      ),
                .m_axi4l_aclk           (axi4l_aclk         ),
                .m_axi4l_awaddr         (axi4l.awaddr       ),
                .m_axi4l_awprot         (axi4l.awprot       ),
                .m_axi4l_awvalid        (axi4l.awvalid      ),
                .m_axi4l_awready        (axi4l.awready      ),
                .m_axi4l_wdata          (axi4l.wdata        ),
                .m_axi4l_wstrb          (axi4l.wstrb        ),
                .m_axi4l_wvalid         (axi4l.wvalid       ),
                .m_axi4l_wready         (axi4l.wready       ),
                .m_axi4l_bresp          (axi4l.bresp        ),
                .m_axi4l_bvalid         (axi4l.bvalid       ),
                .m_axi4l_bready         (axi4l.bready       ),
                .m_axi4l_araddr         (axi4l.araddr       ),
                .m_axi4l_arprot         (axi4l.arprot       ),
                .m_axi4l_arvalid        (axi4l.arvalid      ),
                .m_axi4l_arready        (axi4l.arready      ),
                .m_axi4l_rdata          (axi4l.rdata        ),
                .m_axi4l_rresp          (axi4l.rresp        ),
                .m_axi4l_rvalid         (axi4l.rvalid       ),
                .m_axi4l_rready         (axi4l.rready       ),

                .m_axi3_aresetn         (axi4_aresetn       ),
                .m_axi3_aclk            (axi4_aclk          ),
                .m_axi3_awid            (axi4.awid          ),
                .m_axi3_awaddr          (axi4.awaddr        ),
                .m_axi3_awburst         (axi4.awburst       ),
                .m_axi3_awcache         (axi4.awcache       ),
                .m_axi3_awlen           (axi4.awlen         ),
                .m_axi3_awlock          (axi4.awlock        ),
                .m_axi3_awprot          (axi4.awprot        ),
                .m_axi3_awqos           (axi4.awqos         ),
                .m_axi3_awsize          (axi4.awsize        ),
                .m_axi3_awvalid         (axi4.awvalid       ),
                .m_axi3_awready         (axi4.awready       ),
                .m_axi3_wid             (                   ),
                .m_axi3_wdata           (axi4.wdata         ),
                .m_axi3_wlast           (axi4.wlast         ),
                .m_axi3_wstrb           (axi4.wstrb         ),
                .m_axi3_wvalid          (axi4.wvalid        ),
                .m_axi3_wready          (axi4.wready        ),
                .m_axi3_bid             (axi4.bid           ),
                .m_axi3_bresp           (axi4.bresp         ),
                .m_axi3_bvalid          (axi4.bvalid        ),
                .m_axi3_bready          (axi4.bready        ),
                .m_axi3_arid            (axi4.arid          ),
                .m_axi3_araddr          (axi4.araddr        ),
                .m_axi3_arburst         (axi4.arburst       ),
                .m_axi3_arcache         (axi4.arcache       ),
                .m_axi3_arlen           (axi4.arlen         ),
                .m_axi3_arlock          (axi4.arlock        ),
                .m_axi3_arprot          (axi4.arprot        ),
                .m_axi3_arqos           (axi4.arqos         ),
                .m_axi3_arsize          (axi4.arsize        ),
                .m_axi3_arvalid         (axi4.arvalid       ),
                .m_axi3_arready         (axi4.arready       ),
                .m_axi3_rid             (axi4.rid           ),
                .m_axi3_rdata           (axi4.rdata         ),
                .m_axi3_rlast           (axi4.rlast         ),
                .m_axi3_rresp           (axi4.rresp         ),
                .m_axi3_rvalid          (axi4.rvalid        ),
                .m_axi3_rready          (axi4.rready        )
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

    localparam  int DATA_BITS = 10;
    logic                    mem_we     ;
    logic   [11:0]           mem_addr   ;
    logic   [DATA_BITS-1:0]  mem_r      ;
    logic   [DATA_BITS-1:0]  mem_g      ;
    logic   [DATA_BITS-1:0]  mem_b      ;

    hub75_driver
            #(
                .CLK_DIV        (2              ),
                .DISP_BITS      (16             ),
                .N              (2              ),
                .WIDTH          (64             ),
                .HEIGHT         (32             ),
                .SEL_BITS       (5              ),
                .DATA_BITS      (DATA_BITS      ),
                .RAM_TYPE       ("block"        ),
                .READMEMH       (0              ),
                .READMEM_FILE   (""             )
            )
        u_hub75_driver
            (
                .reset          (1'b0                   ),
                .clk            (clk                    ),

                .hub75_cke      (hub75e_cke             ),
                .hub75_oe_n     (hub75e_oe              ),
                .hub75_lat      (hub75e_lat             ),
                .hub75_sel      ({
                                    hub75e_e,
                                    hub75e_d,
                                    hub75e_c,
                                    hub75e_b,
                                    hub75e_a
                                }),
                .hub75_r        ({hub75e_r2, hub75e_r1} ),
                .hub75_g        ({hub75e_g2, hub75e_g1} ),
                .hub75_b        ({hub75e_b2, hub75e_b1} ),

                .s_axi4l        (axi4l                  ),

                .mem_clk        (clk                    ),
                .mem_we         (mem_we                 ),
                .mem_addr       (mem_addr               ),
                .mem_r          (mem_r                  ),
                .mem_g          (mem_g                  ),
                .mem_b          (mem_b                  )
            );

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


    jelly3_bram_if
            #(
                .ID_BITS    (12             ),
                .ADDR_BITS  (32             ),
                .DATA_BITS  (32             )
            )
        bram
            (
                .reset      (~axi4.aresetn  ),
                .clk        (axi4.aclk      ),
                .cke        (axi4.aclken    )
            );
    
    jelly3_axi4_to_bram
        u_axi4_to_bram
            (
                .s_axi4     (axi4           ),
                .m_bram     (bram           )
            );

    jelly3_bram_accessor
            #(
                .WLATENCY   (1              ),
                .RLATENCY   (1              ),
                .ADDR_BITS  (12             ),
                .DATA_BITS  (30             ),
                .BYTE_BITS  (30             )
            )
        u_bram_accessor
            (
                .s_bram     (bram           ),

                .en         (               ),
                .we         (mem_we         ),
                .addr       (mem_addr       ),
                .wdata      ({
                                mem_r,
                                mem_g,
                                mem_b
                            }),
                .rdata      ('0             )
            );


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
