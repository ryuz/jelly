// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// 固定小数点マルチサイクル atan2
module jelly_fixed_atan2_multicycle
        #(
            parameter   SCALED_RADIAN = 1,
            parameter   X_WIDTH       = 32,
            parameter   Y_WIDTH       = 32,
            parameter   ANGLE_WIDTH   = 32,
            parameter   Q_WIDTH       = SCALED_RADIAN ? ANGLE_WIDTH : ANGLE_WIDTH - 2 // max:32
        )
        (
            input   wire                                reset,
            input   wire                                clk,
            input   wire                                cke,
            
            // input
            input   wire    signed  [X_WIDTH-1:0]       s_x,
            input   wire    signed  [Y_WIDTH-1:0]       s_y,
            input   wire                                s_valid,
            output  wire                                s_ready,
            
            // output
            output  wire    signed  [ANGLE_WIDTH-1:0]   m_angle,
            output  wire                                m_valid,
            input   wire                                m_ready
        );
    
    localparam  XY_WIDTH   = ((X_WIDTH > Y_WIDTH) ? X_WIDTH : Y_WIDTH) + Q_WIDTH;
    localparam  STEP_WIDTH = Q_WIDTH <= 2  ? 1 :
                             Q_WIDTH <= 4  ? 2 :
                             Q_WIDTH <= 8  ? 3 :
                             Q_WIDTH <= 16 ? 4 : 5;
    
    // table
    function signed [ANGLE_WIDTH-1:0] make_tbl(
                                            input [31:0] tbl,
                                            input [4:0]  idx
                                        );
    begin
        if ( SCALED_RADIAN ) begin
            tbl = ((tbl * 64'h00000000_28be60dc) + 64'h00000000_80000000) >> 32;
        end
        make_tbl = (tbl + (32'h80000000 >> Q_WIDTH)) >> (32 - Q_WIDTH);
        if ( idx >= Q_WIDTH ) begin
            make_tbl = 32'hxxxxxxxx;
        end
    end
    endfunction
    
    wire    signed  [ANGLE_WIDTH-1:0]   tbl [0:31];
    assign tbl[0]  = make_tbl(32'hc90fdaa2, 0);
    assign tbl[1]  = make_tbl(32'h76b19c16, 1);
    assign tbl[2]  = make_tbl(32'h3eb6ebf2, 2);
    assign tbl[3]  = make_tbl(32'h1fd5ba9b, 3);
    assign tbl[4]  = make_tbl(32'h0ffaaddc, 4);
    assign tbl[5]  = make_tbl(32'h07ff556f, 5);
    assign tbl[6]  = make_tbl(32'h03ffeaab, 6);
    assign tbl[7]  = make_tbl(32'h01fffd55, 7);
    assign tbl[8]  = make_tbl(32'h00ffffab, 8);
    assign tbl[9]  = make_tbl(32'h007ffff5, 9);
    assign tbl[10] = make_tbl(32'h003fffff, 10);
    assign tbl[11] = make_tbl(32'h00200000, 11);
    assign tbl[12] = make_tbl(32'h00100000, 12);
    assign tbl[13] = make_tbl(32'h00080000, 13);
    assign tbl[14] = make_tbl(32'h00040000, 14);
    assign tbl[15] = make_tbl(32'h00020000, 15);
    assign tbl[16] = make_tbl(32'h00010000, 16);
    assign tbl[17] = make_tbl(32'h00008000, 17);
    assign tbl[18] = make_tbl(32'h00004000, 18);
    assign tbl[19] = make_tbl(32'h00002000, 19);
    assign tbl[20] = make_tbl(32'h00001000, 20);
    assign tbl[21] = make_tbl(32'h00000800, 21);
    assign tbl[22] = make_tbl(32'h00000400, 22);
    assign tbl[23] = make_tbl(32'h00000200, 23);
    assign tbl[24] = make_tbl(32'h00000100, 24);
    assign tbl[25] = make_tbl(32'h00000080, 25);
    assign tbl[26] = make_tbl(32'h00000040, 26);
    assign tbl[27] = make_tbl(32'h00000020, 27);
    assign tbl[28] = make_tbl(32'h00000010, 28);
    assign tbl[29] = make_tbl(32'h00000008, 29);
    assign tbl[30] = make_tbl(32'h00000004, 30);
    assign tbl[31] = make_tbl(32'h00000002, 31);
    
    
    // CORDIC core
    reg                                 reg_busy;
    reg                                 reg_ready;
    reg                                 reg_valid;
    
    reg             [STEP_WIDTH-1:0]    reg_step;
    reg     signed  [XY_WIDTH-1:0]      reg_x;
    reg     signed  [XY_WIDTH-1:0]      reg_y;
    reg     signed  [ANGLE_WIDTH-1:0]   reg_angle;
    
    always @(posedge clk) begin
        if ( reset ) begin
            reg_busy    <= 1'b0;
            reg_ready   <= 1'b0;
            reg_valid   <= 1'b0;
            reg_step    <= {STEP_WIDTH{1'bx}};
            reg_x       <= {XY_WIDTH{1'bx}};
            reg_y       <= {XY_WIDTH{1'bx}};
            reg_angle   <= {ANGLE_WIDTH{1'bx}};
        end
        else if ( cke ) begin
            if ( !reg_busy && !reg_valid ) begin
                reg_ready <= 1'b1;
            end
            
            if ( m_valid & m_ready ) begin
                reg_valid <= 1'b0;
                reg_ready <= 1'b1;
            end
            
            if ( s_valid & s_ready & !m_valid ) begin
                // start
                reg_x       <= (s_x <<< Q_WIDTH);
                reg_y       <= (s_y <<< Q_WIDTH);
                reg_angle   <= 0;
                reg_busy    <= 1'b1;
                reg_ready   <= 1'b0;
                reg_step    <= 0;
            end
            else if ( reg_busy ) begin
                if ( reg_y >= 0 ) begin
                    reg_x     <= reg_x + (reg_y >>> reg_step);
                    reg_y     <= reg_y - (reg_x >>> reg_step);
                    reg_angle <= reg_angle + tbl[reg_step];
                end
                else begin
                    reg_x     <= reg_x - (reg_y >>> reg_step);
                    reg_y     <= reg_y + (reg_x >>> reg_step);
                    reg_angle <= reg_angle - tbl[reg_step];
                end
                
                reg_step <= reg_step + 1'b1;
                if ( reg_step == (Q_WIDTH-1) ) begin
                    reg_busy    <= 1'b0;
                    reg_valid   <= 1'b1;
                end
            end
        end
    end
    
    assign s_ready = reg_ready;
    
    assign m_angle = reg_angle;
    assign m_valid = reg_valid;
    
endmodule


`default_nettype wire


// end of file
