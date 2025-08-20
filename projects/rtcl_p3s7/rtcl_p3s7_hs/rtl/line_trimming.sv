// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------

`timescale 1ns / 1ps
`default_nettype none


module line_trimming
        #(
            parameter   int     X_BITS = 11                 ,
            parameter   type    x_t    = logic [X_BITS-1:0] 
        )
        (
            input var x_t       x_start ,
            input var x_t       x_end   ,

            jelly3_axi4s_if.s   s_axi4s ,
            jelly3_axi4s_if.m   m_axi4s 
        );

    x_t       reg_x_start   ;
    x_t       reg_x_end     ;
    always_ff @(posedge s_axi4s.aclk) begin
        reg_x_start <= x_start  ;
        reg_x_end   <= x_end    ;
    end

    localparam DATA_BITS = s_axi4s.DATA_BITS;
    localparam USER_BITS = s_axi4s.USER_BITS;

    x_t                     s_count ;

    logic   [USER_BITS-1:0] st0_tuser ;
    logic                   st0_tlast ;
    logic   [DATA_BITS-1:0] st0_tdata ;
    logic                   st0_tvalid;

    logic   [USER_BITS-1:0] st1_tuser ;
    logic                   st1_tlast ;
    logic   [DATA_BITS-1:0] st1_tdata ;
    logic                   st1_tvalid;

    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            s_count    <= '0    ;

            st0_tuser  <= 'x    ;
            st0_tlast  <= 'x    ;
            st0_tdata  <= 'x    ;

            st0_tvalid <= 1'b0  ;
            st1_tuser  <= 'x    ;
            st1_tlast  <= 'x    ;
            st1_tdata  <= 'x    ;
            st1_tvalid <= 1'b0  ;
        end
        else if ( s_axi4s.tready ) begin
            if ( s_axi4s.tvalid ) begin
                s_count <= s_axi4s.tlast ? '0 : s_count + 1;
            end

            st0_tuser  <= s_axi4s.tuser ;
            st0_tlast  <= s_axi4s.tlast || s_count == reg_x_end;
            st0_tdata  <= s_axi4s.tdata ;
            st0_tvalid <= s_axi4s.tvalid
                            && s_count >= reg_x_start
                            && s_count <= reg_x_end   ;
        end
    end

    assign s_axi4s.tready = !m_axi4s.tvalid || m_axi4s.tready;

    assign m_axi4s.tuser  = st0_tuser   ;
    assign m_axi4s.tlast  = st0_tlast   ;
    assign m_axi4s.tdata  = st0_tdata   ;
    assign m_axi4s.tvalid = st0_tvalid  ;

endmodule

`default_nettype wire


// end of file
