// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2015 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly2_axi4s_master_model
        #(
            parameter   int     COMPONENTS       = 3,
            parameter   int     DATA_WIDTH       = 8,            
            parameter   int     X_NUM            = 640,
            parameter   int     Y_NUM            = 480,
            parameter   int     X_BLANK          = 0,
            parameter   int     Y_BLANK          = 0,
            parameter   int     X_WIDTH          = 32,
            parameter   int     Y_WIDTH          = 32,
            parameter   int     F_WIDTH          = 32,
            parameter   string  FILE_NAME        = "",
            parameter   string  FILE_EXT         = "",
            parameter   bit     SEQUENTIAL_FILE  = 0,
            parameter   int     BUSY_RATE        = 0,
            parameter   int     RANDOM_SEED      = 0,
            parameter   bit     ENDIAN           = 0,

            localparam  int     AXI4S_DATA_WIDTH = COMPONENTS * DATA_WIDTH
        )
        (
            input   wire                            aresetn,
            input   wire                            aclk,
            input   wire                            aclken,
            
            input   wire                            enable,
            output  reg                             busy,

            output  wire    [0:0]                   m_axi4s_tuser,
            output  wire                            m_axi4s_tlast,
            output  wire    [AXI4S_DATA_WIDTH-1:0]  m_axi4s_tdata,
            output  wire    [X_WIDTH-1:0]           m_axi4s_tx,
            output  wire    [Y_WIDTH-1:0]           m_axi4s_ty,
            output  wire    [F_WIDTH-1:0]           m_axi4s_tf,
            output  wire                            m_axi4s_tvalid,
            input   wire                            m_axi4s_tready
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
                    automatic int data = 0;
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
        string filename;
        int fp;
        int n;
        filename = SEQUENTIAL_FILE ? {FILE_NAME, $sformatf("%04d", f), FILE_EXT} : {FILE_NAME, FILE_EXT};
        fp = $fopen(filename, "r");
        if ( fp == 0 ) begin
            $display("file open error : %s", filename);
        end
        else begin
            string format;
            int    width, height, maxval;
            n = $fscanf(fp, "%s %d %d %d", format, width, height, maxval);
            $display("[read] %s: format=%s width=%0d height=%0d maxval=%0d", filename, format, width, height, maxval);
            for ( int i = 0; i < Y_NUM; ++i ) begin
                for ( int j = 0; j < X_NUM; ++j ) begin
                    for ( int k = 0; k < COMPONENTS; ++k ) begin
                        int data;
                        n = $fscanf(fp, "%d", data);
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
    
    reg     [31:0]  rand_seed = RANDOM_SEED;

    logic           valid;

    always @(posedge aclk) begin
        if ( !aresetn ) begin
            busy  <= 1'b0;
            x     <= 0;
            y     <= 0;
            valid <= 1'b0;
        end
        else if ( aclken ) begin
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
            else if ( m_axi4s_tvalid && m_axi4s_tready ) begin
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
            
            if ( !m_axi4s_tvalid || m_axi4s_tready ) begin
                int rand_val;
                rand_val = int'({$random(rand_seed)} % 100); 
                valid <= (rand_val >= BUSY_RATE);
            end
        end
    end
    

    assign m_axi4s_tuser  = !m_axi4s_tvalid ? 'x : (x == 0) && (y == 0);
    assign m_axi4s_tlast  = !m_axi4s_tvalid ? 'x : (x == X_NUM-1);
    assign m_axi4s_tdata  = !m_axi4s_tvalid ? 'x : mem[y][x];
    assign m_axi4s_tx     = !m_axi4s_tvalid ? 'x : X_WIDTH'(x);
    assign m_axi4s_ty     = !m_axi4s_tvalid ? 'x : Y_WIDTH'(y);
    assign m_axi4s_tf     = !m_axi4s_tvalid ? 'x : f;
    assign m_axi4s_tvalid = busy && valid && (x < X_NUM && y < Y_NUM);

endmodule


`default_nettype wire


// end of file
