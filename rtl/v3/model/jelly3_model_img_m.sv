// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly3_model_img_m
        #(
            parameter   int     IMG_CH_DEPTH     = 3                    ,
            parameter   int     IMG_CH_BITS      = 8                    ,
            parameter   int     IMG_WIDTH        = 640                  ,
            parameter   int     IMG_HEIGHT       = 480                  ,
            parameter   int     COL_BLANK        = 0                    ,   // 基本ゼロ
            parameter   int     ROW_BLANK        = 0                    ,   // 末尾にde落ちラインを追加
            parameter   int     X_BITS           = 32                   ,
            parameter   type    x_t              = logic [X_BITS-1:0]   ,
            parameter   int     Y_BITS           = 32                   ,
            parameter   type    y_t              = logic [Y_BITS-1:0]   ,
            parameter   int     F_BITS           = 32                   ,
            parameter   type    f_t              = logic [F_BITS-1:0]   ,
            parameter   string  FILE_NAME        = ""                   ,
            parameter   string  FILE_EXT         = ""                   ,
            parameter   int     FILE_IMG_WIDTH   = IMG_WIDTH            ,
            parameter   int     FILE_IMG_HEIGHT  = IMG_HEIGHT           ,
            parameter   bit     SEQUENTIAL_FILE  = 0                    ,
            parameter   bit     ENDIAN           = 0                    
        )
        (
            input   var logic   enable      ,
            output  var logic   busy        ,
            
            jelly3_mat_if.m     m_img       ,
            output  var x_t     out_x       ,
            output  var y_t     out_y       ,
            output  var f_t     out_f       
        );

    // -----------------------------
    //  parameters
    // -----------------------------

    localparam  int     MAT_TAPS      = m_img.TAPS      ;
    localparam  int     MAT_DE_BITS   = m_img.DE_BITS   ;
    localparam  int     MAT_CH_DEPTH  = m_img.CH_DEPTH  ;
    localparam  int     MAT_CH_BITS   = m_img.CH_BITS   ;
    localparam  int     MAT_ROWS_BITS = m_img.ROWS_BITS ;
    localparam  int     MAT_COLS_BITS = m_img.COLS_BITS ;


    // -----------------------------
    //  read image file
    // -----------------------------

    localparam  int     MEM_IMG_WIDTH  = IMG_WIDTH  > FILE_IMG_WIDTH  ? IMG_WIDTH  : FILE_IMG_WIDTH;
    localparam  int     MEM_IMG_HEIGHT = IMG_HEIGHT > FILE_IMG_HEIGHT ? IMG_HEIGHT : FILE_IMG_HEIGHT;


    logic   [IMG_CH_DEPTH-1:0][IMG_CH_BITS-1:0]    mem     [MEM_IMG_HEIGHT][MEM_IMG_WIDTH];

    int     x = 0;
    int     y = 0;
    int     f = 0;


    // -----------------------------
    //  read image file
    // -----------------------------

    task    image_clear();
    begin
        for ( int i = 0; i < IMG_HEIGHT; ++i ) begin
            for ( int j = 0; j < IMG_WIDTH; ++j ) begin
                for ( int k = 0; k < IMG_CH_DEPTH; ++k ) begin
                    automatic int val;
                    val = 0;
                    if ( k == 0 ) val = j;
                    if ( k == 1 ) val = i;
                    if ( k == 2 ) val = f;
                    mem[i][j][k] = IMG_CH_BITS'(val);
                end
            end
        end
    end
    endtask
    
    task    image_read();
    begin
        automatic string filename = SEQUENTIAL_FILE ? {FILE_NAME, $sformatf("%04d", f), FILE_EXT} : {FILE_NAME, FILE_EXT};
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
            for ( int i = 0; i < IMG_HEIGHT; ++i ) begin
                for ( int j = 0; j < IMG_WIDTH; ++j ) begin
                    for ( int k = 0; k < IMG_CH_DEPTH; ++k ) begin
                        int val;
                        $fscanf(fp, "%d", val);
                        if ( ENDIAN ) begin
                            mem[i][j][IMG_CH_DEPTH-1-k] = IMG_CH_BITS'(val);                            
                        end
                        else begin
                            mem[i][j][k] = IMG_CH_BITS'(val);
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
    
    localparam TOTAL_WIDTH  = IMG_WIDTH + COL_BLANK;
    localparam TOTAL_HEIGHT = IMG_HEIGHT + ROW_BLANK;
    
    always_ff @(posedge m_img.clk) begin
        if ( m_img.reset ) begin
            busy <= 1'b0;
            f    <= '0;
            x    <= '0;
            y    <= '0;
        end
        else if ( m_img.cke ) begin
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
                x <= x + MAT_TAPS;
                if ( x >= (TOTAL_WIDTH-MAT_TAPS) ) begin
                    x <= 0;
                    y <= y + 1;
                    if ( y >= (TOTAL_HEIGHT-1) ) begin
                        y <= 0;
                        f <= f + 1;
                        busy <= enable;
                    end
                end
            end
        end
    end

    always_comb begin
        for ( int tap = 0; tap < MAT_TAPS; tap++ ) begin
            for ( int ch = 0; ch < MAT_CH_DEPTH; ch++ ) begin
                m_img.data[tap][ch] = m_img.valid ? MAT_CH_BITS'(mem[y][x+tap][ch]) : 'x;
            end
        end
    end

    always_comb begin
        for ( int tap = 0; tap < $bits(m_img.de); tap++ ) begin
            m_img.de[tap] = m_img.valid ? (x+tap < IMG_WIDTH && y < IMG_HEIGHT) : 'x;
        end
    end

    assign m_img.rows      = MAT_ROWS_BITS'(IMG_HEIGHT  );
    assign m_img.cols      = MAT_ROWS_BITS'(IMG_WIDTH   );
    assign m_img.row_first = m_img.valid ? (y == 0)                       : 'x;
    assign m_img.row_last  = m_img.valid ? (y == (IMG_HEIGHT-1))            : 'x;
    assign m_img.col_first = m_img.valid ? (x == 0)                       : 'x;
    assign m_img.col_last  = m_img.valid ? (x >= (IMG_WIDTH-MAT_TAPS))     : 'x;
    assign m_img.valid     = busy;

    assign out_x           = x_t'(x);
    assign out_y           = y_t'(y);
    assign out_f           = f_t'(f);
    
endmodule


`default_nettype wire


// end of file
