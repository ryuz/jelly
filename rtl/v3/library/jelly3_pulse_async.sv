// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// pulse clock convert
module jelly3_pulse_async
        #(
            parameter   bit     ASYNC          = 1          ,
            parameter   int     SYNC_FF        = 2          ,
            parameter           DEVICE         = "RTL"      ,
            parameter           SIMULATION     = "false"    ,
            parameter           DEBUG          = "false"    
        )
        (
            input   var logic       s_reset     ,
            input   var logic       s_clk       ,
            input   var logic       s_cke       ,
            input   var logic       s_pulse     ,
            
            input   var logic       m_reset     ,
            input   var logic       m_clk       ,
            input   var logic       m_cke       ,
            output  var logic       m_pulse     
        );
    
    if ( ASYNC ) begin : async
        // slave
        logic       reg_s_semaphore;
        always_ff @(posedge s_clk) begin
            if ( s_reset ) begin
                reg_s_semaphore <= 1'b0;
            end
            else if ( s_cke ) begin
                if ( s_pulse ) begin
                    reg_s_semaphore <= ~reg_s_semaphore;
                end
            end
        end
        
        logic       cdc_semaphore;
        jelly3_cdc_single
                #(
                    .DEST_SYNC_FF   (SYNC_FF        ),
                    .SIM_ASSERT_CHK (0              ),
                    .SRC_INPUT_REG  (0              ),
                    .DEVICE         (DEVICE         ),
                    .SIMULATION     (SIMULATION     ),
                    .DEBUG          (DEBUG          )
                )
            u_cdc_single
                (
                    .src_clk        (s_clk          ),
                    .src_in         (reg_s_semaphore),
                    .dest_clk       (m_clk          ),
                    .dest_out       (cdc_semaphore  )
                );

        
        // master
        logic       reg_m_semaphore;
        always @(posedge m_clk) begin
            if ( m_reset ) begin
                reg_m_semaphore <= 1'b0;
                m_pulse         <= 1'b0;
            end
            else if ( m_cke ) begin
                m_pulse         <= (cdc_semaphore != reg_m_semaphore);
                reg_m_semaphore <= cdc_semaphore;
            end
        end
    end
    else begin : bypass
        assign m_pulse = s_pulse;
    end
    

endmodule


`default_nettype wire


// end of file
