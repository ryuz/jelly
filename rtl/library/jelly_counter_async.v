// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2017 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// ƒJƒEƒ“ƒ^ÏZ’l‚ğ”ñ“¯Šúæ‚É“`”d
module jelly_counter_async
		#(
			parameter	COUNTER_WIDTH = 16
		)
		(
			input	wire						s_reset,
			input	wire						s_clk,
			input	wire	[COUNTER_WIDTH-1:0]	s_add,
			input	wire						s_valid,
			
			input	wire						m_reset,
			input	wire						m_clk,
			output	wire	[COUNTER_WIDTH-1:0]	m_counter,
			input	wire						m_ready
		);
	
	
	reg		[COUNTER_WIDTH-1:0]		reg_s_counter, next_s_counter;
	wire							sig_s_ready;
	
	always @* begin
		next_s_counter = reg_s_counter;
		
		if ( sig_s_ready ) begin
			next_s_counter = {COUNTER_WIDTH{1'b0}};
		end
		
		if ( s_valid ) begin
			next_s_counter = next_s_counter + s_add;
		end
	end
	
	
	always @(posedge s_clk) begin
		if ( s_reset ) begin
			reg_s_counter <= {COUNTER_WIDTH{1'b0}};
		end
		else begin
			reg_s_counter <= next_s_counter;
		end
	end
	
	
	reg		[COUNTER_WIDTH-1:0]		reg_m_counter, next_m_counter;
	wire	[COUNTER_WIDTH-1:0]		sig_m_counter;
	wire							sig_m_valid;
	
	always @* begin
		next_m_counter = reg_m_counter;
		
		if ( m_ready ) begin
			next_m_counter = 0;
		end
		
		if ( sig_m_valid ) begin
			next_m_counter = next_m_counter + sig_m_counter;
		end
	end
	
	
	always @(posedge m_clk) begin
		if ( m_reset ) begin
			reg_m_counter <= {COUNTER_WIDTH{1'b0}};
		end
		else begin
			reg_m_counter <= next_m_counter;
		end
	end
	
	assign m_counter = reg_m_counter;
	
	
	jelly_data_async
			#(
				.DATA_WIDTH		(COUNTER_WIDTH)
			)
		i_data_async
			(
				.s_reset		(s_reset),
				.s_clk			(s_clk),
				.s_data			(reg_s_counter),
				.s_valid		(1'b1),
				.s_ready		(sig_s_ready),
				
				.m_reset		(m_reset),
				.m_clk			(m_clk),
				.m_data			(sig_m_counter),
				.m_valid		(sig_m_valid),
				.m_ready		(1'b1)
			);
	
	
endmodule


`default_nettype wire


// end of file
