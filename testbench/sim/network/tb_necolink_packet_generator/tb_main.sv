
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


    logic               cke                   ;
    logic               start                 ;
    logic               busy                  ;

    logic               param_mac_enable      ;
    logic   [7:0]       param_node            ;
    logic   [7:0]       param_type            ;
    logic   [15:0]      param_length          ;
    
    
    logic   [15:0]      m_packet_index        ;
    logic               m_packet_preamble     ;
    logic               m_packet_sfd          ;
    logic               m_packet_mac_dst      ;
    logic               m_packet_mac_src      ;
    logic               m_packet_mac_type     ;
    logic               m_packet_node         ;
    logic               m_packet_type         ;
    logic               m_packet_length       ;
    logic               m_packet_payload      ;
    logic               m_packet_fcs          ;
    logic               m_packet_fcs_first    ;
    logic               m_packet_fcs_last     ;
    logic               m_packet_crc          ;
    logic               m_packet_crc_first    ;
    logic               m_packet_crc_last     ;
    logic               m_packet_first        ;
    logic               m_packet_last         ;
    logic   [7:0]       m_packet_data         ;
    logic               m_packet_valid        ;
    logic               m_packet_ready        ;

    jelly2_necolink_packet_generator
            #(
                .DEBUG          (DEBUG     ),
                .SIMULATION     (SIMULATION)
            )
        i_necolink_packet_generator
            (
                .reset                 ,
                .clk                   ,
                .cke                   ,

                .start                 ,
                .busy                  ,

                .param_mac_enable      ,
                .param_node            ,
                .param_type            ,
                .param_length          ,

                .m_packet_index        ,
//              .m_packet_preamble     ,
//              .m_packet_sfd          ,
                .m_packet_mac_dst      ,
                .m_packet_mac_src      ,
                .m_packet_mac_type     ,
                .m_packet_node         ,
                .m_packet_type         ,
                .m_packet_length       ,
                .m_packet_payload      ,
                .m_packet_fcs          ,
                .m_packet_fcs_first    ,
                .m_packet_fcs_last     ,
                .m_packet_crc          ,
                .m_packet_crc_first    ,
                .m_packet_crc_last     ,
                .m_packet_first        ,
                .m_packet_last         ,
                .m_packet_data         ,
                .m_packet_valid        ,
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
        cke <= 1'({$random});
    end

    assign start             = (cycle[7:0] == 8'd2);

    assign param_mac_enable  = cycle[8];
//    assign param_mac_dst     = 48'hff_ff_ff_ff_ff_ff;
//    assign param_mac_src     = 48'h00_00_0c_00_53_00;
//    assign param_mac_type    = 16'h8000;
    assign param_node        = 8'h01;
    assign param_type        = 8'h12;
    assign param_length      = 16'h0f;

//    assign s_payload_data    = 8'haa;
//    assign s_payload_valid   = 1'b1;

    always_ff @(posedge clk) begin
        m_packet_ready <= 1'({$random});
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
