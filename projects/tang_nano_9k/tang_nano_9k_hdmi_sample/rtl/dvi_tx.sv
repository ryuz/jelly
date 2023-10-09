


`timescale 1ns / 1ps
`default_nettype none


module dvi_tx
        (
            input   var logic               reset,
            input   var logic               clk,
            input   var logic               clk_x5,

            // input    
            input   var logic               in_vsync,
            input   var logic               in_hsync,
            input   var logic               in_de,
            input   var logic   [2:0][7:0]  in_data,
            input   var logic   [3:0]       in_ctl,
            
            // output
            output  var logic               out_clk_p,
            output  var logic               out_clk_n,
            output  var logic   [2:0]       out_data_p,
            output  var logic   [2:0]       out_data_n
        );
    
    
    // -----------------------------
    //  encode
    // -----------------------------
    
    logic   [2:0][9:0]  enc_data;
    
    for ( genvar i = 0; i < 3; ++i ) begin
        jelly_dvi_tx_encode
            u_dvi_tx_encode
                (
                    .reset      (reset),
                    .clk        (clk),
                    
                    .in_de      (in_de),
                    .in_d       (in_data[i]),
                    .in_c0      (in_hsync),
                    .in_c1      (in_vsync),
                    
                    .out_d      (enc_data[i])
                );
    end

    // -----------------------------
    //  serdes
    // -----------------------------

    logic   [2:0]   tmds_d;
    for ( genvar i = 0; i < 3; ++i ) begin
        OSER10
            u_OSER10
                (
                    .Q      (tmds_d[i]),
                    .D0     (enc_data[i][0]),
                    .D1     (enc_data[i][1]),
                    .D2     (enc_data[i][2]),
                    .D3     (enc_data[i][3]),
                    .D4     (enc_data[i][4]),
                    .D5     (enc_data[i][5]),
                    .D6     (enc_data[i][6]),
                    .D7     (enc_data[i][7]),
                    .D8     (enc_data[i][8]),
                    .D9     (enc_data[i][9]),
                    .PCLK   (clk),
                    .FCLK   (clk_x5),
                    .RESET  (reset)
                );
    end

    // -----------------------------
    //  T.M.D.S output
    // -----------------------------

    ELVDS_OBUF
        u_ELVDS_OBUF_clk
            (
                .I  (clk),
                .O  (out_clk_p),
                .OB (out_clk_n)
            );

    for ( genvar i = 0; i < 3; ++i ) begin
        ELVDS_OBUF
            u_ELVDS_OBUF
                (
                    .I  (tmds_d[i]),
                    .O  (out_data_p[i]),
                    .OB (out_data_n[i])
                );
    end

    /*
    // -----------------------------
    //  serdes
    // -----------------------------
    
    wire    serdes_clk;
    wire    serdes_data0;
    wire    serdes_data1;
    wire    serdes_data2;

    jelly_serdes_10to1_7series
        i_serdes_10to1_clk
            (
                .reset      (reset),
                .clk        (clk),
                .clk_x5     (clk_x5),
                
                .in_data    (10'b00000_11111),
                
                .out_data   (serdes_clk)
            );
    
    jelly_serdes_10to1_7series
        i_serdes_10to1_0
            (
                .reset      (reset),
                .clk        (clk),
                .clk_x5     (clk_x5),
                
                .in_data    (enc_data0),
                
                .out_data   (serdes_data0)
            );
    
    jelly_serdes_10to1_7series
        i_serdes_10to1_1
            (
                .reset      (reset),
                .clk        (clk),
                .clk_x5     (clk_x5),
                
                .in_data    (enc_data1),
                
                .out_data   (serdes_data1)
            );

    jelly_serdes_10to1_7series
        i_serdes_10to1_2
            (
                .reset      (reset),
                .clk        (clk),
                .clk_x5     (clk_x5),
                
                .in_data    (enc_data2),
                
                .out_data   (serdes_data2)
            );
    
    
    // -----------------------------
    //  T.M.D.S output
    // -----------------------------
    
    OBUFDS
            #(
                .IOSTANDARD ("TMDS_33")
            )
        i_obufds_clk
            (
                .I          (serdes_clk),
                .O          (out_clk_p),
                .OB         (out_clk_n)
            );
    
    OBUFDS
            #(
                .IOSTANDARD ("TMDS_33")
            )
        i_obufds_0
            (
                .I          (serdes_data0),
                .O          (out_data_p[0]),
                .OB         (out_data_n[0])
            );
    
    OBUFDS
            #(
                .IOSTANDARD ("TMDS_33")
            )
        i_obufds_1
            (
                .I          (serdes_data1),
                .O          (out_data_p[1]),
                .OB         (out_data_n[1])
            );
    
    OBUFDS
            #(
                .IOSTANDARD ("TMDS_33")
            )
        i_obufds_2
            (
                .I          (serdes_data2),
                .O          (out_data_p[2]),
                .OB         (out_data_n[2])
            );
    */

endmodule


`default_nettype wire


// end of file
