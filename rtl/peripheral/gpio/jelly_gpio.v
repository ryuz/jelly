// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    GPIO
//
//                                      Copyright (C) 2009 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



`define GPIO_ADR_DIRECTION	2'b00
`define GPIO_ADR_INPUT		2'b01
`define GPIO_ADR_OUTPUT		2'b10


module jelly_gpio
		#(
			parameter	WB_ADR_WIDTH   = 2,
			parameter	WB_DAT_WIDTH   = 32,
			parameter	WB_SEL_WIDTH   = (WB_DAT_WIDTH / 8),
			parameter	PORT_WIDTH     = 8,
			parameter	INIT_DIRECTION = 0,
			parameter	INIT_OUTPUT    = 0,
			parameter	DIRECTION_MASK = 0
		)
		(
			// system
			input	wire						reset,
			input	wire						clk,
			
			// port
			input	wire	[PORT_WIDTH-1:0]	port_i,
			output	wire	[PORT_WIDTH-1:0]	port_o,
			output	wire	[PORT_WIDTH-1:0]	port_t,
			
			// control port (wishbone)
			input	wire	[WB_ADR_WIDTH-1:0]	wb_adr_i,
			output	reg		[WB_DAT_WIDTH-1:0]	wb_dat_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_dat_i,
			input	wire						wb_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	wb_sel_i,
			input	wire						wb_stb_i,
			output	wire						wb_ack_o
		);
	
	
	reg		[PORT_WIDTH-1:0]	reg_direction;
	reg		[PORT_WIDTH-1:0]	reg_output;
	
	always @ ( posedge clk ) begin
		if ( reset ) begin
			reg_direction <= INIT_DIRECTION;
			reg_output    <= INIT_OUTPUT;
		end
		else begin
			// direction
			if ( wb_stb_i & wb_we_i & (wb_adr_i == `GPIO_ADR_DIRECTION) ) begin
				reg_direction <= ((reg_direction & DIRECTION_MASK) | (wb_dat_i[PORT_WIDTH-1:0] & ~DIRECTION_MASK));
			end
			
			// output
			if ( wb_stb_i & wb_we_i & (wb_adr_i == `GPIO_ADR_OUTPUT) ) begin
				reg_output <= wb_dat_i[PORT_WIDTH-1:0];
			end
		end
	end
	
	assign port_o = reg_output;
	assign port_t = ~reg_direction;
	
	always @* begin
		case ( wb_adr_i )
		`GPIO_ADR_DIRECTION:	wb_dat_o <= reg_direction;
		`GPIO_ADR_INPUT:		wb_dat_o <= port_i;
		`GPIO_ADR_OUTPUT:		wb_dat_o <= reg_output;
		default:				wb_dat_o <= {WB_DAT_WIDTH{1'b0}};
		endcase
	end
	
	assign wb_ack_o = wb_stb_i;
	
endmodule

