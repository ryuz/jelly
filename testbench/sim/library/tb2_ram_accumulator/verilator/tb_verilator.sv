
`timescale 1ns / 1ps
`default_nettype none


module tb_verilator(
            input   wire        clk
        );
    

    parameter   ADDR_WIDTH   = 14;
    parameter   DATA_WIDTH   = 32;
    parameter   MEM_SIZE     = (1 << ADDR_WIDTH);
    


    int     cycle = 0;
    always_ff @(posedge clk) begin
        cycle <= cycle + 1;

        if ( cycle > 40100 ) $finish;
    end

    wire        reset       = (cycle < 100);
    wire        cke         = 1'b1;
    wire        clear_start = (cycle == 200 || cycle == 20200);
    wire        enable      = (cycle >= 10000 && cycle < 20000) || (cycle >= 30000 && cycle < 40000);


    integer     i;
    reg     [DATA_WIDTH-1:0]    mem_exp     [0:MEM_SIZE-1];
    initial begin
        for ( i = 0; i < MEM_SIZE; i = i+1 ) begin
            mem_exp[i] = 0;
        end
    end

    logic                       clear_busy;

    logic   [1:0]               s_operation;
    logic   [ADDR_WIDTH-1:0]    s_addr;
    logic   [DATA_WIDTH-1:0]    s_data;
    logic                       s_valid;
    
    logic   [DATA_WIDTH-1:0]    m_user;
    logic   [DATA_WIDTH-1:0]    m_data;
    logic                       m_valid;
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            s_valid <= 1'b0;
        end
        else if ( cke ) begin
            automatic   logic   [1:0]               acc_operation;
            automatic   logic   [ADDR_WIDTH-1:0]    acc_addr;
            automatic   logic   [DATA_WIDTH-1:0]    acc_data;
            automatic   logic                       acc_valid;
            acc_valid     = enable && 1'({$random});
            acc_operation = acc_valid ? 2'({{$random}})        : 'x;
            acc_addr      = acc_valid ? ADDR_WIDTH'({$random}) : 'x;
            acc_data      = acc_valid ? DATA_WIDTH'({$random}) : 'x;

            s_operation <= acc_operation;
            s_addr      <= acc_addr;
            s_data      <= acc_data;
            s_valid     <= acc_valid;
            
            // exp
            if ( clear_start ) begin
                for ( int i = 0; i < MEM_SIZE; ++i ) begin
                    mem_exp[i] = '0;
                end
            end

            if ( acc_valid ) begin
                case ( acc_operation )
                2'b00:  mem_exp[acc_addr] = mem_exp[acc_addr] + acc_data;
                2'b01:  mem_exp[acc_addr] = mem_exp[acc_addr] - acc_data;
                2'b10:  mem_exp[acc_addr] = mem_exp[acc_addr];
                2'b11:  mem_exp[acc_addr] = acc_data;
                endcase
            end
        end
    end

/*
            if ( cycle >= TEST_CYCLE + 10 ) begin
                for ( int i = 0; i < (1<<ADDR_WIDTH); ++i ) begin
                    if ( mem_exp[acc_addr] !=  ) begin
                    end
                end
            end
*/
    
    reg                         mem_en   = 0;
    reg                         mem_we   = 0;
    reg     [ADDR_WIDTH-1:0]    mem_addr = 0;
    reg     [DATA_WIDTH-1:0]    mem_din  = 0;
    wire    [DATA_WIDTH-1:0]    mem_dout;
    
    reg                         max_clear = 0;
    wire    [ADDR_WIDTH-1:0]    max_addr;
    wire    [DATA_WIDTH-1:0]    max_data;
    
    jelly2_ram_accumulator
            #(
                .USER_WIDTH     (DATA_WIDTH),
                .ADDR_WIDTH     (ADDR_WIDTH),
                .DATA_WIDTH     (DATA_WIDTH),
                .MEM_SIZE       (MEM_SIZE),
                
                .FILLMEM        (1),
                .FILLMEM_DATA   (0)
            )
        i_ram_accumulator
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (1'b1),

                .clear_start    (clear_start),
                .clear_busy     (clear_busy),

                .s_user         (mem_exp[s_addr]),
                .s_operation    (s_operation),
                .s_addr         (s_addr),
                .s_data         (s_data),
                .s_valid        (s_valid),
                
                .m_user         (m_user),
                .m_data         (m_data),
                .m_valid        (m_valid),

                .max_clear      (max_clear),
                .max_addr       (max_addr),
                .max_data       (max_data)
            );
    
    wire result_error = m_valid && (m_user != m_data);
    
endmodule


`default_nettype wire


// end of file
