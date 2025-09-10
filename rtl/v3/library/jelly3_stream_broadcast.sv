// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none

module jelly3_stream_broadcast
        #(
            parameter   int     NUM        = 16                     ,
            parameter   int     DATA_BITS  = 8                      ,
            parameter   type    data_t     = logic[DATA_BITS-1:0]   ,
            parameter   bit     S_REG      = 1                      ,
            parameter   bit     M_REG      = 1                      
        )
        (
            input   var logic                       reset   ,
            input   var logic                       clk     ,
            input   var logic                       cke     ,
            
            input   var data_t                      s_data  ,
            input   var logic                       s_valid ,
            output  var logic                       s_ready ,
            
            output  var data_t  [NUM-1:0]           m_data  ,
            output  var logic   [NUM-1:0]           m_valid ,
            input   var logic   [NUM-1:0]           m_ready
        );
    
    
    // -----------------------------------------
    //  insert FF
    // -----------------------------------------
    
    data_t              ff_s_data   ;
    logic               ff_s_valid  ;
    logic               ff_s_ready  ;

    data_t  [NUM-1:0]   ff_m_data   ;
    logic   [NUM-1:0]   ff_m_valid  ;
    logic   [NUM-1:0]   ff_m_ready  ;

    jelly3_stream_ff
            #(
                .DATA_BITS      ($bits(data_t)  ),
                .S_REG          (S_REG          ),
                .M_REG          (S_REG          )
            )
        u_stream_ff_s
            (
                .reset          (reset          ),
                .clk            (clk            ),
                .cke            (cke            ),
                
                .s_data         (s_data         ),
                .s_valid        (s_valid        ),
                .s_ready        (s_ready        ),
                
                .m_data         (ff_s_data      ),
                .m_valid        (ff_s_valid     ),
                .m_ready        (ff_s_ready     )
            );
    
    
    for ( genvar i = 0; i < NUM; i = i+1 ) begin : loop_ff_m
    jelly3_stream_ff
                #(
                    .DATA_BITS      ($bits(data_t)  ),
                    .S_REG          (M_REG          ),
                    .M_REG          (M_REG          )
                )
            u_stream_ff_m
                (
                    .reset          (reset          ),
                    .clk            (clk            ),
                    .cke            (cke            ),
                    
                    .s_data         (ff_m_data [i]  ),
                    .s_valid        (ff_m_valid[i]  ),
                    .s_ready        (ff_m_ready[i]  ),
                    
                    .m_data         (m_data [i]     ),
                    .m_valid        (m_valid[i]     ),
                    .m_ready        (m_ready[i]     )
                );
    end
    
    
    
    // -----------------------------------------
    //  spliter
    // -----------------------------------------
    
    logic   [NUM-1:0]   sig_s_ready ;
    data_t  [NUM-1:0]   sig_m_data  ;
    logic               sig_m_valid ;
    
    for ( genvar i = 0; i < NUM; i = i+1 ) begin : loop_m_valid
        assign ff_m_valid[i] = (ff_s_valid && ff_s_ready);
    end
    
    assign ff_m_data  = {NUM{ff_s_data}}    ;
    assign ff_s_ready = &ff_m_ready         ;
    
endmodule


`default_nettype wire


// end of file
