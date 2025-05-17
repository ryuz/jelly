
`timescale 1ns / 1ps
`default_nettype none


module python_to_axi4s
        (
            input   var logic   [3:0][9:0]  s_data      ,
            input   var logic        [9:0]  s_sync      ,
            input   var logic               s_valid     ,

            jelly3_axi4s_if.m               m_axi4s
        );

    logic enable;
    initial begin
        enable = 0;
        #1000
        enable = 1;
    end

    localparam LANES   = 4  ;
    localparam WIDTH   = 640;
    localparam HEIGHT  = 480;

    logic                   tuser   ;
    logic                   tlast   ;
    logic [LANES-1:0][9:0]  tdata   ;
    logic                   tvalid  ;
    initial begin
        tuser  = 'x;
        tlast  = 'x;
        tdata  = 'x;
        tvalid = 1'b0;
        #10000;

        forever begin
            for ( int y = 0; y < HEIGHT; y++ ) begin
                for ( int x = 0; x < WIDTH/LANES; x++ ) begin
                    @(posedge m_axi4s.aclk) #0;
                    tuser  = (y == 0 && x == 0);
                    tlast  = (x >= WIDTH/LANES - 1);
                    for ( int i = 0; i < LANES; i++ ) begin
                        tdata[i] = tuser ? i : tdata[i] + LANES;
                    end
                    tvalid = 1'b1;

                    @(posedge m_axi4s.aclk) #0;
                    tvalid = 1'b0;
                    @(posedge m_axi4s.aclk) #0;
                    tvalid = 1'b0;
                    @(posedge m_axi4s.aclk) #0;
                    tvalid = 1'b0;
                    @(posedge m_axi4s.aclk) #0;
                    tvalid = 1'b0;
                end

                @(posedge m_axi4s.aclk) #0;
                tuser  = '0;
                tlast  = '0;
//              tdata  = '0;
                tvalid = 1'b0;
                for ( int i = 0; i < 600; i++ ) begin
                    @(posedge m_axi4s.aclk) #0;
                end
            end
            for ( int i = 0; i < 256; i++ ) begin
                @(posedge m_axi4s.aclk) #0;
            end
        end
    end

    assign m_axi4s.tuser  = tvalid ? tuser : 'x;
    assign m_axi4s.tlast  = tvalid ? tlast : 'x;
    assign m_axi4s.tdata  = tvalid ? tdata : 'x;
    assign m_axi4s.tvalid = tvalid;

    /*
    jelly3_model_axi4s_m
            #(
                .COMPONENTS     (4      ),
                .DATA_BITS      (10     ),
                .IMG_WIDTH      (640/4  ),
                .IMG_HEIGHT     (480    ),
                .H_BLANK        (32     ),
                .V_BLANK        (16     ),
                .X_BITS         (32     ),
                .BUSY_RATE      (80     ),
                .RANDOM_SEED    (0      ),
                .ENDIAN         (0      )
            )
        u_model_axi4s_m
            (
                .enable         (enable ),
                .busy           (       ),
                .m_axi4s        (m_axi4s),
                .out_x          (       ),
                .out_y          (       ),
                .out_f          (       )
            );
    */

endmodule

`default_nettype wire

// end of file
