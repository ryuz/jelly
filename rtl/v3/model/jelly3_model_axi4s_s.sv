// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_model_axi4s_s
        #(
            parameter   int     BUSY_RATE        = 0                    ,
            parameter   int     RANDOM_SEED      = 0                    
        )
        (
            jelly3_axi4s_if.s   s_axi4s         
        );
    
    integer         rand_seed = RANDOM_SEED;
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            s_axi4s.tready <= 1'b0;
        end
        else if ( s_axi4s.aclken ) begin
            int rand_val;
            rand_val = int'({$random(rand_seed)} % 100); 
            s_axi4s.tready <= (rand_val >= BUSY_RATE);
        end
    end

endmodule

`default_nettype wire

// end of file
