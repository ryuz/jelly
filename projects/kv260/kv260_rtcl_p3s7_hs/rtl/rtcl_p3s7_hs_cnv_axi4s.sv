

`timescale 1ns / 1ps
`default_nettype none

module rtcl_p3s7_hs_cnv_axi4s
        #(
            parameter   int     X_BITS         = 10                         ,
            parameter   type    x_t            = logic  [X_BITS-1:0]        ,
            parameter   int     Y_BITS         = 10                         ,
            parameter   type    y_t            = logic  [Y_BITS-1:0]        ,
            parameter   int     RAW_BITS       = 10                         ,
            parameter   type    raw_t          = logic  [RAW_BITS-1:0]      ,
            parameter           DEBUG          = "false"                    
        )
        (
            input   var x_t     param_width     ,
            input   var y_t     param_height    ,

            input   var logic   s_first         ,
            input   var logic   s_last          ,
            input   var raw_t   s_data          ,
            input   var logic   s_valid         ,

            jelly3_axi4s_if.m   m_axi4s         
        );

    logic       aresetn     ;
    logic       aclk        ;
    logic       aclken      ;
    assign aresetn = m_axi4s.aresetn    ;
    assign aclk    = m_axi4s.aclk       ;
    assign aclken  = m_axi4s.aclken     ;

    x_t         x           ;
    y_t         y           ;
    logic       busy        ;
    logic       frame_start ;
    logic       frame_end   ;
    logic       line_last   ;
    raw_t       data        ;
    logic       valid       ;
    always_ff @(posedge aclk) begin
        if ( !aresetn ) begin
            x           <= 'x     ;
            y           <= 'x     ;
            busy        <= 1'b0   ;
            frame_start <= 'x     ;
            frame_end   <= 'x     ;
            line_last   <= 'x     ;
            data        <= 'x     ;
            valid       <= 1'b0   ;
        end
        else begin
            if ( !busy ) begin
                if ( s_valid && s_first ) begin
                    x           <= '0                   ;
                    y           <= '0                   ;
                    busy        <= 1'b1                 ;
                    frame_start <= 1'b1                 ;
                    frame_end   <= (param_height == 1)  ;
                    line_last   <= (param_width  == 1)  ;
                    data        <= s_data               ;
                    valid       <= s_data != 0          ;
                end
                else begin
                    valid       <= 1'b0                 ;
                end
            end
            else begin
                if ( valid ) begin
                    x           <= x + 1            ;
                    frame_start <= 1'b0             ;
                    line_last   <= (x + 1) == (param_width - 1);
                    if ( line_last ) begin
                        x <= '0;
                        y <= y + 1;
                        frame_end <= (y + 1) == (param_height - 1);
                        if ( frame_end ) begin
                            busy  <= 1'b0   ;
                            valid <= 1'b0   ;
                        end
                    end
                end
                data    <= s_data                   ;
                valid   <= s_valid && (s_data != 0) ;
            end
            if ( s_valid && s_last ) begin
                busy  <= 1'b0   ;
            end
        end
    end

    assign m_axi4s.tuser  = m_axi4s.USER_BITS'({(frame_end & line_last), frame_start});
    assign m_axi4s.tlast  = line_last    ;
    assign m_axi4s.tdata  = data         ;
    assign m_axi4s.tvalid = valid        ;

endmodule

`default_nettype wire

// end of file
