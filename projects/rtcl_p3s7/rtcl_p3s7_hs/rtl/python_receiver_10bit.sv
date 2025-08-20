`timescale 1ns / 1ps
`default_nettype none


module python_receiver_10bit
        #(
            parameter   int CHANNELS         = 4                        ,
            parameter       DDR_CLK_EDGE     = "SAME_EDGE_PIPELINED"    ,
            parameter       IOSTANDARD       = "DIFF_HSTL_I_18"         ,
            parameter       DIFF_TERM        = "FALSE"                  ,
            parameter       IODELAY_GRP      = "IODELAY_GRP_LVDS"       ,
            parameter       REFCLK_FREQUENCY = 200.0                    ,
            parameter       DEVICE           = "7SERIES"                
        )
        (
            input   var logic                       in_reset    ,
            input   var logic                       in_clk_p    ,
            input   var logic                       in_clk_n    ,
            input   var logic   [CHANNELS-1:0]      in_data_p   ,
            input   var logic   [CHANNELS-1:0]      in_data_n   ,
            input   var logic                       in_sync_p   ,
            input   var logic                       in_sync_n   ,
            input   var logic                       sw_reset    ,

            input   var logic                       bitslip     ,
            output  var logic                       out_reset   ,
            output  var logic                       out_clk     ,
            output  var logic   [CHANNELS-1:0][9:0] out_data    ,
            output  var logic                 [9:0] out_sync    
        );
    
    // clock input
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

    // delay the input clock
    logic       in_clk_dly;
    (* IODELAY_GROUP = IODELAY_GRP *)
    IDELAYE2
            #(
                .CINVCTRL_SEL           ("FALSE"            ),
                .DELAY_SRC              ("IDATAIN"          ),
                .HIGH_PERFORMANCE_MODE  ("FALSE"            ),
                .IDELAY_TYPE            ("FIXED"            ),
                .IDELAY_VALUE           (8                  ),
                .REFCLK_FREQUENCY       (REFCLK_FREQUENCY   ),
                .PIPE_SEL               ("FALSE"            ),
                .SIGNAL_PATTERN         ("CLOCK"            )
            )
        u_idelaye2_clk
            (
                .DATAOUT                (in_clk_dly         ),
                .DATAIN                 (1'b0               ),
                .C                      (1'b0               ),
                .CE                     (1'b0               ),
                .INC                    (1'b0               ),
                .IDATAIN                (in_clk             ),
                .LD                     (in_reset           ),
                .LDPIPEEN               (1'b0               ),
                .REGRST                 (1'b0               ),
                .CNTVALUEIN             (5'b00000           ),
                .CNTVALUEOUT            (                   ),
                .CINVCTRL               (1'b0               )
            );

    // I/O clock buffer
    logic   io_clk;
    BUFIO
        u_bufio
            (
                .I              (in_clk_dly ),
                .O              (io_clk     )
            );


    // Resional clock buffer
    BUFR
            #(
                .SIM_DEVICE     (DEVICE     ),
                .BUFR_DIVIDE    ("5"        )
            )
        u_bufr
            (
                .CE             (1'b1       ),
                .CLR            (1'b0       ),
                .I              (in_clk_dly ),
                .O              (out_clk    )
            );

    // reset
    logic   reset;
    assign reset = in_reset || sw_reset;
    jelly3_reset
            #(
                .ADDITIONAL_CYCLE   (16         )
            )
        u_reset
            (
                .clk                (out_clk    ),
                .cke                (1'b1       ),
                .in_reset           (reset      ),
                .out_reset          (out_reset  )
            );

    // SERDES
    logic   [CHANNELS:0]          iserdes_d_p     ;
    logic   [CHANNELS:0]          iserdes_d_n     ;
    assign iserdes_d_p = {in_sync_p, in_data_p};
    assign iserdes_d_n = {in_sync_n, in_data_n};

    logic   [CHANNELS:0]          iserdes_d       ;
    logic   [CHANNELS:0][9:0]     iserdes_q       ;
    for ( genvar i = 0; i < CHANNELS+1; i++ ) begin : iserdes
        IBUFDS
                #(
                    .DIFF_TERM      (DIFF_TERM      ),
                    .IOSTANDARD     (IOSTANDARD     )
                )
            u_ibufds_data
                (
                    .I              (iserdes_d_p[i] ),
                    .IB             (iserdes_d_n[i] ),
                    .O              (iserdes_d  [i] )
                );


        // ISERDES
        logic shiftout1, shiftout2, shiftin1, shiftin2;
        ISERDESE2
                #(
                    .DATA_RATE      ("DDR"              ),
                    .DATA_WIDTH     (10                 ),
                    .INTERFACE_TYPE ("NETWORKING"       ),
                    .NUM_CE         (2                  ),
                    .OFB_USED       ("FALSE"            ),
                    .IOBDELAY       ("NONE"             ),
                    .SERDES_MODE    ("MASTER"           )
                )
            u_iserdes_master
                (
                    .Q1             (iserdes_q[i][0]    ),
                    .Q2             (iserdes_q[i][1]    ),
                    .Q3             (iserdes_q[i][2]    ),
                    .Q4             (iserdes_q[i][3]    ),
                    .Q5             (iserdes_q[i][4]    ),
                    .Q6             (iserdes_q[i][5]    ),
                    .Q7             (iserdes_q[i][6]    ),
                    .Q8             (iserdes_q[i][7]    ),
                    .SHIFTOUT1      (shiftout1          ),
                    .SHIFTOUT2      (shiftout2          ),
                    .BITSLIP        (bitslip            ),
                    .CE1            (1'b1               ),
                    .CE2            (1'b1               ),
                    .CLK            (io_clk             ),
                    .CLKB           (~io_clk            ),
                    .CLKDIV         (out_clk            ),
                    .D              (iserdes_d[i]       ),
                    .DDLY           (1'b0               ),
                    .RST            (out_reset          ),
                    .SHIFTIN1       (1'b0               ),
                    .SHIFTIN2       (1'b0               ),
                    .DYNCLKDIVSEL   (1'b0               ),
                    .DYNCLKSEL      (1'b0               ),
                    .OFB            (                   ),
                    .OCLK           (                   ),
                    .OCLKB          (                   ),
                    .O              (                   )
                );

        ISERDESE2
                #(
                    .DATA_RATE      ("DDR"              ),
                    .DATA_WIDTH     (10                 ),
                    .INTERFACE_TYPE ("NETWORKING"       ),
                    .NUM_CE         (2                  ),
                    .OFB_USED       ("FALSE"            ),
                    .IOBDELAY       ("NONE"             ),
                    .SERDES_MODE    ("SLAVE"            )
                )
            u_iserdes_slave
                (
                    .Q1             (                   ),
                    .Q2             (                   ),
                    .Q3             (iserdes_q[i][8]    ),
                    .Q4             (iserdes_q[i][9]    ),
                    .Q5             (                   ),
                    .Q6             (                   ),
                    .Q7             (                   ),
                    .Q8             (                   ),
                    .SHIFTOUT1      (                   ),
                    .SHIFTOUT2      (                   ),
                    .BITSLIP        (bitslip            ),
                    .CE1            (1'b1               ),
                    .CE2            (1'b1               ),
                    .CLK            (io_clk             ),
                    .CLKB           (~io_clk            ),
                    .CLKDIV         (out_clk            ),
                    .D              (1'b0               ),
                    .DDLY           (1'b0               ),
                    .RST            (out_reset          ),
                    .SHIFTIN1       (shiftout1          ),
                    .SHIFTIN2       (shiftout2          ),
                    .DYNCLKDIVSEL   (1'b0               ),
                    .DYNCLKSEL      (1'b0               ),
                    .OFB            (                   ),
                    .OCLK           (                   ),
                    .OCLKB          (                   ),
                    .O              (                   )
                );
    end


    // 出力へ格納
    assign {out_sync, out_data} = iserdes_q;

endmodule

`default_nettype wire

// end of file
