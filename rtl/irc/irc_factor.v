// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    Interrupt controller
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------



`timescale 1ns / 1ps



module irc_factor
		(
			reset, clk,
			interrupt_in, interrupt_req, mask_level,
			wb_adr_i, wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o
		);
	
	parameter	PRIORITY_WIDTH = 3;
	
	parameter	WB_ADR_WIDTH   = 2;
	parameter	WB_DAT_WIDTH   = 32;
	localparam	WB_SEL_WIDTH   = (WB_DAT_WIDTH / 8);
	
	// system
	input							clk;
	input							reset;
	
	// interrupt
	input							interrupt_in;
	output							interrupt_req;
	input	[PRIORITY_WIDTH-1:0]	mask_level;
	
	// control port (wishbone)
	input	[1:0]					wb_adr_i;
	output	[WB_DAT_WIDTH-1:0]		wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]		wb_dat_i;
	input							wb_we_i;
	input	[WB_SEL_WIDTH-1:0]		wb_sel_i;
	input							wb_stb_i;
	output							wb_ack_o;
	
	
	
	
	// register
	reg								reg_enable;
	reg								reg_assert;
	reg		[PRIORITY_WIDTH-1:0]	reg_level;
	
	
	// interrupt
	assign interrupt_req = (reg_level < mask_level) & reg_assert & reg_enable;
	
	
	// register
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_enable <= 1'b0;
			reg_assert <= 1'b0;
			reg_level  <= {PRIORITY_WIDTH{1'b0}};
		end
		else begin
			// enable
			if ( wb_stb_i & wb_we_i & (wb_adr_i == 0) ) begin
				reg_enable <= wb_dat_i[0];
			end
			
			// assert
			if ( interrupt_in ) begin
				reg_assert <= 1'b1;
			end
			else if ( wb_stb_i & wb_we_i & (wb_adr_i == 1) ) begin
				reg_assert <= wb_dat_i[0];
			end
			
			// level
			if ( wb_stb_i & wb_we_i & (wb_adr_i == 3) ) begin
				reg_level  <= wb_dat_i;
			end
		end
	end
	
	
	// wb_dat_o
	reg		[WB_DAT_WIDTH-1:0]		wb_dat_o;
	always @* begin
		if ( wb_stb_i ) begin
			case ( wb_adr_i[1:0] )
			2'b00:		wb_dat_o <= reg_enable;
			2'b01:		wb_dat_o <= reg_assert;
			2'b10:		wb_dat_o <= interrupt_req;
			2'b11:		wb_dat_o <= reg_level;
			default:	wb_dat_o <= {WB_DAT_WIDTH{1'bx}};
			endcase
		end
		else begin
			wb_dat_o <= {WB_DAT_WIDTH{1'b0}};
		end
	end
	
endmodule



