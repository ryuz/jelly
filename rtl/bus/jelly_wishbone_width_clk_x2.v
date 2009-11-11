// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



// whishbone x2 clock bridge
module jelly_wishbone_clk2x
		#(
			parameter	WB_SLAVE_ADR_WIDTH  = 30,
			parameter	WB_SLAVE_DAT_WIDTH  = 32,
			parameter	WB_SLAVE_SEL_WIDTH  = (WB_DAT_WIDTH / 8)
			
			parameter	WB_MASTER_ADR_WIDTH = WB_SLAVE_ADR_WIDTH + 1,
			parameter	WB_MASTER_DAT_WIDTH = (WB_SLAVE_DAT_WIDTH >> 1),
			parameter	WB_MASTER_SEL_WIDTH = (WB_SLAVE_SEL_WIDTH >> 1)
		)
		(
			//system
			input	wire								reset,
			input	wire								clk,
			input	wire								clk_x2,
			
			// endian
			input	wire								endian,
			
			// slave port (WISHBONE)
			input	wire	[WB_SLAVE_ADR_WIDTH-1:0]	wb_slave_adr_i,
			output	wire	[WB_SLAVE_DAT_WIDTH-1:0]	wb_slave_dat_o,
			input	wire	[WB_SLAVE_DAT_WIDTH-1:0]	wb_slave_dat_i,
			input	wire								wb_slave_we_i,
			input	wire	[WB_SLAVE_SEL_WIDTH-1:0]	wb_slave_sel_i,
			input	wire								wb_slave_stb_i,
			output	wire								wb_slave_ack_o,
			
			// master port (WISHBONE)
			output	wire	[WB_MASTER_ADR_WIDTH-1:0]	wb_master_adr_o,
			output	wire	[WB_MASTER_DAT_WIDTH-1:0]	wb_master_dat_o,
			input	wire	[WB_MASTER_DAT_WIDTH-1:0]	wb_master_dat_i,
			output	wire								wb_master_we_o,
			output	wire	[WB_MASTER_SEL_WIDTH-1:0]	wb_master_sel_o,
			output	wire								wb_master_stb_o,
			input	wire								wb_master_ack_i
		);
	
	
	reg				delay_clk;
	always @* begin
		delay_clk <= #1 clk;
	end
	
	reg				reg_phase;
	always @( posedge clk_x2 ) begin
		reg_phase <= delay_clk;
	end
	
	
	reg									reg_2nd;
	reg									reg_end;
	reg		[WB_SLAVE_DAT_WIDTH-1:0]	reg_dat;
	
	always @( posedge clk_x2 ) begin
		if ( reset ) begin
			reg_2nd <= 1'b0;
			reg_end <= 1'b0;
			reg_dat <= {WB_SLAVE_DAT_WIDTH{1'bx}};
		end
		else begin
			if ( reg_end ) begin
				if ( reg_phase == 1'b1 ) begin
					reg_end <= 1'b0;
					reg_dat <= {WB_SLAVE_DAT_WIDTH{1'bx}};
				end
			end
			else begin
				reg_2nd <= !reg_2nd & wb_master_stb_o & wb_master_ack_i;
				if ( reg_2nd & wb_master_ack_i & !reg_phase ) begin
					reg_end <= 1'b1;
					reg_dat <= endian ? wb_master_dat_i[0 +: WB_SLAVE_DAT_WIDTH] : wb_master_dat_i[WB_SLAVE_DAT_WIDTH +: WB_SLAVE_DAT_WIDTH];
				end
			end
		end
	end
	
	assign wb_master_adr_o = {wb_slave_adr_i, reg_2nd};
	assign wb_master_dat_o = reg_2nd ^ endian ? wb_slave_dat_i[0 +: WB_MASTER_DAT_WIDTH] : wb_slave_dat_i[WB_MASTER_DAT_WIDTH +: WB_MASTER_DAT_WIDTH];
	assign wb_master_we_o  = wb_slave_we_i;
	assign wb_master_sel_o = reg_2nd ^ endian ? wb_slave_sel_i[0 +: WB_MASTER_SEL_WIDTH] : wb_slave_sel_i[WB_MASTER_SEL_WIDTH +: WB_MASTER_SEL_WIDTH];
	assign wb_master_stb_o = wb_slave_stb_i & !reg_end;
	
	assign wb_slave_dat_i[0 +: WB_MASTER_DAT_WIDTH]  = 
	
	assign wb_slave_ack_o = reg_end | (reg_2nd & wb_master_ack_i);
	
	
	
endmodule


// End of file
