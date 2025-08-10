


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
                    .RESET  (1'b0)//(reset)
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

endmodule


`default_nettype wire


// end of file
