
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset   ,
            input   var logic   clk0    ,
            input   var logic   clk1
        );


    parameter   int     PTR_BITS     = 2                    ;
    localparam  int     FIFO_SIZE    = 2 ** PTR_BITS        ;
    parameter   int     SIZE_BITS    = $clog2(FIFO_SIZE + 1);
    parameter   type    size_t       = logic [SIZE_BITS-1:0];
    parameter   int     DATA_BITS    = 8                    ;
    parameter   type    data_t       = logic [DATA_BITS-1:0];
    parameter   int     S_SYNC_FF    = 2                    ;
    parameter   int     M_SYNC_FF    = 2                    ;
    parameter           RAM_TYPE     = "block"              ;
    parameter   bit     DOUT_REG     = 1'b0                 ;
    parameter           DEVICE       = "RTL"                ;
    parameter           SIMULATION   = "false"              ;
    parameter           DEBUG        = "false"              ;

    logic   s_reset     ;
    logic   s_clk       ;
    logic   s_cke       ;
    data_t  s_data      ;
    logic   s_valid     ;
    logic   s_ready     ;
    size_t  s_free_size ;
    logic   m_reset     ;
    logic   m_clk       ;
    logic   m_cke       ;
    data_t  m_data      ;
    logic   m_valid     ;
    logic   m_ready     ;
    size_t  m_data_size ;
    
    jelly3_stream_fifo_async
            #(
                .PTR_BITS       (PTR_BITS       ),
                .SIZE_BITS      (SIZE_BITS      ),
                .size_t         (size_t         ),
                .DATA_BITS      (DATA_BITS      ),
                .data_t         (data_t         ),
                .S_SYNC_FF      (S_SYNC_FF      ),
                .M_SYNC_FF      (M_SYNC_FF      ),
                .RAM_TYPE       (RAM_TYPE       ),
                .DOUT_REG       (DOUT_REG       ),
                .DEVICE         (DEVICE         ),
                .SIMULATION     (SIMULATION     ),
                .DEBUG          (DEBUG          )
            )
        u_stream_fifo_async
            (
                .s_reset        (s_reset        ),
                .s_clk          (s_clk          ),
                .s_cke          (s_cke          ),
                .s_data         (s_data         ),
                .s_valid        (s_valid        ),
                .s_ready        (s_ready        ),
                .s_free_size    (s_free_size    ),
                .m_reset        (m_reset        ),
                .m_clk          (m_clk          ),
                .m_cke          (m_cke          ),
                .m_data         (m_data         ),
                .m_valid        (m_valid        ),
                .m_ready        (m_ready        ),
                .m_data_size    (m_data_size    )
            );

    assign s_reset = reset ;
    assign s_clk   = clk0  ;
    always_ff @(posedge s_clk) begin
        s_cke <= 1'({$random});
    end

    assign m_reset = reset ;
    assign m_clk   = clk1  ;
    always_ff @(posedge m_clk) begin
        m_cke <= 1'({$random});
    end


    // write
    data_t      reg_data;
    logic       reg_valid;
    always_ff @(posedge s_clk) begin
        if ( s_reset ) begin
            reg_data  <= 0;
            reg_valid <= 1'b0;
        end
        else if ( s_cke ) begin
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
    
    int         count_ok = 0;
    data_t      reg_expectation_value;
    logic       reg_ready;
    always_ff @(posedge m_clk) begin
        if ( m_reset ) begin
            reg_expectation_value  <= 0;
            reg_ready              <= 1'b0;
        end
        else if ( m_cke ) begin
            reg_ready <= 1'($random);
            
            if ( m_valid && m_ready ) begin
                $fdisplay(fp, "%h %h", m_data, reg_expectation_value);
                if ( m_data == reg_expectation_value ) begin
                    count_ok <= count_ok + 1;
                end
                else begin
                    $display("error! %h %h", m_data, reg_expectation_value);
                end
                reg_expectation_value <= reg_expectation_value + 1'b1;
            end

            if ( count_ok >= 10000 ) begin
                $fclose(fp);
                $display("count_ok = %d", count_ok);
                $finish;
            end
        end
    end
    assign m_ready = reg_ready;

    always_ff @(posedge s_clk) begin
        if ( !s_reset && s_cke ) begin
            if ( (s_ready && s_free_size == 0) || (!s_ready && s_free_size != 0) ) begin
                $display("%t error : s_ready = %d  s_free_size = %d", $time(), s_ready, s_free_size);
            end
        end
    end

    always_ff @(posedge m_clk) begin
        if ( !m_reset && m_cke) begin
            if ( (m_valid && m_data_size == 0) || (!m_valid && m_data_size != 0)  ) begin
                $display("%t error : m_valid = %d  m_data_size = %d", $time(), m_valid, m_data_size);
            end
        end
    end


endmodule


`default_nettype wire


// end of file
