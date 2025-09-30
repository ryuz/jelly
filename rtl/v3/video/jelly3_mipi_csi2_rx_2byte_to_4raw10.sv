
`timescale 1ns / 1ps
`default_nettype none


module jelly3_mipi_csi2_rx_2byte_to_4raw10
        #(
            parameter   DEVICE         = "RTL"      ,
            parameter   SIMULATION     = "false"    ,
            parameter   DEBUG          = "false"    
        )
        (
            jelly3_axi4s_if.s   s_axi4s,
            jelly3_axi4s_if.m   m_axi4s
        );

    // parameter check
    initial begin
        if (s_axi4s.DATA_BITS != 16) begin
            $error("%m s_axi4s.DATA_BITS must be 16, but it is %0d", s_axi4s.DATA_BITS);
        end
        if (m_axi4s.DATA_BITS != 40) begin
            $error("%m m_axi4s.DATA_BITS must be 40, but it is %0d", m_axi4s.DATA_BITS);
        end
    end


    // stage0 input buffer
    logic   [2:0]            st0_pahse  ;
    logic   [0:0]            st0_user   ;
    logic                    st0_last   ;
    logic   [4:0][15:0]      st0_buf    ;
    logic                    st0_valid  ;
    logic                    st0_ready  ;
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            st0_pahse <= 0  ;
            st0_user  <= 'x ;
            st0_last  <= 'x ;
            st0_buf   <= 'x ;
            st0_valid <= 1'b0;
        end
        else if ( s_axi4s.aclken ) begin
            if ( !st0_valid || st0_ready ) begin
                st0_valid <= 1'b0;
                if ( st0_pahse == '0 ) begin
                    st0_user <= s_axi4s.tuser;
                end
                if ( st0_valid ) begin
                    st0_last <= 1'b0;
                end
                if ( s_axi4s.tvalid && s_axi4s.tlast ) begin
                    st0_last <= 1'b1;
                end
                st0_buf[st0_pahse] <= s_axi4s.tdata;
                if ( s_axi4s.tvalid ) begin
                    st0_pahse <= st0_pahse + 1;
                    if ( st0_pahse == 3'd4 || s_axi4s.tlast ) begin
                        st0_pahse <= '0     ;
                        st0_valid <= 1'b1   ;
                    end
                end
            end
        end
    end
    logic   [9:0][7:0]       st0_bytes  ;
    assign st0_bytes = st0_buf;

    assign s_axi4s.tready = !st0_valid || st0_ready;


    // stage1 decode
    logic   [0:0]            st1_user   ;
    logic                    st1_last   ;
    logic   [7:0][9:0]       st1_raw10s ;
    logic                    st1_valid  ;
    logic                    st1_ready  ;
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            st1_user   <= 'x    ;
            st1_last   <= 'x    ;
            st1_raw10s <= 'x    ;
            st1_valid  <= 1'b0  ;
        end
        else if ( s_axi4s.aclken ) begin
            if ( !st1_valid || st1_ready ) begin
                st1_user      <= st0_user;
                st1_last      <= st0_last;
                st1_raw10s[0] <= {st0_bytes[0], st0_bytes[4][0*2+:2]};
                st1_raw10s[1] <= {st0_bytes[1], st0_bytes[4][1*2+:2]};
                st1_raw10s[2] <= {st0_bytes[2], st0_bytes[4][2*2+:2]};
                st1_raw10s[3] <= {st0_bytes[3], st0_bytes[4][3*2+:2]};
                st1_raw10s[4] <= {st0_bytes[5], st0_bytes[9][0*2+:2]};
                st1_raw10s[5] <= {st0_bytes[6], st0_bytes[9][1*2+:2]};
                st1_raw10s[6] <= {st0_bytes[7], st0_bytes[9][2*2+:2]};
                st1_raw10s[7] <= {st0_bytes[8], st0_bytes[9][3*2+:2]};
                st1_valid     <= st0_valid;
            end
        end
    end
    assign st0_ready = !st1_valid || st1_ready;


    // stage2 output
    logic                    st2_pahse  ;
    logic   [0:0]            st2_user   ;
    logic                    st2_last   ;
    logic   [1:0][3:0][9:0]  st2_raw10s ;
    logic                    st2_valid  ;
    logic                    st2_ready  ;
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            st2_pahse  <= 1'b0      ;
            st2_user   <= 'x        ;
            st2_last   <= 'x        ;
            st2_raw10s <= 'x        ;
            st2_valid  <= 1'b0      ;
        end
        else if ( s_axi4s.aclken ) begin
            if ( !st2_valid || st2_ready ) begin
                if ( st2_valid ) begin
                    st2_user[0] <= 1'b0;
                end
                if ( st1_valid && st1_ready ) begin
                    st2_pahse  <= 1'd1      ;
                    st2_user   <= st1_user  ;
                    st2_last   <= st1_last  ;
                    st2_raw10s <= st1_raw10s;
                    st2_valid  <= 1'b1      ;
                end
                else begin
                    if ( st2_valid ) begin
                        st2_pahse  <= 1'b0               ;
                        st2_raw10s <= st2_raw10s >> 4*10 ;
                        st2_valid  <= st2_pahse          ;
                    end
                end
            end
        end
    end

    assign st1_ready = ~st2_pahse;

    assign m_axi4s.tuser  = st2_user                ;
    assign m_axi4s.tlast  = st2_last & ~st2_pahse   ;
    assign m_axi4s.tdata  = st2_raw10s[0]           ;
    assign m_axi4s.tvalid = st2_valid               ;
    assign st2_ready = m_axi4s.tready               ;
    
endmodule


`default_nettype wire


// end of file
