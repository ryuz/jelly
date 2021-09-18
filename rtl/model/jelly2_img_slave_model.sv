// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2015 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_img_slave_model
        #(
            parameter   int     COMPONENTS      = 3,
            parameter   int     DATA_WIDTH      = 8,
            parameter   int     INIT_FRAME_NUM  = 0,
            parameter   int     X_WIDTH         = 32,
            parameter   int     Y_WIDTH         = 32,
            parameter   int     F_WIDTH         = 32,
            parameter   string  FORMAT          = "P3",
            parameter   string  FILE_NAME       = "img_",
            parameter   string  FILE_EXT        = ".ppm",
            parameter   bit     SEQUENTIAL_FILE = 1
        )
        (
            input   wire                                        reset,
            input   wire                                        clk,
            input   wire                                        cke,

            input   wire    [X_WIDTH-1:0]                       param_width,
            input   wire    [Y_WIDTH-1:0]                       param_height,
            output  wire    [F_WIDTH-1:0]                       frame_num,
            
            input   wire                                        s_img_row_first,
            input   wire                                        s_img_row_last,
            input   wire                                        s_img_col_first,
            input   wire                                        s_img_col_last,
            input   wire                                        s_img_de,
            input   wire    [COMPONENTS-1:0][DATA_WIDTH-1:0]    s_img_data,
            input   wire                                        s_img_valid
        );
    
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
            $fdisplay(fp, "%0d %0d", param_width, param_height);
            $fdisplay(fp, "%0d", (1 << DATA_WIDTH)-1);
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

    always_ff @(posedge clk) begin
        if ( !reset & cke) begin
            if ( s_img_valid ) begin
                if ( s_img_row_first && s_img_col_first ) begin
                    frame_start();
                end
                if ( s_img_de && fp != 0) begin
                    for ( int i = 0; i < COMPONENTS; ++i ) begin
                        $fdisplay(fp, "%d", s_img_data[i]);
                    end
                end
                if ( s_img_row_last && s_img_col_last ) begin
                    frame_end();
                end
            end
        end
    end
    
    final begin
        frame_end();
    end

endmodule


// `default_nettype wire


// end of file
