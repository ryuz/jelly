// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    block sram interface
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



module jelly_sram
		#(
			parameter							WB_ADR_WIDTH  = 10,
			parameter							WB_DAT_WIDTH  = 32,
			parameter							WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8)
		)
		(
			input	wire						reset,
			input	wire						clk,
			
			// wishbone
			input	wire	[WB_ADR_WIDTH-1:0]	wb_adr_i,
			output	wire	[WB_DAT_WIDTH-1:0]	wb_dat_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_dat_i,
			input	wire						wb_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	wb_sel_i,
			input	wire						wb_stb_i,
			output	wire						wb_ack_o
		);
	
	generate
	genvar	i;
	for ( i = 0; i < WB_SEL_WIDTH; i = i + 1 ) begin : ram
		ram_dualport
				#(
					.DATA_WIDTH	(8),
					.ADDR_WIDTH	(WB_ADR_WIDTH)
				)
			i_ram_dualport
				(
					.clk0		(~clk),
					.en0		(wb_stb_i),
					.we0		(wb_we_i & wb_sel_i[i]),
					.addr0		(wb_adr_i),
					.din0		(wb_dat_i[i*8 +: 8]),
					.dout0		(wb_dat_o[i*8 +: 8]),
					
					.clk1		(1'b0),
					.en1		(1'b0),
					.we1		(1'b0),
					.addr1		({WB_ADR_WIDTH{1'b0}}),
					.din1		(8'h00),
					.dout1		()
				);
	end
	endgenerate
	
	assign wb_ack_o = 1'b1;
	
endmodule

