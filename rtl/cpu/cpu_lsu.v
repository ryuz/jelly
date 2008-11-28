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
		(
			reset, clk,
			interlock, busy,
			in_en, in_we, in_sel, in_addr, in_data,
			out_data,
			wb_adr_o, wb_dat_i, wb_dat_o, wb_we_o, wb_sel_o, wb_stb_o, wb_ack_i
		);
	
	parameter	ADDR_WIDTH   = 32;
	parameter	DATA_SIZE    = 2;  				// 0:8bit, 1:16bit, 2:32bit ...
	
	localparam	SEL_WIDTH    = (1 << DATA_SIZE);
	localparam	DATA_WIDTH   = (8 << DATA_SIZE);
	
	
	// system
	input								reset;
	input								clk;
	
	// pipline control
	input								interlock;
	output								busy;
	
	// input
	input								in_en;
	input								in_we;
	input	[SEL_WIDTH-1:0]				in_sel;
	input	[ADDR_WIDTH-1:0]			in_addr;
	input	[DATA_WIDTH-1:0]			in_data;
	
	// output
	output	[DATA_WIDTH-1:0]			out_data;
	
	// Whishbone bus
	output	[ADDR_WIDTH-1:DATA_SIZE]	wb_adr_o;
	input	[DATA_WIDTH-1:0]			wb_dat_i;
	output	[DATA_WIDTH-1:0]			wb_dat_o;
	output								wb_we_o;
	output	[SEL_WIDTH-1:0]				wb_sel_o;
	output								wb_stb_o;
	input								wb_ack_i;
	
	
	
	reg									tmp_en;
	reg		[DATA_WIDTH-1:0]			tmp_data;
	reg		[DATA_WIDTH-1:0]			out_data;
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			tmp_en <= 1'b0;
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

