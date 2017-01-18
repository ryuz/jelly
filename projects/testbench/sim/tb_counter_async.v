
`timescale 1ns / 1ps
`default_nettype none


module tb_counter_async();
	localparam S_RATE = 1000.0/20.0;
	localparam M_RATE = 1000.0/210.7;
	
	initial begin
		$dumpfile("tb_counter_async.vcd");
		$dumpvars(0, tb_counter_async);
		
		#100000;
			$finish;
	end
	
	reg		s_clk = 1'b1;
	always #(S_RATE/2.0)	s_clk = ~s_clk;
	
	reg		m_clk = 1'b1;
	always #(M_RATE/2.0)	m_clk = ~m_clk;
	
	reg		reset = 1'b1;
	initial #(S_RATE*100)	reset = 1'b0;
	
	
	localparam	COUNTER_WIDTH = 16;
	
	reg		[COUNTER_WIDTH-1:0]	s_add   = 1;
	reg							s_valid = 0;
	
	wire	[COUNTER_WIDTH-1:0]	m_counter;
	reg							m_ready = 1;
	
	initial begin
		#(S_RATE*200)	s_valid = 1'b1;
		#(S_RATE*300)	s_valid = 1'b0;
	end
	
	integer	s_c = 0;
	always @(posedge s_clk) begin
		if ( s_valid  ) begin
			s_c <= s_c + s_add;
		end
	end
	
	integer	m_c = 0;
	always @(posedge m_clk) begin
		if ( !reset ) begin
			m_ready <= {$random};
			
			if ( m_ready ) begin
				m_c <= m_c + m_counter;
			end
		end
	end
	
	jelly_counter_async
			#(
				.COUNTER_WIDTH	(COUNTER_WIDTH)
			)
		i_count_async
			(
				.s_reset		(reset),
				.s_clk			(s_clk),
				.s_add			(s_add),
				.s_valid		(s_valid),
				
				.m_reset		(reset),
				.m_clk			(m_clk),
				.m_counter		(m_counter),
				.m_ready		(m_ready)
			);
	
	
endmodule


`default_nettype wire


// end of file
