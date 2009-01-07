// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



// Load Store Unit
module cpu_lsu
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
			
			// pipline control
			input	wire								interlock,
			output	wire								busy,
			
			// input
			input	wire								in_en,
			input	wire								in_we,
			input	wire	[SEL_WIDTH-1:0]				in_sel,
			input	wire	[ADDR_WIDTH-1:0]			in_addr,
			input	wire	[DATA_WIDTH-1:0]			in_data,
			
			// output
			output	reg		[DATA_WIDTH-1:0]			out_data,
			
			// Whishbone bus
			output	wire	[ADDR_WIDTH-1:DATA_SIZE]	wb_adr_o,
			input	wire	[DATA_WIDTH-1:0]			wb_dat_i,
			output	wire	[DATA_WIDTH-1:0]			wb_dat_o,
			output	wire								wb_we_o,
			output	wire	[SEL_WIDTH-1:0]				wb_sel_o,
			output	wire								wb_stb_o,
			input	wire								wb_ack_i
		);
	
	
	reg									tmp_en;
	reg		[DATA_WIDTH-1:0]			tmp_data;
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			tmp_en   <= 1'b0;
			tmp_data <= {DATA_WIDTH{1'bx}};
			out_data <= {DATA_WIDTH{1'bx}};
		end
		else begin
			if ( !interlock ) begin
				out_data <= tmp_en ? tmp_data : wb_dat_i;
				tmp_en   <= 1'b0;
			end
			else begin
				if ( wb_stb_o & wb_ack_i ) begin
					tmp_en <= 1'b1;
				end
			end
			
			if ( !tmp_en ) begin
				tmp_data <= wb_dat_i;
			end
		end
	end
	
	assign wb_adr_o = in_addr[ADDR_WIDTH-1:DATA_SIZE];
	assign wb_dat_o = in_data;
	assign wb_we_o  = in_we;
	assign wb_sel_o = in_sel;
	assign wb_stb_o = in_en & ~tmp_en;

	assign busy = wb_stb_o & ~wb_ack_i;
	
endmodule

