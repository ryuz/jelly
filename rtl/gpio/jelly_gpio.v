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
			parameter	INIT_OUTPUT    = 0
		)
		(
			// system
			input	wire						reset,
			input	wire						clk,
			
			// port
			inout	wire	[PORT_WIDTH-1:0]	port,
			
			// control port (wishbone)
			input	wire	[WB_ADR_WIDTH-1:0]	wb_adr_i,
			output	reg		[WB_DAT_WIDTH-1:0]	wb_dat_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_dat_i,
			input	wire						wb_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	wb_sel_i,
			input	wire						wb_stb_i,
			output	wire						wb_ack_o
		);
	
	
	(* IOB = "TRUE" *)	reg		[PORT_WIDTH-1:0]	reg_direction;
	(* IOB = "TRUE" *)	reg		[PORT_WIDTH-1:0]	reg_input;
	(* IOB = "TRUE" *)	reg		[PORT_WIDTH-1:0]	reg_output;
	
	always @ ( posedge clk ) begin
		if ( reset ) begin
			reg_direction <= INIT_DIRECTION;
			reg_input     <= {PORT_WIDTH{1'bx}};
			reg_output    <= INIT_OUTPUT;
		end
		else begin
			// direction
			if ( wb_stb_i & wb_we_i & (wb_adr_i == `GPIO_ADR_DIRECTION) ) begin
				reg_direction <= wb_dat_i[PORT_WIDTH-1:0];
			end
			
			// output
			if ( wb_stb_i & wb_we_i & (wb_adr_i == `GPIO_ADR_OUTPUT) ) begin
				reg_output <= wb_dat_i[PORT_WIDTH-1:0];
			end
			
			// input
			reg_input <= port;
		end
	end
	
	generate
	genvar	i;
	for ( i = 0; i < PORT_WIDTH; i = i + 1 ) begin : io
		assign port[i] = reg_direction[i] ? reg_output[i] : 1'bz;
	end
	endgenerate
	
	
	always @* begin
		case ( wb_adr_i )
		`GPIO_ADR_DIRECTION:	wb_dat_o <= reg_direction;
		`GPIO_ADR_INPUT:		wb_dat_o <= reg_input;
		`GPIO_ADR_OUTPUT:		wb_dat_o <= reg_output;
		default:				wb_dat_o <= {WB_DAT_WIDTH{1'b0}};
		endcase
	end
		
	assign wb_ack_o = wb_stb_i;
	
endmodule

