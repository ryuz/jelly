// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   math
//
//                                 Copyright (C) 2008-2022 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_video_gate
        #(
            parameter   TUSER_WIDTH = 1,
            parameter   TDATA_WIDTH = 24
        )
        (
            input   wire                        aresetn,
            input   wire                        aclk,
            input   wire                        aclken,
            
            input   wire                        enable,
            output  reg                         busy,
            
            input   wire                        param_skip,
            
            input   wire    [TUSER_WIDTH-1:0]   s_axi4s_tuser,
            input   wire                        s_axi4s_tlast,
            input   wire    [TDATA_WIDTH-1:0]   s_axi4s_tdata,
            input   wire                        s_axi4s_tvalid,
            output  reg                         s_axi4s_tready,
            
            output  reg     [TUSER_WIDTH-1:0]   m_axi4s_tuser,
            output  reg                         m_axi4s_tlast,
            output  reg     [TDATA_WIDTH-1:0]   m_axi4s_tdata,
            output  reg                         m_axi4s_tvalid,
            input   wire                        m_axi4s_tready
        );
    
    
    logic       reg_busy;
    always_ff @ (posedge aclk) begin
        if ( ~aresetn ) begin
            reg_busy <= '0;
        end
        else if ( aclken ) begin
            if ( s_axi4s_tuser[0] && s_axi4s_tvalid && s_axi4s_tready ) begin
                reg_busy <= enable;
            end
        end
    end

    always_comb busy = reg_busy || ((s_axi4s_tuser[0] && s_axi4s_tvalid) && enable);

    always_comb s_axi4s_tready = busy ? m_axi4s_tready : (param_skip || !s_axi4s_tuser[0]);

    always_comb m_axi4s_tuser  = s_axi4s_tuser;
    always_comb m_axi4s_tdata  = s_axi4s_tdata;
    always_comb m_axi4s_tlast  = s_axi4s_tlast;
    always_comb m_axi4s_tvalid = s_axi4s_tvalid & busy;

endmodule


`default_nettype wire


// end of file
