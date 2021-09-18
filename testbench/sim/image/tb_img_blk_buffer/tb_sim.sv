
`timescale 1ns/1ps

module tb_sim(
            input   logic   reset,
            input   logic   clk
        );

    parameter   USER_WIDTH = 1;
    parameter   DATA_WIDTH = 8;
    
    parameter   X_NUM      = 16;
    parameter   Y_NUM      = 8;
    
    parameter   X_WIDTH    = 4;
    parameter   Y_WIDTH    = 3;
    
    parameter   PGM_FILE   = "";
    
    parameter   LINE_NUM   = 5;
    parameter   PIXEL_NUM  = 7;
    

    
    // blok
    wire                                        img_blk_line_first;
    wire                                        img_blk_line_last;
    wire                                        img_blk_pixel_first;
    wire                                        img_blk_pixel_last;
    wire                                        img_blk_de;
    wire    [LINE_NUM*PIXEL_NUM*DATA_WIDTH-1:0] img_blk_data;
    wire                                        img_blk_user;
    wire                                        img_blk_valid;
    
    wire    [PIXEL_NUM*DATA_WIDTH-1:0]          img_blk_data0 = img_blk_data[0*PIXEL_NUM*DATA_WIDTH +: PIXEL_NUM*DATA_WIDTH];
    wire    [PIXEL_NUM*DATA_WIDTH-1:0]          img_blk_data1 = img_blk_data[1*PIXEL_NUM*DATA_WIDTH +: PIXEL_NUM*DATA_WIDTH];
    wire    [PIXEL_NUM*DATA_WIDTH-1:0]          img_blk_data2 = img_blk_data[2*PIXEL_NUM*DATA_WIDTH +: PIXEL_NUM*DATA_WIDTH];
    wire    [PIXEL_NUM*DATA_WIDTH-1:0]          img_blk_data3 = img_blk_data[3*PIXEL_NUM*DATA_WIDTH +: PIXEL_NUM*DATA_WIDTH];
    wire    [PIXEL_NUM*DATA_WIDTH-1:0]          img_blk_data4 = img_blk_data[4*PIXEL_NUM*DATA_WIDTH +: PIXEL_NUM*DATA_WIDTH];
    
    jelly2_img_blk_buffer
            #(
                .ROWS                   (LINE_NUM),
                .COLS                   (PIXEL_NUM),
                .DATA_WIDTH             (DATA_WIDTH),
                .COLS_MAX               (1024),
                .RAM_TYPE               ("block"),
//              .BORDER_MODE            ("CONSTANT")    // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
//              .BORDER_MODE            ("CONSTANT")
//              .BORDER_MODE            ("REPLICATE")
//              .BORDER_MODE            ("REFLECT")
                .BORDER_MODE            ("REFLECT_101")
            )
        i_img_blk_buffer
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (img_cke),
                
                .s_img_row_first        (src_img_line_first),
                .s_img_row_last         (src_img_line_last),
                .s_img_col_first        (src_img_pixel_first),
                .s_img_col_last         (src_img_pixel_last),
                .s_img_de               (src_img_de),
                .s_img_user             (src_img_user),
                .s_img_data             (src_img_data),
                .s_img_valid            (src_img_valid),
                
                .m_img_row_first        (img_blk_line_first),
                .m_img_row_last         (img_blk_line_last),
                .m_img_col_first        (img_blk_pixel_first),
                .m_img_col_last         (img_blk_pixel_last),
                .m_img_de               (img_blk_de),
                .m_img_user             (img_blk_user),
                .m_img_data             (img_blk_data),
                .m_img_valid            (img_blk_valid)
            );
    
            
endmodule


`default_nettype wire


// end of file
