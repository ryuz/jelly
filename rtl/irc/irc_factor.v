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
			factor_id,
			in_interrupt,
			reqest_reset, reqest_start, reqest_send, reqest_sense,
			wb_adr_i, wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o
		);
	
	parameter	FACTOR_ID_WIDTH = 2;
	parameter	PRIORITY_WIDTH  = 3;
	localparam	PACKET_WIDTH    = PRIORITY_WIDTH + FACTOR_ID_WIDTH;
	
	parameter	WB_ADR_WIDTH   = 2;
	parameter	WB_DAT_WIDTH   = 32;
	localparam	WB_SEL_WIDTH   = (WB_DAT_WIDTH / 8);
	
	// system
	input							clk;
	input							reset;
	
	input	[FACTOR_ID_WIDTH-1:0]	factor_id;
	
	// interrupt
	input							in_interrupt;
	
	// request
	input							reqest_reset;
	input							reqest_start;
	output							reqest_send;
	input							reqest_sense;
	
	
	// control port (wishbone)
	input	[1:0]					wb_adr_i;
	output	[WB_DAT_WIDTH-1:0]		wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]		wb_dat_i;
	input							wb_we_i;
	input	[WB_SEL_WIDTH-1:0]		wb_sel_i;
	input							wb_stb_i;
	output							wb_ack_o;
	
	
	// registers
	reg								reg_enable;
	reg								reg_pending;
	reg		[PRIORITY_WIDTH-1:0]	reg_priority;
	
	// interrupt
	wire							interrupt_assert;
	assign interrupt_assert = reg_pending & reg_enable;
	
	
	// request send
	reg		[PACKET_WIDTH-1:0]		send_packet;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			send_packet  <= {PACKET_WIDTH{1'b1}};
		end
		else begin
			if ( reqest_reset ) begin
				send_packet <= {PACKET_WIDTH{1'b1}};
			end
			else begin
				if ( interrupt_assert & reqest_start ) begin
					send_packet  <= {reg_priority, factor_id};
				end
				else begin
					send_packet  <= {send_packet, 1'b1};
				end
			end
		end
	end
	
	assign reqest_send = send_packet[PACKET_WIDTH-1];
	
	
	// registers
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_enable    <= 1'b0;
			reg_pending   <= 1'b0;
			reg_priority  <= {PRIORITY_WIDTH{1'b0}};
		end
		else begin
			// enable
			if ( wb_stb_i & wb_we_i & (wb_adr_i == 0) ) begin
				reg_enable <= wb_dat_i[0];
			end
			
			// pending
			if ( in_interrupt ) begin
				reg_pending <= 1'b1;
			end
			else if ( wb_stb_i & wb_we_i & (wb_adr_i == 1) ) begin
				reg_pending <= wb_dat_i[0];
			end
			
			// priority
			if ( wb_stb_i & wb_we_i & (wb_adr_i == 3) ) begin
				reg_priority <= wb_dat_i;
			end
		end
	end
	
	
	// wb_dat_o
	reg		[WB_DAT_WIDTH-1:0]		wb_dat_o;
	always @* begin
		if ( wb_stb_i ) begin
			case ( wb_adr_i[1:0] )
			2'b00:		wb_dat_o <= reg_enable;			// enable
			2'b01:		wb_dat_o <= reg_pending;		// pending
			2'b10:		wb_dat_o <= in_interrupt;		// status
			2'b11:		wb_dat_o <= reg_priority;		// priority
			default:	wb_dat_o <= {WB_DAT_WIDTH{1'b0}};
			endcase
		end
		else begin
			wb_dat_o <= {WB_DAT_WIDTH{1'b0}};
		end
	end
	
endmodule


