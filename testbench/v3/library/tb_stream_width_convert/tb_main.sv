`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );
    
    localparam  int     UNIT_BITS = 8;
    localparam  int     S_NUM     = 2;
    localparam  int     M_NUM     = 4;
    localparam  type    unit_t    = logic [UNIT_BITS-1:0];
    
    logic [UNIT_BITS*S_NUM-1:0] s_data;
    logic                       s_valid;
    logic                       s_ready;
    
    logic [UNIT_BITS*M_NUM-1:0] m_data;
    logic                       m_valid;
    logic                       m_ready;
    
    jelly3_stream_width_convert
            #(
                .UNIT_BITS      (UNIT_BITS  ),
                .S_NUM          (S_NUM      ),
                .M_NUM          (M_NUM      ),
                .USE_FIRST      (0          ),
                .USE_LAST       (0          ),
                .USE_STRB       (1          ),
                .USE_KEEP       (1          ),
                .USE_ALIGN_S    (1          ),
                .USE_ALIGN_M    (1          )
            )
        u_stream_width_convert
            (
                .reset          (reset      ),
                .clk            (clk        ),
                .cke            (1'b1       ),
                .endian         (1'b0       ),
                .padding        ('0         ),
                .s_align_s      ('0         ),
                .s_align_m      ('0         ),
                .s_first        (1'b0       ),
                .s_last         (1'b0       ),
                .s_data         (s_data     ),
                .s_strb         ({S_NUM{1'b1}}),
                .s_keep         ({S_NUM{1'b1}}),
                .s_user_f       ('0         ),
                .s_user_l       ('0         ),
                .s_valid        (s_valid    ),
                .s_ready        (s_ready    ),
                .m_first        (           ),
                .m_last         (           ),
                .m_data         (m_data     ),
                .m_strb         (           ),
                .m_keep         (           ),
                .m_user_f       (           ),
                .m_user_l       (           ),
                .m_valid        (m_valid    ),
                .m_ready        (m_ready    )
            );

    jelly2_stream_width_convert
            #(
                .UNIT_WIDTH     (UNIT_BITS  ),
                .S_NUM          (S_NUM      ),
                .M_NUM          (M_NUM      ),
                .HAS_FIRST      (0          ),
                .HAS_LAST       (0          ),
                .HAS_STRB       (1          ),
                .HAS_KEEP       (1          ),
                .HAS_ALIGN_S    (1          ),
                .HAS_ALIGN_M    (1          )
            )
        u_stream_width_convert2
            (
                .reset          (reset      ),
                .clk            (clk        ),
                .cke            (1'b1       ),
                .endian         (1'b0       ),
                .padding        ('0         ),
                .s_align_s      ('0         ),
                .s_align_m      ('0         ),
                .s_first        (1'b0       ),
                .s_last         (1'b0       ),
                .s_data         (s_data     ),
                .s_strb         ({S_NUM{1'b1}}),
                .s_keep         ({S_NUM{1'b1}}),
                .s_user_f       ('0         ),
                .s_user_l       ('0         ),
                .s_valid        (s_valid    ),
                .s_ready        (           ),
                .m_first        (           ),
                .m_last         (           ),
                .m_data         (           ),
                .m_strb         (           ),
                .m_keep         (           ),
                .m_user_f       (           ),
                .m_user_l       (           ),
                .m_valid        (           ),
                .m_ready        (m_ready    )
            );



    // write
    logic [UNIT_BITS*S_NUM-1:0] reg_data;
    logic                       reg_valid;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_data  <= '0;
            reg_valid <= 1'b0;
        end
        else begin
            if ( !(s_valid && !s_ready) ) begin
                reg_valid <= 1'($random);
            end
            
            if ( s_valid && s_ready ) begin
                reg_data <= reg_data + 1'b1;
            end
        end
    end
    assign s_data  = reg_data;
    assign s_valid = reg_valid;
    
    
    // read
    integer     fp;
    initial begin
        fp = $fopen("log.txt", "w");
    end
    
    logic [UNIT_BITS*M_NUM-1:0] reg_expectation_value;
    logic                       reg_ready;
    // Adjusted read logic to account for alignment and buffering
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_expectation_value  <= '0;
            reg_ready              <= 1'b0;
        end
        else begin
            reg_ready <= 1'($random);
            
            if ( m_valid && m_ready ) begin
                // Adjust expectation value based on alignment and buffering
                reg_expectation_value <= (reg_expectation_value + 1'b1) << (UNIT_BITS * S_NUM / M_NUM);
                
                $fdisplay(fp, "%h %h", m_data, reg_expectation_value);
                if ( m_data != reg_expectation_value ) begin
                    $display("error! %h %h", m_data, reg_expectation_value);
                end
            end
        end
    end
    assign m_ready = reg_ready;
    
endmodule


`default_nettype wire


// end of file
