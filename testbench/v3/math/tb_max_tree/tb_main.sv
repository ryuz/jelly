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
    localparam  int     DATA_BITS    = 8                                        ;
    localparam  type    data_t       = logic signed [DATA_BITS-1:0]             ;
    localparam  int     USER_BITS    = DATA_BITS                                ;
    localparam  type    user_t       = data_t                                   ;
    localparam  int     LATENCY      = ($clog2(N)+$clog2(UNIT)-1)/$clog2(UNIT)  ;

    logic               cke     = 1'b1;

    logic      [N-1:0]  s_en    ;
    data_t     [N-1:0]  s_data  ;
    user_t              s_user  ;
    logic               s_valid ;

    data_t              m_data  ;
    user_t              m_user  ;
    logic               m_valid ;


    jelly3_max_tree
            #(
                .N              (N              ),
                .UNIT           (UNIT           ),
                .USER_BITS      (USER_BITS      ),
                .user_t         (user_t         ),
                .DATA_BITS      (DATA_BITS      ),
                .data_t         (data_t         ),
                .LATENCY        (LATENCY        )
            )
        u_max_tree
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

    // stimulus: randomize en and cycle through values
    always_ff @( posedge clk ) begin
        if ( reset ) begin
            for ( int i = 0; i < N; i++ ) begin
                s_en[i]   <= 1'b0;
                s_data[i] <= data_t'(-i);
            end
            s_valid <= '0;
        end
        else if ( cke ) begin
            for ( int i = 0; i < N; i++ ) begin
                s_en[i]   <= 1'($urandom_range(1));
                s_data[i] <= s_data[i] + 1;
            end
            s_valid <= 1'b1;
        end
    end

    // expected value: combinational max of enabled inputs
    localparam  data_t  MIN_VALUE = (data_t'(1) << (DATA_BITS - 1));

    always_comb begin
        s_user = MIN_VALUE;
        for ( int i = 0; i < N; ++i ) begin
            if ( s_en[i] ) begin
                if ( $signed(s_data[i]) > $signed(s_user) ) begin
                    s_user = s_data[i];
                end
            end
        end
    end

    // checker
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
                    $display("m_data:%d expected:%d", m_data, m_user);
                    $error("error! got=%0d expected=%0d", $signed(m_data), $signed(m_user));
                    err <= 1'b1;
                end
                else begin
                    ok_count <= ok_count + 1;
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
