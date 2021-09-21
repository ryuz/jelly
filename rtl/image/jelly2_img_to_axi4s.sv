// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// 全フレーム有効データの場合は de は frame_start と frame_end で生成可能なので省略できる
// valid も 各信号の0初期化が保証されていれば省略できる


module jelly2_img_to_axi4s
        #(
            parameter   int     TUSER_WIDTH = 8,
            parameter   int     TDATA_WIDTH = 8,
            parameter   bit     USE_DE      = 1,        // s_img_de を利用する
            parameter   bit     USE_VALID   = 1,        // s_img_valid を利用する
            
            localparam  int     USER_WIDTH  = TUSER_WIDTH > 1 ? TUSER_WIDTH - 1 : 1
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire                        s_img_row_first,
            input   wire                        s_img_row_last,
            input   wire                        s_img_col_first,
            input   wire                        s_img_col_last,
            input   wire                        s_img_de,
            input   wire    [USER_WIDTH-1:0]    s_img_user,
            input   wire    [TDATA_WIDTH-1:0]   s_img_data,
            input   wire                        s_img_valid,
            
            output  wire    [TUSER_WIDTH-1:0]   m_axi4s_tuser,
            output  wire                        m_axi4s_tlast,
            output  wire    [TDATA_WIDTH-1:0]   m_axi4s_tdata,
            output  wire                        m_axi4s_tvalid
        );
    
    logic                       s_valid     = USE_VALID ? s_img_valid : 1'b1;
    logic                       s_row_first = (s_valid & s_img_row_first);
    logic                       s_row_last  = (s_valid & s_img_row_last);
    logic                       s_col_first = (s_valid & s_img_col_first);
    logic                       s_col_last  = (s_valid & s_img_col_last);
    logic                       s_de        = (s_valid & s_img_de);
    logic   [USER_WIDTH-1:0]    s_user      = s_img_user;
    logic   [TDATA_WIDTH-1:0]   s_data      = s_img_data;
    
    logic                       reg_de;
    logic   [TUSER_WIDTH-1:0]   reg_tuser;
    logic                       reg_tlast;
    logic   [TDATA_WIDTH-1:0]   reg_tdata;
    logic                       reg_tvalid;
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_de     <= 1'b0;
            reg_tuser  <= {TUSER_WIDTH{1'bx}};
            reg_tlast  <= 1'bx;
            reg_tdata  <= {TDATA_WIDTH{1'bx}};
            reg_tvalid <= 1'b0;
        end
        else if ( cke ) begin
            reg_tuser <= TUSER_WIDTH'({s_user, reg_tuser[0]});
            if ( reg_tvalid ) begin
                reg_tuser[0] <= 1'b0;
            end
            if ( s_valid && s_row_first && s_col_first ) begin
                reg_tuser[0] <= 1'b1;
            end
            
            reg_tlast    <= s_col_last;
            reg_tdata    <= s_data;
            
            if ( USE_DE ) begin
                reg_tvalid <= s_de;
            end
            else begin
                // auto create de
                if ( s_row_first ) begin
                    reg_de <= 1'b1;
                end
                else if ( s_row_last ) begin
                    reg_de <= 1'b0;
                end
                reg_tvalid <= reg_de;
            end
        end
        else begin
            reg_tvalid <= 1'b0;
            if ( reg_tvalid ) begin
                reg_tuser[0] <= 1'b0;
            end
        end
    end
    
    assign m_axi4s_tuser  = reg_tuser;
    assign m_axi4s_tlast  = reg_tlast;
    assign m_axi4s_tdata  = reg_tdata;
    assign m_axi4s_tvalid = reg_tvalid;
    
endmodule


`default_nettype wire


// end of file
