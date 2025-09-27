// ---------------------------------------------------------------------------
//  RTC-lab  PYTHON300 + Spartan7 MIPI Global shutter camera
//
//                                 Copyright (C) 2024-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module pixel_swap
        (
            jelly3_axi4s_if.s   s_axi4s ,
            jelly3_axi4s_if.m   m_axi4s  
        );
    
    localparam  int     DATA_BITS = s_axi4s.DATA_BITS / 4;
    localparam  type    data_t    = logic   [DATA_BITS-1:0];
    localparam  int     USER_BITS = s_axi4s.USER_BITS;
    localparam  type    user_t    = logic   [USER_BITS-1:0];


    // stage 0
    user_t          st0_tuser   ;
    logic           st0_tlast   ;
    data_t  [3:0]   st0_tdata   ;
    logic           st0_tvalid  ;
    logic           st0_tready  ;
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            st0_tuser  <= 'x    ;
            st0_tlast  <= 'x    ;
            st0_tdata  <= 'x    ;
            st0_tvalid <= 1'b0  ;
        end
        else if ( s_axi4s.aclken ) begin
            if ( s_axi4s.tready ) begin
                st0_tuser  <= s_axi4s.tuser ;
                st0_tlast  <= s_axi4s.tlast ;
                st0_tdata  <= s_axi4s.tdata ;
                st0_tvalid <= s_axi4s.tvalid;
            end
        end
    end
    assign s_axi4s.tready = !st0_tvalid || st0_tready;

    // stage 1
    logic   [1:0]   st1_phase   ;
    user_t          st1_tuser   ;
    logic           st1_tlast   ;
    data_t  [3:0]   st1_tdata0  ;
    data_t  [3:0]   st1_tdata1  ;
    logic           st1_tvalid  ;
    logic           st1_tready  ;
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            st1_phase  <= '0    ;
            st1_tuser  <= 'x    ;
            st1_tlast  <= 'x    ;
            st1_tdata0 <= 'x    ;
            st1_tdata1 <= 'x    ;
            st1_tvalid <= 1'b0  ;
        end
        else if ( s_axi4s.aclken ) begin
            if ( st1_tready ) begin
                st1_tuser  <= st0_tuser ;
                st1_tlast  <= st0_tlast ;
                st1_tdata0 <= st0_tdata ;
                st1_tvalid <= st0_tvalid && st0_tready;
            end
            if ( st1_tvalid && st1_tready ) begin
                st1_phase  <= st1_tlast ? '0 : st1_phase + 1;
                st1_tdata1 <= st1_tdata0;
            end
        end
    end
    assign st0_tready = (!st1_tvalid || st1_tready) && (st0_tvalid && (st0_tlast || s_axi4s.tvalid));   // 続けてデータが来ていれば進める

    // stage 2
    user_t          st2_tuser   ;
    logic           st2_tlast   ;
    data_t  [3:0]   st2_tdata   ;
    logic           st2_tvalid  ;
    logic           st2_tready  ;
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            st2_tuser  <= 'x    ;
            st2_tlast  <= 'x    ;
            st2_tdata  <= 'x    ;
            st2_tvalid <= 1'b0  ;
        end
        else if ( s_axi4s.aclken ) begin
            if ( st1_tready ) begin
                case ( st1_phase )
                2'b00:
                    begin
                        st2_tdata[0] <= st1_tdata0[0];
                        st2_tdata[1] <= st0_tdata [0];
                        st2_tdata[2] <= st1_tdata0[1];
                        st2_tdata[3] <= st0_tdata [1];
                    end
                2'b01:
                    begin
                        st2_tdata[0] <= st1_tdata1[2];
                        st2_tdata[1] <= st1_tdata0[2];
                        st2_tdata[2] <= st1_tdata1[3];
                        st2_tdata[3] <= st1_tdata0[3];
                    end
                2'b10:
                    begin
                        st2_tdata[0] <= st0_tdata [3];
                        st2_tdata[1] <= st1_tdata0[3];
                        st2_tdata[2] <= st0_tdata [2];
                        st2_tdata[3] <= st1_tdata0[2];
                    end
                2'b11:
                    begin
                        st2_tdata[0] <= st1_tdata0[1];
                        st2_tdata[1] <= st1_tdata1[1];
                        st2_tdata[2] <= st1_tdata0[0];
                        st2_tdata[3] <= st1_tdata1[0];
                    end
                endcase
                st2_tuser  <= st1_tuser ;
                st2_tlast  <= st1_tlast ;
                st2_tvalid <= st1_tvalid;
            end
        end
    end

    assign st1_tready = (!st2_tvalid || st2_tready);


    assign m_axi4s.tuser  = st2_tuser ;
    assign m_axi4s.tlast  = st2_tlast ;
    assign m_axi4s.tdata  = st2_tdata ;
    assign m_axi4s.tvalid = st2_tvalid;
    assign st2_tready = m_axi4s.tready;

endmodule


`default_nettype wire


// end of file
