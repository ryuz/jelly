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
			parameter							WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8),
			parameter							CYCLE         = 0
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
	if ( CYCLE == 0 ) begin
		for ( i = 0; i < WB_SEL_WIDTH; i = i + 1 ) begin : ram
			ram_singleport
					#(
						.DATA_WIDTH		(8),
						.ADDR_WIDTH		(WB_ADR_WIDTH)
					)
				i_ram_singleport
					(
						.clk			(~clk),
						.en				(wb_stb_i),
						.we				(wb_we_i & wb_sel_i[i]),
						.addr			(wb_adr_i),
						.din			(wb_dat_i[i*8 +: 8]),
						.dout			(wb_dat_o[i*8 +: 8])
					);
		end
		assign wb_ack_o = 1'b1;
	end
	else begin
		for ( i = 0; i < WB_SEL_WIDTH; i = i + 1 ) begin : ram
			ram_singleport
					#(
						.DATA_WIDTH		(8),
						.ADDR_WIDTH		(WB_ADR_WIDTH)
					)
				i_ram_singleport
					(
						.clk			(clk),
						.en				(wb_stb_i),
						.we				(wb_we_i & wb_sel_i[i]),
						.addr			(wb_adr_i),
						.din			(wb_dat_i[i*8 +: 8]),
						.dout			(wb_dat_o[i*8 +: 8])
					);
		end
		
		reg		read;
		always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
				read <= 1'b0;
			end
			else begin
				read <= !read & wb_stb_i & !wb_we_i;
			end
		end
		assign wb_ack_o = wb_we_i | read;
	end
	endgenerate
	
endmodule
