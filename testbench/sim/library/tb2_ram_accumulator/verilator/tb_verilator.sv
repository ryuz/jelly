
`timescale 1ns / 1ps
`default_nettype none


module tb_verilator(
            input   wire        reset,
            input   wire        clk
        );
    

    parameter   ADDR_WIDTH   = 10;
    parameter   DATA_WIDTH   = 32;
    parameter   MEM_SIZE     = (1 << ADDR_WIDTH);
    
    integer     i;
    reg     [DATA_WIDTH-1:0]    mem_exp     [0:MEM_SIZE-1];
    initial begin
        for ( i = 0; i < MEM_SIZE; i = i+1 ) begin
            mem_exp[i] = 0;
        end
    end
    
    logic                       acc_enable = 1'b1;
    logic   [ADDR_WIDTH-1:0]    acc_addr;
    logic   [DATA_WIDTH-1:0]    acc_data;
    logic   [0:0]               acc_operation;
    logic                       acc_valid;
    
    logic   [ADDR_WIDTH-1:0]    exp_addr;
    logic   [DATA_WIDTH-1:0]    exp_prev;
    logic   [DATA_WIDTH-1:0]    exp_data;
    logic                       exp_valid;
    
    always @(posedge clk) begin
        if ( reset ) begin
            acc_valid <= 1'b0;
        end
        else begin
            acc_addr      <= ADDR_WIDTH'({$random});
            acc_data      <= DATA_WIDTH'({$random} & 32'hff);
            acc_operation <= 1'b0; //{$random};
            acc_valid     <= acc_enable ? 1'({$random}) : 1'b0;
            
            // exp
            exp_valid = acc_valid;
            if ( acc_valid ) begin
                exp_prev = mem_exp[acc_addr];
                if ( acc_operation == 1'b0 ) begin
                    mem_exp[acc_addr] = mem_exp[acc_addr] + acc_data;
                end
                else begin
                    mem_exp[acc_addr] = mem_exp[acc_addr] - acc_data;
                end
                exp_addr = acc_addr;
                exp_data = mem_exp[acc_addr];
            end
        end
    end
    
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

                .clear_start    (1'b0),
                .clear_busy     (),

                .acc_addr       (acc_valid ? acc_addr      : {ADDR_WIDTH{1'bx}}),
                .acc_data       (acc_valid ? acc_data      : {DATA_WIDTH{1'bx}}),
                .acc_operation  (acc_valid ? acc_operation : 1'bx              ),
                .acc_valid      (acc_valid),
                
                .max_clear      (max_clear),
                .max_addr       (max_addr),
                .max_data       (max_data)
            );
    
    
endmodule


`default_nettype wire


// end of file
