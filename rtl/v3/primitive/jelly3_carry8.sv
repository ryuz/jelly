

// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_carry_chain
        #(
            parameter   int     DATA_BITS  = 7                       ,
            parameter   type    data_t     = logic [DATA_BITS-1:0]   ,
            parameter           DEVICE     = "RTL"                   ,
            parameter           SIMULATION = "false"                 ,
            parameter           DEBUG      = "false"                 
        )
        (
            input   var logic   reset       ,
            input   var logic   clk         ,
            input   var logic   cke         ,
            
            input   var logic   cin         ,
            input   var data_t  sin         ,
            input   var data_t  din         ,

            output  var data_t  dout        ,
            output  var logic   cout        
        );


    if ( DATA_BITS > 4 && DATA_BITS <= 8
            && (string'(DEVICE) == "ULTRASCALE"
            ||  string'(DEVICE) == "ULTRASCALE_PLUS"
            ||  string'(DEVICE) == "ULTRASCALE_PLUS_ES1"
            ||  string'(DEVICE) == "ULTRASCALE_PLUS_ES2" ) ) begin : xilinx
        logic           carry8_ci;
        logic   [7:0]   carry8_s;
        logic   [7:0]   carry8_di;
        logic   [7:0]   carry8_o;
        logic   [7:0]   carry8_co;
        CARRY8
                #(
                    .CARRY_TYPE ("SINGLE_CY8") 
                )
            u_carry8
                (
                    .CO         (carry8_co  ),
                    .O          (carry8_o   ),
                    .CI         (carry8_ci  ),
                    .CI_TOP     (1'b0       ),
                    .DI         (carry8_di  ),
                    .S          (carry8_s   )
                );
        assign carry8_ci = cin;
        assign carry8_s  = 8'(sin);
        assign carry8_di = 8'(din);
        assign dout = data_t'(carry8_o);
        assign cout = carry8_co[$bits(data_t)-1];
    end
    else begin : rtl
        always_comb begin
            automatic logic c;
            c = cin;
            for ( int i = 0; i < DATA_BITS; i++ ) begin
                dout[i] = c ^ sin[i];
                c = sin[i] ? c : din[i];
            end
            cout = c;
        end
    end

endmodule


`default_nettype wire


// end of file
