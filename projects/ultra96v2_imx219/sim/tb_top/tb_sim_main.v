// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuz 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_sim_main(
            input   wire    reset,
            input   wire    clk
        );
    
    ultra96v2_imx219
        i_top
            (
                .cam_clk_p      (),
                .cam_clk_n      (),
                .cam_data_p     (),
                .cam_data_n     ()
            );
    
endmodule


`default_nettype wire


// end of file
