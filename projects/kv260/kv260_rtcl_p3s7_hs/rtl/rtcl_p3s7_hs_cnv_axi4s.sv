

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
            input   var x_t     param_black_width   ,
            input   var y_t     param_black_height  ,
            input   var x_t     param_image_width   ,
            input   var y_t     param_image_height  ,

            input   var logic   s_first             ,
            input   var logic   s_last              ,
            input   var raw_t   s_data              ,
            input   var logic   s_valid             ,

            jelly3_axi4s_if.m   m_axi4s_black       ,
            jelly3_axi4s_if.m   m_axi4s_image       
        );

    logic       aresetn     ;
    logic       aclk        ;
    logic       aclken      ;
    assign aresetn = m_axi4s_image.aresetn    ;
    assign aclk    = m_axi4s_image.aclk       ;
    assign aclken  = m_axi4s_image.aclken     ;

    x_t         x           ;
    y_t         y           ;
    logic       busy        ;
    logic       black       ;
    logic       frame_start ;
    logic       frame_end   ;
    logic       line_last   ;
    raw_t       data        ;
    logic       valid       ;

    x_t         param_width ;
    y_t         param_height;
    assign param_width  = black ? param_black_width  : param_image_width ;
    assign param_height = black ? param_black_height : param_image_height;

    always_ff @(posedge aclk) begin
        if ( !aresetn ) begin
            x           <= 'x     ;
            y           <= 'x     ;
            busy        <= 1'b0   ;
            black       <= 'x     ;
            frame_start <= 'x     ;
            frame_end   <= 'x     ;
            line_last   <= 'x     ;
            data        <= 'x     ;
            valid       <= 1'b0   ;
        end
        else begin
            if ( !busy ) begin
                if ( s_valid && s_first ) begin
                    if ( param_black_height == 0 ) begin
                        black       <= 1'b0                     ;
                        x           <= '0                       ;
                        y           <= '0                       ;
                        busy        <= 1'b1                     ;
                        frame_start <= 1'b1                     ;
                        frame_end   <= (param_image_height == 1);
                        line_last   <= (param_image_width  == 1);
                        data        <= s_data                   ;
                        valid       <= s_data != 0              ;
                    end
                    else begin
                        black       <= 1'b1                     ;
                        x           <= '0                       ;
                        y           <= '0                       ;
                        busy        <= 1'b1                     ;
                        frame_start <= 1'b1                     ;
                        frame_end   <= (param_black_height == 1);
                        line_last   <= (param_black_width  == 1);
                        data        <= s_data                   ;
                        valid       <= s_data != 0              ;
                   end
                end
                else begin
                    valid       <= 1'b0                 ;
                end
            end
            else begin
                if ( valid ) begin
                    x           <= x + 1                        ;
                    frame_start <= 1'b0                         ;
                    line_last   <= (x + 1) == (param_width - 1) ;
                    if ( line_last ) begin
                        x <= '0;
                        y <= y + 1;
                        frame_end <= (y + 1) == (param_height - 1);
                        if ( frame_end ) begin
                            if ( black ) begin
                                // 黒領域を終えて画像領域へ移行
                                black       <= 1'b0                     ;
                                y           <= '0                       ;
                                frame_start <= 1'b1                     ;
                                frame_end   <= (param_image_height == 1);
                                line_last   <= (param_image_width  == 1);
                            end
                            else begin
                                // 画像領域のFEで完了
                                busy  <= 1'b0;
                                valid <= 1'b0;
                            end
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

    assign m_axi4s_black.tuser  = m_axi4s_black.USER_BITS'({(frame_end & line_last), frame_start});
    assign m_axi4s_black.tlast  = line_last             ;
    assign m_axi4s_black.tdata  = data                  ;
    assign m_axi4s_black.tvalid = valid & busy & black  ;

    assign m_axi4s_image.tuser  = m_axi4s_image.USER_BITS'({(frame_end & line_last), frame_start});
    assign m_axi4s_image.tlast  = line_last             ;
    assign m_axi4s_image.tdata  = data                  ;
    assign m_axi4s_image.tvalid = valid & busy & ~black ;

endmodule

`default_nettype wire

// end of file
