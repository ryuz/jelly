
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset   ,
            input   var logic   clk
        );

    int     cycle = 0;
    always_ff @(posedge clk) begin
        cycle <= cycle + 1;
        if ( cycle > 1000 ) begin
            $error("timeout");
        end
    end

    // target
    localparam  int     N            = 16                                       ;
    localparam  int     UNIT         = 2                                        ;
    localparam  int     S_DATA_BITS  = 8                                        ;
    localparam  type    s_data_t     = logic signed [S_DATA_BITS-1:0]           ;
    localparam  int     M_DATA_BITS  = $bits(s_data_t) + $clog2(N)              ;
    localparam  type    m_data_t     = logic signed [M_DATA_BITS-1:0]           ;
    localparam  int     USER_BITS    = M_DATA_BITS                              ;
    localparam  type    user_t       = m_data_t ; //logic [USER_BITS-1:0]                    ;
    localparam  int     LATENCY      = ($clog2(N)+$clog2(UNIT)-1)/$clog2(UNIT)  ;

    logic               cke     = 1'b1;

     logic      [N-1:0] s_en    ;
    s_data_t    [N-1:0] s_data  ;
    user_t              s_user  ;
    logic               s_valid ;

    m_data_t            m_data  ;
    user_t              m_user  ;
    logic               m_valid ;


    jelly3_sum_tree
            #(
                .N              (N              ),
                .UNIT           (UNIT           ),
                .USER_BITS      (USER_BITS      ),
                .user_t         (user_t         ),
                .S_DATA_BITS    (S_DATA_BITS    ),
                .s_data_t       (s_data_t       ),
                .M_DATA_BITS    (M_DATA_BITS    ),
                .m_data_t       (m_data_t       ),
                .LATENCY        (LATENCY        )
            )
        u_sum_tree
            (
                .reset  ,
                .clk    ,
                .cke    ,

                .s_en   ,
                .s_data ,
                .s_user ,
                .s_valid,

                .m_data ,
                .m_user ,
                .m_valid
            );
        
    // test
    always_ff @( posedge clk ) begin
        if ( reset ) begin
            for ( int i = 0; i < N; i++ ) begin
                s_en[i]   <= 1'b0;
                s_data[i] <= s_data_t'(-i);
            end
            s_valid <= '0;
        end
        else if ( cke ) begin
            for ( int i = 0; i < N; i++ ) begin
                s_en[i]   <= 1'($urandom_range(2));
                s_data[i] <= s_data[i] + 1;
            end
            s_valid <= 1'b1;
        end
    end

    always_comb begin
        s_user = '0;
        for ( int i = 0; i < N; ++i ) begin
            s_user += s_en[i] ? user_t'($signed(s_data[i])) : '0;
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
