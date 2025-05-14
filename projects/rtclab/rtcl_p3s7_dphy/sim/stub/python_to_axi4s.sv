
`timescale 1ns / 1ps
`default_nettype none


module python_to_axi4s
        (
            input   var logic   [3:0][9:0]  s_data      ,
            input   var logic        [9:0]  s_sync      ,
            input   var logic               s_valid     ,

            jelly3_axi4s_if.m               m_axi4s
        );

    logic enable;
    initial begin
        enable = 0;
        #1000
        enable = 1;
    end

    jelly3_model_axi4s_m
            #(
                .COMPONENTS     (4      ),
                .DATA_BITS      (10     ),
                .IMG_WIDTH      (640/4  ),
                .IMG_HEIGHT     (480    ),
                .H_BLANK        (32     ),
                .V_BLANK        (16     ),
                .X_BITS         (32     ),
                .BUSY_RATE      (60     ),
                .RANDOM_SEED    (0      ),
                .ENDIAN         (0      )
            )
        u_model_axi4s_m
            (
                .enable         (enable ),
                .busy           (       ),
                .m_axi4s        (m_axi4s),
                .out_x          (       ),
                .out_y          (       ),
                .out_f          (       )
            );

endmodule

`default_nettype wire

// end of file
