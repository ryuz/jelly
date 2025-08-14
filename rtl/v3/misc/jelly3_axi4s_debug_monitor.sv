// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none

module jelly3_axi4s_debug_monitor
        #(
            parameter   int     TIMER_BITS = 32                     ,
            parameter   type    timer_t    = logic [TIMER_BITS-1:0] ,
            parameter   int     FRAME_BITS = 32                     ,
            parameter   type    frame_t    = logic [FRAME_BITS-1:0] ,
            parameter   int     PIXEL_BITS = 32                     ,
            parameter   type    pixel_t    = logic [PIXEL_BITS-1:0] ,
            parameter   int     X_BITS     = 16                     ,
            parameter   type    x_t        = logic [X_BITS-1:0]     ,
            parameter   int     Y_BITS     = 16                     ,
            parameter   type    y_t        = logic [Y_BITS-1:0]     
        )
        (
            jelly3_axi4s_if.mon     mon_axi4s       
        );
    
    localparam  type    tuser_t   = logic [mon_axi4s.USER_BITS-1:0];
    localparam  type    data_t    = logic [mon_axi4s.USER_BITS-1:0];
    
    (* MARK_DEBUG = "true" *)   tuser_t     dbg_axi4s_tuser ;
    (* MARK_DEBUG = "true" *)   logic       dbg_axi4s_tlast ;
    (* MARK_DEBUG = "true" *)   data_t      dbg_axi4s_tdata ;
    (* MARK_DEBUG = "true" *)   logic       dbg_axi4s_tvalid;
    (* MARK_DEBUG = "true" *)   logic       dbg_axi4s_tready;
    
    (* MARK_DEBUG = "true" *)   timer_t     dbg_timer;
    (* MARK_DEBUG = "true" *)   pixel_t     dbg_pixel;
    (* MARK_DEBUG = "true" *)   frame_t     dbg_frame;
    (* MARK_DEBUG = "true" *)   x_t         dbg_x;
    (* MARK_DEBUG = "true" *)   y_t         dbg_y;
    (* MARK_DEBUG = "true" *)   x_t         dbg_width;
    (* MARK_DEBUG = "true" *)   y_t         dbg_height;
    
    always @(posedge mon_axi4s.aclk) begin
        dbg_axi4s_tuser  <= mon_axi4s.tuser ;
        dbg_axi4s_tlast  <= mon_axi4s.tlast ;
        dbg_axi4s_tdata  <= mon_axi4s.tdata ;
        dbg_axi4s_tvalid <= mon_axi4s.tvalid;
        dbg_axi4s_tready <= mon_axi4s.tready;
    end
    
    always @(posedge mon_axi4s.aclk) begin
        if ( ~mon_axi4s.aresetn ) begin
            dbg_timer  <= 0;
            dbg_pixel  <= 0;
            dbg_frame  <= 0;
            dbg_x      <= 0;
            dbg_y      <= 0;
            dbg_width  <= 0;
            dbg_height <= 0;
        end
        else if ( mon_axi4s.aclken ) begin
            dbg_timer <= dbg_timer + 1;
            
            if ( mon_axi4s.tvalid && mon_axi4s.tready ) begin
                dbg_pixel <= dbg_pixel + 1;
                dbg_x     <= dbg_x     + 1;
                
                if ( mon_axi4s.tlast ) begin
                    dbg_x     <= 0;
                    dbg_y     <= dbg_y + 1;
                    dbg_width <= dbg_x + 1;
                end
                
                if ( mon_axi4s.tuser[0] ) begin
                    dbg_frame  <= dbg_frame + 1;
                    dbg_pixel  <= 0;
    //              dbg_x      <= 0;
                    dbg_y      <= 0;
                    dbg_height <= dbg_y;
                end
            end
        end
    end
    
    
endmodule


`default_nettype wire

// end of file
