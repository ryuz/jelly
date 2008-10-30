// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


module cpu_gpr
			(
				reset, clk, clk_x2,
				interlock,
				w0_en, w0_addr, w0_data,
				w1_en, w1_addr, w1_data,
				r0_en, r0_addr, r0_data,
				r1_en, r1_addr, r1_data
			);
	parameter	DATA_WIDTH = 32;
	parameter	ADDR_WIDTH = 5;
	
	input						reset;
	input						clk;
	input						clk_x2;
	
	input						interlock;
	
	input						w0_en;
	input	[ADDR_WIDTH-1:0]	w0_addr;
	input	[DATA_WIDTH-1:0]	w0_data;
	
	input						w1_en;
	input	[ADDR_WIDTH-1:0]	w1_addr;
	input	[DATA_WIDTH-1:0]	w1_data;
	
	input						r0_en;
	input	[ADDR_WIDTH-1:0]	r0_addr;
	output	[DATA_WIDTH-1:0]	r0_data;
	
	input						r1_en;
	input	[ADDR_WIDTH-1:0]	r1_addr;
	output	[DATA_WIDTH-1:0]	r1_data;
	
	
	reg		clk_dly;
	always @* begin
		clk_dly = #1 clk;
	end
	
	// phase
	reg							phase;
	always @ ( posedge clk_x2 ) begin
		phase <= clk_dly;
	end
	
	
	// dualport ram
	wire						ram_en0;
	wire						ram_we0;
	wire	[ADDR_WIDTH-1:0]	ram_addr0;
	wire	[DATA_WIDTH-1:0]	ram_din0;
	wire	[DATA_WIDTH-1:0]	ram_dout0;
	wire						ram_en1;
	wire						ram_we1;
	wire	[ADDR_WIDTH-1:0]	ram_addr1;
	wire	[DATA_WIDTH-1:0]	ram_din1;
	wire	[DATA_WIDTH-1:0]	ram_dout1;
	
	ram_dualport_xilinx
			#(
				.DATA_WIDTH		(DATA_WIDTH),
				.ADDR_WIDTH		(ADDR_WIDTH),
				.MEM_SIZE		((1 << (ADDR_WIDTH)))
			)
		i_ram_dualport
			(
				.clk0			(clk_x2),
				.en0			(ram_en0),
				.we0			(ram_we0),
				.addr0			(ram_addr0),
				.din0			(ram_din0),
				.dout0			(ram_dout0),
				
				.clk1			(clk_x2),
				.en1			(ram_en1),
				.we1			(ram_we1),
				.addr1			(ram_addr1),
				.din1			(ram_din1),
				.dout1			(ram_dout1)
			);
	
	assign ram_en0   = (phase == 1'b0) ? r0_en   : w0_en;
	assign ram_we0   = (phase == 1'b0) ? 1'b0    : 1'b1;
	assign ram_addr0 = (phase == 1'b0) ? r0_addr : w0_addr;
	assign ram_din0  = w0_data;

	assign ram_en1   = (phase == 1'b0) ? r1_en   : w1_en;
	assign ram_we1   = (phase == 1'b0) ? 1'b0    : 1'b1;
	assign ram_addr1 = (phase == 1'b0) ? r1_addr : w1_addr;
	assign ram_din1  = w1_data;
	
	
	reg		[DATA_WIDTH-1:0]	r0_data;	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			r0_data <= 0;
		end
		else begin
			if ( !interlock ) begin
				if ( r0_en ) begin
					if ( w0_en & (r0_addr == w0_addr) ) begin
						r0_data <= w0_data;
					end
					else if ( w1_en & (r0_addr == w1_addr) ) begin
						r0_data <= w1_data;
					end
					else begin
						r0_data <= ram_dout0;
					end
				end
			end
		end
	end
	
	reg		[DATA_WIDTH-1:0]	r1_data;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			r1_data <= 0;
		end
		else begin
			if ( !interlock ) begin
				if ( r1_en ) begin
					if ( w0_en & (r1_addr == w0_addr) ) begin
						r1_data <= w0_data;
					end
					else if ( w1_en & (r1_addr == w1_addr) ) begin
						r1_data <= w1_data;
					end
					else begin
						r1_data <= ram_dout1;
					end
				end
			end
		end
	end
	
endmodule


