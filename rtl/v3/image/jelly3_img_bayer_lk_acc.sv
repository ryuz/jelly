// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_bayer_lk_acc
        #(
            parameter   int     CALC_BITS   = 36                            ,
            parameter   type    calc_t      = logic signed  [CALC_BITS-1:0] ,
            parameter   int     ACC_BITS    = $bits(calc_t) + 20            ,
            parameter   type    acc_t       = logic signed  [ACC_BITS-1:0]  
        )
        (
            input   var logic       reset           ,
            input   var logic       clk             ,
            input   var logic       cke             ,

            input   var logic       in_first        ,
            input   var logic       in_last         ,
            input   var logic       in_de           ,
            input   var calc_t      in_gx2          ,
            input   var calc_t      in_gy2          ,
            input   var calc_t      in_gxy          ,
            input   var calc_t      in_ex           ,
            input   var calc_t      in_ey           ,
            input   var logic       in_valid        ,

            output  var acc_t       out_gx2         ,
            output  var acc_t       out_gy2         ,
            output  var acc_t       out_gxy         ,
            output  var acc_t       out_ex          ,
            output  var acc_t       out_ey          ,
            output  var logic       out_valid       
        );
    

    acc_t                   acc_gx2         ;
    acc_t                   acc_gy2         ;
    acc_t                   acc_gxy         ;
    acc_t                   acc_ex          ;
    acc_t                   acc_ey          ;
    logic                   acc_valid       ;

    always_ff @(posedge clk) begin
        if ( cke ) begin
            if ( in_valid ) begin
                if ( in_first ) begin
                    acc_gx2 <= '0;
                    acc_gy2 <= '0;
                    acc_gxy <= '0;
                    acc_ex  <= '0;
                    acc_ey  <= '0;
                end
                else if ( in_de ) begin
                    acc_gx2 <= acc_gx2 + acc_t'(in_gx2);
                    acc_gy2 <= acc_gy2 + acc_t'(in_gy2);
                    acc_gxy <= acc_gxy + acc_t'(in_gxy);
                    acc_ex  <= acc_ex  + acc_t'(in_ex );
                    acc_ey  <= acc_ey  + acc_t'(in_ey );
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            acc_valid <= '0;
        end
        else if ( cke ) begin
            acc_valid <= in_last && in_valid;
        end
    end

    assign out_gx2   = acc_gx2  ;
    assign out_gy2   = acc_gy2  ;
    assign out_gxy   = acc_gxy  ;
    assign out_ex    = acc_ex   ;
    assign out_ey    = acc_ey   ;
    assign out_valid = acc_valid;    

endmodule


`default_nettype wire


// end of file
