
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic                           reset           ,
            input   var logic                           clk             
        );


    // -------------------------------------
    //  DUT
    // -------------------------------------

    logic           cke   ;
//    assign cke = 1'b1;


    localparam DATA_BITS  = 32;

    localparam ROWS_BITS  = 14;
    localparam COLS_BITS  = 16;

    localparam IMG_WIDTH  = 64;
    localparam IMG_HEIGHT = 32;


    jelly3_axi4s_if
            #(
                .DATA_BITS  (DATA_BITS  )
            )
        axi4s_src
            (
                .aresetn    (~reset     ),
                .aclk       (clk        ),
                .aclken     (1'b1       )
            );

    jelly3_axi4s_if
            #(
                .DATA_BITS  (DATA_BITS  )
            )
        axi4s_dst
            (
                .aresetn    (~reset     ),
                .aclk       (clk        ),
                .aclken     (1'b1       )
            );


    logic           img_cke   ;
    jelly3_mat_if
            #(
                .CH_BITS    (DATA_BITS  ),
                .CH_DEPTH   (1          ),
                .ROWS_BITS  (ROWS_BITS  ),
                .COLS_BITS  (COLS_BITS  )
            )
        img_src
            (
                .reset      (reset  ),
                .clk        (clk    ),
                .cke        (img_cke)
            );

   jelly3_mat_if
            #(
                .CH_BITS    (DATA_BITS  ),
                .CH_DEPTH   (1          ),
                .ROWS_BITS  (ROWS_BITS  ),
                .COLS_BITS  (COLS_BITS  )
            )
        img_sink
            (
                .reset      (reset  ),
                .clk        (clk    ),
                .cke        (img_cke)
            );
    
    // Target
    jelly3_axi4s_mat
            #(
                .ROWS_BITS      (ROWS_BITS  ),
                .COLS_BITS      (COLS_BITS  ),
                .BLANK_BITS     (4          ),
                .CKE_BUFG       (0          )
            )
        u_axi4s_mat
            (
                .param_rows     (IMG_HEIGHT ),
                .param_cols     (IMG_WIDTH  ),
                .param_blank    (4'd5       ),
                .s_axi4s        (axi4s_src.s),
                .m_axi4s        (axi4s_dst.m),

                .out_cke        (img_cke    ),
                .m_mat          (img_src.m  ),
                .s_mat          (img_src.s  )
        );

    // -------------------------------------
    //  Simulation
    // -------------------------------------

    jelly3_model_axi4s_m
            #(
                .COMPONENTS     (1          ),
                .DATA_BITS      (8          ),
                .IMG_WIDTH      (IMG_WIDTH  ),
                .IMG_HEIGHT     (IMG_HEIGHT ),
                .H_BLANK        (16         ),
                .V_BLANK        (8          ),
                .BUSY_RATE      (0          ),
                .RANDOM_SEED    (0          )
            )
        u_model_axi4s_m
            (
                .enable         (1'b1       ),
                .busy           (           ),
                .m_axi4s        (axi4s_src.m),
                .out_x          (           ),
                .out_y          (           ),
                .out_f          (           )
            );
    
    assign axi4s_dst.tready = 1'b1;

//  assign img_sink = img_src;

    /*
    initial begin
    #10000;
        force axi4s_src.tvalid = 1'b0;
    #10000;
        release axi4s_src.tvalid;
    end
    */
    
endmodule


`default_nettype wire


// end of file
