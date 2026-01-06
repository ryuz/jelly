// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_model_axi4s_dump
        #(
            parameter   int     COMPONENTS       = 3                    ,
            parameter   int     DATA_BITS        = 8                    ,
            parameter   int     INIT_FRAME_NUM   = 0                    ,
            parameter   int     X_BITS           = 32                   ,
            parameter   type    x_t              = logic [X_BITS-1:0]   ,
            parameter   int     Y_BITS           = 32                   ,
            parameter   type    y_t              = logic [Y_BITS-1:0]   ,
            parameter   int     F_BITS           = 32                   ,
            parameter   type    f_t              = logic [F_BITS-1:0]   ,
            parameter   string  FORMAT           = "P3"                 ,
            parameter   string  FILE_NAME        = "img_"               ,
            parameter   string  FILE_EXT         = ".ppm"               ,
            parameter   bit     SEQUENTIAL_FILE  = 1                    ,
            parameter   bit     ENDIAN           = 0                    
        )
        (
            input   var x_t         param_width     ,
            input   var y_t         param_height    ,
            output  var f_t         frame_num       ,
            
            jelly3_axi4s_if.mon     mon_axi4s       
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
            $fdisplay(fp, "%0d", (1 << DATA_BITS)-1);
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

    always_ff @(posedge mon_axi4s.aclk) begin
        if ( ~mon_axi4s.aresetn ) begin
        end
        else if ( mon_axi4s.aclken ) begin
            if ( mon_axi4s.tvalid && mon_axi4s.tready ) begin
                if ( mon_axi4s.tuser[0] ) begin
                    frame_start();
                end
                if ( fp != 0) begin
                    for ( int i = 0; i < COMPONENTS; i++ ) begin
                        logic [COMPONENTS-1:0][DATA_BITS-1:0]  data;
                        data = (COMPONENTS*DATA_BITS)'(mon_axi4s.tdata);
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
