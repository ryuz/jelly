
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );
    
    localparam  int     DATA_BITS = 16;
    localparam  type    data_t    = logic [DATA_BITS-1:0];
    
    data_t      s_data;
    logic       s_valid;
    logic       s_ready;
    
    data_t      m_data;
    logic       m_valid;
    logic       m_ready;
    
    jelly3_data_ff
            #(
                .DATA_BITS      (DATA_BITS  ),
                .data_t         (data_t     ),
                .S_REGS         (1          ),
                .M_REGS         (1          )
            )
        i_data_ff
            (
                .reset          (reset      ),
                .clk            (clk        ),
                .cke            (1'b1       ),
                
                .s_data         (s_data     ),
                .s_valid        (s_valid    ),
                .s_ready        (s_ready    ),
                
                .m_data         (m_data     ),
                .m_valid        (m_valid    ),
                .m_ready        (m_ready    )
            );
    
    // write
    data_t      reg_data;
    logic       reg_valid;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_data  <= 0;
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
    
    data_t      reg_expectation_value;
    logic       reg_ready;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_expectation_value  <= 0;
            reg_ready              <= 1'b0;
        end
        else begin
            reg_ready <= 1'($random);
            
            if ( m_valid && m_ready ) begin
                $fdisplay(fp, "%h %h", m_data, reg_expectation_value);
                if ( m_data != reg_expectation_value ) begin
                    $display("error!");
                end
                
                reg_expectation_value <= reg_expectation_value + 1'b1;
            end
        end
    end
    assign m_ready = reg_ready;
    
endmodule


`default_nettype wire


// end of file
