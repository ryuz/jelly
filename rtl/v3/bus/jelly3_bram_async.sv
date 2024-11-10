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
    typedef logic   [s_bram.ID_BITS-1:0]       id_t    ;
    typedef logic   [s_bram.ADDR_BITS-1:0]     addr_t  ;
    typedef logic   [s_bram.DATA_BITS-1:0]     data_t  ;
    typedef logic   [s_bram.STRB_BITS-1:0]     strb_t  ;

    // command
    id_t        cid         ;
    logic       cread       ;
    logic       cwrite      ;
    addr_t      caddr       ;
    logic       clast       ;
    strb_t      cstrb       ;
    data_t      cdata       ;
    logic       cvalid      ;
    logic       cready      ;
    jelly2_fifo_generic_fwtf
            #(
                .ASYNC          (ASYNC              ),
                .DATA_WIDTH     (  s_bram.ID_BITS   
                                 + 2                
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
                                    s_bram.cid      ,
                                    s_bram.cwrite   ,
                                    s_bram.cread    ,
                                    s_bram.caddr    ,
                                    s_bram.clast    ,
                                    s_bram.cstrb    ,
                                    s_bram.cdata
                                }),
                .s_valid        (s_bram.cvalid      ),
                .s_ready        (s_bram.cready      ),
                .s_free_count   (                   ),

                .m_reset        (m_bram.reset       ),
                .m_clk          (m_bram.clk         ),
                .m_cke          (m_bram.cke         ),
                .m_data         ({
                                    cid             ,
                                    cwrite          ,
                                    cread           ,
                                    caddr           ,
                                    clast           ,
                                    cstrb           ,
                                    cdata           
                                }),
                .m_valid        (cvalid             ),
                .m_ready        (cready             ),
                .m_data_count   (                   )
        );
    always_ff @( posedge m_bram.clk ) begin
        if ( m_bram.reset ) begin
            m_bram.cid    <= 'x     ;
            m_bram.cwrite <= 1'b0   ;
            m_bram.cread  <= 1'b0   ;
            m_bram.caddr  <= 'x     ;
            m_bram.clast  <= 'x     ;
            m_bram.cstrb  <= '0     ;
            m_bram.cdata  <= 'x     ;
            m_bram.cvalid <= 1'b0   ;
        end
        else if ( m_bram.cke && cready ) begin
            m_bram.cid    <= cvalid ? cid    : 'x   ; 
            m_bram.cwrite <= cvalid ? cwrite : 1'b0 ;
            m_bram.cread  <= cvalid ? cread  : 1'b0 ;
            m_bram.caddr  <= cvalid ? caddr  : 'x   ; 
            m_bram.clast  <= cvalid ? clast  : 'x   ; 
            m_bram.cstrb  <= cvalid ? cstrb  : '0   ;
            m_bram.cdata  <= cvalid ? cdata  : 'x   ; 
            m_bram.cvalid <= cvalid ;
        end
    end
    assign cready = !m_bram.cvalid || m_bram.cready;


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
