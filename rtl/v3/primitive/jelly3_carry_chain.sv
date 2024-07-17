// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_carry_chain
        #(
            parameter   int     DATA_BITS  = 8                       ,
            parameter   type    data_t     = logic [DATA_BITS-1:0]   ,
            parameter           DEVICE     = "RTL"                   ,
            parameter           SIMULATION = "false"                 ,
            parameter           DEBUG      = "false"                 
        )
        (
            input   var logic   cin         ,
            input   var data_t  sin         ,
            input   var data_t  din         ,

            output  var data_t  dout        ,
            output  var data_t  cout        
        );


    if (       string'(DEVICE) == "ULTRASCALE"
            || string'(DEVICE) == "ULTRASCALE_PLUS"
            || string'(DEVICE) == "ULTRASCALE_PLUS_ES1"
            || string'(DEVICE) == "ULTRASCALE_PLUS_ES2" ) begin : xilinx
        
        localparam  int     CARRY8_N    = ($bits(data_t) + 7) / 8;
        localparam  int     CARRY8_BITS = CARRY8_N * 8;

        logic   [CARRY8_N-1:0]      carry8_ci;
        logic   [CARRY8_N*8-1:0]    carry8_s;
        logic   [CARRY8_N*8-1:0]    carry8_di;
        logic   [CARRY8_N*8-1:0]    carry8_o;
        logic   [CARRY8_N*8-1:0]    carry8_co;
        for ( genvar i = 0; i < CARRY8_N; i++ ) begin : carry8
            CARRY8
                    #(
                        .CARRY_TYPE ("SINGLE_CY8") 
                    )
                u_carry8
                    (
                        .CO         (carry8_co[i*8 +: 8]),
                        .O          (carry8_o [i*8 +: 8]),
                        .CI         (carry8_ci[i]       ),
                        .CI_TOP     (1'b0               ),
                        .DI         (carry8_di[i*8 +: 8]),
                        .S          (carry8_s [i*8 +: 8])
                    );
            assign carry8_ci[i] = (i == 0 ? cin : carry8_co[i*8 - 1]);
        end

        assign carry8_s  = CARRY8_BITS'(sin);
        assign carry8_di = CARRY8_BITS'(din);
        assign dout = data_t'(carry8_o );
        assign cout = data_t'(carry8_co);
    end
    else begin : rtl
        always_comb begin
            automatic logic c = cin;
            for ( int i = 0; i < DATA_BITS; i++ ) begin
                dout[i] = c ^ sin[i];
                c = sin[i] ? c : din[i];
                cout[i] = c;
            end
        end
    end

endmodule


`default_nettype wire


// end of file
