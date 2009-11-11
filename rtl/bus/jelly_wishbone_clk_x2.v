// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



// whishbone x2 clock bridge
module jelly_wishbone_clk_x2
		#(
			parameter	WB_ADR_WIDTH  = 30,
			parameter	WB_DAT_WIDTH  = 32,
			parameter	WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8)
		)
		(
			//system
			input								clk,
			input								clk_x2,
			input								reset,
			
			// wishbone
			input	wire	[WB_ADR_WIDTH-1:0]	wb_adr_i,
			output	reg		[WB_DAT_WIDTH-1:0]	wb_dat_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_dat_i,
			input	wire						wb_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	wb_sel_i,
			input	wire						wb_stb_i,
			output	reg							wb_ack_o,
			
			// wishbone
			output	reg		[WB_ADR_WIDTH-1:0]	wb_x2_adr_o,
			output	reg		[WB_DAT_WIDTH-1:0]	wb_x2_dat_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_x2_dat_i,
			output	reg							wb_x2_we_o,
			output	reg		[WB_SEL_WIDTH-1:0]	wb_x2_sel_o,
			output	reg							wb_x2_stb_o,
			input	wire						wb_x2_ack_i
		);
	
	reg							st_idle;
	reg							st_busy;
	reg							st_end;

	always @( posedge clk ) begin
		if ( reset ) begin
			wb_ack_o <= 1'b0;
		end
		else begin
			if ( wb_stb_i & ~wb_ack_o & st_end ) begin
				wb_ack_o <= 1'b1;
			end
			else begin
				wb_ack_o <= 1'b0;
			end
		end
	end
	
	
	always @( posedge clk_x2 ) begin
		if ( reset ) begin
			st_idle <= 1'b1;
			st_busy <= 1'b0;
			st_end  <= 1'b0;
			
			wb_x2_adr_o <= {WB_ADR_WIDTH{1'bx}};
			wb_x2_dat_o <= {WB_DAT_WIDTH{1'bx}};
			wb_x2_we_o  <= 1'bx;
			wb_x2_sel_o <= {WB_SEL_WIDTH{1'bx}};
			wb_x2_stb_o <= 1'b0;
		end
		else begin
			if ( st_idle ) begin
				if ( wb_stb_i & ~wb_ack_o ) begin
					wb_x2_adr_o <= wb_adr_i;
					wb_x2_dat_o <= wb_dat_i;
					wb_x2_we_o  <= wb_we_i;
					wb_x2_sel_o <= wb_sel_i;
					wb_x2_stb_o <= 1'b1;
					
					st_idle <= 1'b0;
					st_busy <= 1'b1;
				end
			end
			else if ( st_busy ) begin
				wb_dat_o <= wb_x2_dat_i;
				if ( wb_x2_ack_i ) begin
					wb_x2_stb_o <= 1'b0;
					st_busy     <= 1'b0;
					st_end      <= 1'b1;
				end
			end
			else if ( st_end ) begin
				if ( wb_ack_o ) begin
					st_end  <= 1'b0;
					st_idle <= 1'b1;
				end
			end
		end
	end
	
endmodule


// End of file
