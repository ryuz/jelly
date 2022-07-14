// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly2_video_rendezvous
        #(
            parameter   int     TUSER_WIDTH = 1,
            parameter   int     TDATA_WIDTH = 24
        )
        (
            input   wire                        aresetn,
            input   wire                        aclk,
            input   wire                        aclken,

            input   wire    [TDATA_WIDTH-1:0]   padding_tdata,
            output  reg                         busy,

            input   wire    [0:0]               sync_tuser,
            input   wire                        sync_tlast,
            input   wire                        sync_tvalid,
            input   wire                        sync_tready,
            
            input   wire    [TUSER_WIDTH-1:0]   s_axi4s_tuser,
            input   wire    [TDATA_WIDTH-1:0]   s_axi4s_tdata,
            input   wire                        s_axi4s_tlast,
            input   wire                        s_axi4s_tvalid,
            output  reg                         s_axi4s_tready,
            
            output  reg     [TUSER_WIDTH-1:0]   m_axi4s_tuser,
            output  reg     [TDATA_WIDTH-1:0]   m_axi4s_tdata,
            output  reg                         m_axi4s_tlast,
            output  reg                         m_axi4s_tvalid
        );

    logic       reg_busy;
    always_ff @ (posedge aclk) begin
        if ( ~aresetn ) begin
            reg_busy <= !0;
        end
        else if ( aclken ) begin
            if ( sync_tuser[0] && sync_tvalid && sync_tready ) begin
                reg_busy <= s_axi4s_tuser[0] && s_axi4s_tvalid;
            end
        end
    end

    always_comb busy = reg_busy || ((sync_tuser[0] && sync_tvalid && sync_tready) && (s_axi4s_tuser[0] && s_axi4s_tvalid));

    always_comb s_axi4s_tready = busy ? (sync_tvalid & sync_tready) : !(s_axi4s_tuser[0] && s_axi4s_tvalid);
    
    always_comb m_axi4s_tuser  = s_axi4s_tuser;
    always_comb m_axi4s_tdata  = busy ? s_axi4s_tdata  : padding_tdata;
    always_comb m_axi4s_tlast  = s_axi4s_tlast;
    always_comb m_axi4s_tvalid = busy & s_axi4s_tvalid & s_axi4s_tready;
    
endmodule


`default_nettype wire


// end of file
