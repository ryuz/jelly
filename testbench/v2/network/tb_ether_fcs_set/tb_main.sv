
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(
            parameter bit          DEBUG        = 1'b0,
            parameter bit          SIMULATION   = 1'b0
        )
        (
            input   wire        reset,
            input   wire        clk
        );

    localparam bit  RAND = 1;

    logic               cke                 ;

    logic   [1:0]       s_packet_index      ;
    logic               s_packet_fcs        ;
    logic               s_packet_crc_start  ;
    logic               s_packet_first      ;
    logic               s_packet_last       ;
    logic   [7:0]       s_packet_data       ;
    logic               s_packet_valid      ;
    logic               s_packet_ready      ;

    logic               m_packet_first      ;
    logic               m_packet_last       ;
    logic   [7:0]       m_packet_data       ;
    logic               m_packet_valid      ;
    logic               m_packet_ready      ;

    jelly2_ether_fcs_set
            #(
                .DEBUG          (DEBUG     ),
                .SIMULATION     (SIMULATION)
            )
        u_necolink_packet_fcs_set
            (
                .reset               ,
                .clk                 ,
                .cke                 ,
    
                .s_packet_index      ,
                .s_packet_fcs        ,
                .s_packet_crc_start  ,
                .s_packet_first      ,
                .s_packet_last       ,
                .s_packet_data       ,
                .s_packet_valid      ,
                .s_packet_ready      ,

                .m_packet_first      ,
                .m_packet_last       ,
                .m_packet_data       ,
                .m_packet_valid      ,
                .m_packet_ready
            );

    
    int     cycle;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            cycle <= 0;
        end
        else if ( cke ) begin
            cycle <= cycle + 1;
        end
    end

    always_ff @(posedge clk) begin
        cke <= RAND ? 1'({$random}) : 1'b1;
    end


    logic   [255:0][15:0]     test_data;
    initial begin
        automatic int i = 0;
        test_data = '0;
        //              valid, count, fcs, crc, crc_first, first, last, data
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 8'h55};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 8'h55};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 8'h55};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 8'h55};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 8'h55};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 8'h55};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 8'h55};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 8'hd5};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 8'hff};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'hff};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'hff};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'hff};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'hff};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'hff};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'he5};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'hf1};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h13};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'hce};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h98};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h88};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h99};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h23};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h5f};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h4c};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h0c};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h20};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h60};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h16};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'he5};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'hf1};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h13};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'hce};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h98};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h03};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'bxx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 8'h00};
        test_data[i++] = {1'b1, 2'b00, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 8'h00}; // 05
        test_data[i++] = {1'b1, 2'b01, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 8'h00}; // de
        test_data[i++] = {1'b1, 2'b10, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 8'h00}; // 86
        test_data[i++] = {1'b1, 2'b11, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 8'h00}; // 42
    end

    int                 index;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            index           <= '0;
        end
        else if ( cke ) begin
            if ( !s_packet_valid || s_packet_ready ) begin
                index <= index + 1;
            end
            if ( index >= 255 ) begin
                $finish();
            end
        end
    end

    assign s_packet_index     = s_packet_valid ? test_data[index][14:13] : 'x;
    assign s_packet_fcs       = s_packet_valid ? test_data[index][12]    : 'x;
//  assign s_packet_crc       = s_packet_valid ? test_data[index][11]    : 'x;
    assign s_packet_crc_start = s_packet_valid ? test_data[index][10]    : 'x;
    assign s_packet_first     = s_packet_valid ? test_data[index][9]     : 'x;
    assign s_packet_last      = s_packet_valid ? test_data[index][8]     : 'x;
    assign s_packet_data      = s_packet_valid ? test_data[index][7:0]   : 'x;
    assign s_packet_valid     = test_data[index][15];


    // monitor
    always_ff @(posedge clk) begin
        m_packet_ready <= RAND ? 1'({$random}) : 1'b1;
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
        end
        else if ( cke ) begin
            if ( m_packet_valid && m_packet_ready ) begin
                $write("%02x ", m_packet_data);
                if ( m_packet_last ) begin
                    $write("\n");
                end
            end
        end
    end

endmodule


`default_nettype wire


// end of file
