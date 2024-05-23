// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// USE_VALID で valid 信号を使うと、信号は増えるが初期化が減る

module jelly2_axi4s_to_img_simple
        #(
            parameter   int     TUSER_WIDTH   = 1,
            parameter   int     TDATA_WIDTH   = 8,
            parameter   int     IMG_X_WIDTH   = 12,
            parameter   int     IMG_Y_WIDTH   = 12,
            parameter   int     BLANK_Y_WIDTH = IMG_Y_WIDTH,
            parameter   bit     IMG_CKE_BUFG  = 0,
            parameter   bit     WITH_VALID    = 1,
            
            localparam  int     USER_WIDTH   = (TUSER_WIDTH > 1) ? (TUSER_WIDTH - 1) : 1
        )
        (
            input   wire                                reset,
            input   wire                                clk,
            input   wire                                cke,
            
            input   wire    [IMG_X_WIDTH-1:0]           param_img_width,
            input   wire    [IMG_Y_WIDTH-1:0]           param_img_height,
            input   wire    [BLANK_Y_WIDTH-1:0]         param_blank_height,
            
            input   wire    [TUSER_WIDTH-1:0]           s_axi4s_tuser,
            input   wire                                s_axi4s_tlast,
            input   wire    [TDATA_WIDTH-1:0]           s_axi4s_tdata,
            input   wire                                s_axi4s_tvalid,
            output  wire                                s_axi4s_tready,
            
            output  reg                                 m_img_cke,
            output  reg                                 m_img_row_first,
            output  reg                                 m_img_row_last,
            output  reg                                 m_img_col_first,
            output  reg                                 m_img_col_last,
            output  reg                                 m_img_de,
            output  reg     [USER_WIDTH-1:0]            m_img_user,
            output  reg     [TDATA_WIDTH-1:0]           m_img_data,
            output  reg                                 m_img_valid
        );
    
    
    logic                       blank;
    logic   [IMG_X_WIDTH-1:0]   x_count, x_next;
    logic   [IMG_Y_WIDTH-1:0]   y_count, y_next;
    logic   [BLANK_Y_WIDTH-1:0] b_count, b_next;

    always_comb x_next = x_count + 1'b1;
    always_comb y_next = y_count + 1'b1;
    always_comb b_next = b_count + 1'b1;
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            blank   <= 1'b0;
            x_count <= '0;
            y_count <= '0;
            b_count <= '0;
        end
        else if ( cke ) begin
            if ( !blank ) begin
                if ( s_axi4s_tvalid ) begin
                    sva_tuser : assert (s_axi4s_tuser[0] == (x_count == '0 && y_count == '0));
                    x_count <= x_count + 1'b1;
                    if ( x_next == param_img_width ) begin
                        sva_tlast : assert (s_axi4s_tlast);
                        x_count <= '0;
                        y_count <= y_next;
                        if ( y_next == param_img_height ) begin
                            blank   <= (param_blank_height != '0);
                            y_count <= '0;
                        end
                    end
                end
                b_count <= '0;
            end
            else begin
                x_count <= x_count + 1'b1;
                if ( x_next == param_img_width ) begin
                    x_count <= '0;
                    b_count <= b_next;
                    if ( b_next == param_blank_height ) begin
                        blank   <= 1'b0;
                        b_count <= '0;
                    end
                end
                y_count <= '0;
            end
        end
    end

    assign s_axi4s_tready = cke && !blank;


    logic                               img_cke;
    logic                               img_row_first;
    logic                               img_row_last;
    logic                               img_col_first;
    logic                               img_col_last;
    logic                               img_de;
    logic   [USER_WIDTH-1:0]            img_user;
    logic   [TDATA_WIDTH-1:0]           img_data;
    logic                               img_valid;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            img_cke   <= 1'b0;
        end
        else begin
            img_cke   <= cke && (s_axi4s_tvalid || blank);
        end
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            img_row_first <='x;
            img_row_last  <='x;
            img_col_first <='x;
            img_col_last  <='x;
            img_de        <='x;
            img_user      <='x;
            img_data      <='x;
            img_valid     <= 1'b0;
        end
        if ( cke ) begin
            if (s_axi4s_tvalid || blank) begin
                img_row_first <= !blank && y_count == '0;
                img_row_last  <= !blank && y_next  == param_img_height;
                img_col_first <= x_count == '0;
                img_col_last  <= x_next == param_img_width;
                img_de        <= !blank;
                img_user      <= USER_WIDTH'(s_axi4s_tuser >> 1);
                img_data      <= s_axi4s_tdata;
                img_valid     <= 1'b1;
            end
        end
    end

    
    // 仕組み上 cke の fanout が大きくなるケースがあるのでBUFGを使えるようにしておく
`ifndef VERILATOR
    generate
    if ( IMG_CKE_BUFG ) begin
        BUFG
            i_bufg
                (
                    .I  (img_cke),
                    .O  (m_img_cke)
                );
    end
    else begin
        always_comb m_img_cke = img_cke;
    end
    endgenerate
`else
    always_comb m_img_cke = img_cke;
`endif

    
    always_comb m_img_row_first = img_valid & img_row_first;
    always_comb m_img_row_last  = img_valid & img_row_last;
    always_comb m_img_col_first = img_valid & img_col_first;
    always_comb m_img_col_last  = img_valid & img_col_last;
    always_comb m_img_de        = img_valid & img_de;
    always_comb m_img_user      = img_user;
    always_comb m_img_data      = img_data;
    always_comb m_img_valid     = img_valid;
    
endmodule


`default_nettype wire


// end of file
