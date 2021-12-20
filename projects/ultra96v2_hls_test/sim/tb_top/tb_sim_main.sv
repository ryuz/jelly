

`timescale 1ns / 1ps
`default_nettype none


module tb_sim_main();

    wire    [1:0]   led;

    ultra96v2_hls_test
        i_top
            (
                .led        (led)
            );
    
endmodule


`default_nettype wire


// end of file
