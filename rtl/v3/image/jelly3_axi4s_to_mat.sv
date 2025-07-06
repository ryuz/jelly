// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4s_to_mat
        #(
            parameter   int     ROWS_BITS   = 9                         ,
            parameter   type    rows_t      = logic [ROWS_BITS-1:0]     ,
            parameter   int     COLS_BITS   = 10                        ,
            parameter   type    cols_t      = logic [COLS_BITS-1:0]     ,
            parameter   int     BLANK_BITS  = ROWS_BITS                 ,
            parameter   type    blank_t     = logic [BLANK_BITS-1:0]    ,
            parameter   bit     CKE_BUFG    = 0                         
        )
        (
            input   var rows_t      param_rows      ,
            input   var cols_t      param_cols      ,
            input   var blank_t     param_blank     ,
            
            input   var logic       almost_full     ,
            jelly3_axi4s_if.s       s_axi4s         ,
            
            output  var logic       out_cke         ,
            jelly3_mat_if.m         m_mat           
        );
    
    localparam  type user_t = logic [s_axi4s.USER_BITS-1:0];
    localparam  type data_t = logic [s_axi4s.DATA_BITS-1:0];

    // マトリックス用の信号に変換
    logic       wait_fs ;
    logic       blank   ;
    cols_t      x_count, x_next;
    rows_t      y_count, y_next;
    blank_t     b_count, b_next;

    always_comb x_next = x_count + 1'b1;
    always_comb y_next = y_count + 1'b1;
    always_comb b_next = b_count + 1'b1;
    
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            wait_fs <= 1'b1 ;
            blank   <= 1'b0 ;
            x_count <= '0   ;
            y_count <= '0   ;
            b_count <= '0   ;
        end
        else begin
            // frame start 受信でフラグを倒す
            if ( s_axi4s.aclken && s_axi4s.tvalid && s_axi4s.tready && s_axi4s.tuser[0] ) begin
                wait_fs <= 1'b0;
            end

            if ( !almost_full ) begin
                if ( !blank ) begin
                    // 通常のデータ区間
                    if ( s_axi4s.aclken && s_axi4s.tvalid && s_axi4s.tready && (!wait_fs || s_axi4s.tuser[0]) ) begin
                        x_count <= x_next;
                        if ( x_next == param_cols ) begin
                            x_count <= '0;
                            y_count <= y_next;
                            if ( y_next == param_rows ) begin
                                y_count <= '0;
                                if ( param_blank > 0 ) begin
                                    blank   <= 1'b1;
                                end
                                else begin
                                    wait_fs <= 1'b1;
                                end
                            end
                        end
                    end
                    b_count <= '0;
                end
                else begin
                    // balnking 挿入中
                    x_count <= x_next;
                    if ( x_next == param_cols ) begin
                        x_count <= '0;
                        b_count <= b_next;
                        if ( b_next == param_blank ) begin
                            blank   <= 1'b0;
                            wait_fs <= 1'b1;
                            b_count <= '0;
                        end
                    end
                    y_count <= '0;
                end
            end
        end
    end

    assign s_axi4s.tready = !almost_full && (!blank || (wait_fs && ! s_axi4s.tuser[0]));

    
    logic       mat_cke;
    always_ff @(posedge s_axi4s.aclk ) begin
        if ( ~s_axi4s.aresetn ) begin
            mat_cke <= 1'b0;
        end
        else begin
            mat_cke <= !almost_full && ((s_axi4s.aclken && s_axi4s.tvalid && (!wait_fs || s_axi4s.tuser[0])) || blank);
        end
    end

    always_ff @(posedge m_mat.clk) begin
        if ( m_mat.reset ) begin
            m_mat.row_first <='x;
            m_mat.row_last  <='x;
            m_mat.col_first <='x;
            m_mat.col_last  <='x;
            m_mat.de        <='x;
            m_mat.user      <='x;
            m_mat.data      <='x;
            m_mat.valid     <= 1'b0;
        end
        if ( !almost_full ) begin
            if ( s_axi4s.tvalid || blank ) begin
                m_mat.row_first <= !blank && y_count == '0;
                m_mat.row_last  <= !blank && y_next  == param_rows;
                m_mat.col_first <= x_count == '0;
                m_mat.col_last  <= x_next == param_cols;
                m_mat.de        <= !blank;
                m_mat.user      <= s_axi4s.tuser >> 1;
                m_mat.data      <= s_axi4s.tdata;
                m_mat.valid     <= 1'b1;
            end
        end
    end
    
    assign m_mat.rows = param_rows;
    assign m_mat.cols = param_cols;


    // 仕組み上 cke の fanout が大きくなるケースがあるのでBUFGを使えるようにしておく
    if ( CKE_BUFG ) begin
        BUFG
            u_bufg
                (
                    .I  (mat_cke    ),
                    .O  (out_cke    )
                );
    end
    else begin
        always_comb out_cke = mat_cke;
    end

endmodule


`default_nettype wire


// end of file
