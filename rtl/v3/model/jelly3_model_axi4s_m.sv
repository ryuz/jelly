// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_model_axi4s_m
        #(
            parameter   int     COMPONENTS       = 3                    ,
            parameter   int     DATA_BITS        = 8                    ,
            parameter   int     IMG_WIDTH        = 640                  ,
            parameter   int     IMG_HEIGHT       = 480                  ,
            parameter   int     H_BLANK          = 0                    ,
            parameter   int     V_BLANK          = 0                    ,
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
            parameter   int     BUSY_RATE        = 0                    ,
            parameter   int     RANDOM_SEED      = 0                    ,
            parameter   bit     ENDIAN           = 0                    
        )
        (
            input   var logic   enable  ,
            output  var logic   busy    ,

            jelly3_axi4s_if.m   m_axi4s ,
            output  var x_t     out_x   ,
            output  var y_t     out_y   ,
            output  var f_t     out_f   
        );
    

    // -----------------------------
    //  read image file
    // -----------------------------

    localparam  int     MEM_IMG_WIDTH  = IMG_WIDTH  > FILE_IMG_WIDTH  ? IMG_WIDTH  : FILE_IMG_WIDTH;
    localparam  int     MEM_IMG_HEIGHT = IMG_HEIGHT > FILE_IMG_HEIGHT ? IMG_HEIGHT : FILE_IMG_HEIGHT;


    logic   [COMPONENTS-1:0][DATA_BITS-1:0]    mem     [MEM_IMG_HEIGHT][MEM_IMG_WIDTH];

    int     x = 0;
    int     y = 0;
    int     f = 0;


    // -----------------------------
    //  read image file
    // -----------------------------

    task    image_clear();
    begin
        for ( int i = 0; i < IMG_HEIGHT; i++ ) begin
            for ( int j = 0; j < IMG_WIDTH; j++ ) begin
                for ( int k = 0; k < COMPONENTS; k++ ) begin
                    automatic int data;
                    data = 0;
                    if ( k == 0 ) data = j;
                    if ( k == 1 ) data = i;
                    if ( k == 2 ) data = f;
                    mem[i][j][k] = DATA_BITS'(data);
                end
            end
        end
    end
    endtask

    task    image_read();
    begin
        automatic string filename;
        automatic int fp;
        automatic int n;
        filename = SEQUENTIAL_FILE ? {FILE_NAME, $sformatf("%04d", f), FILE_EXT} : {FILE_NAME, FILE_EXT};
        fp = $fopen(filename, "r");
        if ( fp == 0 ) begin
            $display("file open error : %s", filename);
        end
        else begin
            automatic string format;
            automatic int    width, height, maxval;
            n = $fscanf(fp, "%s %d %d %d", format, width, height, maxval);
            $display("[read] %s: format=%s width=%0d height=%0d maxval=%0d", filename, format, width, height, maxval);
            for ( int i = 0; i < FILE_IMG_HEIGHT; i++ ) begin
                for ( int j = 0; j < FILE_IMG_WIDTH; j++ ) begin
                    for ( int k = 0; k < COMPONENTS; k++ ) begin
                        int data;
                        n = $fscanf(fp, "%d", data);
                        if ( ENDIAN ) begin
                            mem[i][j][COMPONENTS-1-k] = DATA_BITS'(data);                            
                        end
                        else begin
                            mem[i][j][k] = DATA_BITS'(data);
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

    localparam TOTAL_H = IMG_WIDTH + H_BLANK;
    localparam TOTAL_V = IMG_HEIGHT + V_BLANK;
    
    reg     [31:0]  rand_seed = RANDOM_SEED;

    logic           valid;

    always_ff @(posedge m_axi4s.aclk) begin
        if ( !m_axi4s.aresetn ) begin
            busy  <= 1'b0;
            x     <= 0;
            y     <= 0;
            valid <= 1'b0;
        end
        else if ( m_axi4s.aclken ) begin
            if ( !busy ) begin
                if ( enable ) begin
                    if ( FILE_NAME != "" ) begin
                        image_read();
                    end
                    busy  <= 1'b1;
                    x     <= 0;
                    y     <= 0;
                end
            end
            else if ( valid && (!m_axi4s.tvalid || m_axi4s.tready) ) begin
                x <= x + 1;
                if ( x >= (TOTAL_H-1) ) begin
                    x <= 0;
                    y <= y + 1;
                    if ( y >= (TOTAL_V-1) ) begin
                        y <= 0;
                        f <= f + 1;
                        busy <= 1'b0;
                    end
                end
            end
            
            if ( !m_axi4s.tvalid || m_axi4s.tready ) begin
                int rand_val;
                rand_val = int'({$random(rand_seed)} % 100); 
                valid <= (rand_val >= BUSY_RATE);
            end
        end
    end
    

    assign m_axi4s.tuser  = !m_axi4s.tvalid ? 'x : (x == 0) && (y == 0);
    assign m_axi4s.tlast  = !m_axi4s.tvalid ? 'x : (x == IMG_WIDTH-1);
    assign m_axi4s.tdata  = !m_axi4s.tvalid ? 'x : m_axi4s.DATA_BITS'(mem[y][x]);
    assign m_axi4s.tvalid = busy && valid && (x < IMG_WIDTH && y < IMG_HEIGHT);

    assign out_x = x_t'(x);
    assign out_y = y_t'(y);
    assign out_f = f_t'(f);

endmodule


`default_nettype wire


// end of file

