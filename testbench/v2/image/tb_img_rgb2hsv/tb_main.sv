
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire                        reset,
            input   wire                        clk
        );


    parameter   USER_WIDTH = 0;
    parameter   DATA_WIDTH = 8;            
    parameter   USER_BITS  = USER_WIDTH > 0 ? USER_WIDTH : 1;

    logic                           cke = 1'b1;

    logic                           s_img_row_first;
    logic                           s_img_row_last;
    logic                           s_img_col_first;
    logic                           s_img_col_last;
    logic                           s_img_de;
    logic   [USER_BITS-1:0]         s_img_user;
    logic   [DATA_WIDTH-1:0]        s_img_r;
    logic   [DATA_WIDTH-1:0]        s_img_g;
    logic   [DATA_WIDTH-1:0]        s_img_b;
    logic                           s_img_valid;

    logic                           m_img_row_first;
    logic                           m_img_row_last;
    logic                           m_img_col_first;
    logic                           m_img_col_last;
    logic                           m_img_de;
    logic   [USER_BITS-1:0]         m_img_user;
    logic   [DATA_WIDTH-1:0]        m_img_h;
    logic   [DATA_WIDTH-1:0]        m_img_s;
    logic   [DATA_WIDTH-1:0]        m_img_v;
    logic                           m_img_valid;

    jelly2_img_rgb2hsv
            #(
                .USER_WIDTH         (USER_WIDTH),
                .DATA_WIDTH         (DATA_WIDTH)
            )
        i_img_rgb2hsv
            (
                .reset,
                .clk,
                .cke,
                
                .s_img_row_first,
                .s_img_row_last,
                .s_img_col_first,
                .s_img_col_last,
                .s_img_de,
                .s_img_user,
                .s_img_r,
                .s_img_g,
                .s_img_b,
                .s_img_valid,

                .m_img_row_first,
                .m_img_row_last,
                .m_img_col_first,
                .m_img_col_last,
                .m_img_de,
                .m_img_user,
                .m_img_h,
                .m_img_s,
                .m_img_v,
                .m_img_valid
            );




    jelly2_img_master_model
            #(
                .COMPONENTS         (3),
                .DATA_WIDTH         (8),
                .X_NUM              (256),
                .Y_NUM              (256),
                .X_BLANK            (0),     // 基本ゼロ
                .Y_BLANK            (0),     // 末尾にde落ちラインを追加
                .X_WIDTH            (32),
                .Y_WIDTH            (32),
                .F_WIDTH            (32),
//              .FILE_NAME          ("../../../../data/color/Parrots.ppm"),
                .FILE_NAME          ("../../../../data/col_ptn.ppm"),
                .FILE_EXT           (""),
                .SEQUENTIAL_FILE    (0),
                .ENDIAN             (0)
            )
        i_img_master_model
            (
                .reset,
                .clk,
                .cke,
                
                .enable             (1'b1),
                .busy               (),
                
                .m_img_row_first    (s_img_row_first),
                .m_img_row_last     (s_img_row_last),
                .m_img_col_first    (s_img_col_first),
                .m_img_col_last     (s_img_col_last),
                .m_img_de           (s_img_de),
                .m_img_data         ({s_img_r, s_img_g, s_img_b}),
                .m_img_x            (),
                .m_img_y            (),
                .m_img_f            (),
                .m_img_valid        (s_img_valid)
            );
    
    
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
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (0)
            )
        i_img_slave_model
            (
                .reset,
                .clk,
                .cke,

                .param_width        (256),
                .param_height       (256),
                .frame_num          (),
                
                .s_img_row_first    (m_img_row_first),
                .s_img_row_last     (m_img_row_last),
                .s_img_col_first    (m_img_col_first),
                .s_img_col_last     (m_img_col_last),
                .s_img_de           (m_img_de),
                .s_img_data         ({m_img_h, m_img_s, m_img_v}),
                .s_img_valid        (m_img_valid)
            );
    
endmodule


`default_nettype wire


// end of file
