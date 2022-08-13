
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire                        reset,
            input   wire                        clk
        );

    int     cycle = 0;
    always_ff @(posedge clk) begin
        cycle <= cycle + 1;
        if ( cycle > 1000 ) begin
            $error("timeout");
        end
    end

    // target
    localparam  int         N            = 3;
    localparam  int         S_DATA_WIDTH = 8;
    localparam  int         M_DATA_WIDTH = S_DATA_WIDTH + $clog2(N);
    localparam  int         USER_WIDTH   = M_DATA_WIDTH;
    localparam  bit         SIGNED       = 1;
    localparam  int         LATENCY      = 0; // $clog2(N) + 20;
    localparam  int         USER_BITS    = USER_WIDTH > 0 ? USER_WIDTH : 1;

    logic                               cke = 1'b1;
    always_ff @(posedge clk) cke <= 1'($random());

    logic   signed  [USER_BITS-1:0]             s_user;
    logic   signed  [N-1:0][S_DATA_WIDTH-1:0]   s_data;
    logic                                       s_valid;
    
    logic   signed  [USER_BITS-1:0]             m_user;
    logic   signed  [M_DATA_WIDTH-1:0]          m_data;
    logic                                       m_valid;

    jelly2_sum_tree
            #(
                .N              (N),
                .USER_WIDTH     (USER_WIDTH),
                .S_DATA_WIDTH   (S_DATA_WIDTH),
                .M_DATA_WIDTH   (M_DATA_WIDTH),
                .SIGNED         (SIGNED),
                .LATENCY        (LATENCY)
            )
        i_sum_tree
            (
                .reset,
                .clk,
                .cke,

                .s_user,
                .s_data,
                .s_valid,

                .m_user,
                .m_data,
                .m_valid
            );
        
    // test
    always_ff @( posedge clk ) begin
        if ( reset ) begin
            for ( int i = 0; i < N; ++i ) begin
                s_data[i]  <= S_DATA_WIDTH'(-i);
            end
            s_valid <= '0;
        end
        else if ( cke ) begin
            for ( int i = 0; i < N; ++i ) begin
                s_data[i] <= s_data[i] + 1;
            end
            s_valid <= 1'b1;
        end
    end

    always_comb begin
        s_user = '0;
        for ( int i = 0; i < N; ++i ) begin
            s_user += M_DATA_WIDTH'($signed(s_data[i]));
        end
    end

    logic   err;
    int     ok_count;
    always_ff @( posedge clk ) begin
        if ( reset ) begin
            ok_count <= 0;
        end
        else if ( cke ) begin
            err <= 1'b0;
            if ( m_valid ) begin
                if ( m_data != m_user ) begin
                    $error("error!");
//                  $finish(1);
                    err <= 1'b1;
                end
                else begin
                    ok_count <= ok_count + 1;
   //               $display("OK");

                    if ( ok_count > 100 ) begin
                        $display("ALL-OK");
                        $finish();
                    end
                end
            end
        end
    end

endmodule


`default_nettype wire


// end of file
