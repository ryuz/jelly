// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2016 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly2_texture_cache_limitter
        #(
            parameter   int     LIMIT_NUM    = 1,   // if 0, no-limitter
            parameter   bit     PACKET_FIRST = 0
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            
            input   wire                            arvalid,
            input   wire                            arready,
            input   wire                            rlast,
            input   wire                            rvalid,
            input   wire                            rready,
            
            output  wire                            limit_arready
        );
    
    
    localparam  COUNTER_WIDTH  = $clog2(LIMIT_NUM) > 0 ? $clog2(LIMIT_NUM) : 1;
    
    generate
    if ( LIMIT_NUM <= 0 ) begin : blk_bypass
        assign limit_arready = 1'b1;
    end
    else begin : blk_limitter
        // packet end
        wire    rend;
        
        if ( PACKET_FIRST ) begin
            reg     reg_rfirst;
            always_ff @(posedge clk) begin
                if ( reset ) begin
                    reg_rfirst <= 1'b1;
                end
                else begin
                    if ( rvalid && rready ) begin
                        reg_rfirst <= rlast;
                    end
                end
            end
            assign rend = reg_rfirst;
        end
        else begin
            assign rend = rlast;
        end
        
        
        // limitter
        reg     [COUNTER_WIDTH-1:0]     reg_counter, next_counter;
        reg                             reg_arready, next_arready;
        
        always_comb begin
            next_counter = reg_counter;
            next_arready = reg_arready;
            
            if ( arvalid && arready ) begin
                next_counter = next_counter + 1'b1;
            end
            
            if ( rvalid && rready && rend ) begin
                next_counter = next_counter - 1'b1;
            end
            
            next_arready = (int'(next_counter) < LIMIT_NUM);
        end
        
        always_ff @(posedge clk) begin
            if ( reset ) begin
                reg_counter <= {COUNTER_WIDTH{1'b0}};
                reg_arready <= 1'b1;
            end
            else begin
                reg_counter <= next_counter;
                reg_arready <= next_arready;
            end
        end
        
        assign limit_arready = reg_arready;
    end
    endgenerate
    
    
endmodule



`default_nettype wire


// end of file
