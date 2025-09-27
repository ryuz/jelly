// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module axi4s_to_dphy
        #(
            parameter   int     DATA_BITS   = 2*8                   ,
            parameter   type    data_t      = logic [DATA_BITS-1:0] 
        )
        (
            jelly3_axi4s_if.s       s_axi4s         ,

            output  var data_t      dphy_data       ,
            output  var logic       dphy_request    ,
            input   var logic       dphy_ready      
        );


//    logic   busy;
//  logic   last;
    always_ff @(posedge s_axi4s.aclk ) begin
        if ( !s_axi4s.aresetn ) begin
//          busy         <= 1'b0    ;
//          dphy_data    <= '0      ;
            dphy_request <= 1'b0    ;
//          last         <= 1'b0    ;
        end
        else begin
            if ( !dphy_request && !dphy_ready ) begin
                if ( s_axi4s.tvalid && s_axi4s.tuser[0] ) begin
                    dphy_request <= 1'b1;   // start
                end
            end
            else begin
                if ( s_axi4s.tvalid && s_axi4s.tready && s_axi4s.tlast ) begin
                    dphy_request <= 1'b0;   // end
                end
            end
        end
    end

    assign s_axi4s.tready = dphy_request && dphy_ready || (!dphy_request && !s_axi4s.tuser[0]);

    assign dphy_data = dphy_request ? s_axi4s.tdata : '0;

endmodule


`default_nettype wire


// end of file
