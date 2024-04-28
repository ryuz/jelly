// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_instruction_fetch_delay
        #(
            parameter   int                     ID_BITS     = 2                                 ,
            parameter   type                    id_t        = logic [ID_BITS-1:0]               ,
            parameter   int                     PC_BITS     = 32                                ,
            parameter   type                    pc_t        = logic [PC_BITS-1:0]               
        )
        (
            input   var logic   reset           ,
            input   var logic   clk             ,
            input   var logic   cke             ,

            input   var logic   branch_en       ,
            input   var id_t    branch_id       ,
            input   var pc_t    branch_pc       ,

            input   id_t        s_id            ,
            input   pc_t        s_pc            ,
            input   logic       s_mem           ,
            input   logic       s_valid         ,
            output  logic       s_ready         ,

            output  id_t        m_id            ,
            output  pc_t        m_pc            ,
            output  logic       m_mem           ,
            output  logic       m_valid         ,
            input   logic       m_ready         
        );


    always_ff @(posedge clk) begin
        if ( reset ) begin
            m_id    <= 'x;
            m_pc    <= 'x;
            m_mem   <= 1'b0;
            m_valid <= 1'b0;
        end
        else if ( cke ) begin
            if ( m_ready || !m_valid ) begin
                m_id    <= s_id   ;
                m_pc    <= s_pc   ;
                m_mem   <= s_mem  ;
                m_valid <= s_valid;

                // ブランチで無効化する
                if ( branch_en && branch_id == s_id ) begin
                    m_valid <= 1'b0;
                end
            end
        end
    end

endmodule


`default_nettype wire


// End of file
