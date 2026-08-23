// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_morphology_filter_calc
        #(
            parameter   int     N           = 3 ,
            parameter   int     M           = 3 
        )
        (
            input   var logic                   reset           ,
            input   var logic                   clk             ,
            input   var logic                   cke             ,

            input   var logic                   enable          ,
            input   var logic                   param_dilation  ,
            input   var logic   [N-1:0][M-1:0]  param_filter    ,

            input   var logic   [N-1:0][M-1:0]  in_data         ,

            output  var logic                   out_data        
        );
    
    
    logic   st0_data        ;
    logic   st0_erode       ;
    logic   st0_dilate      ;

    logic   st1_data        ;
    
    always_ff @(posedge clk) begin
        if ( cke ) begin
            // stage0
            st0_data    <= in_data[M/2][N/2] ;
            st0_erode   <= &(in_data | ~param_filter);
            st0_dilate  <= |(in_data &  param_filter);

            // stage1
            if ( enable ) begin
                st1_data <= param_dilation ? st0_dilate : st0_erode;
            end
            else begin
                st1_data <= st0_data;
            end
        end
    end
    
    assign out_data = st1_data;
    
endmodule


`default_nettype wire


// end of file
