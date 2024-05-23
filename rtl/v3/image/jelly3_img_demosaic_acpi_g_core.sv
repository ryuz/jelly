// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_demosaic_acpi_g_core
        #(
            parameter   int     DATA_BITS = 10,
            parameter   type    data_t    = logic [DATA_BITS-1:0],
            parameter   int     MAX_COLS  = 4096,
            parameter           RAM_TYPE  = "block",
            localparam  type    phase_t   = logic [1:0]
        )
        (
            input   var phase_t param_phase,
            jelly3_img_if.s     s_img,
            jelly3_img_if.m     m_img
        );
    
    localparam  int     USER_BITS = s_img.USER_BITS;
    localparam  type    user_t    = logic   [USER_BITS-1:0];
    
    logic               img_blk_row_first;
    logic               img_blk_row_last;
    logic               img_blk_col_first;
    logic               img_blk_col_last;
    user_t              img_blk_user;
    logic               img_blk_de;
    data_t  [4:0][4:0]  img_blk_raw;
    logic               img_blk_valid;
    
    jelly2_img_blk_buffer
            #(
                .M                  (5                  ),
                .N                  (5                  ),
                .USER_WIDTH         (USER_BITS          ),
                .DATA_WIDTH         (DATA_BITS          ),
                .MAX_COLS           (MAX_COLS           ),
                .RAM_TYPE           (RAM_TYPE           ),
                .BORDER_MODE        ("REFLECT_101"      )
            )
        u_img_blk_buffer
            (
                .reset              (s_img.reset        ),
                .clk                (s_img.clk          ),
                .cke                (s_img.cke          ),

                .s_img_row_first    (s_img.row_first    ),
                .s_img_row_last     (s_img.row_last     ),
                .s_img_col_first    (s_img.col_first    ),
                .s_img_col_last     (s_img.col_last     ),
                .s_img_de           (s_img.de           ),
                .s_img_user         (s_img.user         ),
                .s_img_data         (s_img.data         ),
                .s_img_valid        (s_img.valid        ),
                
                .m_img_row_first    (img_blk_row_first  ),
                .m_img_row_last     (img_blk_row_last   ),
                .m_img_col_first    (img_blk_col_first  ),
                .m_img_col_last     (img_blk_col_last   ),
                .m_img_de           (img_blk_de         ),
                .m_img_user         (img_blk_user       ),
                .m_img_data         (img_blk_raw        ),
                .m_img_valid        (img_blk_valid      )
            );
    

    data_t          acpi_raw;
    data_t          acpi_g;

    jelly3_img_demosaic_acpi_g_calc
            #(
                .DATA_BITS          (DATA_BITS  ),
                .data_t             (data_t     )
            )
        u_img_demosaic_acpi_g_calc
            (
                .reset              (s_img.reset),
                .clk                (s_img.clk  ),
                .cke                (s_img.cke  ),

                .param_phase        (param_phase),
                
                .in_line_first      (img_blk_row_first & img_blk_valid  ),
                .in_pixel_first     (img_blk_col_first & img_blk_valid  ),
                .in_raw             (img_blk_raw                        ),
                
                .out_raw            (acpi_raw   ),
                .out_g              (acpi_g     )
            );
    assign m_img.data = {acpi_g, acpi_raw};
    
    jelly2_img_delay
            #(
                .USER_WIDTH         (USER_BITS          ),
                .LATENCY            (7                  ),
                .USE_VALID          (m_img.USE_VALID    )
            )
        u_img_delay
            (
                .reset              (m_img.reset        ),
                .clk                (m_img.clk          ),
                .cke                (m_img.cke          ),
                
                .s_img_row_first    (img_blk_row_first  ),
                .s_img_row_last     (img_blk_row_last   ),
                .s_img_col_first    (img_blk_col_first  ),
                .s_img_col_last     (img_blk_col_last   ),
                .s_img_de           (img_blk_de         ),
                .s_img_user         (img_blk_user       ),
                .s_img_valid        (img_blk_valid      ),
                
                .m_img_row_first    (m_img.row_first    ),
                .m_img_row_last     (m_img.row_last     ),
                .m_img_col_first    (m_img.col_first    ),
                .m_img_col_last     (m_img.col_last     ),
                .m_img_de           (m_img.de           ),
                .m_img_user         (m_img.user         ),
                .m_img_valid        (m_img.valid        )
            );
    

    // assertion
    initial begin
        sva_data_bits   : assert ( DATA_BITS == s_img.DATA_BITS ) else $warning("DATA_BITS != s_img.DATA_BITS");
        sva_m_data_bits : assert ( m_img.DATA_BITS == s_img.DATA_BITS * 2) else $warning("m_img.DATA_BITS != s_img.DATA_BITS * 2");
    end
    always_comb begin
        sva_connect_clk : assert (m_img.clk === s_img.clk);
    end

endmodule


`default_nettype wire


// end of file
