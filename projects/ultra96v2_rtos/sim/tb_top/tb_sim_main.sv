

`timescale 1ns / 1ps
`default_nettype none


module tb_sim_main();

    logic   [1:0]   led;
    
    ultra96v2_rtos
        i_top
            (
                .*
            );
    
endmodule


//`default_nettype wire


// end of file
