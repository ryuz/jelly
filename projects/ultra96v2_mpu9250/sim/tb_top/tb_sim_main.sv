

`timescale 1ns / 1ps
`default_nettype none


module tb_sim_main();

    wire    [1:0]   led;
    wire            imu_sck;
    wire            imu_sda;

    ultra96v2_mpu9250
        i_top
            (
                .led        (led),
                .imu_sck    (imu_sck),
                .imu_sda    (imu_sda)
            );
    
endmodule


//`default_nettype wire


// end of file
