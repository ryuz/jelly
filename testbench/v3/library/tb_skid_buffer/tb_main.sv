
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );
    

    // ---------------------------------
    //  DUT
    // ---------------------------------

    parameter   int     BUF_SIZE   = 2                                          ;
    parameter   int     SIZE_BITS  = BUF_SIZE > 0 ? $clog2(BUF_SIZE + 1) : 1    ;
    parameter   type    size_t     = logic [SIZE_BITS-1:0]                      ;
    parameter   int     DATA_BITS  = 8                                          ;
    parameter   type    data_t     = logic [DATA_BITS-1:0]                      ;
    parameter   bit     M_REG      = 1'b1                                       ;
    parameter           DEVICE     = "RTL"                                      ;
    parameter           SIMULATION = "false"                                    ;
    parameter           DEBUG      = "false"                                    ;

    logic   cke      = 1'b1 ;
    data_t  s_data          ;
    logic   s_valid         ;
    logic   s_ready         ;
    data_t  m_data          ;
    logic   m_valid         ;
    logic   m_ready         ;
    size_t  current_size    ;
    size_t  next_size       ;
    
    jelly3_skid_buffer
            #(
                .BUF_SIZE       (BUF_SIZE               ),
                .SIZE_BITS      (SIZE_BITS              ),
                .size_t         (size_t                 ),
                .DATA_BITS      (DATA_BITS              ),
                .data_t         (data_t                 ),
                .M_REG          (M_REG                  ),
                .DEVICE         (DEVICE                 ),
                .SIMULATION     (SIMULATION             ),
                .DEBUG          (DEBUG                  )
            )
        u_skid_buffer
            (
                .reset          (reset                  ),
                .clk            (clk                    ),
                .cke            (cke                    ),
                .s_data         (s_valid ? s_data : 'x  ),
                .s_valid        (s_valid                ),
                .s_ready        (s_ready                ),
                .m_data         (m_data                 ),
                .m_valid        (m_valid                ),
                .m_ready        (m_ready                ),
                .current_size   (current_size           ),
                .next_size      (next_size              )
            );
    

    // ---------------------------------
    //  Simulation
    // ---------------------------------

    always_ff @(posedge clk) begin
        cke <= 1'($random);
    end

    // write
    always_ff @(posedge clk) begin
        if ( reset ) begin
            s_data  <= 0;
            s_valid <= 1'b0;
        end
        else if ( cke ) begin
            if ( !(s_valid && !s_ready) ) begin
                s_valid <= 1'($random);
            end
            
            if ( s_valid && s_ready ) begin
                s_data <= s_data + 1'b1;
            end
        end
    end
    
    
    // read
    data_t      expect_value;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            expect_value  <= 0;
            m_ready       <= 1'b0;
        end
        else if ( cke ) begin
            m_ready <= 1'($random);
            
            if ( m_valid && m_ready ) begin
                if ( m_data != expect_value ) begin
                    $display("error! %h %h", m_data, expect_value);
//                  $finish;
                end
                expect_value <= expect_value + 1;
            end
        end
    end
    
endmodule


`default_nettype wire


// end of file
