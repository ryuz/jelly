
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire                        reset,
            input   wire                        clk
        );

    int     cycle = 0;
    always_ff @(posedge clk)    cycle <= cycle + 1;


    localparam  int     N           = 8;
    localparam  int     ADD_WIDTH   = 48;
    localparam  int     COEFF_WIDTH = 18;
    localparam  int     DATA_WIDTH  = 18;

    logic                                       cke = 1'b1;

    logic   signed  [N-1:0][COEFF_WIDTH-1:0]    param_coeff;

    logic   signed         [ADD_WIDTH-1:0]      s_add   = '0;
    logic   signed  [N-1:0][DATA_WIDTH-1:0]     s_data  = '0;
    logic                                       s_valid;

    logic   signed         [ADD_WIDTH-1:0]      m_data;
    logic                                       m_valid;

    jelly2_mul_add_array
            #(
                .N              (N),
                .ADD_WIDTH      (ADD_WIDTH),
                .COEFF_WIDTH    (COEFF_WIDTH),
                .DATA_WIDTH     (DATA_WIDTH)
            )
        i_mul_add_array
            (
                .reset,
                .clk,
                .cke,

                .param_coeff,

                .s_add          (s_valid ? s_add  :'x),
                .s_data         (s_valid ? s_data :'x),
                .s_valid        (s_valid),

                .m_data,
                .m_valid
            );

    assign s_valid = (cycle == 200);

    initial begin
        for ( int i = 0; i < N; ++i ) begin
            param_coeff[i] = COEFF_WIDTH'(i);
            s_data[i]      = DATA_WIDTH'(i);
        end
    end

endmodule


`default_nettype wire


// end of file
