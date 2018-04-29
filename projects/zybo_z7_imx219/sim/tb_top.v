// ---------------------------------------------------------------------------
//
//                                  Copyright (C) 2015-2018 by Ryuji Fuchikami
//                                      http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_top();
	localparam RATE125 = 1000.0/125.0;
	
	initial begin
		$dumpfile("tb_top.vcd");
		$dumpvars(0, tb_top);
		
	#100000000
		$finish;
	end
	
	reg		clk125 = 1'b1;
	always #(RATE125/2.0)	clk125 = ~clk125;
	
	
	top
		i_top
			(
				.in_clk125		(clk125),
				
				.push_sw		(0),
				.dip_sw			(0),
				.led			(),
				.pmod_a			()
			);
	
	
	
	
	// WISHBONE master
	parameter	WB_ADR_WIDTH        = 30;
	parameter	WB_DAT_WIDTH        = 32;
	parameter	WB_SEL_WIDTH        = (WB_DAT_WIDTH / 8);
	
	wire							wb_rst_i = i_top.wb_rst_o;
	wire							wb_clk_i = i_top.wb_clk_o;
	reg		[WB_ADR_WIDTH-1:0]		wb_adr_o;
	wire	[WB_DAT_WIDTH-1:0]		wb_dat_i = i_top.wb_host_dat_i;
	reg		[WB_DAT_WIDTH-1:0]		wb_dat_o;
	reg								wb_we_o;
	reg		[WB_SEL_WIDTH-1:0]		wb_sel_o;
	reg								wb_stb_o = 0;
	wire							wb_ack_i = i_top.wb_host_ack_i;
	
	initial begin
		force i_top.wb_host_adr_o = wb_adr_o;
		force i_top.wb_host_dat_o = wb_dat_o;
		force i_top.wb_host_we_o  = wb_we_o;
		force i_top.wb_host_sel_o = wb_sel_o;
		force i_top.wb_host_stb_o = wb_stb_o;
	end
	
	
	reg		[WB_DAT_WIDTH-1:0]		reg_wb_dat;
	reg								reg_wb_ack;
	always @(posedge wb_clk_i) begin
		if ( ~wb_we_o & wb_stb_o & wb_ack_i ) begin
			reg_wb_dat <= wb_dat_i;
		end
		reg_wb_ack <= wb_ack_i;
	end
	
	
	task wb_write(
				input [31:0]	adr,
				input [31:0]	dat,
				input [3:0]		sel
			);
	begin
		$display("WISHBONE_WRITE(adr:%h dat:%h sel:%b)", adr, dat, sel);
		@(negedge wb_clk_i);
			wb_adr_o = (adr >> 2);
			wb_dat_o = dat;
			wb_sel_o = sel;
			wb_we_o  = 1'b1;
			wb_stb_o = 1'b1;
		@(negedge wb_clk_i);
			while ( reg_wb_ack == 1'b0 ) begin
				@(negedge wb_clk_i);
			end
			wb_adr_o = {WB_ADR_WIDTH{1'bx}};
			wb_dat_o = {WB_DAT_WIDTH{1'bx}};
			wb_sel_o = {WB_SEL_WIDTH{1'bx}};
			wb_we_o  = 1'bx;
			wb_stb_o = 1'b0;
	end
	endtask
	
	task wb_read(
				input [31:0]	adr
			);
	begin
		@(negedge wb_clk_i);
			wb_adr_o = (adr >> 2);
			wb_dat_o = {WB_DAT_WIDTH{1'bx}};
			wb_sel_o = {WB_SEL_WIDTH{1'b1}};
			wb_we_o  = 1'b0;
			wb_stb_o = 1'b1;
		@(negedge wb_clk_i);
			while ( reg_wb_ack == 1'b0 ) begin
				@(negedge wb_clk_i);
			end
			wb_adr_o = {WB_ADR_WIDTH{1'bx}};
			wb_dat_o = {WB_DAT_WIDTH{1'bx}};
			wb_sel_o = {WB_SEL_WIDTH{1'bx}};
			wb_we_o  = 1'bx;
			wb_stb_o = 1'b0;
			$display("WISHBONE_READ(adr:%h dat:%h)", adr, reg_wb_dat);
	end
	endtask
	
	
	
	initial begin
	@(negedge wb_rst_i);
	#1000;
		$display("start");
		wb_write(32'h40010000, 32'h00000001, 4'b1111);
		
		
		/*
		wb_write(32'h40010020, 32'h00100000, 4'b1111);
		wb_write(32'h40010024, 256,  4'b1111);			// stride
		wb_write(32'h40010028, 64,   4'b1111);			// width
		wb_write(32'h4001002c, 16,   4'b1111);			// height
		wb_write(32'h40010030, 16*1024, 4'b1111);	// size
		wb_write(32'h4001003c, 7,    4'b1111);			// awlen
		wb_write(32'h40010010, 32'h07, 4'b1111);
		wb_read(32'h40010014);
		wb_read(32'h40010014);
		
		while (1) begin
			#1000;
			wb_read(32'h40010014);
			while ( reg_wb_dat != 0 ) begin
				wb_read(32'h40010014);
			end
			
			wb_read(32'h40010014);
			wb_read(32'h40010014);
			
			#1000;
			wb_write(32'h40010020, 32'h00100000, 4'b1111);
			wb_write(32'h40010024, 256,  4'b1111);			// stride
			wb_write(32'h40010028, 64,   4'b1111);			// width
			wb_write(32'h4001002c, 16,   4'b1111);			// height
			wb_write(32'h40010030, 1024, 4'b1111);	// size
			wb_write(32'h4001003c, 7,    4'b1111);			// awlen
			wb_write(32'h40010010, 32'h07, 4'b1111);
		end
		*/
		
	end
	
	
	
endmodule


`default_nettype wire


// end of file
