// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly3_model_img_dump
        #(
            parameter   int     INIT_FRAME_NUM  = 0                     ,
//            parameter   int     X_BITS          = 32                    ,
//            parameter   type    x_t             = logic [X_BITS-1:0]    ,
//            parameter   int     Y_BITS          = 32                    ,
//            parameter   type    y_t             = logic [Y_BITS-1:0]    ,
            parameter   int     F_BITS          = 32                    ,
            parameter   type    f_t             = logic [F_BITS-1:0]    ,
            parameter   string  FORMAT          = "P3"                  ,
            parameter   string  FILE_NAME       = "img_"                ,
            parameter   string  FILE_EXT        = ".ppm"                ,
            parameter   bit     SEQUENTIAL_FILE = 1                     ,
            parameter   bit     ENDIAN          = 0                     
        )
        (
            jelly3_mat_if.s     s_img       ,

            output  var f_t     frame_num   
        );

    // -----------------------------
    //  parameters
    // -----------------------------

    localparam  int     MAT_TAPS      = s_img.TAPS      ;
    localparam  int     MAT_DE_BITS   = s_img.DE_BITS   ;
    localparam  int     MAT_CH_DEPTH  = s_img.CH_DEPTH  ;
    localparam  int     MAT_CH_BITS   = s_img.CH_BITS   ;
    localparam  int     MAT_ROWS_BITS = s_img.ROWS_BITS ;
    localparam  int     MAT_COLS_BITS = s_img.COLS_BITS ;

    string                      filename;
    int                         fp = 0;
    int                         f  = INIT_FRAME_NUM;

    task frame_start();
    begin
        frame_end();
        filename = SEQUENTIAL_FILE ? {FILE_NAME, $sformatf("%04d", f), FILE_EXT} : {FILE_NAME, FILE_EXT};
        fp = $fopen(filename, "w");
        if ( fp == 0 ) begin
            $display("file open error : %s", filename);
        end
        else begin
            $display("file open: %s", filename);
            $fdisplay(fp, "%s", FORMAT);
            $fdisplay(fp, "%0d %0d", s_img.cols, s_img.rows);
            $fdisplay(fp, "%0d", (1 << MAT_CH_BITS)-1);
        end
    end
    endtask

    task frame_end();
        if ( fp != 0 ) begin
            $fclose(fp);
            fp = 0;
            $display("file close: %s", filename);
            f++;
        end
    endtask

    always_ff @(posedge s_img.clk) begin
        if ( !s_img.reset & s_img.cke ) begin
            if ( s_img.valid ) begin
                if ( s_img.row_first && s_img.col_first ) begin
                    frame_start();
                end
                if ( s_img.de != 0 && fp != 0) begin
                    for ( int t = 0; t < MAT_TAPS; t++ ) begin
                        for ( int c = 0; c < MAT_CH_DEPTH; c++ ) begin
                            if ( ENDIAN ) begin
                                $fdisplay(fp, "%d", s_img.data[MAT_TAPS-1-t][MAT_CH_DEPTH-1-c]);
                            end
                            else begin
                                $fdisplay(fp, "%d", s_img.data[t][c]);
                            end
                        end
                    end
                end
                if ( s_img.row_last && s_img.col_last ) begin
                    frame_end();
                end
            end
        end
    end
    
    final begin
        frame_end();
    end

    assign frame_num = f;

endmodule


`default_nettype wire


// end of file
