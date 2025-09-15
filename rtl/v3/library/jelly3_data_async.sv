// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// data clock convert
module jelly3_data_async
        #(
            parameter   bit     ASYNC       = 1                     ,
            parameter   int     DATA_BITS   = 8                     ,
            parameter   type    data_t      = logic [DATA_BITS-1:0] ,
            parameter   int     M_SYNC_FF   = 2                     ,
            parameter   int     S_SYNC_FF   = 2                     ,
            parameter           DEVICE      = "RTL"                 ,
            parameter           SIMULATION  = "false"               ,
            parameter           DEBUG       = "false"               
        )
        (
            input   var logic       s_reset ,
            input   var logic       s_clk   ,
            input   var logic       s_cke   ,
            input   var data_t      s_data  ,
            input   var logic       s_valid ,
            output  var logic       s_ready ,
            
            input   var logic       m_reset ,
            input   var logic       m_clk   ,
            input   var logic       m_cke   ,
            output  var data_t      m_data  ,
            output  var logic       m_valid ,
            input   var logic       m_ready 
        );
    
    if ( ASYNC ) begin : blk_async
        // semaphore
        logic   s_reg_semaphore ;
        data_t  s_reg_data      ;
        logic   s_cdc_semaphore  ;
        
        data_t  m_reg_data      ;
        logic   m_reg_semaphore ;
        logic   m_cdc_semaphore  ;
        
        jelly3_cdc_single
                #(
                    .DEST_SYNC_FF   (M_SYNC_FF      ),
                    .SIM_ASSERT_CHK (0              ),
                    .SRC_INPUT_REG  (0              ),
                    .DEVICE         (DEVICE         ),
                    .SIMULATION     (SIMULATION     ),
                    .DEBUG          (DEBUG          )
                )
            u_cdc_single_m
                (
                    .src_clk        (s_clk          ),
                    .src_in         (s_reg_semaphore),
                    .dest_clk       (m_clk          ),
                    .dest_out       (m_cdc_semaphore)
                );

        jelly3_cdc_single
                #(
                    .DEST_SYNC_FF   (S_SYNC_FF      ),
                    .SIM_ASSERT_CHK (0              ),
                    .SRC_INPUT_REG  (0              ),
                    .DEVICE         (DEVICE         ),
                    .SIMULATION     (SIMULATION     ),
                    .DEBUG          (DEBUG          )
                )
            u_cdc_single_s
                (
                    .src_clk        (m_clk          ),
                    .src_in         (m_reg_semaphore),
                    .dest_clk       (s_clk          ),
                    .dest_out       (s_cdc_semaphore)
                );
        
        // slave
        always @(posedge s_clk) begin
            if ( s_reset ) begin
                s_reg_semaphore <= 1'b0 ;
                s_reg_data      <= 'x   ;
            end
            else if ( s_cke ) begin
                if ( s_valid & s_ready ) begin
                    s_reg_semaphore <= ~s_reg_semaphore ;
                    s_reg_data      <= s_data           ;
                end
            end
        end
        
        assign s_ready = (s_reg_semaphore == s_cdc_semaphore);
        
        
        // master
        always @(posedge m_clk) begin
            if ( m_reset ) begin
                m_reg_semaphore <= 1'b0 ;
            end
            else if ( m_cke ) begin
                if ( m_valid & m_ready ) begin
                    m_reg_semaphore <= ~m_reg_semaphore;
                end
            end
        end
        
        always @(posedge m_clk) begin
            m_reg_data <= s_reg_data;
        end
        
        assign m_data  = m_reg_data;
        assign m_valid = (m_reg_semaphore != m_cdc_semaphore);
    end
    else begin : blk_bypass
        assign m_data  = s_data;
        assign m_valid = s_valid;
        assign s_ready = m_ready;
    end
    
endmodule


`default_nettype wire


// end of file
