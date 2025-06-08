


`timescale 1ns / 1ps
`default_nettype none


module axi4s_to_video
        #(
            parameter   int     X_BITS     = 14                     ,
            parameter   type    x_t        = logic [X_BITS-1:0]     ,
            parameter   int     Y_BITS     = 14                     ,
            parameter   type    y_t        = logic [Y_BITS-1:0]     ,
            parameter   int     PULSE_BITS = 14                     ,
            parameter   type    pulse_t    = logic [PULSE_BITS-1:0] 
        )
        (
            input   var x_t                 width   ,
            input   var y_t                 height  ,
            input   var pulse_t             h_pulse ,
            input   var pulse_t             v_pulse ,

            jelly3_axi4s_if.s               axi4s   ,

            output  var logic               out_fv  ,
            output  var logic               out_lv  ,
            output  var logic   [2:0][7:0]  out_data
        );
    
     // FIFO
    jelly3_axi4s_if
            #(
                .DATA_BITS      (3*8            ),
                .DEBUG          ("false"        )
            )
        axi4s_fifo
            (
                .aresetn        (axi4s.aresetn  ),
                .aclk           (axi4s.aclk     ),
                .aclken         (axi4s.aclken   )
            );
    
   jelly3_axi4s_fifo
            #(
                .ASYNC          (0              ),
                .PTR_BITS       (10             ),
                .RAM_TYPE       ("block"        ),
                .LOW_DEALY      (0              ),
                .DOUT_REG       (1              ),
                .S_REG          (1              ),
                .M_REG          (1              )
            )
       u_axi4s_fifo
            (
                .s_axi4s        (axi4s          ),
                .m_axi4s        (axi4s_fifo     ),
                .s_free_count   (               ),
                .m_data_count   (               )
            );


    x_t         x           ;
    y_t         y           ;
    pulse_t     count       ;
    logic       out_le      ;
    always_ff @(posedge axi4s_fifo.aclk) begin
        if ( ~axi4s_fifo.aresetn ) begin
            x        <= 0;
            y        <= 0;
            count    <= 0;
            out_le   <= 0;
            out_fv   <= 0;
            out_lv   <= 0;
            out_data <= '0;
        end
        else begin
            if ( axi4s_fifo.aclken && axi4s_fifo.tvalid && axi4s_fifo.tready ) begin
                if ( axi4s_fifo.tlast ) begin
                    out_fv <= 1;
                    out_lv <= 0;
                end
                else begin
                    out_fv <= 0;
                    out_lv <= 1;
                end
            end
            else begin
                out_fv <= 0;
                out_lv <= 0;
            end

        end
    end



endmodule


`default_nettype wire


// end of file
