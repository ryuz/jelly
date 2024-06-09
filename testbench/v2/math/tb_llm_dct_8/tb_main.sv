
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire                        reset,
            input   wire                        clk
        );

    parameter   int                     DATA_WIDTH = 18;
    parameter   int                     DATA_Q     = 12;

    int cycle = 0;
    always_ff @( posedge clk ) begin
        cycle <= cycle + 1;
    end


    logic                       cke = 1'b1;

    

    logic                       start;
    logic                       ready;
    logic                       done;

    logic                       in_re;
    logic   [2:0]               in_addr;
    logic   [DATA_WIDTH-1:0]    in_rdata;

    logic                       out_we;
    logic   [2:0]               out_addr;
    logic   [DATA_WIDTH-1:0]    out_wdata;

    assign start = ready && (cycle > 200 && cycle < 1000);

    jelly2_llm_dct_8
            #(
                .DATA_WIDTH     (DATA_WIDTH ),
                .DATA_Q         (DATA_Q     )
            )
        u_llm_dct_8
            (
                .reset,
                .clk,
                .cke,

                .start,
                .ready,
                .done,

                .in_re,
                .in_addr,
                .in_rdata,

                .out_we,
                .out_addr,
                .out_wdata
            );


    logic   [7:0]   in_mem  [0:7];
    initial begin
        in_mem[0] = 145;
        in_mem[1] = 49;
        in_mem[2] = 137;
        in_mem[3] = 62;
        in_mem[4] = 71;
        in_mem[5] = 92;
        in_mem[6] = 153;
        in_mem[7] = 74;
    end

//    assign start = 1'b1;

    always_ff @(posedge clk) begin
        in_rdata <= DATA_WIDTH'(in_mem[in_addr]) << (DATA_Q - 8);
    end



endmodule


`default_nettype wire


// end of file
