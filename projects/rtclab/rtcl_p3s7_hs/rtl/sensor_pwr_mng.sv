
`timescale 1ns / 1ps
`default_nettype none

module sensor_pwr_mng
        (
            input   var logic           clk72                   ,
            input   var logic           reset                   ,

            input   var logic           enable                  ,
            output  var logic           ready                   ,

            output  var logic           sensor_pwr_en_vdd18     ,
            output  var logic           sensor_pwr_en_vdd33     ,
            output  var logic           sensor_pwr_en_pix       ,
            input   var logic           sensor_pgood            ,

            output  var logic           python_reset_n          ,
            output  var logic           python_clk_pll          
        );
    
    // PGOOD ラッチ
    (* ASYNC_REG = "true" *)
    logic           ff0_pgood, ff1_pgood;
    always_ff @(posedge clk72 or negedge sensor_pgood) begin
        if ( ~sensor_pgood ) begin
            ff0_pgood <= 1'b0;
            ff1_pgood <= 1'b0;
        end
        else begin
            ff0_pgood <= 1'b1;
            ff1_pgood <= ff0_pgood;
        end
    end

    // prescaler (74MHz -> 100kHz)
    logic   [9:0]   prescl_counter = '0;
    logic           prescl_pulse = 1'b0;
    always_ff @(posedge clk72) begin
        if ( reset ) begin
            prescl_counter <= '0;
            prescl_pulse   <= 1'b0;
        end
        else begin
            prescl_counter <= prescl_counter + 1;
            prescl_pulse   <= 1'b0;
            if ( prescl_counter >= 10'd719 ) begin
                prescl_counter <= '0;
                prescl_pulse   <= 1'b1;
            end
        end
    end

    // sensor power management
    logic  [2:0]    pwr_counter;
    logic           mng_vdd_18_en   = 1'b0;
    logic           mng_vdd_33_en   = 1'b0;
    logic           mng_vdd_pix3_en = 1'b0;
    logic           mng_clk_en      = 1'b0;
    logic           mng_reset_n     = 1'b0;
    always_ff @(posedge clk72) begin
        if ( reset ) begin
            pwr_counter <= '0;
            mng_vdd_18_en   <= 1'b0;
            mng_vdd_33_en   <= 1'b0;
            mng_vdd_pix3_en <= 1'b0;
            mng_clk_en      <= 1'b0;
            mng_reset_n     <= 1'b0;
        end
        else begin
            if ( prescl_pulse ) begin
                if ( enable && ff1_pgood ) begin
                    if ( pwr_counter < 3'd7 ) begin
                        pwr_counter <= pwr_counter + 1;
                    end
                end
                else begin
                    if ( pwr_counter > 3'd0 ) begin
                        pwr_counter <= pwr_counter - 1;
                    end
                end
            end
            mng_vdd_18_en   <= pwr_counter > 3'd1;
            mng_vdd_33_en   <= pwr_counter > 3'd2;
            mng_vdd_pix3_en <= pwr_counter > 3'd3;
            mng_clk_en      <= pwr_counter > 3'd4;
            mng_reset_n     <= pwr_counter > 3'd5;
            ready           <= pwr_counter > 3'd6;
        end
    end

    assign sensor_pwr_en_vdd18 = mng_vdd_18_en      ;
    assign sensor_pwr_en_vdd33 = mng_vdd_33_en      ;
    assign sensor_pwr_en_pix   = mng_vdd_pix3_en    ;

    assign python_reset_n      = mng_reset_n        ;

    ODDR
            #(
                .DDR_CLK_EDGE   ("SAME_EDGE")
            )
        u_oddrc_python_clk_pll
            (
                .Q      (python_clk_pll  ),
                .C      (clk72           ),
                .CE     (1'b1            ),
                .D1     (mng_clk_en      ),
                .D2     (1'b0            ),
                .R      (1'b0            ),
                .S      (1'b0            )
            );

endmodule

`default_nettype wire

// end of file
