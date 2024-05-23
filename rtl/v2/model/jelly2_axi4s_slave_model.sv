// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_axi4s_slave_model
        #(
            parameter   int     COMPONENTS       = 3,
            parameter   int     DATA_WIDTH       = 8,
            parameter   int     INIT_FRAME_NUM   = 0,
            parameter   int     X_WIDTH          = 32,
            parameter   int     Y_WIDTH          = 32,
            parameter   int     F_WIDTH          = 32,
            parameter   string  FORMAT           = "P3",
            parameter   string  FILE_NAME        = "img_",
            parameter   string  FILE_EXT         = ".ppm",
            parameter   bit     SEQUENTIAL_FILE  = 1,
            parameter   bit     ENDIAN           = 0,
            parameter   int     BUSY_RATE        = 0,
            parameter   int     RANDOM_SEED      = 0,

            localparam  int     AXI4S_DATA_WIDTH = COMPONENTS * DATA_WIDTH
        )
        (
            input   wire                            aresetn,
            input   wire                            aclk,
            input   wire                            aclken,

            input   wire    [X_WIDTH-1:0]           param_width,
            input   wire    [Y_WIDTH-1:0]           param_height,
            output  wire    [F_WIDTH-1:0]           frame_num,
            
            input   wire    [0:0]                   s_axi4s_tuser,
            input   wire                            s_axi4s_tlast,
            input   wire    [AXI4S_DATA_WIDTH-1:0]  s_axi4s_tdata,
            input   wire                            s_axi4s_tvalid,
            output  reg                             s_axi4s_tready
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


    integer         rand_seed = RANDOM_SEED;
    int             a = 0;
    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            s_axi4s_tready <= 1'b0;
        end
        else if ( aclken ) begin
            int rand_val;
            rand_val = int'({$random(rand_seed)} % 100); 
            s_axi4s_tready <= (rand_val >= BUSY_RATE);
            a += 1;
            
            if ( s_axi4s_tvalid && s_axi4s_tready ) begin
                if ( s_axi4s_tuser[0] ) begin
                    frame_start();
                end
                if ( fp != 0) begin
                    for ( int i = 0; i < COMPONENTS; ++i ) begin
                        logic [COMPONENTS-1:0][DATA_WIDTH-1:0]  data;
                        data = s_axi4s_tdata;
                        if ( ENDIAN ) begin
                            $fdisplay(fp, "%d", data[COMPONENTS-1-i]);
                        end
                        else begin
                            $fdisplay(fp, "%d", data[i]);
                        end
                    end
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
