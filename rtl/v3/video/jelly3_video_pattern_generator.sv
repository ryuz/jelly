// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_video_pattern_generator
        #(
            parameter   int     X_BITS           = 32                       ,
            parameter   type    x_t              = logic [X_BITS-1:0]       ,
            parameter   int     Y_BITS           = 32                       ,
            parameter   type    y_t              = logic [Y_BITS-1:0]       ,
            parameter   int     F_BITS           = 32                       ,
            parameter   type    f_t              = logic [F_BITS-1:0]       ,
            parameter   int     PATTERN_BITS     = 3                        ,
            parameter   type    pattern_t        = logic [PATTERN_BITS-1:0] ,
            parameter   int     BLOCK_BITS       = 8                        
        )
        (
            input   var logic       enable          ,
            output  var logic       busy            ,

            input   var pattern_t   param_pattern   ,
            input   var x_t         param_width     ,
            input   var y_t         param_height    ,
            input   var x_t         param_h_total   ,
            input   var y_t         param_v_total   ,

            jelly3_axi4s_if.m       m_axi4s         ,
            output  var x_t         out_x           ,
            output  var y_t         out_y           ,
            output  var f_t         out_f           
        );
    
    localparam  type    data_t = logic [m_axi4s.DATA_BITS-1:0];


    pattern_t   reg_pattern     ;
    x_t         reg_width       ;
    y_t         reg_height      ;
    x_t         reg_h_total     ;
    y_t         reg_v_total     ;
    x_t         x               ;
    y_t         y               ;
    f_t         f               ;

    always_ff @(posedge m_axi4s.aclk) begin
        if ( !m_axi4s.aresetn ) begin
            reg_pattern <= 'x   ;
            reg_width   <= 'x   ;
            reg_height  <= 'x   ;
            reg_h_total <= 'x   ;
            reg_v_total <= 'x   ;

            busy        <= 1'b0 ;
            x           <= '0   ;
            y           <= '0   ;
            f           <= '0   ;
        end
        else if ( m_axi4s.aclken ) begin
            if ( !busy ) begin
                reg_pattern <= param_pattern    ;
                reg_width   <= param_width   - 1;
                reg_height  <= param_height  - 1;
                reg_h_total <= param_h_total - 1;
                reg_v_total <= param_v_total - 1;
                busy  <= enable;
                x     <= 0;
                y     <= 0;
            end
            else if ( !m_axi4s.tvalid || m_axi4s.tready ) begin
                x <= x + 1;
                if ( x >= reg_h_total ) begin
                    x <= 0;
                    y <= y + 1;
                    if ( y >= reg_v_total ) begin
                        y <= 0;
                        f <= f + 1;
                        busy <= 1'b0;
                    end
                end
            end
        end
    end
    

    always_ff @(posedge m_axi4s.aclk) begin
        if ( !m_axi4s.aresetn ) begin
            m_axi4s.tuser  <= '0    ;
            m_axi4s.tlast  <= '0    ;
            m_axi4s.tdata  <= '0    ;
            m_axi4s.tvalid <= 1'b0  ;
            out_x  <= '0;
            out_y  <= '0;
            out_f  <= '0;
        end
        else if ( m_axi4s.aclken ) begin
            m_axi4s.tuser  <= (x == 0) && (y == 0);
            m_axi4s.tlast  <= (x == reg_width);
            case ( reg_pattern )
            0      :    m_axi4s.tdata  <= data_t'({x, y[BLOCK_BITS-1:0]}    )       ;
            1      :    m_axi4s.tdata  <= data_t'({y, x[BLOCK_BITS-1:0]}    )       ;
            2      :    m_axi4s.tdata  <= data_t'(x                         )       ;
            3      :    m_axi4s.tdata  <= data_t'(y                         )       ;
            4      :    m_axi4s.tdata  <= data_t'(x + y                     )       ;
            5      :    m_axi4s.tdata  <= '0                                        ;
            6      :    m_axi4s.tdata  <= '1                                        ;
            7      :    m_axi4s.tdata  <= (x % 16 == 0) || (y % 16 == 0) ? '1 : '0  ;
            default:    m_axi4s.tdata  <= '0                                        ;
            endcase
            m_axi4s.tvalid <= busy && (x <= reg_width && y <= reg_height);
            out_x <= x;
            out_y <= y;
            out_f <= f;
        end
    end

endmodule


`default_nettype wire


// end of file

