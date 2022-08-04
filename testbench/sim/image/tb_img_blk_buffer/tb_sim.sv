
`timescale 1ns/1ps


module tb_sim(
            input   logic   reset,
            input   logic   clk
        );


    // ------------------------------------
    //  target
    // ------------------------------------

    parameter   int                         M            = 1;   // block width
    parameter   int                         N            = 7;   // block height
    parameter   int                         USER_WIDTH   = 0;
    parameter   int                         DATA_WIDTH   = 3*8;
    parameter   int                         CENTER_X     = (M-1) / 2;
    parameter   int                         CENTER_Y     = (N-1) / 2;
    parameter   int                         MAX_COLS     = 1024;
    parameter   string                      BORDER_MODE  = "REFLECT_101";   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
    parameter   logic   [DATA_WIDTH-1:0]    BORDER_VALUE = {DATA_WIDTH{1'b0}};
    parameter                               RAM_TYPE     = "block";
    parameter   bit                         ENDIAN       = 0;               // 0: little, 1:big

    localparam  int                         USER_BITS    = USER_WIDTH > 0 ? USER_WIDTH : 1;
    
    wire                                    cke = 1;

    wire                                    s_img_row_first;
    wire                                    s_img_row_last;
    wire                                    s_img_col_first;
    wire                                    s_img_col_last;
    wire                                    s_img_de;
    wire    [USER_BITS-1:0]                 s_img_user;
    wire    [DATA_WIDTH-1:0]                s_img_data;
    wire                                    s_img_valid;

    wire                                    m_img_row_first;
    wire                                    m_img_row_last;
    wire                                    m_img_col_first;
    wire                                    m_img_col_last;
    wire                                    m_img_de;
    wire    [USER_BITS-1:0]                 m_img_user;
    wire    [N-1:0][M-1:0][DATA_WIDTH-1:0]  m_img_data;
    wire                                    m_img_valid;
    
 //   wire    [PIXEL_NUM*DATA_WIDTH-1:0]          img_blk_data0 = img_blk_data[0*PIXEL_NUM*DATA_WIDTH +: PIXEL_NUM*DATA_WIDTH];
 //   wire    [PIXEL_NUM*DATA_WIDTH-1:0]          img_blk_data1 = img_blk_data[1*PIXEL_NUM*DATA_WIDTH +: PIXEL_NUM*DATA_WIDTH];
 //   wire    [PIXEL_NUM*DATA_WIDTH-1:0]          img_blk_data2 = img_blk_data[2*PIXEL_NUM*DATA_WIDTH +: PIXEL_NUM*DATA_WIDTH];
 //   wire    [PIXEL_NUM*DATA_WIDTH-1:0]          img_blk_data3 = img_blk_data[3*PIXEL_NUM*DATA_WIDTH +: PIXEL_NUM*DATA_WIDTH];
 //   wire    [PIXEL_NUM*DATA_WIDTH-1:0]          img_blk_data4 = img_blk_data[4*PIXEL_NUM*DATA_WIDTH +: PIXEL_NUM*DATA_WIDTH];
    
    jelly2_img_blk_buffer
            #(
                .M                  (M           ),
                .N                  (N           ),
                .USER_WIDTH         (USER_WIDTH  ),
                .DATA_WIDTH         (DATA_WIDTH  ),
                .CENTER_X           (CENTER_X    ),
                .CENTER_Y           (CENTER_Y    ),
                .MAX_COLS           (MAX_COLS    ),
                .BORDER_MODE        (BORDER_MODE ),
                .BORDER_VALUE       (BORDER_VALUE),
                .RAM_TYPE           (RAM_TYPE    ),
                .ENDIAN             (ENDIAN      )
            )
        i_img_blk_buffer
            (
                .*
            );



    // ------------------------------------
    //  image read
    // ------------------------------------

    
    parameter   string  IMAGE_FILE  = "../Mandrill.ppm";
    parameter   int     IMAGE_WIDTH = 256;
    parameter   int     IMAGE_HEIGHT= 256;
    
//  parameter   string  IMAGE_FILE  = "";
//  parameter   int     IMAGE_WIDTH = 8;
//  parameter   int     IMAGE_HEIGHT= 8;

    jelly2_img_master_model
            #(
                .COMPONENTS         (3),
                .DATA_WIDTH         (8),
                .X_NUM              (IMAGE_WIDTH),
                .Y_NUM              (IMAGE_HEIGHT),
                .X_BLANK            (0),     // 基本ゼロ
                .Y_BLANK            (8),     // 末尾にde落ちラインを追加
                .X_WIDTH            (32),
                .Y_WIDTH            (32),
                .FILE_NAME          (IMAGE_FILE),
                .FILE_EXT           (""),
                .SEQUENTIAL_FILE    (0)
            )
        i_img_master_model
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .enable             (1'b1),
                .busy               (),

                .m_img_row_first    (s_img_row_first),
                .m_img_row_last     (s_img_row_last),
                .m_img_col_first    (s_img_col_first),
                .m_img_col_last     (s_img_col_last),
                .m_img_de           (s_img_de),
                .m_img_data         (s_img_data),
                .m_img_x            (),
                .m_img_y            (),
                .m_img_f            (),
                .m_img_valid        (s_img_valid)
            );

    // save
    int    frame_num;

    jelly2_img_slave_model
            #(
                .COMPONENTS         (3),
                .DATA_WIDTH         (8),
                .INIT_FRAME_NUM     (0),
                .X_WIDTH            (32),
                .Y_WIDTH            (32),
                .F_WIDTH            (32),
                .FORMAT             ("P3"),
                .FILE_NAME          ("img_"),
                .FILE_EXT           (".ppm"),
                .SEQUENTIAL_FILE    (1)
            )
        i_img_slave_model
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),

                .param_width        (IMAGE_WIDTH),
                .param_height       (IMAGE_HEIGHT),
                .frame_num          (frame_num),
                
                .s_img_row_first    (m_img_row_first),
                .s_img_row_last     (m_img_row_last),
                .s_img_col_first    (m_img_col_first),
                .s_img_col_last     (m_img_col_last),
                .s_img_de           (m_img_de),
                .s_img_data         (m_img_data[CENTER_Y][CENTER_X]),
                .s_img_valid        (m_img_valid)
            );
    
    always_ff @(posedge clk) begin
        if ( frame_num > 3 ) begin
            $finish();
        end
    end

endmodule


/*
module tb_sim3(
            input   logic   reset,
            input   logic   clk
        );

    parameter   int                         USER_WIDTH   = 0;
    parameter   int                         DATA_WIDTH   = 8;
    parameter   int                         N            = 3;
    parameter   int                         CENTER       = (N-1) / 2;
    parameter   int                         MAX_COLS     = 1024;
    parameter   string                      BORDER_MODE  = "REPLICATE";         // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
    parameter   logic   [DATA_WIDTH-1:0]    BORDER_VALUE = {DATA_WIDTH{1'b0}};  // BORDER_MODE == "CONSTANT"
    parameter                               RAM_TYPE     = "block";
    parameter   bit                         ENDIAN       = 0;                   // 0: little, 1:big

    localparam  int  USER_BITS    = USER_WIDTH > 0 ? USER_WIDTH : 1;

    logic                               cke;
    
    logic                               s_img_row_first;
    logic                               s_img_row_last;
    logic                               s_img_col_first;
    logic                               s_img_col_last;
    logic                               s_img_de;
    logic   [USER_BITS-1:0]             s_img_user;
    logic   [DATA_WIDTH-1:0]            s_img_data;
    logic                               s_img_valid;
    
    logic                               m_img_row_first;
    logic                               m_img_row_last;
    logic                               m_img_col_first;
    logic                               m_img_col_last;
    logic                               m_img_de;
    logic   [USER_BITS-1:0]             m_img_user;
    logic   [N-1:0][DATA_WIDTH-1:0]     m_img_data;
    logic                               m_img_valid;

    jelly2_img_line_buffer
            #(
                .USER_WIDTH         (USER_WIDTH  ),
                .DATA_WIDTH         (DATA_WIDTH  ),
                .N                  (N           ),
                .CENTER             (CENTER      ),
                .MAX_COLS           (MAX_COLS    ),
                .BORDER_MODE        (BORDER_MODE ),
                .BORDER_VALUE       (BORDER_VALUE),
                .RAM_TYPE           (RAM_TYPE    ),
                .ENDIAN             (ENDIAN      )
            )
        i_img_line_buffer
            (
                .*
            );

endmodule
*/

/*
module tb_sim2(
            input   logic   reset,
            input   logic   clk
        );

    parameter   int                         USER_WIDTH   = 0;
    parameter   int                         DATA_WIDTH   = 3*8;
    parameter   int                         M            = 3;
    parameter   int                         CENTER       = (M - 1) / 2;
    parameter   string                      BORDER_MODE  = "REPLICATE";         // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
    parameter   logic   [DATA_WIDTH-1:0]    BORDER_VALUE = {DATA_WIDTH{1'b0}};  // BORDER_MODE == "CONSTANT"
    parameter   bit                         ENDIAN       = 0;                   // 0: little, 1:big
    
    parameter   int                         USER_BITS    = USER_WIDTH > 0 ? USER_WIDTH : 1;


    wire                                cke;
    
    wire                                s_img_row_first;
    wire                                s_img_row_last;
    wire                                s_img_col_first;
    wire                                s_img_col_last;
    wire                                s_img_de;
    wire    [USER_BITS-1:0]             s_img_user;
    wire    [DATA_WIDTH-1:0]            s_img_data;
    wire                                s_img_valid;
    
    wire                                m_img_row_first;
    wire                                m_img_row_last;
    wire                                m_img_col_first;
    wire                                m_img_col_last;
    wire                                m_img_de;
    wire    [USER_BITS-1:0]             m_img_user;
    wire    [M-1:0][DATA_WIDTH-1:0]     m_img_data;
    wire                                m_img_valid;

    jelly2_img_pixel_buffer
            #(
                .USER_WIDTH     (USER_WIDTH  ),
                .DATA_WIDTH     (DATA_WIDTH  ),
                .M              (M),
                .CENTER         (CENTER),
                .BORDER_MODE    (BORDER_MODE ),
                .BORDER_VALUE   (BORDER_VALUE),
                .ENDIAN         (ENDIAN      )
            )
        i_img_pixel_buffer
            (
                .*
            );
endmodule
*/





`default_nettype wire


// end of file
