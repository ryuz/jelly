
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

    // 期待値
    logic   signed  [17:0]   exp_mem  [0:7][0:7] = {
        {11086, -1181,  -411,   531, -1551,  -283,   387,   510},
        { -291,  1712,   519,  -167,   404,  1029,   -56,   772},
        { -353,   270,   -48,   640,   217,   455,    21,   687},
        { 1150, -1403,   292,   -92,   191,  1177,   513,   380},
        {  324,   104,   408,  -321,  -468,   -53,   892,   210},
        {  538,   157,   352,   -62,   -56,   -64,  -862,  -169},
        {  255,  -121,   432,   463,  -605,   375,   116,  -589},
        {  248,   309,   198,    -7,   208,    25,   337,   -53}
    };

//  assign start = 1'b1;

    always_ff @(posedge clk) begin
        in_rdata <= DATA_WIDTH'(in_mem[in_addry][in_addrx]) << (DATA_Q - 8);
    end

    logic      signed   [17:0]   out_mem  [0:7][0:7];
    always_ff @(posedge clk) begin
        if ( out_we ) begin
            out_mem[out_addry][out_addrx] <= out_wdata;
        end

        if ( cycle == 1000 ) begin
            for ( int y = 0; y < 8; ++y ) begin
                for ( int x = 0; x < 8; ++x ) begin
                    $write("%d ", out_mem[y][x]);
                    if ( out_mem[y][x] != exp_mem[y][x] ) begin
                        $write("NG! ");
                    end
                end
                $display("");
            end
        end
    end

endmodule

`default_nettype wire

// end of file
