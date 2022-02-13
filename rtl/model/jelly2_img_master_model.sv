// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly2_img_master_model
        #(
            parameter   int     COMPONENTS       = 3,
            parameter   int     DATA_WIDTH       = 8,
            parameter   int     X_NUM            = 640,
            parameter   int     Y_NUM            = 480,
            parameter   int     X_BLANK          = 0,     // 基本ゼロ
            parameter   int     Y_BLANK          = 0,     // 末尾にde落ちラインを追加
            parameter   int     X_WIDTH          = 32,
            parameter   int     Y_WIDTH          = 32,
            parameter   int     F_WIDTH          = 32,
            parameter   string  FILE_NAME        = "",
            parameter   string  FILE_EXT         = "",
            parameter   bit     SEQUENTIAL_FILE  = 0,
            parameter   bit     ENDIAN           = 0
        )
        (
            input   wire                                        reset,
            input   wire                                        clk,
            input   wire                                        cke,
            
            input   wire                                        enable,
            output  reg                                         busy,
            
            output  wire                                        m_img_row_first,
            output  wire                                        m_img_row_last,
            output  wire                                        m_img_col_first,
            output  wire                                        m_img_col_last,
            output  wire                                        m_img_de,
            output  wire    [COMPONENTS-1:0][DATA_WIDTH-1:0]    m_img_data,
            output  wire    [X_WIDTH-1:0]                       m_img_x,
            output  wire    [Y_WIDTH-1:0]                       m_img_y,
            output  wire    [F_WIDTH-1:0]                       m_img_f,
            output  wire                                        m_img_valid
        );
    
    
    // -----------------------------
    //  read image file
    // -----------------------------
    
    logic   [COMPONENTS-1:0][DATA_WIDTH-1:0]    mem     [Y_NUM][X_NUM];
    
    int                                         x = 0;
    int                                         y = 0;
    bit     [F_WIDTH-1:0]                       f = 0;
    
    
    // -----------------------------
    //  read image file
    // -----------------------------
    
    task    image_clear();
    begin
        for ( int i = 0; i < Y_NUM; ++i ) begin
            for ( int j = 0; j < X_NUM; ++j ) begin
                for ( int k = 0; k < COMPONENTS; ++k ) begin
                    automatic int data;
                    data = 0;
                    if ( k == 0 ) data = j;
                    if ( k == 1 ) data = i;
                    if ( k == 2 ) data = f;
                    mem[i][j][k] = DATA_WIDTH'(data);
                end
            end
        end
    end
    endtask
    
    task    image_read();
    begin
        string filename = SEQUENTIAL_FILE ? {FILE_NAME, $sformatf("%04d", f), FILE_EXT} : {FILE_NAME, FILE_EXT};
        automatic int fp;
        fp = $fopen(filename, "r");
        if ( fp == 0 ) begin
            $display("file open error : %s", filename);
        end
        else begin
            string format;
            int    width, height, maxval;
            $fscanf(fp, "%s %d %d %d", format, width, height, maxval);
            $display("[read] %s: format=%s width=%0d height=%0d maxval=%0d", filename, format, width, height, maxval);
            for ( int i = 0; i < Y_NUM; ++i ) begin
                for ( int j = 0; j < X_NUM; ++j ) begin
                    for ( int k = 0; k < COMPONENTS; ++k ) begin
                        int data;
                        $fscanf(fp, "%d", data);
                        if ( ENDIAN ) begin
                            mem[i][j][COMPONENTS-1-k] = DATA_WIDTH'(data);                            
                        end
                        else begin
                            mem[i][j][k] = DATA_WIDTH'(data);
                        end
                    end
                end
            end
            $fclose(fp);
        end
    end
    endtask
    
    initial begin
        image_clear();
    end
    
    
    // -----------------------------
    //  main
    // -----------------------------
    
    localparam TOTAL_X = X_NUM + X_BLANK;
    localparam TOTAL_Y = Y_NUM + Y_BLANK;
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            busy <= 1'b0;
            f    <= '0;
            x    <= '0;
            y    <= '0;
        end
        else if ( cke ) begin
            if ( !busy ) begin
                if ( enable ) begin
                    if ( FILE_NAME != "" ) begin
                        image_read();
                    end
                    busy <= 1'b1;
                    x    <= '0;
                    y    <= '0;
                end
            end
            else begin
                x <= x + 1;
                if ( x >= (TOTAL_X-1) ) begin
                    x <= 0;
                    y <= y + 1;
                    if ( y >= (TOTAL_Y-1) ) begin
                        y <= 0;
                        f <= f + 1;
                        busy <= 1'b0;
                    end
                end
            end
        end
    end
    
    assign m_img_row_first = !m_img_valid ? '0 : (y == 0);
    assign m_img_row_last  = !m_img_valid ? '0 : (y == (Y_NUM-1));
    assign m_img_col_first = !m_img_valid ? '0 : (x == 0);
    assign m_img_col_last  = !m_img_valid ? '0 : (x == (X_NUM-1));
    assign m_img_de        = !m_img_valid ? '0 : (x < X_NUM && y < Y_NUM);
    assign m_img_data      = !m_img_valid ? 'x : mem[y][x];
    assign m_img_x         = X_WIDTH'(x);
    assign m_img_y         = Y_WIDTH'(y);
    assign m_img_f         = F_WIDTH'(f);
    assign m_img_valid     = busy;
    
endmodule


`default_nettype wire


// end of file
