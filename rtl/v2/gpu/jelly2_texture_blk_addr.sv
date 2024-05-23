// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2017 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly2_texture_blk_addr
        #(
            parameter   int     USER_WIDTH     = 1,
            parameter   int     ADDR_X_WIDTH   = 12,
            parameter   int     ADDR_Y_WIDTH   = 12,
            parameter   int     DATA_SIZE      = 0,
            parameter   int     BLK_X_NUM      = 1,
            parameter   int     BLK_Y_NUM      = 1,
            parameter   int     FIFO_PTR_WIDTH = 6,
            parameter           FIFO_RAM_TYPE  = "distributed"
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            
            input   wire    [USER_WIDTH-1:0]    s_user,
            input   wire    [ADDR_X_WIDTH-1:0]  s_addrx,
            input   wire    [ADDR_Y_WIDTH-1:0]  s_addry,
            input   wire                        s_valid,
            output  wire                        s_ready,
            
            output  wire    [USER_WIDTH-1:0]    m_user,
            output  wire                        m_last,
            output  wire    [ADDR_X_WIDTH-1:0]  m_addrx,
            output  wire    [ADDR_Y_WIDTH-1:0]  m_addry,
            output  wire                        m_valid,
            input   wire                        m_ready
        );
        
    localparam  int     BLK_X_WIDTH = $clog2(BLK_X_NUM) > 0 ? $clog2(BLK_X_NUM) : 1;
    localparam  int     BLK_Y_WIDTH = $clog2(BLK_Y_NUM) > 0 ? $clog2(BLK_Y_NUM) : 1;
    
    localparam  int     X_STEP  = (1 << DATA_SIZE);
    localparam  int     X_WIDTH = BLK_X_WIDTH > 0 ? BLK_X_WIDTH : 1;
    localparam  int     Y_WIDTH = BLK_Y_WIDTH > 0 ? BLK_Y_WIDTH : 1;
    
    // addressing
    generate
    if ( BLK_X_NUM > 1 || BLK_Y_NUM > 1 ) begin : blk_addr
        reg     [USER_WIDTH-1:0]    reg_user;
        reg     [ADDR_X_WIDTH-1:0]  reg_addrx;
        reg     [ADDR_Y_WIDTH-1:0]  reg_addry;
        reg     [X_WIDTH-1:0]       reg_x;
        reg     [Y_WIDTH-1:0]       reg_y;
        reg                         reg_valid;
        always_ff @(posedge clk) begin
            if ( reset ) begin
                reg_user  <= {USER_WIDTH{1'bx}};
                reg_addrx <= {ADDR_X_WIDTH{1'bx}};
                reg_addry <= {ADDR_Y_WIDTH{1'bx}};
                reg_x     <= {X_WIDTH{1'bx}};
                reg_y     <= {Y_WIDTH{1'bx}};
                reg_valid <= 1'b0;
            end
            else begin
                if ( m_valid && m_ready ) begin
                    reg_x <= reg_x + X_WIDTH'(X_STEP);
                    if ( reg_x == X_WIDTH'(BLK_X_NUM-X_STEP) ) begin
                        reg_x <= {X_WIDTH{1'b0}};
                        reg_y <= reg_y + 1'b1;
                        if ( reg_y == Y_WIDTH'(BLK_Y_NUM-1) ) begin
                            reg_user   <= {USER_WIDTH{1'bx}};
                            reg_x      <= {X_WIDTH{1'bx}};
                            reg_y      <= {Y_WIDTH{1'bx}};
                            reg_valid  <= 1'b0;
                        end
                    end
                end
                
                if ( s_valid & s_ready ) begin
                    reg_user  <= s_user;
                    reg_addrx <= s_addrx;
                    reg_addry <= s_addry;
                    reg_x     <= {X_WIDTH{1'b0}};
                    reg_y     <= {Y_WIDTH{1'b0}};
                    reg_valid <= 1'b1;
                end
            end
        end
        
        assign s_ready = (!reg_valid || (m_ready && (reg_x == X_WIDTH'(BLK_X_NUM-X_STEP)) && (reg_y == Y_WIDTH'(BLK_Y_NUM-1))));
        
        assign m_user  = reg_user;
        assign m_last  = ((reg_x == X_WIDTH'(BLK_X_NUM-X_STEP)) && (reg_y == Y_WIDTH'(BLK_Y_NUM-1)));
        assign m_addrx = reg_addrx + ADDR_X_WIDTH'(reg_x);
        assign m_addry = reg_addry + ADDR_Y_WIDTH'(reg_y);
        assign m_valid = reg_valid;
    end
    else begin : blk_bypass
        assign s_ready = m_ready;
        
        assign m_user  = s_user;
        assign m_last  = 1'b1;
        assign m_addrx = s_addrx;
        assign m_addry = s_addry;
        assign m_valid = s_valid;
    end
    endgenerate
    
    
endmodule



`default_nettype wire


// end of file
