
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   s_reset     ,
            input   var logic   s_clk       ,
            input   var logic   m_reset     ,
            input   var logic   m_clk       
        );

    logic s_cke = 1'b1;
    logic m_cke = 1'b1;

    // -------------------------
    //  DUT
    // -------------------------

    parameter   bit     ASYNC          = 1                  ;
    parameter   int     FIFO_PTR_BITS  = 4;//9                  ;
    parameter           FIFO_RAM_TYPE  = "block"            ;
    parameter   int     FIFO_S_SYNC_FF = 2                  ;
    parameter   int     FIFO_M_SYNC_FF = 2                  ;
    parameter   bit     FIFO_DOUT_REG  = 1                  ;
    parameter   int     LIMIT_SIZE     = 2 ** FIFO_PTR_BITS ;
    parameter           DEVICE         = "RTL"              ;
    parameter           SIMULATION     = "false"            ;
    parameter           DEBUG          = "false"            ;

    jelly3_axi4s_if
        s_axi4s
            (
                .aresetn    (~s_reset       ),
                .aclk       (s_clk          ),
                .aclken     (s_cke          )
            );

    jelly3_axi4s_if
        m_axi4s
            (
                .aresetn    (~m_reset      ),
                .aclk       (m_clk         ),
                .aclken     (m_cke         )
            );

    jelly3_axi4s_packet_smoother
            #(
                .ASYNC          (ASYNC          ),
                .FIFO_PTR_BITS  (FIFO_PTR_BITS  ),
                .FIFO_RAM_TYPE  (FIFO_RAM_TYPE  ),
                .FIFO_S_SYNC_FF (FIFO_S_SYNC_FF ),
                .FIFO_M_SYNC_FF (FIFO_M_SYNC_FF ),
                .FIFO_DOUT_REG  (FIFO_DOUT_REG  ),
                .LIMIT_SIZE     (LIMIT_SIZE     ),
                .DEVICE         (DEVICE         ),
                .SIMULATION     (SIMULATION     ),
                .DEBUG          (DEBUG          )
            )
        u_axi4s_packet_smoother
            (
                .s_axi4s        (s_axi4s        ),
                .m_axi4s        (m_axi4s        )
            );
    

    // -------------------------
    //  Simulation
    // -------------------------

    always_ff @(posedge s_clk) begin
        if ( s_reset ) begin
            s_axi4s.tlast  <= 1'bx  ;
            s_axi4s.tdata  <= '0    ;
            s_axi4s.tvalid <= 1'b0  ;
        end
        else begin
            if ( s_axi4s.tvalid && s_axi4s.tready ) begin
                s_axi4s.tdata <= s_axi4s.tdata + 1;
            end
            if ( !s_axi4s.tvalid || s_axi4s.tready ) begin
                if ( $urandom_range(0, 1) != 0 ) begin
                    s_axi4s.tlast  <= 1'($urandom_range(0, 100) == 0);
                    s_axi4s.tvalid <= 1'b1;
                end
                else begin
                    s_axi4s.tlast  <= 1'bx;
                    s_axi4s.tvalid <= 1'b0;
                end
            end
        end
    end
    
    always_ff @(posedge s_clk) begin
        if ( s_reset ) begin
            m_axi4s.tready <= 1'b0;
        end
        else begin
            m_axi4s.tready <= 1;//1'($urandom_range(0, 1));
        end
    end

endmodule


`default_nettype wire


// end of file
