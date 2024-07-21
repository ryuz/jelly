// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_phase_match
        #(
            parameter   int                     THREADS     = 4                                 ,
            parameter   int                     ID_BITS     = THREADS > 1 ? $clog2(THREADS) : 1 ,
            parameter   type                    id_t        = logic         [ID_BITS-1:0]       ,
            parameter   int                     PHASE_BITS  = 1                                 ,
            parameter   type                    phase_t     = logic [PHASE_BITS-1:0]            ,
            parameter                           DEVICE      = "RTL"                             ,
            parameter                           SIMULATION  = "false"                           ,
            parameter                           DEBUG       = "false"                   
        )
        (
            input   var phase_t [THREADS-1:0]   in_phase_table  ,
            input   var phase_t                 in_id           ,
            input   var logic   [THREADS-1:0]   in_id_mask      ,
            input   var phase_t                 in_phase        ,
            output  var logic                   out_enable      
        );

    if ( $bits(phase_t) == 1 && THREADS > 4
          && ( string'(DEVICE) == "ULTRASCALE"
            || string'(DEVICE) == "ULTRASCALE_PLUS"
            || string'(DEVICE) == "ULTRASCALE_PLUS_ES1"
            || string'(DEVICE) == "ULTRASCALE_PLUS_ES2") ) begin : xilinx

        localparam int  CC_BITS = (THREADS + 1) / 2;

        logic                    cin     ;
        logic   [CC_BITS-1:0]    sin     ;
        logic   [CC_BITS-1:0]    din     ;
        logic   [CC_BITS-1:0]    dout    ;
        logic   [CC_BITS-1:0]    cout    ;

        jelly3_carry_chain
                #(
                    .DATA_BITS      (CC_BITS    ),
                    .DEVICE         (DEVICE     ),
                    .SIMULATION     (SIMULATION ),
                    .DEBUG          (DEBUG      )
                )
            u_jelly3_carry_chain
                (
                    .cin         ,
                    .sin         ,
                    .din         ,
                    .dout        ,
                    .cout        
                );
        
        always_comb begin
            cin = 1'b1;
            sin = '1;
            din = '0;
            for ( int i = 0; i < THREADS; i++ ) begin
                if ( in_id_mask[i] && (in_phase != in_phase_table[i]) ) begin
                    sin[i/2] = 1'b0;
                end
            end
        end
        assign out_enable = cout[CC_BITS-1];
    end
    else if ( THREADS > 4 ) begin : rtl_mask
        always_comb begin
            out_enable = 1'b1;
            for ( int i = 0; i < THREADS; i++ ) begin
                if ( in_id_mask[i] && (in_phase != in_phase_table[i]) ) begin
                    out_enable = 1'b0;
                end
            end
        end
    end
    else begin : rtl
        assign out_enable = (in_phase_table[in_id] == in_phase);
    end

endmodule


`default_nettype wire


// End of file
