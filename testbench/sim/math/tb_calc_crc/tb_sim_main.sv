
`timescale 1ns / 1ps
`default_nettype none


module tb_sim_main
        (
            input   wire                        reset,
            input   wire                        clk
        );

    localparam                          DATA_WIDTH = 8;
    localparam                          CRC_WIDTH  = 32;
    localparam   bit    [CRC_WIDTH-1:0] POLY_REPS  = 32'h04C11DB7; // 32'hEDB88320,  // Polynomial representations
    localparam   bit                    REVERSED   = 0;

    logic                        cke = 1;

    logic                        in_update;
    logic    [DATA_WIDTH-1:0]    in_data;
    logic                        in_valid;
    
    logic    [CRC_WIDTH-1:0]     out_crc;


    // CRC
    jelly2_calc_crc
            #(
                .DATA_WIDTH     (DATA_WIDTH),
                .CRC_WIDTH      (CRC_WIDTH),
                .POLY_REPS      (POLY_REPS),
                .REVERSED       (REVERSED)
            )
        i_calc_crc
            (
                .reset,
                .clk,
                .cke,

                .in_update,
                .in_data,
                .in_valid,

                .out_crc
            );



    typedef  struct packed {
        bit             valid;
        logic           update;
        logic [7:0]     data;
    } test_data_t;


    localparam TEST_SIZE = 14;

    test_data_t test_table [0:TEST_SIZE-1];

    initial begin
        test_table[0]  = {1'b0, 1'bx, 8'hxx};
        test_table[1]  = {1'b1, 1'b0, 8'h31};
        test_table[2]  = {1'b1, 1'b1, 8'h32};
        test_table[3]  = {1'b1, 1'b1, 8'h33};
        test_table[4]  = {1'b1, 1'b1, 8'h34};
        test_table[5]  = {1'b0, 1'bx, 8'hxx};
        test_table[6]  = {1'b1, 1'b1, 8'h35};
        test_table[7]  = {1'b1, 1'b1, 8'h36};
        test_table[8]  = {1'b1, 1'b1, 8'h37};
        test_table[9]  = {1'b1, 1'b1, 8'h38};
        test_table[10] = {1'b1, 1'b1, 8'h39};
        test_table[11] = {1'b1, 1'b0, 8'ha5};
        test_table[12] = {1'b1, 1'b1, 8'h5a};
        test_table[13] = {1'b0, 1'bx, 8'hxx};
    end


    int         cycle = 0;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            cycle <= 0;
        end
        else if ( cke ) begin
            cycle <= cycle + 1;
            if ( cycle >= TEST_SIZE-1 ) begin
                $finish();
            end
        end
    end

    assign in_update = test_table[cycle].update;
    assign in_data   = test_table[cycle].data;
    assign in_valid  = test_table[cycle].valid;


endmodule


`default_nettype wire


// end of file
