
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );
    
    // -----------------------------
    //  target
    // -----------------------------

    localparam  int     N            = 3                            ;
    localparam  int     USER_BITS    = 8                            ;
    localparam  type    user_t       = logic    [USER_BITS-1:0]     ;
    localparam  int     DATA_BITS    = 16                           ;
    localparam  type    data_t       = logic    [DATA_BITS-1:0]     ;
    localparam  int     BUF_SIZE     = 1024                         ;
    localparam          RAM_TYPE     = "block"                      ;
    localparam  bit     DOUT_REG     = 1'b1                         ;

    logic           cke     ;
    user_t          s_user  ;
    data_t          s_data  ;
    logic           s_last  ;
    logic           s_valid ;
    user_t  [N-1:0] m_user  ;
    data_t  [N-1:0] m_data  ;
    logic           m_last  ;
    logic   [N-1:0] m_valid ;

    jelly3_line_buffer_sdp
        #(
                .N              (N          ),
                .USER_BITS      (USER_BITS  ),
                .user_t         (user_t     ),
                .DATA_BITS      (DATA_BITS  ),
                .data_t         (data_t     ),
                .BUF_SIZE       (BUF_SIZE   ),
                .RAM_TYPE       (RAM_TYPE   ),
                .DOUT_REG       (DOUT_REG   )
            )
        u_line_buffer_sdp
            (
                .reset   ,
                .clk     ,
                .cke     ,

                .s_user  ,
                .s_data  ,
                .s_last  ,
                .s_valid ,
                
                .m_user  ,
                .m_data  ,
                .m_last  ,
                .m_valid 
            );
    


    // -----------------------------
    //  model
    // -----------------------------

    jelly3_axi4s_if
            #(
                .USER_BITS      (1          ),
                .DATA_BITS      (DATA_BITS  )
            )
        axi4s_src
            (
                .aresetn        (~reset     ),
                .aclk           (clk        ),
                .aclken         (cke        )
            );

    logic   [31:0]    out_x   ;
    logic   [31:0]    out_y   ;
    logic   [31:0]    out_f   ;

    jelly3_model_axi4s_m
            #(
                .IMG_WIDTH      (64             ),
                .IMG_HEIGHT     (64             ),
                .BUSY_RATE      (0              ),
                .RANDOM_SEED    (123            )
            )
        u_model_axi4s_m
            (
                .aclken         (cke            ),
                .enable         (1'b1           ),
                .busy           (               ),

                .m_axi4s        (axi4s_src.m    ),
                .out_x          (out_x          ),
                .out_y          (out_y          ),
                .out_f          (out_f          )
            );

    always_ff @(posedge clk) begin
        cke <= $random;
    end

    assign s_user  = {axi4s_src.tuser, out_y[6:0]};
    assign s_data  = axi4s_src.tdata    ;
    assign s_last  = axi4s_src.tlast    ;
    assign s_valid = axi4s_src.tvalid   ;
    
    assign axi4s_src.tready = 1'b1;


    int  fp;
    initial begin
        fp = $fopen("output_log.txt", "w");
    end
    int count = 0;
    always_ff @(posedge clk) begin
        if ( !reset && cke && m_valid ) begin
            $fwrite(fp, "%b_%3b_%02h_%02h_%02h__%04h_%04h_%04h\n", m_last, m_valid, m_user[2], m_user[1], m_user[0], m_data[2], m_data[1], m_data[0]);
            count++;
            if ( count >= 64*64*2 ) begin
                $fclose(fp);
                $finish;
            end
        end
    end


endmodule


`default_nettype wire


// end of file
