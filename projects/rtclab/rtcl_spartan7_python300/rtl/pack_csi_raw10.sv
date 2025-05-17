
`timescale 1ns / 1ps
`default_nettype none


module pack_csi_raw10
        (
            jelly3_axi4s_if.s   s_axi4s,
            jelly3_axi4s_if.m   m_axi4s
        );

    logic   [2:0]       phase   ;
    logic   [3:0][1:0]  lsb     ;
    logic   [0:0]       tuser   ;
    logic               tlast   ;
    logic   [1:0][7:0]  tdata   ;
    logic               tvalid  ;
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            phase  <= '0    ;
            lsb    <= 'x    ;
            tuser  <= 'x    ;
            tlast  <= 1'bx  ;
            tdata  <= 'x    ;
            tvalid <= 1'b0  ;
        end
        else begin
            if ( m_axi4s.tvalid && m_axi4s.tready ) begin
                tuser  <= 1'b0;
                tlast  <= 1'b0;
                tvalid <= 1'b0;
            end
            if ( s_axi4s.tvalid && s_axi4s.tready ) begin
                case ( phase )
                3'd0: begin tdata[0] <= s_axi4s.tdata[9:2];                                 lsb[0] <= s_axi4s.tdata[1:0];                 end
                3'd1: begin                                 tdata[1] <= s_axi4s.tdata[9:2]; lsb[1] <= s_axi4s.tdata[1:0]; tvalid <= 1'b1; end
                3'd2: begin tdata[0] <= s_axi4s.tdata[9:2];                                 lsb[2] <= s_axi4s.tdata[1:0];                 end
                3'd3: begin                                 tdata[1] <= s_axi4s.tdata[9:2]; lsb[3] <= s_axi4s.tdata[1:0]; tvalid <= 1'b1; end
                3'd4: begin tdata[0] <= lsb;                tdata[1] <= s_axi4s.tdata[9:2]; lsb[0] <= s_axi4s.tdata[1:0]; tvalid <= 1'b1; end
                3'd5: begin tdata[0] <= s_axi4s.tdata[9:2];                                 lsb[1] <= s_axi4s.tdata[1:0];                 end
                3'd6: begin                                 tdata[1] <= s_axi4s.tdata[9:2]; lsb[2] <= s_axi4s.tdata[1:0]; tvalid <= 1'b1; end
                3'd7: begin tdata[0] <= s_axi4s.tdata[9:2]; tdata[1] <= {s_axi4s.tdata[1:0], lsb[2:0]};                   tvalid <= 1'b1; end
                endcase
                if ( phase == '0 ) begin
                    tuser  <= s_axi4s.tuser;
                end
                tlast <= s_axi4s.tlast;
                phase <= phase + 1;
            end
            if ( m_axi4s.tlast && m_axi4s.tvalid && m_axi4s.tready ) begin
                phase <= '0;
            end
        end
    end

    assign s_axi4s.tready = !m_axi4s.tvalid || m_axi4s.tready;

    assign m_axi4s.tuser  = tuser   ;
    assign m_axi4s.tlast  = tlast   ;
    assign m_axi4s.tdata  = tdata   ;
    assign m_axi4s.tvalid = tvalid  ;

endmodule

`default_nettype wire

// end of file
