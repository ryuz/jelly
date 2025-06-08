// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_video_format_regularizer_core
        #(
            parameter   int     WIDTH_BITS       = 16                           ,
            parameter   type    width_t          = logic [WIDTH_BITS-1:0]       ,
            parameter   int     HEIGHT_BITS      = 16                           ,
            parameter   type    height_t         = logic [HEIGHT_BITS-1:0]      ,
            parameter   int     INDEX_BITS       = 1                            ,
            parameter   type    index_t          = logic [INDEX_BITS-1:0]       ,
            parameter   int     FRAME_TIMER_BITS = 32                           ,
            parameter   type    frame_timer_t    = logic [FRAME_TIMER_BITS-1:0] ,
            parameter   int     TIMER_BITS       = 32                           ,
            parameter   type    timer_t          = logic [TIMER_BITS-1:0]       ,
            parameter   bit     S_REG            = 1                            ,
            parameter   bit     M_REG            = 1                            
        )
        (
            jelly3_axi4s_if.s                           s_axi4s         ,
            jelly3_axi4s_if.m                           m_axi4s         ,

            input   var logic                           ctl_enable      ,
            input   var logic                           ctl_update      ,
            output  var index_t                         ctl_index       ,
            output  var logic                           ctl_busy        ,
            input   var logic                           ctl_skip        ,
            input   var logic                           ctl_frm_timer_en,
            input   var frame_timer_t                   ctl_frm_timeout ,

            input   var width_t                         param_width     ,
            input   var height_t                        param_height    ,
            input   var logic   [m_axi4s.DATA_BITS-1:0] param_fill      ,
            input   var timer_t                         param_timeout   ,

            output  var width_t                         current_width   ,
            output  var height_t                        current_height  
        );
    
    
    // input FF
    typedef logic [s_axi4s.USER_BITS-1:0]   user_t;
    typedef logic [s_axi4s.DATA_BITS-1:0]   data_t;
    
    typedef struct packed {
        user_t  tuser;
        logic   tlast;
        data_t  tdata;
    } axi4s_t;


    user_t  in_tuser;
    logic   in_tlast;
    data_t  in_tdata;
    logic   in_tvalid;
    logic   in_tready;

    jelly3_stream_ff
            #(
                .data_t         (axi4s_t                                        ),
                .S_REG          (S_REG                                          ),
                .M_REG          (1                                              )
            )
        u_stream_ff_s
            (
                .reset          (~s_axi4s.aresetn                               ),
                .clk            (s_axi4s.aclk                                   ),
                .cke            (s_axi4s.aclken                                 ),
                
                .s_data         ({s_axi4s.tuser, s_axi4s.tlast, s_axi4s.tdata}  ),
                .s_valid        (s_axi4s.tvalid                                 ),
                .s_ready        (s_axi4s.tready                                 ),
                
                .m_data         ({in_tuser, in_tlast, in_tdata}                 ),
                .m_valid        (in_tvalid                                      ),
                .m_ready        (in_tready                                      )
            );
    
    
    logic           cke                 ;
    
    index_t         reg_index           ;
    width_t         reg_param_width     ;
    height_t        reg_param_height    ;
    data_t          reg_param_fill      ;
    frame_timer_t   reg_param_timeout   ;
    
    logic           reg_busy            ;
    logic           reg_fill_h          ;
    logic           reg_fill_v          ;
    logic           reg_skip            ;
    
    logic           reg_frame_timeout   ;
    frame_timer_t   reg_frame_timer     ;
    
    logic           reg_timeout         ;
    timer_t         reg_timer           ;
    width_t         reg_x               ;
    height_t        reg_y               ;
    logic           reg_x_last          ;
    logic           reg_y_last          ;

    logic   sig_x_first ;
    logic   sig_y_first ;
    logic   sig_x_last  ;
    logic   sig_y_last  ;
    assign sig_x_first = (reg_x == 0)   ;
    assign sig_y_first = (reg_y == 0)   ;
    assign sig_x_last  = reg_x_last     ;
    assign sig_y_last  = reg_y_last     ;
    
    user_t      reg_tuser   ;
    logic       reg_tlast   ;
    data_t      reg_tdata   ;
    logic       reg_tvalid  ;
    logic       sig_tready  ;
    
    logic       sig_valid;
    
    
    assign sig_valid = (!reg_busy && (((in_tuser[0] && in_tvalid) || reg_frame_timeout) && ctl_enable))
                            || (reg_busy && ((!reg_skip && in_tvalid && in_tready) || (reg_fill_h || reg_fill_v)));
    
    assign in_tready = cke && ((!reg_busy && (~in_tuser[0] || ctl_enable || ctl_skip)) || (reg_busy && ((~in_tuser[0] && !reg_fill_h) || reg_skip)));
    
    assign cke       = s_axi4s.aclken && (!reg_tvalid || sig_tready);
    
    
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            current_width     <= '0;
            current_height    <= '0;
            
            reg_index         <= '0;
            reg_param_width   <= 'x;
            reg_param_height  <= 'x;
            reg_param_fill    <= 'x;
            reg_param_timeout <= 'x;
            
            reg_frame_timeout <= 1'b0;
            reg_frame_timer   <= '0;
            
            reg_busy          <= 1'b0;
            reg_fill_h        <= 1'bx;
            reg_fill_v        <= 1'bx;
            reg_skip          <= 1'bx;
            reg_timeout       <= 1'bx;
            reg_timer         <= 'x;
            reg_x             <= '0;
            reg_x_last        <= 1'b0;
            reg_y             <= '0;
            reg_y_last        <= 1'b0;
            
            reg_tuser         <= 'x;
            reg_tlast         <= 1'bx;
            reg_tdata         <= 'x;
            reg_tvalid        <= 1'b0;
        end
        else if ( cke ) begin
            // skip
            if ( (sig_x_last && sig_valid) && !reg_fill_h ) begin
                reg_skip <= 1'b1;
            end
            if ( in_tlast && in_tvalid && in_tready ) begin
                reg_skip <= 1'b0;
            end
            
            // fill_h
            if ( !reg_skip && (in_tlast && in_tvalid && in_tready) ) begin
                reg_fill_h <= 1'b1;
            end
            if ( sig_x_last && sig_valid ) begin
                reg_fill_h <= 1'b0;
            end
            
            // fill_v
            if ( reg_busy && (in_tuser[0] && in_tvalid) ) begin
                reg_fill_v <= 1'b1;
            end
            if ( sig_x_last && sig_y_last && sig_valid ) begin
                reg_fill_v <= 1'b0;
            end
            
            // timer
            reg_timer <= reg_timer + 1;
            if ( reg_param_timeout != 0 && reg_timer == reg_param_timeout ) begin
                reg_timeout <= 1'b1;
            end
            if ( !reg_busy || in_tvalid ) begin
                reg_timer   <= '0;
                reg_timeout <= 1'b0;
            end
            
            if ( reg_timeout ) begin
                reg_skip   <= 1'b1;
                reg_fill_h <= 1'b1;
                reg_fill_v <= 1'b1;
            end
            
            // frame timer
            reg_frame_timeout <= 1'b0;
            if ( ctl_enable && ctl_frm_timer_en && ~reg_busy ) begin
                reg_frame_timer <= reg_frame_timer + 1'b1;
                if ( reg_frame_timer == ctl_frm_timeout ) begin
                    reg_frame_timeout <= 1'b1;
                end
            end
            else begin
                reg_frame_timer <= '0;
            end
            
            
            // x-y count
            if ( sig_valid ) begin
                reg_x      <= reg_x + 1'b1;
                reg_x_last <= ((reg_x + 1'b1) == reg_param_width);
                if ( sig_x_last ) begin
                    reg_x      <= '0;
                    reg_x_last <= 1'b0; // (reg_param_width == 1);
                    reg_y      <= reg_y + 1'b1;
                    reg_y_last <= ((reg_y + 1'b1) == reg_param_height);
                    if ( sig_y_last ) begin
                        reg_y      <= '0;
                        reg_y_last <= 1'b0;
                    end
                end
            end
            
            // control
            if ( !reg_busy ) begin
                reg_skip    <= 1'b1;
                reg_fill_h  <= 1'b0;
                reg_fill_v  <= 1'b0;
                reg_x       <= '0;
                reg_x_last  <= 1'b0; // (param_width == 1);
                reg_y       <= '0;
                reg_y_last  <= 1'b0; // (param_height == 1);
                
//              reg_param_width   <= 'x;
//              reg_param_height  <= 'x;
//              reg_param_fill    <= 'x;
                
                if ( ((in_tuser[0] && in_tvalid) || reg_frame_timeout) && ctl_enable ) begin
                    // start
                    reg_busy          <= 1'b1;
                    reg_skip          <= 1'b0;
                    reg_x             <= 1;
                    
                    if ( reg_frame_timeout ) begin
                        reg_fill_v  <= 1'b1;
                    end
                    
                    if ( ctl_update ) begin
                        // parameter update
                        reg_index         <= reg_index + 1'b1;
                        reg_param_width   <= param_width  - 1;
                        reg_param_height  <= param_height - 1;
                        reg_param_fill    <= param_fill;
                        reg_param_timeout <= param_timeout;
                        current_width     <= param_width;
                        current_height    <= param_height;
                    end
                end
            end
            else begin
                if ( sig_x_last && sig_y_last && sig_valid ) begin
                    // end
                    reg_busy   <= 1'b0;
                    
                    reg_x      <= '0;
                    reg_x_last <= 1'b0;
                    reg_y      <= '0;
                    reg_y_last <= 1'b0;
                end
            end
            
            
            // data
            reg_tuser  <= sig_x_first && sig_y_first;
            reg_tlast  <= sig_x_last;
            reg_tdata  <= (reg_fill_h || reg_fill_v || reg_frame_timeout) ? reg_param_fill : in_tdata;
            reg_tvalid <= sig_valid;
        end
    end
    
    assign ctl_busy  = reg_busy;
    assign ctl_index = reg_index;
    
    // output FF
    jelly3_stream_ff
            #(
                .data_t         (axi4s_t                                        ),
                .S_REG          (1'b1                                           ),
                .M_REG          (M_REG                                          )
            )
        u_stream_ff_m
            (
                .reset          (~s_axi4s.aresetn                               ),
                .clk            (s_axi4s.aclk                                   ),
                .cke            (s_axi4s.aclken                                 ),
                
                .s_data         ({reg_tuser, reg_tlast, reg_tdata}              ),
                .s_valid        (reg_tvalid                                     ),
                .s_ready        (sig_tready                                     ),
                
                .m_data         ({m_axi4s.tuser, m_axi4s.tlast, m_axi4s.tdata}  ),
                .m_valid        (m_axi4s.tvalid                                 ),
                .m_ready        (m_axi4s.tready                                 )
            );
    
    
endmodule


`default_nettype wire


// end of file
