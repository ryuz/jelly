
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
    logic   [2:0]               in_addrx;
    logic   [2:0]               in_addry;
    logic   [DATA_WIDTH-1:0]    in_rdata;

    logic                       out_we;
    logic   [2:0]               out_addrx;
    logic   [2:0]               out_addry;
    logic   [DATA_WIDTH-1:0]    out_wdata;

//    assign start = ready && (cycle > 200 && cycle < 1000);
    assign start = ready && (cycle == 200);

    jelly2_llm_dct_8x8
            #(
                .DATA_WIDTH     (DATA_WIDTH ),
                .DATA_Q         (DATA_Q     )
            )
        u_llm_dct_8x8
            (
                .reset,
                .clk,
                .cke,

                .start,
                .ready,
                .done,

                .in_re,
                .in_addrx,
                .in_addry,
                .in_rdata,

                .out_we,
                .out_addrx,
                .out_addry,
                .out_wdata
            );


    logic   [7:0]   in_mem  [0:7][0:7] = {
        {8'h91, 8'h31, 8'h89, 8'h3e, 8'h47, 8'h5c, 8'h99, 8'h4a },
        {8'h4d, 8'h2e, 8'h62, 8'h3c, 8'h6c, 8'h31, 8'h48, 8'h1e },
        {8'h57, 8'h84, 8'h48, 8'h43, 8'h43, 8'h59, 8'h46, 8'h23 },
        {8'h2b, 8'h86, 8'h67, 8'h3d, 8'h53, 8'h5d, 8'h59, 8'h54 },
        {8'h39, 8'h38, 8'h89, 8'h42, 8'h52, 8'h93, 8'h62, 8'h86 },
        {8'h21, 8'h39, 8'h47, 8'h54, 8'h58, 8'hac, 8'ha7, 8'h78 },
        {8'h24, 8'h5a, 8'h3f, 8'h50, 8'h87, 8'h71, 8'h78, 8'h67 },
        {8'h1d, 8'h54, 8'h53, 8'h19, 8'h5e, 8'h98, 8'h48, 8'h40 }
    };

//    assign start = 1'b1;

    always_ff @(posedge clk) begin
        in_rdata <= DATA_WIDTH'(in_mem[in_addry][in_addrx]) << (DATA_Q - 8);
    end




endmodule


`default_nettype wire


// end of file
