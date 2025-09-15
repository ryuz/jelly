
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset0  ,
            input   var logic   clk0    ,
            input   var logic   reset1  ,
            input   var logic   clk1
        );
    

    // ---------------------------------
    //  DUT
    // ---------------------------------

    logic   cke0 = 1'b1;
    logic   cke1 = 1'b1;

    logic   src_pulse;
    logic   pulse0;
    jelly3_pulse_async
            #(
                .ASYNC      (1          ),
                .SYNC_FF    (2          )
            )
        u_pulse_async_0
            (
                .s_reset    (reset0     ),
                .s_clk      (clk0       ),
                .s_cke      (cke0       ),
                .s_pulse    (src_pulse  ),
                
                .m_reset    (reset1     ),
                .m_clk      (clk1       ),
                .m_cke      (cke1       ),
                .m_pulse    (pulse0     )
            );

    logic   pulse1;
    jelly3_pulse_async
            #(
                .ASYNC      (1          ),
                .SYNC_FF    (3          )
            )
        u_pulse_async_1
            (
                .s_reset    (reset1     ),
                .s_clk      (clk1       ),
                .s_cke      (cke1       ),
                .s_pulse    (pulse0     ),
                
                .m_reset    (reset0     ),
                .m_clk      (clk0       ),
                .m_cke      (cke0       ),
                .m_pulse    (pulse1     )
            );

    logic   pulse2;
    jelly3_pulse_async
            #(
                .ASYNC      (0          ),
                .SYNC_FF    (3          )
            )
        u_pulse_async_2
            (
                .s_reset    (reset1     ),
                .s_clk      (clk1       ),
                .s_cke      (cke1       ),
                .s_pulse    (pulse1     ),
                
                .m_reset    (reset1     ),
                .m_clk      (clk1       ),
                .m_cke      (cke1       ),
                .m_pulse    (pulse2     )
            );


    // test
    int count;
    always_ff @(posedge clk0) begin
        if ( reset0 ) begin
            count     <= 0;
            src_pulse <= 1'b0;
        end
        else if ( cke0 ) begin
            count     <= count + 1;
            src_pulse <= count % 13 == 0;
        end
    end

    
endmodule


`default_nettype wire


// end of file
