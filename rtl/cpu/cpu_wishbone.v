// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


// CPU bus to WISHBONE bus bridge
module jelly_cpu_wishbone
		#(
			parameter									ADDR_WIDTH   = 32,
			parameter									DATA_SIZE    = 2,  				// 0:8bit, 1:16bit, 2:32bit ...
			parameter									SEL_WIDTH    = (1 << DATA_SIZE),
			parameter									DATA_WIDTH   = (8 << DATA_SIZE)
		)
		(
			// system
			input	wire								reset,
			input	wire								clk,
			
			// CPU bus
			input	wire								cpu_interlock,
			input	wire								cpu_en,
			input	wire								cpu_we,
			input	wire	[SEL_WIDTH-1:0]				cpu_sel,
			input	wire	[ADDR_WIDTH-1:0]			cpu_addr,
			input	wire	[DATA_WIDTH-1:0]			cpu_wdata,
			output	reg		[DATA_WIDTH-1:0]			cpu_rdata,
			output	wire								cpu_busy,
			
			// WISHBONE bus
			output	wire	[ADDR_WIDTH-1:DATA_SIZE]	wb_adr_o,
			input	wire	[DATA_WIDTH-1:0]			wb_dat_i,
			output	wire	[DATA_WIDTH-1:0]			wb_dat_o,
			output	wire								wb_we_o,
			output	wire	[SEL_WIDTH-1:0]				wb_sel_o,
			output	wire								wb_stb_o,
			input	wire								wb_ack_i
		);
	
	
	reg									buf_en;
	reg		[DATA_WIDTH-1:0]			buf_data;
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			buf_en    <= 1'b0;
			buf_data  <= {DATA_WIDTH{1'bx}};
			cpu_rdata <= {DATA_WIDTH{1'bx}};
		end
		else begin
			if ( !cpu_interlock ) begin
				cpu_rdata <= buf_en ? buf_data : wb_dat_i;
				buf_en    <= 1'b0;
			end
			else begin
				if ( wb_stb_o & wb_ack_i ) begin
					buf_en <= 1'b1;
				end
			end
			
			if ( !buf_en ) begin
				buf_data <= wb_dat_i;
			end
		end
	end
	
	assign wb_adr_o = cpu_addr[ADDR_WIDTH-1:DATA_SIZE];
	assign wb_dat_o = cpu_wdata;
	assign wb_we_o  = cpu_we;
	assign wb_sel_o = cpu_sel;
	assign wb_stb_o = cpu_en & ~buf_en;
	
	assign cpu_busy = wb_stb_o & ~wb_ack_i;
	
endmodule

