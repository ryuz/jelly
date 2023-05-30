// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//  Ultra96V2 Real-Time OS
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module kv260_speed_test
            (
                output  var logic           fan_en
            );
    
    
    
    design_1
        i_design_1
            (
                .fan_en             (fan_en)
            );
    
endmodule



`default_nettype wire


// end of file
