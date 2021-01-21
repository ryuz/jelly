// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2015 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// pipe
module jelly_pipe
        #(
            parameter   ASYNC           = 0,
            parameter   DATA_WIDTH      = 1 + 8,
            
            parameter   WB_ADR_WIDTH    = 8,
            parameter   WB_DAT_WIDTH    = 32,
            parameter   WB_SEL_WIDTH    = (WB_DAT_WIDTH / 8),
            
            parameter   USE_0TO1        = 1,
            parameter   USE_1TO0        = 1,
            
            parameter   FIFO0_PTR_WIDTH = 6,
            parameter   FIFO0_RAM_TYPE  = "distributed"
            parameter   FIFO0_DOUT_REGS = 1,
            parameter   FIFO0_LOW_DEALY = 0,
            parameter   FIFO0_S_REGS    = 0,
            parameter   FIFO0_M_REGS    = 0
            
            parameter   FIFO1_PTR_WIDTH = 6,
            parameter   FIFO1_RAM_TYPE  = "distributed"
            parameter   FIFO1_DOUT_REGS = 1,
            parameter   FIFO1_LOW_DEALY = 0,
            parameter   FIFO1_S_REGS    = 0,
            parameter   FIFO1_M_REGS    = 0
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            input   wire                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o,
            
            output  wire                        irq0,
            output  wire                        irq1,
        );
    
    
    // FIFO0
    wire    [DATA_WIDTH-1:0]    fifo0_tx_data;
    wire                        fifo0_tx_valid;
    wire                        fifo0_tx_ready;
    
    wire    [DATA_WIDTH-1:0]    fifo0_rx_data;
    wire                        fifo0_rx_valid;
    wire                        fifo0_rx_ready;
    
    jelly_fifo_generic_fwtf
            #(
                .ASYNC          (0),
                .DATA_WIDTH     (DATA_WIDTH),
                .PTR_WIDTH      (FIFO0_PTR_WIDTH),
                .DOUT_REGS      (FIFO0_DOUT_REGS),
                .RAM_TYPE       (FIFO0_RAM_TYPE),
                .LOW_DEALY      (FIFO0_LOW_DEALY),
                .SLAVE_REGS     (FIFO0_S_REGS),
                .MASTER_REGS    (FIFO0_M_REGS)
            )
        i_fifo_generic_fwtf_0
            (
                .s_reset        (reset),
                .s_clk          (clk),
                .s_data         (fifo0_tx_data),
                .s_valid        (fifo0_tx_valid),
                .s_ready        (fifo0_tx_ready),
                .s_free_count   (),
                
                .s_reset        (reset),
                .s_clk          (clk),
                .m_data         (fifo0_rx_data),
                .m_valid        (fifo0_rx_valid),
                .m_ready        (fifo0_rx_ready),
                .m_data_count   ()
            );
    
    
    // FIFO1
    wire    [DATA_WIDTH-1:0]    fifo1_tx_data;
    wire                        fifo1_tx_valid;
    wire                        fifo1_tx_ready;
    
    wire    [DATA_WIDTH-1:0]    fifo1_rx_data;
    wire                        fifo1_rx_valid;
    wire                        fifo1_rx_ready;
    
    jelly_fifo_generic_fwtf
            #(
                .ASYNC          (0),
                .DATA_WIDTH     (DATA_WIDTH),
                .PTR_WIDTH      (FIFO1_PTR_WIDTH),
                .DOUT_REGS      (FIFO1_DOUT_REGS),
                .RAM_TYPE       (FIFO1_RAM_TYPE),
                .LOW_DEALY      (FIFO1_LOW_DEALY),
                .SLAVE_REGS     (FIFO1_S_REGS),
                .MASTER_REGS    (FIFO1_M_REGS)
            )
        i_fifo_generic_fwtf_1
            (
                .s_reset        (reset),
                .s_clk          (clk),
                .s_data         (fifo1_tx_data),
                .s_valid        (fifo1_tx_valid),
                .s_ready        (fifo1_tx_ready),
                .s_free_count   (),
                
                .s_reset        (reset),
                .s_clk          (clk),
                .m_data         (fifo1_rx_data),
                .m_valid        (fifo1_rx_valid),
                .m_ready        (fifo1_rx_ready),
                .m_data_count   ()
            );
    
    
    // PORT0
    wire    [WB_DAT_WIDTH-1:0]  wb_port0_dat_o;
    wire                        wb_port0_stb_i;
    wire                        wb_port0_ack_o;
    jelly_pipe_port
            #(
                .DATA_WIDTH     (DATA_WIDTH),
                
                .WB_ADR_WIDTH   (4),
                .WB_DAT_WIDTH   (WB_DAT_WIDTH)
            )
        i_pipe_port_0
            (
                .reset          (reset),
                .clk            (clk),
                
                .s_wb_adr_i     (s_wb_adr_i[3:0]),
                .s_wb_dat_o     (wb_port0_dat_o),
                .s_wb_dat_i     (s_wb_dat_i),
                .s_wb_we_i      (s_wb_we_i),
                .s_wb_sel_i     (s_wb_sel_i),
                .s_wb_stb_i     (wb_port0_stb_i),
                .s_wb_ack_o     (wb_port0_ack_o),
                .irq            (irq),
                
                .m_tx_data      (fifo0_tx_data),
                .m_tx_valid     (fifo0_tx_valid),
                .m_tx_ready     (fifo0_tx_ready),
                
                .s_rx_data      (fifo1_rx_data),
                .s_rx_valid     (fifo1_rx_valid),
                .s_rx_ready     (fifo1_rx_valid)
            );
    
    // PORT1
    wire    [WB_DAT_WIDTH-1:0]  wb_port1_dat_o;
    wire                        wb_port1_stb_i;
    wire                        wb_port1_ack_o;
    jelly_pipe_port
            #(
                .DATA_WIDTH     (DATA_WIDTH),
                
                .WB_ADR_WIDTH   (4),
                .WB_DAT_WIDTH   (WB_DAT_WIDTH)
            )
        i_pipe_port_1
            (
                .reset          (reset),
                .clk            (clk),
                
                .s_wb_adr_i     (s_wb_adr_i[3:0]),
                .s_wb_dat_o     (wb_port1_dat_o),
                .s_wb_dat_i     (s_wb_dat_i),
                .s_wb_we_i      (s_wb_we_i),
                .s_wb_sel_i     (s_wb_sel_i),
                .s_wb_stb_i     (wb_port1_stb_i),
                .s_wb_ack_o     (wb_port1_ack_o),
                .irq            (irq),
                
                .m_tx_data      (fifo1_tx_data),
                .m_tx_valid     (fifo1_tx_valid),
                .m_tx_ready     (fifo1_tx_ready),
                
                .s_rx_data      (fifo0_rx_data),
                .s_rx_valid     (fifo0_rx_valid),
                .s_rx_ready     (fifo0_rx_valid)
            );
    
    // WISHBONE
    assign wb_port0_stb_i = s_wb_stb_i && (s_wb_adr_i[WB_ADR_WIDTH-1:4] == 0);
    assign wb_port1_stb_i = s_wb_stb_i && (s_wb_adr_i[WB_ADR_WIDTH-1:4] == 1);
    
    assign s_wb_dat_o     = wb_port0_stb_i ? wb_port0_dat_o : 
                            wb_port1_stb_i ? wb_port1_dat_o : 
                            {WB_DAT_WIDTH{1'b0}};
    
    assign s_wb_ack_o     = wb_port0_stb_i ? wb_port0_ack_o : 
                            wb_port1_stb_i ? wb_port1_ack_o : 
                            s_wb_stb_i;
    
    
    
    
endmodule


`default_nettype wire



// end of file
