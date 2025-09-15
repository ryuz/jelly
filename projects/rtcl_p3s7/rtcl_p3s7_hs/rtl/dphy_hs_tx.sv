// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module dphy_hs_tx
        #(
            parameter   int     DATA_BITS   = 2*8                   ,
            parameter   type    data_t      = logic [DATA_BITS-1:0] 
        )
        (
            input   var logic       reset           ,
            input   var logic       clk             ,

            jelly3_axi4s_if.s       s_axi4s         ,

            output  var data_t      dphy_data       ,
            output  var logic       dphy_request    ,
            input   var logic       dphy_ready      
        );

    enum logic [1:0] {
        STATE_IDLE = 2'b00,
        STATE_HEAD = 2'b10,
        STATE_DATA = 2'b11
    } state_t;

    logic   last;
    always_ff @(posedge clk ) begin
        if ( reset ) begin
            dphy_data    <= '0  ;
            dphy_request <= 1'b0;
            last         <= 1'b0;
        end
        else begin
            last         <= 1'b0;
            if ( !dphy_request ) begin
                if ( !dphy_ready ) begin
                    // start
                    if ( s_axi4s.tvalid && s_axi4s.tuser[0] ) begin
                        dphy_data    <= data_t'(s_axi4s.tuser >> 1);
                        dphy_request <= 1'b1;
                    end
                end
            end
            else begin
                if ( dphy_ready ) begin
                    if ( last ) begin
                        // end
                        dphy_data    <= '0  ;
                        dphy_request <= 1'b0;
                    end
                    else begin
                        // payload
                        dphy_data    <= data_t'(s_axi4s.tdata);
                        dphy_request <= 1'b1;
                        last         <= s_axi4s.tlast;
                    end
                end
            end
        end
    end

    assign s_axi4s.tready = (!dphy_request && !(s_axi4s.tvalid && s_axi4s.tuser[0])) || (dphy_request && dphy_ready);

endmodule


`default_nettype wire


// end of file
