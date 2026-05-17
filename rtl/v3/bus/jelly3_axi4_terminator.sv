// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4_terminator
    #(
        parameter   READ_VALUE = '0
    )
    (
        jelly3_axi4_if.s    s_axi4
    );

    wire logic   reset = ~s_axi4.aresetn;
    wire logic   clk   = s_axi4.aclk;
    wire logic   cke   = s_axi4.aclken;

    localparam type id_t   = logic [s_axi4.ID_BITS  -1:0];
    localparam type len_t  = logic [s_axi4.LEN_BITS -1:0];
    localparam type data_t = logic [s_axi4.DATA_BITS-1:0];


    // -------------------------------------------------------------------------
    //  Write response (accept one burst, consume all W beats, then return B)
    // -------------------------------------------------------------------------
    logic   w_busy;
    id_t    w_id;
    len_t   w_len;

    always_ff @(posedge clk) begin
        if (reset) begin
            w_busy        <= 1'b0;
            w_id          <= 'x;
            w_len         <= 'x;
            s_axi4.bvalid <= 1'b0;
            s_axi4.bid    <= 'x;
        end
        else if (cke) begin
            if (s_axi4.bvalid && s_axi4.bready) begin
                s_axi4.bvalid <= 1'b0;
            end

            if (s_axi4.awvalid && s_axi4.awready) begin
                w_busy <= 1'b1;
                w_id   <= s_axi4.awid;
                w_len  <= s_axi4.awlen;
            end

            if (s_axi4.wvalid && s_axi4.wready) begin
                if (w_len == '0) begin
                    w_busy        <= 1'b0;
                    s_axi4.bvalid <= 1'b1;
                    s_axi4.bid    <= w_id;
                end
                else begin
                    w_len <= w_len - len_t'(1);
                end
            end
        end
    end

    assign s_axi4.awready = !w_busy && !(s_axi4.bvalid && !s_axi4.bready);
    assign s_axi4.wready  = w_busy;
    assign s_axi4.bresp   = '0;
    assign s_axi4.buser   = '0;


    // -------------------------------------------------------------------------
    //  Read response (accept one burst and return fixed value beats)
    // -------------------------------------------------------------------------
    logic   r_busy;
    id_t    r_id;
    len_t   r_len;

    always_ff @(posedge clk) begin
        if (reset) begin
            r_busy        <= 1'b0;
            r_id          <= 'x;
            r_len         <= 'x;
            s_axi4.rvalid <= 1'b0;
        end
        else if (cke) begin
            if (s_axi4.arvalid && s_axi4.arready) begin
                r_busy        <= 1'b1;
                r_id          <= s_axi4.arid;
                r_len         <= s_axi4.arlen;
                s_axi4.rvalid <= 1'b1;
            end
            else if (s_axi4.rvalid && s_axi4.rready) begin
                if (r_len == '0) begin
                    r_busy        <= 1'b0;
                    s_axi4.rvalid <= 1'b0;
                end
                else begin
                    r_len <= r_len - len_t'(1);
                end
            end
        end
    end

    assign s_axi4.arready = !r_busy;
    assign s_axi4.rid     = r_id;
    assign s_axi4.rdata   = data_t'(READ_VALUE);
    assign s_axi4.rresp   = '0;
    assign s_axi4.rlast   = (r_len == '0);
    assign s_axi4.ruser   = '0;

endmodule


`default_nettype wire


// end of file
