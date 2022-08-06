// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_data_logger_fifo
        #(
            parameter   CORE_ID          = 32'h527a_f002,
            parameter   CORE_VERSION     = 32'h0001_0000,
            parameter   NUM              = 4,
            parameter   DATA_WIDTH       = 32,
            parameter   TIMER_WIDTH      = 64,
            parameter   FIFO_ASYNC       = 1,
            parameter   FIFO_PTR_WIDTH   = 10,
            parameter   FIFO_RAM_TYPE    = "block",
            parameter   WB_ADR_WIDTH     = 8,
            parameter   WB_DAT_WIDTH     = 32,
            parameter   WB_SEL_WIDTH     = (WB_DAT_WIDTH / 8),
            parameter   INIT_CTL_CONTROL = 2'b00,
            parameter   INIT_LIMIT_SIZE  = 0
        )
        (
            input   wire                                reset,
            input   wire                                clk,
            input   wire                                cke,
            
            input   wire    [NUM-1:0][DATA_WIDTH-1:0]   s_data,
            input   wire                                s_valid,
            output  wire                                s_ready,
            
            input   wire                                s_wb_rst_i,
            input   wire                                s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]          s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]          s_wb_dat_i,
            output  reg     [WB_DAT_WIDTH-1:0]          s_wb_dat_o,
            input   wire                                s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]          s_wb_sel_i,
            input   wire                                s_wb_stb_i,
            output  wire                                s_wb_ack_o
        );
    
    localparam  TIMER_BITS = TIMER_WIDTH > 0 ? TIMER_WIDTH : 1;
    
    
    // -------------------------------------
    //  FIFO
    // -------------------------------------
    
    logic   [TIMER_BITS-1:0]                    fifo_s_timer;
    
    logic   [TIMER_BITS-1:0]                    fifo_m_timer;
    logic   [NUM-1:0][DATA_WIDTH-1:0]           fifo_m_data;
    logic                                       fifo_m_valid;
    logic                                       fifo_m_ready;
    logic   [FIFO_PTR_WIDTH:0]                  fifo_m_data_count;

    logic   [TIMER_WIDTH+NUM*DATA_WIDTH-1:0]    fifo_s_pack;
    logic   [TIMER_WIDTH+NUM*DATA_WIDTH-1:0]    fifo_m_pack;    
    
    assign fifo_s_pack = {fifo_s_timer, s_data};
    assign {fifo_m_timer, fifo_m_data} = {1'b0, fifo_m_pack};
    
    jelly_fifo_generic_fwtf
            #(
                .ASYNC          (FIFO_ASYNC),
                .DATA_WIDTH     (TIMER_WIDTH+NUM*DATA_WIDTH),
                .PTR_WIDTH      (FIFO_PTR_WIDTH),
                .DOUT_REGS      (1),
                .RAM_TYPE       (FIFO_RAM_TYPE),
                .LOW_DEALY      (0),
                .SLAVE_REGS     (1),
                .MASTER_REGS    (1)
            )
        i_fifo_generic_fwtf
            (
                .s_reset        (reset),
                .s_clk          (clk),
                .s_data         (fifo_s_pack),
                .s_valid        (s_valid & cke),
                .s_ready        (s_ready),
                .s_free_count   (),
                
                .m_reset        (s_wb_rst_i),
                .m_clk          (s_wb_clk_i),
                .m_data         (fifo_m_pack),
                .m_valid        (fifo_m_valid),
                .m_ready        (fifo_m_ready),
                .m_data_count   (fifo_m_data_count)
            );
    

    
    // -------------------------------------
    //  Timer
    // -------------------------------------
    
    reg [TIMER_BITS-1:0]    reg_timer;
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_timer <= 0;
        end
        else begin
            reg_timer <= reg_timer + 1'b1;
        end
    end
    
    assign fifo_s_timer = reg_timer;
    
    
    
    // -------------------------------------
    //  Register
    // -------------------------------------
    
    // register address offset
    localparam  int  ADR_CORE_ID        = 'h00;
    localparam  int  ADR_CORE_VERSION   = 'h01;
    localparam  int  ADR_CTL_CONTROL    = 'h04;
    localparam  int  ADR_CTL_STATUS     = 'h05;
    localparam  int  ADR_CTL_COUNT      = 'h07;
    localparam  int  ADR_LIMIT_SIZE     = 'h08;
    localparam  int  ADR_READ_DATA      = 'h10;
    localparam  int  ADR_POL_TIMER0     = 'h18;
    localparam  int  ADR_POL_TIMER1     = 'h19;
    localparam  int  ADR_POL_DATA_BASE  = 'h20;
    
    // registers
    reg                             reg_force_read;
    reg     [FIFO_PTR_WIDTH:0]      reg_limit_size;

    function [WB_DAT_WIDTH-1:0] reg_mask(
                                        input [WB_DAT_WIDTH-1:0] org,
                                        input [WB_DAT_WIDTH-1:0] wdat,
                                        input [WB_SEL_WIDTH-1:0] msk
                                    );
    integer i;
    begin
        for ( i = 0; i < WB_DAT_WIDTH; i = i+1 ) begin
            reg_mask[i] = msk[i/8] ? wdat[i] : org[i];
        end
    end
    endfunction

    always_ff @(posedge s_wb_clk_i ) begin
        if ( s_wb_rst_i ) begin
            reg_force_read <= INIT_CTL_CONTROL[1];
            reg_limit_size <= INIT_LIMIT_SIZE;
        end
        else begin
            // register write
            if ( s_wb_stb_i && s_wb_we_i ) begin
                if ( (s_wb_adr_i == ADR_CTL_CONTROL) && s_wb_sel_i[0] ) begin
                    reg_force_read <= s_wb_dat_i[1];
                end
                if ( s_wb_adr_i == ADR_LIMIT_SIZE ) begin
                    reg_limit_size <= reg_mask(reg_limit_size, s_wb_dat_i, s_wb_sel_i);
                end
            end
        end
    end
    
    // register read
    always_comb begin : blk_wb_dat_o 
        s_wb_dat_o = '0;
        
        case (s_wb_adr_i)
        ADR_CORE_ID:        s_wb_dat_o = WB_DAT_WIDTH'(CORE_ID);
        ADR_CORE_VERSION:   s_wb_dat_o = WB_DAT_WIDTH'(CORE_VERSION);
        ADR_CTL_CONTROL:    s_wb_dat_o = WB_DAT_WIDTH'({reg_force_read, 1'b0});
        ADR_CTL_STATUS:     s_wb_dat_o = WB_DAT_WIDTH'(fifo_m_valid);
        ADR_CTL_COUNT:      s_wb_dat_o = WB_DAT_WIDTH'(fifo_m_data_count);
        ADR_READ_DATA:      s_wb_dat_o = WB_DAT_WIDTH'(fifo_m_data);
        ADR_POL_TIMER0:     s_wb_dat_o = WB_DAT_WIDTH'(fifo_m_timer >> (0*WB_DAT_WIDTH));
        ADR_POL_TIMER1:     s_wb_dat_o = WB_DAT_WIDTH'(fifo_m_timer >> (1*WB_DAT_WIDTH));
        default: ;
        endcase

        for ( int i = 0; i < NUM; ++i ) begin
            if ( int'(s_wb_adr_i) == ADR_POL_DATA_BASE+i ) begin
                s_wb_dat_o = WB_DAT_WIDTH'(fifo_m_data[i]);
            end
        end
    end
    
    assign s_wb_ack_o = s_wb_stb_i;
    
    // CTL_CONTROL[0] への 1 書き込み or READ_DATA で読み進む
    assign fifo_m_ready = (s_wb_stb_i && (s_wb_adr_i == ADR_CTL_CONTROL) && s_wb_we_i && s_wb_sel_i[0] && s_wb_dat_i[0])
                        | (s_wb_stb_i && (s_wb_adr_i == ADR_READ_DATA) && ~s_wb_we_i)
                        | (reg_limit_size != 0 && fifo_m_data_count > reg_limit_size)
                        | reg_force_read;
    
    
    
endmodule


`default_nettype wire


// end of file
