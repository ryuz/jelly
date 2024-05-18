// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2016 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// 16bit multiplexer
module jelly3_multiplexer16
        #(
            parameter   DEVICE = "RTL"
        )
        (
            input   var logic   [3:0]   sel,
            input   var logic   [15:0]  din,
            output  var logic           dout
        );

    if ( string'(DEVICE) == "SPARTAN6"
            || string'(DEVICE) == "VIRTEX6"
            || string'(DEVICE) == "7SERIES"
            || string'(DEVICE) == "ULTRASCALE"
            || string'(DEVICE) == "ULTRASCALE_PLUS"
            || string'(DEVICE) == "ULTRASCALE_PLUS_ES1"
            || string'(DEVICE) == "ULTRASCALE_PLUS_ES2") begin : xilinx    
        
        // XILINX XAPP522
        logic   [3:0]   l;
        
        LUT6
                #(
                    .INIT(64'hFF00F0F0CCCCAAAA)
                )
            u_lut6_0
                (
                    .O      (l[0]   ),
                    
                    .I0     (din[0] ),
                    .I1     (din[1] ),
                    .I2     (din[2] ),
                    .I3     (din[3] ),
                    
                    .I4     (sel[0] ),
                    .I5     (sel[1] )
                );
        
        LUT6
                #(
                    .INIT(64'hFF00F0F0CCCCAAAA)
                )
            u_lut6_1
                (
                    .O      (l[1]   ),
                    
                    .I0     (din[4] ),
                    .I1     (din[5] ),
                    .I2     (din[6] ),
                    .I3     (din[7] ),
                    
                    .I4     (sel[0] ),
                    .I5     (sel[1] )
                );
        
        LUT6
                #(
                    .INIT(64'hFF00F0F0CCCCAAAA)
                )
            u_lut6_2
                (
                    .O      (l[2]   ),
                    
                    .I0     (din[8] ),
                    .I1     (din[9] ),
                    .I2     (din[10]),
                    .I3     (din[11]),
                    
                    .I4     (sel[0] ),
                    .I5     (sel[1] )
                );
        
        LUT6
                #(
                    .INIT(64'hFF00F0F0CCCCAAAA)
                )
            u_lut6_3
                (
                    .O      (l[3]   ),
                    
                    .I0     (din[12]),
                    .I1     (din[13]),
                    .I2     (din[14]),
                    .I3     (din[15]),
                    
                    .I4     (sel[0] ),
                    .I5     (sel[1] )
                );
        
        
        logic   [1:0]   m;
        
        MUXF7
            u_mux7_0
                (
                    .O      (m[0]   ),
                    
                    .I0     (l[0]   ),
                    .I1     (l[1]   ),
                    
                    .S      (sel[2] )
                );
        
        MUXF7
            u_mux7_1
                (
                    .O      (m[1])  ,
                    
                    .I0     (l[2]   ),
                    .I1     (l[3]   ),
                    
                    .S      (sel[2] )
                );
        
        
        MUXF8
            u_mux8
                (
                    .O      (dout),
                    
                    .I0     (m[0]),
                    .I1     (m[1]),
                    
                    .S      (sel[3] )
                );
        
    end
    else  begin : rtl
        assign dout = din[sel];
    end
    
    
endmodule


`default_nettype wire


// end of file
