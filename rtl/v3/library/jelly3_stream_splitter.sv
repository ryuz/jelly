// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_stream_splitter
        #(
            parameter   int     NUM            = 4                      ,
            parameter   int     DATA_BITS      = 32                     ,
            parameter   type    data_t         = logic [DATA_BITS-1:0]  ,
            parameter   bit     S_REG          = 1                      ,
            parameter   bit     M_REG          = 1
        )
        (
            input   var logic               reset   ,
            input   var logic               clk     ,
            input   var logic               cke     ,

            input   var data_t              s_data  ,
            input   var logic               s_valid ,
            output  var logic               s_ready ,
            
            output  var data_t  [NUM-1:0]   m_data  ,
            output  var logic   [NUM-1:0]   m_valid ,
            input   var logic   [NUM-1:0]   m_ready
        );

    if ( NUM >= 2 ) begin : blk_splitter
        // Slave Port
        data_t      s_ff_data;
        logic       s_ff_valid;
        logic       s_ff_ready;
        jelly3_stream_ff
                #(
                    .DATA_BITS      ($bits(data_t)  ),
                    .data_t         (data_t         ),
                    .S_REG          (S_REG          ),
                    .M_REG          (0              )
                )
            u_stream_ff_s
                (
                    .reset          (reset          ),
                    .clk            (clk            ),
                    .cke            (cke            ),
                    
                    .s_data         (s_data         ),
                    .s_valid        (s_valid        ),
                    .s_ready        (s_ready        ),
                    
                    .m_data         (s_ff_data      ),
                    .m_valid        (s_ff_valid     ),
                    .m_ready        (s_ff_ready     )
                );
        
        // Master Port
        always_ff @(posedge clk) begin
            if ( reset ) begin
                m_data  <= 'x;
                m_valid <= '0;
            end
            else if ( cke ) begin
                m_data  <= 'x;
                m_valid <= '0;
                for ( int i = 0; i < NUM; i++ ) begin
                    if ( m_ready[i] ) begin
                        m_data [i] <= 'x;
                        m_valid[i] <= 1'b0;
                    end
                    if ( s_ff_valid && s_ff_ready ) begin
                        m_data [i] <= s_ff_data;
                        m_valid[i] <= 1'b1;
                    end
                end
            end
        end
        always_comb begin
            s_ff_ready = 1'b1;
            for ( int i = 0; i < NUM; i++ ) begin
                if ( m_valid[i] && !m_ready[i] ) begin
                    s_ff_ready = 1'b0;
                end
            end
        end
    end
    else begin : blk_bypass
        assign m_data  = s_data;
        assign m_valid = s_valid;
        assign s_ready = m_ready;
    end

endmodule


`default_nettype wire


// end of file
