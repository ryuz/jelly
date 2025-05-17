
`timescale 1ns / 1ps
`default_nettype none

module python_receiver
        #(
            parameter   int CHANNELS     = 4                        ,
            parameter       DDR_CLK_EDGE = "SAME_EDGE_PIPELINED"    ,
            parameter       IOSTANDARD   = "DIFF_HSTL_I_18"         ,
            parameter       DIFF_TERM    = "FALSE"                  ,
            parameter       DEVICE       = "7SERIES"                
        )
        (
            input   var logic                       in_reset    ,
            input   var logic                       in_clk_p    ,
            input   var logic                       in_clk_n    ,
            input   var logic   [CHANNELS-1:0]      in_data_p   ,
            input   var logic   [CHANNELS-1:0]      in_data_n   ,
            input   var logic                       in_sync_p   ,
            input   var logic                       in_sync_n   ,

            output  var logic                       out_reset   ,
            output  var logic                       out_clk     ,
            output  var logic   [CHANNELS-1:0][1:0] out_data    ,
            output  var logic                 [1:0] out_sync    
        );

    logic   in_clk;
    IBUFDS
            #(
                .IOSTANDARD     (IOSTANDARD)
            )
       u_ibufds_clk
            (
                .I              (in_clk_p   ),
                .IB             (in_clk_n   ),
                .O              (in_clk     )
            );

    BUFR
            #(
                .SIM_DEVICE     (DEVICE     ),
                .BUFR_DIVIDE    ("BYPASS"   )
            )
        u_bufr_clk
            (
                .O              (out_clk    ),
                .CE             (1'b1       ),
                .CLR            (1'b0       ),
                .I              (in_clk     )
            );


    jelly_reset
            #(
                .COUNTER_WIDTH  (4          )
//                .INSERT_BUFG    (1)
            )
        u_reset
            (
                .clk            (out_clk    ),
                .in_reset       (in_reset   ),
                .out_reset      (out_reset  )
            );

    logic   [CHANNELS-1:0]      in_data;
    logic   [CHANNELS-1:0][1:0] iddr_data   ;
    for ( genvar i = 0; i < CHANNELS; i++ ) begin : datas
        IBUFDS
                #(
                    .DIFF_TERM      (DIFF_TERM      ),
                    .IOSTANDARD     (IOSTANDARD     )
                )
            u_ibufds_data
                (
                    .I              (in_data_p[i]   ),
                    .IB             (in_data_n[i]   ),
                    .O              (in_data  [i]   )
                );

        IDDR
                #(
                    .DDR_CLK_EDGE   (DDR_CLK_EDGE   ),
                    .INIT_Q1        (1'b0           ),
                    .INIT_Q2        (1'b0           ),
                    .SRTYPE         ("ASYNC"        )
                )
            u_iddr_data
                (
                    .Q1             (iddr_data[i][1]),
                    .Q2             (iddr_data[i][0]),
                    .C              (out_clk        ),
                    .CE             (1'b1           ),
                    .D              (in_data [i]    ),
                    .R              (in_reset       ),
                    .S              (1'b0           )
                );
    end

    logic                       in_sync     ;
    logic                 [1:0] iddr_sync   ;
    IBUFDS
            #(
                .DIFF_TERM      (DIFF_TERM      ),
                .IOSTANDARD     (IOSTANDARD     )
            )
        u_ibufds_sync
            (
                .I              (in_sync_p      ),
                .IB             (in_sync_n      ),
                .O              (in_sync        )
            );

    IDDR
            #(
                .DDR_CLK_EDGE   (DDR_CLK_EDGE   ),
                .INIT_Q1        (1'b0           ),
                .INIT_Q2        (1'b0           ),
                .SRTYPE         ("ASYNC"        )
            )
        u_iddr_sync
            (
                .Q1             (iddr_sync[1]  ),
                .Q2             (iddr_sync[0]  ),
                .C              (out_clk        ),
                .CE             (1'b1           ),
                .D              (in_sync        ),
                .R              (in_reset       ),
                .S              (1'b0           )
            );


    // insert FF
    always_ff @(posedge out_clk) begin
        out_data  <= iddr_data;
        out_sync  <= iddr_sync;
    end

endmodule

`default_nettype wire

// end of file
