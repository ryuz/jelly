`timescale 1ns / 1ps


// DualPort-RAM
module ram_dualport(
				clk0, en0, we0, addr0, din0, dout0,
				clk1, en1, we1, addr1, din1, dout1
			);
	parameter DATA_WIDTH = 8;
	parameter ADDR_WIDTH = 8;
	parameter MEM_SIZE   = (1 << ADDR_WIDTH);
	
	// port0
	input						clk0;
	input						en0;
	input						we0;
	input	[ADDR_WIDTH-1:0]	addr0;
	input	[DATA_WIDTH-1:0]	din0;
	output	[DATA_WIDTH-1:0]	dout0;
	
	// port1
	input						clk1;
	input						en1;
	input						we1;
	input	[ADDR_WIDTH-1:0]	addr1;
	input	[DATA_WIDTH-1:0]	din1;
	output	[DATA_WIDTH-1:0]	dout1;
	
	// memory
	reg		[DATA_WIDTH-1:0]	mem	[0:MEM_SIZE-1];
	
	
	// port0
	reg		[DATA_WIDTH-1:0]		dout0;
	always @ ( posedge clk0 ) begin
		if ( en0 ) begin
			if ( we0 ) begin
				mem[addr0] <= din0;
			end
			dout0 <= mem[addr0];
		end
	end
	
	// port1
	reg		[DATA_WIDTH-1:0]		dout1;
	always @ ( posedge clk1 ) begin
		if ( en1 ) begin
			if ( we1 ) begin
				mem[addr1] <= din1;
			end
			dout1 <= mem[addr1];
		end
	end
	
endmodule


