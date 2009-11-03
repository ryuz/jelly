// ---------------------------------------------------------------------------
//  Jelly
//
//                                 Copyright (C) 2009 by Ryuji Fuchikami 
//                                 http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


module jelly_wishbone_test_model
		#(
			parameter	ADR_WIDTH  = 12,
			parameter	DAT_SIZE   = 2,		// 2^n (0:8bit, 1:16bit, 2:32bit ...)
			parameter	DAT_WIDTH  = (8 << DAT_SIZE),
			parameter	SEL_WIDTH  = (1 << DAT_SIZE),
			parameter	TABLE_FILE = "",
			parameter	TABLE_SIZE = 256
		)
		(
			// system
			input	wire						clk,
			input	wire						reset,
			
			// wishbone
			output	wire	[ADR_WIDTH-1:0]		wb_adr_o,
			output	wire	[DAT_WIDTH-1:0]		wb_dat_o,
			input	wire	[DAT_WIDTH-1:0]		wb_dat_i,
			output	wire						wb_we_o,
			output	wire	[SEL_WIDTH-1:0]		wb_sel_o,
			output	wire						wb_stb_o,
			input	wire						wb_ack_i
		);
	
	
	integer		index;
	initial begin
		index = 0;
	end
	
	localparam DAT_POS     = 0;
	localparam SEL_POS     = DAT_POS + DAT_WIDTH;
	localparam ADR_POS     = SEL_POS + SEL_WIDTH;
	localparam STB_POS     = ADR_POS + ADR_WIDTH;
	localparam END_POS     = STB_POS + 1;
	localparam TABLE_WIDTH = END_POS + 1;
	
	reg		[TABLE_WIDTH-1:0]	test_table	[0:TABLE_SIZE-1];
	initial begin
		$readmemb(TABLE_FILE, test_table);
	end
	
	assign wb_stb_o = test_table[index][STB_POS];
	assign wb_adr   = test_table[index][ADR_POS +: ADR_WIDTH];
	assign wb_sel_o = test_table[index][DAT_POS +: DAT_WIDTH];
	assign wb_dat_o = wb_we_o ? test_table[index][DAT_POS +: DAT_WIDTH] : {DAT_WIDTH{1'bx}};
	
	function cmp_data;
	input	[DAT_WIDTH]		dat;
	input	[DAT_WIDTH]		exp;
	integer					i;
	begin
		cmp_data = 1'b1;
		for ( i = 0; i < DAT_WIDTH; i = i + 1 ) begin
			if ( exp[i] !== 1'bx && !(dat[i] == exp[i]) ) begin
				cmp_data = 1'b0;
			end
		end
	end
	endfunction
	
	always @ ( posedge clk ) begin
		if ( reset ) begin
			index <= 0;
		end
		else begin
			if ( !wb_stb_o | wb_ack_i ) begin
				if ( !test_table[index][END_POS] ) begin
					index <= index + 1;
				end
			end
			if ( !wb_we_o & wb_stb_o & wb_ack_i ) begin
				if ( !cmp_data(wb_dat_i, test_table[index][DAT_POS +: DAT_WIDTH]) ) begin
					$display("%t read error", $time);
				end
			end
		end
	end
	
	
endmodule


// end of file
