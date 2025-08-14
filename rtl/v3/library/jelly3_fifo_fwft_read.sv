// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// FIFO FWFT(First-Word Fall-Through mode) Read
module jelly3_fifo_fwft_read
        #(
            parameter   int     PTR_BITS     = 5                    ,
            parameter   int     FIFO_SIZE    = 2 ** PTR_BITS        ,
            parameter   int     SIZE_BITS    = $clog2(FIFO_SIZE + 1),
            parameter   type    size_t       = logic [SIZE_BITS-1:0],
            parameter   int     DATA_BITS    = 8                    ,
            parameter   type    data_t       = logic [DATA_BITS-1:0],
            parameter   bit     DOUT_REG     = 1'b0                 ,
            parameter           DEVICE       = "RTL"                ,
            parameter           SIMULATION   = "false"              ,
            parameter           DEBUG        = "false"              
        )
        (
            input   var logic   reset           ,
            input   var logic   clk             ,
            input   var logic   cke             ,

            // FIFO
            output  var logic   rd_en           ,
            output  var logic   rd_regcke       ,
            input   var data_t  rd_data         ,
            input   var logic   rd_empty        ,
            input   var size_t  rd_data_size    ,

            // master port
            output  var data_t  m_data          ,
            output  var logic   m_valid         ,
            input   var logic   m_ready         ,
            output  var size_t  m_data_size     
        );
    
    logic   st0_valid       ;
    logic   st0_ready       ;

    logic   st1_valid_next  ;
    logic   st1_valid       ;
    logic   st1_ready       ;

    logic   st2_valid_next  ;
    logic   st2_valid       ;
    logic   st2_ready       ;

    // stage 0
    assign st0_valid = !rd_empty;

    // stage 1
    if ( DOUT_REG ) begin : dout_reg
        always_comb begin
            st1_valid_next = st1_valid;
            if ( !st1_valid || st1_ready ) begin
                st1_valid_next = st0_valid;
            end
        end
        always_ff @(posedge clk) begin
            if ( reset ) begin
                st1_valid <= 1'b0;
            end
            else if ( cke ) begin
                st1_valid <= st1_valid_next;
            end
        end
        assign st0_ready = (!st1_valid || st1_ready);
    end
    else begin : dout_bypass
        assign st1_valid_next = 1'b0        ;
        assign st1_valid      = st0_valid   ;
        assign st0_ready      = st1_ready   ;
    end

    // stage 2
    always_comb begin
        st2_valid_next = st2_valid;
        if ( !st2_valid || st2_ready ) begin
            st2_valid_next = st1_valid;
        end
    end
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st2_valid <= 1'b0;
        end
        else if ( cke ) begin
            st2_valid <= st2_valid_next;
        end
    end
    assign st1_ready = (!st2_valid || st2_ready);


    assign rd_en     = cke && st0_valid && st0_ready;
    assign rd_regcke = cke && st1_valid && st1_ready;

    assign m_data    = rd_data;
    assign m_valid   = st2_valid;
    assign st2_ready = m_ready;

    // data_size (連続して読める状態にある個数だけカウント)
    size_t  data_size_next;
    always_comb begin
        if ( !st2_valid_next ) begin
            data_size_next = '0;    // 出力ステージにデータが無い場合は0
        end
        else begin
            data_size_next = 1;
            if ( !DOUT_REG || st1_valid_next ) begin
                data_size_next += size_t'(DOUT_REG);
                if ( st0_valid ) begin
                    data_size_next += (rd_data_size - 1); // 出力パイプラインが充填ならFIFOのデータサイズを加算
                end
            end
        end
    end
    always_ff @(posedge clk) begin
        if ( reset ) begin
            m_data_size <= '0;
        end
        else if ( cke ) begin
            if ( !m_valid || m_ready ) begin
                m_data_size <= data_size_next;
            end
        end
    end

endmodule

`default_nettype wire

// end of file
