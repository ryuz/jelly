// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


`define INTERVAL_TIMER_ADR_CONTROL	2'b00
`define INTERVAL_TIMER_ADR_COMPARE	2'b01
`define INTERVAL_TIMER_ADR_COUNTER	2'b11


//    Timer
module jelly_interval_timer
		#(
			parameter							WB_ADR_WIDTH  = 2,
			parameter							WB_DAT_WIDTH  = 32,
			parameter							WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8)
		)
		(
			// system
			input	wire						reset,
			input	wire						clk,
			
			// irq
			output	reg							interrupt_req,
			
			// control port (wishbone)
			input	wire	[WB_ADR_WIDTH-1:0]	wb_adr_i,
			output	reg		[WB_DAT_WIDTH-1:0]	wb_dat_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_dat_i,
			input	wire						wb_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	wb_sel_i,
			input	wire						wb_stb_i,
			output	wire						wb_ack_o
		);
	
	reg					reg_enable;
	reg					reg_clear;
	reg		[31:0]		reg_counter;
	reg		[31:0]		reg_compare;
	
	wire				compare_match;
	assign compare_match = (reg_counter == reg_compare);
	
	always @ ( posedge clk ) begin
		if ( reset ) begin
			reg_enable    <= 1'b0;
			reg_clear     <= 1'b0;
			reg_counter   <= 0;
			reg_compare   <= 50000 - 1;
			interrupt_req <= 1'b0;
		end
		else begin
			// control
			if ( wb_stb_i & wb_we_i & (wb_adr_i == `INTERVAL_TIMER_ADR_CONTROL) ) begin
				reg_enable <= wb_dat_i[0];
				reg_clear  <= wb_dat_i[1];
			end
			else begin
				reg_clear  <= 1'b0;		// auto clear;
			end
			
			// compare
			if ( wb_stb_i & wb_we_i & (wb_adr_i == `INTERVAL_TIMER_ADR_COMPARE) ) begin
				reg_compare <= wb_dat_i;
			end
			
			// counter
			if ( compare_match | reg_clear ) begin
				reg_counter <= 0;
			end
			else begin
				reg_counter <= reg_counter + reg_enable;
			end
			
			// interrupt
			if ( compare_match ) begin
				interrupt_req <= reg_enable;
			end
			else begin
				interrupt_req <= 1'b0;
			end
		end
	end
	
	always @* begin
		case ( wb_adr_i )
		`INTERVAL_TIMER_ADR_CONTROL:	wb_dat_o <= {reg_clear, reg_enable};
		`INTERVAL_TIMER_ADR_COMPARE:	wb_dat_o <= reg_compare;
		`INTERVAL_TIMER_ADR_COUNTER:	wb_dat_o <= reg_counter;
		default:						wb_dat_o <= {WB_DAT_WIDTH{1'b0}};
		endcase
	end
		
	assign wb_ack_o = wb_stb_i;
	
endmodule


`default_nettype wire


//  end of file
