// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//   整数の順次インクリメント/デクリメント値生成コア
//
//                                 Copyright (C) 2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// 整数の順次インクリメント/デクリメント値生成コア
module jelly_integer_step
		#(
			parameter	DATA_WIDTH = 32
		)
		(
			input	wire								clk,
			
			input	wire	[5:0]						stage_cke,
			
			input	wire	signed	[DATA_WIDTH-1:0]	param_init,
			input	wire	signed	[DATA_WIDTH-1:0]	param_step,
			
			input	wire								set_param,
			input	wire								increment,
			
			output	wire	signed	[DATA_WIDTH-1:0]	out_data
		);
	
	reg		signed	[DATA_WIDTH-1:0]	reg_data;
	
	always @(posedge clk) begin
		if ( cke ) begin
			if ( set_param ) begin
				reg_data <= param_init;
			end
			else begin
				if ( increment ) begin
					reg_data <= reg_data + param_step;
				end
			end
		end
	end
	
	assign out_data = reg_data;
	
endmodule


`default_nettype wire


// end of file
