// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    block sram interface
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


module jelly_sram
		#(
			parameter	WB_ADR_WIDTH  = 10,
			parameter	WB_DAT_WIDTH  = 32,
			parameter	WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8),
			parameter	READMEMB      = 0,
			parameter	READMEMH      = 0,
			parameter	READMEM_FILE  = ""
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
	
	wire						ram_en;
	wire						ram_we;
	wire	[WB_ADR_WIDTH-1:0]	ram_addr;
	wire	[WB_DAT_WIDTH-1:0]	ram_wdata;
	wire	[WB_DAT_WIDTH-1:0]	ram_rdata;
	
	jelly_wishbone_to_ram
			#(
				.WB_ADR_WIDTH	(WB_ADR_WIDTH),
				.WB_DAT_WIDTH	(WB_DAT_WIDTH)
			)
		i_wishbone_to_ram
			(
				.reset			(reset),
				.clk			(clk),
				
				.wb_adr_i		(wb_adr_i),
				.wb_dat_o		(wb_dat_o),
				.wb_dat_i		(wb_dat_i),
				.wb_we_i		(wb_we_i),
				.wb_sel_i		(wb_sel_i),
				.wb_stb_i		(wb_stb_i),
				.wb_ack_o		(wb_ack_o),
				
				.ram_en			(ram_en),
				.ram_we			(ram_we),
				.ram_addr		(ram_addr),
				.ram_wdata		(ram_wdata),
				.ram_rdata		(ram_rdata)
			);                 
	
	jelly_ram_singleport
			#(
				.ADDR_WIDTH		(WB_ADR_WIDTH),
				.DATA_WIDTH		(WB_DAT_WIDTH),
				.WRITE_FIRST	(0),
				.FILLMEM		(0),
				.FILLMEM_DATA	({WB_DAT_WIDTH{1'b0}}),
				.READMEMB		(READMEMB),
				.READMEMH		(READMEMH),
				.READMEM_FILE	(READMEM_FILE)
			)
		i_ram_singleport
			(
				.clk			(clk),
				.en				(ram_en),
				.we				(ram_we),
				.addr			(ram_addr),
				.din			(ram_wdata),
				.dout			(ram_rdata)
			);                 
			
endmodule
