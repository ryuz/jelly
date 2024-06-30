// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_bram_async
        #(
            parameter   bit     ASYNC          = 1              ,
            parameter   int     CFIFO_PTR_BITS = ASYNC ? 5 : 0  ,
            parameter           CFIFO_RAM_TYPE = "distributed"  ,
            parameter   int     RFIFO_PTR_BITS = ASYNC ? 5 : 0  ,
            parameter           RFIFO_RAM_TYPE = "distributed"  ,
            parameter           DEVICE         = "RTL"          ,
            parameter           SIMULATION     = "false"        ,
            parameter           DEBUG          = "false"        
        )
        (
            jelly3_bram_if.s        s_bram  ,
            jelly3_bram_if.m        m_bram  
        );

    // command
    jelly2_fifo_generic_fwtf
            #(
                .ASYNC          (ASYNC              ),
                .DATA_WIDTH     (  s_bram.ID_BITS   
                                 + s_bram.ADDR_BITS 
                                 + 1                
                                 + s_bram.STRB_BITS 
                                 + s_bram.DATA_BITS 
                                ),
                .PTR_WIDTH      (CFIFO_PTR_BITS     ),
                .RAM_TYPE       (CFIFO_RAM_TYPE     )
            )
        u_fifo_generic_fwtf_cmd
            (
                .s_reset        (s_bram.reset       ),
                .s_clk          (s_bram.clk         ),
                .s_cke          (s_bram.cke         ),
                .s_data         ({
                                    s_bram.cid  ,
                                    s_bram.caddr,
                                    s_bram.clast,
                                    s_bram.cstrb,
                                    s_bram.cdata
                                }),
                .s_valid        (s_bram.cvalid      ),
                .s_ready        (s_bram.cready      ),
                .s_free_count   (                   ),

                .m_reset        (m_bram.reset       ),
                .m_clk          (m_bram.clk         ),
                .m_cke          (m_bram.cke         ),
                .m_data         ({
                                    m_bram.cid  ,
                                    m_bram.caddr,
                                    m_bram.clast,
                                    m_bram.cstrb,
                                    m_bram.cdata
                                }),
                .m_valid        (m_bram.cvalid      ),
                .m_ready        (m_bram.cready      ),
                .m_data_count   ()
        );
    
    // response
    jelly2_fifo_generic_fwtf
            #(
                .ASYNC          (ASYNC              ),
                .DATA_WIDTH     (  s_bram.ID_BITS   
                                 + 1                
                                 + s_bram.DATA_BITS 
                                ),
                .PTR_WIDTH      (RFIFO_PTR_BITS     ),
                .RAM_TYPE       (RFIFO_RAM_TYPE     )
            )
        u_fifo_generic_fwtf_res
            (
                .s_reset        (m_bram.reset       ),
                .s_clk          (m_bram.clk         ),
                .s_cke          (m_bram.cke         ),
                .s_data         ({
                                    m_bram.rid  ,
                                    m_bram.rlast,
                                    m_bram.rdata
                                }),
                .s_valid        (m_bram.rvalid      ),
                .s_ready        (m_bram.rready      ),
                .s_free_count   (                   ),

                .m_reset        (s_bram.reset       ),
                .m_clk          (s_bram.clk         ),
                .m_cke          (s_bram.cke         ),
                .m_data         ({
                                    s_bram.rid  ,
                                    s_bram.rlast,
                                    s_bram.rdata
                                }),
                .m_valid        (s_bram.rvalid      ),
                .m_ready        (s_bram.rready      ),
                .m_data_count   ()
        );

    initial begin
        if ( s_bram.ADDR_BITS != m_bram.ADDR_BITS ) begin
            $error("ERROR: ADDR_BITS of s_bram and m_bram must be same");
        end
        if ( s_bram.DATA_BITS != m_bram.DATA_BITS ) begin
            $error("ERROR: DATA_BITS of s_bram and m_bram must be same");
        end
        if ( s_bram.STRB_BITS != m_bram.STRB_BITS ) begin
            $error("ERROR: DATA_BITS of s_bram and m_bram must be same");
        end
    end

endmodule


`default_nettype wire


// end of file
