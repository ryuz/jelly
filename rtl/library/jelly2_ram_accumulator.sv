// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// accumulator memory
module jelly2_ram_accumulator
        #(
            parameter   int                         ADDR_WIDTH   = 10,
            parameter   int                         DATA_WIDTH   = 18,
            parameter   int                         MEM_SIZE     = (1 << ADDR_WIDTH),
            parameter                               RAM_TYPE     = "block",
            
            parameter   bit                         FILLMEM      = 0,
            parameter   logic   [DATA_WIDTH-1:0]    FILLMEM_DATA = 0,
            parameter   bit                         READMEMB     = 0,
            parameter   bit                         READMEMH     = 0,
            parameter                               READMEM_FIlE = ""
        )
        (
            // system
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,

            // accumulator port
            input   wire    [ADDR_WIDTH-1:0]    acc_addr,
            input   wire    [DATA_WIDTH-1:0]    acc_data,
            input   wire    [0:0]               acc_operation,  // 0:add, 1:subtraction
            input   wire                        acc_valid,

            // clear
            input   wire                        clear_start,
            output  wire                        clear_busy,

            // max
            input   wire                        max_clear,
            output  wire    [ADDR_WIDTH-1:0]    max_addr,
            output  wire    [DATA_WIDTH-1:0]    max_data
        );
    
    logic                       st0_we;
    logic   [ADDR_WIDTH-1:0]    st0_addr;
    logic   [DATA_WIDTH-1:0]    st0_din;
    logic   [DATA_WIDTH-1:0]    st0_data;
    logic   [0:0]               st0_operation;
    logic                       st0_valid;
    
    logic                       st1_fw_st2;
    logic                       st1_fw_st3;
    logic   [ADDR_WIDTH-1:0]    st1_addr;
    logic   [DATA_WIDTH-1:0]    st1_data;
    logic   [0:0]               st1_operation;
    logic                       st1_valid;
    
    logic   [DATA_WIDTH-1:0]    st1_dout;
    logic   [DATA_WIDTH-1:0]    st1_rdata;
    
    logic                       st2_we;
    logic   [ADDR_WIDTH-1:0]    st2_addr;
    logic   [DATA_WIDTH-1:0]    st2_data;
    logic                       st2_valid;
    
    logic   [DATA_WIDTH-1:0]    st3_data;
    
    
    // fowarding
    always_comb begin : blk_st1
        st1_rdata = st1_dout;
        if ( st1_fw_st3 ) begin st1_rdata = st3_data; end
        if ( st1_fw_st2 ) begin st1_rdata = st2_data; end
    end
    
    // pipeline
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_we        <= 1'bx;
            st0_addr      <= {ADDR_WIDTH{1'bx}};
            st0_data      <= {DATA_WIDTH{1'bx}};
            st0_operation <= 1'bx;
            st0_valid     <= 1'b0;
            
            st1_fw_st2    <= 1'bx;
            st1_fw_st3    <= 1'bx;
            st1_addr      <= {ADDR_WIDTH{1'bx}};
            st1_data      <= {DATA_WIDTH{1'bx}};
            st1_operation <= 1'bx;
            st1_valid     <= 1'b0;
            
            st2_we        <= 1'b0;
            st2_addr      <= {ADDR_WIDTH{1'bx}};
            st2_data      <= {DATA_WIDTH{1'bx}};
            st2_valid     <= 1'b0;
            
            st3_data      <= {DATA_WIDTH{1'bx}};
        end
        else if ( cke ) begin
            // stage 0
            st0_we        <= 1'b0;
            st0_addr      <= acc_addr;
            st0_din       <= '0;
            st0_data      <= acc_data;
            st0_operation <= acc_operation;
            st0_valid     <= acc_valid;
            
            // stage 1
            st1_fw_st2    <= st0_valid && st1_valid && (st0_addr == st1_addr);
            st1_fw_st3    <= st0_valid && st2_valid && (st0_addr == st2_addr);
            st1_addr      <= st0_addr;
            st1_data      <= st0_data;
            st1_operation <= st0_operation;
            st1_valid     <= st0_valid;
            
            // stage 2
            st2_we        <= st1_valid;
            st2_addr      <= st1_addr;
            st2_data      <= (st1_operation == 1'b0) ? st1_rdata + st1_data : st1_rdata - st1_data;
            st2_valid     <= st1_valid;
            
            // stage 3
            st3_data      <= st2_data;
        end
    end
    
    
    // memory
    logic   [1:0]                   ram_reset;
    logic   [1:0]                   ram_clk;
    logic   [1:0][DATA_WIDTH-1:0]   ram_clear_din;
    logic   [1:0]                   ram_clear_start;
    logic   [1:0]                   ram_clear_busy;
    logic   [1:0]                   ram_en;
    logic   [1:0]                   ram_regcke;
    logic   [1:0]                   ram_we;
    logic   [1:0][ADDR_WIDTH-1:0]   ram_addr;
    logic   [1:0][DATA_WIDTH-1:0]   ram_din;
    logic   [1:0][DATA_WIDTH-1:0]   ram_dout;

    jelly2_ram_with_autoclear
            #(
                    .ADDR_WIDTH         (ADDR_WIDTH),
                    .DATA_WIDTH         (DATA_WIDTH),
                    .MEM_SIZE           (MEM_SIZE),
                    .RAM_TYPE           (RAM_TYPE),
                    .DOUT_REGS0         (0),
                    .DOUT_REGS1         (0),
                    .FILLMEM            (FILLMEM),
                    .FILLMEM_DATA       (FILLMEM_DATA),
                    .READMEMB           (READMEMB),
                    .READMEMH           (READMEMH),
                    .READMEM_FIlE       (READMEM_FIlE)
            )
        i_ram_with_autoclear
            (
                    .reset              (ram_reset),
                    .clk                (ram_clk),
                    .clear_din          (ram_clear_din),
                    .clear_start        (ram_clear_start),
                    .clear_busy         (ram_clear_busy),
                    .en                 (ram_en),
                    .regcke             (ram_regcke),
                    .we                 (ram_we),
                    .addr               (ram_addr),
                    .din                (ram_din),
                    .dout               (ram_dout)
            );

    assign ram_reset       [0] = reset;
    assign ram_clk         [0] = clk;
    assign ram_clear_din   [0] = '0;
    assign ram_clear_start [0] = clear_start;
    assign ram_en          [0] = cke;
    assign ram_regcke      [0] = cke;
    assign ram_we          [0] = st0_we;
    assign ram_addr        [0] = st0_addr;
    assign ram_din         [0] = st0_din;
    assign clear_busy          = ram_clear_busy[0]; 
    assign st1_dout            = ram_dout      [0];


    assign ram_reset       [1] = reset;
    assign ram_clk         [1] = clk;
    assign ram_clear_din   [1] = '0;
    assign ram_clear_start [1] = '0;
    assign ram_en          [1] = cke;
    assign ram_regcke      [1] = cke;
    assign ram_we          [1] = st2_we;
    assign ram_addr        [1] = st2_addr;
    assign ram_din         [1] = st2_data;
        
    
    // max
    reg     [ADDR_WIDTH-1:0]    reg_max_addr;
    reg     [DATA_WIDTH-1:0]    reg_max_data;
    always @(posedge clk) begin
        if ( reset || max_clear ) begin
            reg_max_addr <= {ADDR_WIDTH{1'b0}};
            reg_max_data <= {DATA_WIDTH{1'b0}};
        end
        else begin
            if ( st2_we && (st2_data > reg_max_data) ) begin
                reg_max_addr <= st2_addr;
                reg_max_data <= st2_data;
            end
        end
    end
    
    assign max_addr = reg_max_addr;
    assign max_data = reg_max_data;
    
    
endmodule


`default_nettype wire


// End of file
