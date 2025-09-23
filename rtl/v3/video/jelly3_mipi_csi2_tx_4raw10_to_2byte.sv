
`timescale 1ns / 1ps
`default_nettype none


module jelly3_mipi_csi2_tx_4raw10_to_2byte
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
        if (s_axi4s.DATA_BITS != 40) begin
            $error("%m s_axi4s.DATA_BITS must be 50, but it is %0d", s_axi4s.DATA_BITS);
        end
        if (m_axi4s.DATA_BITS != 16) begin
            $error("%m m_axi4s.DATA_BITS must be 16, but it is %0d", m_axi4s.DATA_BITS);
        end
    end

    logic   [3:0][9:0]      raw10_data;
    logic   [4:0][7:0]      csi2_data;
    assign raw10_data   = s_axi4s.tdata;
    assign csi2_data[0] = raw10_data[0][9:2];
    assign csi2_data[1] = raw10_data[1][9:2];
    assign csi2_data[2] = raw10_data[2][9:2];
    assign csi2_data[3] = raw10_data[3][9:2];
    assign csi2_data[4] = {raw10_data[3][1:0], raw10_data[2][1:0], raw10_data[1][1:0], raw10_data[0][1:0]};


    logic   [2:0]            reg_count, next_count  ;
    logic   [5:0]            reg_user , next_user   ;
    logic   [5:0]            reg_last , next_last   ;
    logic   [47:0]           reg_data , next_data   ;
    logic                    reg_valid, next_valid  ;
    logic                               sig_ready   ;
    always_comb begin
        next_count = reg_count;
        next_user  = reg_user ;
        next_last  = reg_last ;
        next_data  = reg_data ;
        next_valid = reg_valid;
        sig_ready  = 1'b0     ;

        if ( m_axi4s.tvalid && m_axi4s.tready ) begin
            next_count -= 2;
            next_user >>= 2;
            next_last >>= 2;
        end

        if ( s_axi4s.tvalid && (next_count <= 1) ) begin
            sig_ready = 1'b1;
            if ( next_count[0] == 1'b0 ) begin
                next_data[47:0] = {8'd0, csi2_data};
                next_user[0]    = s_axi4s.tuser;
                if ( s_axi4s.tlast ) begin
                    next_count   = 6;
                    next_last[5] = s_axi4s.tlast;
                end
                else begin
                    next_count   = 5;
                    next_last[4] = s_axi4s.tlast;
                end
            end
            else begin
                next_data[47:8] = csi2_data;
                next_user[1]    = s_axi4s.tuser;
                next_last[5]    = s_axi4s.tlast;
                next_count      = 6;
            end
        end

        next_valid = (next_count >= 2);
    end

    always_ff @(posedge s_axi4s.aclk ) begin
        if ( ~s_axi4s.aresetn ) begin
            reg_count <= '0;
            reg_user  <= '0;
            reg_last  <= '0;
            reg_data  <= 'x;
            reg_valid <= '0;
        end
        else if ( s_axi4s.aclken ) begin
            reg_count <= next_count  ;
            reg_user  <= next_user   ;
            reg_last  <= next_last   ;
            reg_data  <= next_data   ;
            reg_valid <= next_valid  ;
        end
    end

    assign s_axi4s.tready = sig_ready       ;

    assign m_axi4s.tuser  = reg_user[0]     ;
    assign m_axi4s.tlast  = reg_last[1]     ;
    assign m_axi4s.tdata  = reg_data[15:0]  ;
    assign m_axi4s.tvalid = reg_valid       ;
    
endmodule


`default_nettype wire


// end of file
