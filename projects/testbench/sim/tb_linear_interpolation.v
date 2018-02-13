
`timescale 1ns / 1ps
`default_nettype none


module tb_linear_interpolation();
	localparam RATE = 10.0;
	
	initial begin
		$dumpfile("tb_linear_interpolation.vcd");
		$dumpvars(0, tb_linear_interpolation);
		
		#10000
		$finish();
	end
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		reset = 1'b1;
	always #(RATE*20)	reset = 1'b0;
	
	
	parameter	USER_WIDTH    = 0;
	parameter	RATE_WIDTH    = 4;
	parameter	COMPONENT_NUM = 3;
	parameter	DATA_WIDTH    = 8;
	parameter	DATA_SIGNED   = 1;
	
	// local
	parameter	USER_BITS     = USER_WIDTH > 0 ? USER_WIDTH : 1;
	
	reg										cke = 1;
	
	reg		[USER_BITS-1:0]					s_user;
	reg		[RATE_WIDTH-1:0]				s_rate  = 4'b0100;
	reg		[COMPONENT_NUM*DATA_WIDTH-1:0]	s_data0 = 24'h7f_ff_00;
	reg		[COMPONENT_NUM*DATA_WIDTH-1:0]	s_data1 = 24'h80_00_ff;
	reg										s_valid = 1;
	wire	[USER_BITS-1:0]					m_user;
	wire	[COMPONENT_NUM*DATA_WIDTH-1:0]	m_data;
	wire									m_valid;
	
	
	always @(posedge clk) begin
		if ( reset ) begin
			s_rate <=  4'b0000;
		end
		else if ( cke ) begin
			s_rate <=  s_rate + s_valid;
		end
	end
	
	
	jelly_linear_interpolation
			#(
				.USER_WIDTH    		(USER_WIDTH),
				.RATE_WIDTH    		(RATE_WIDTH),
				.COMPONENT_NUM 		(COMPONENT_NUM),
				.DATA_WIDTH 		(DATA_WIDTH),
				.DATA_SIGNED  		(DATA_SIGNED)
			)
		i_linear_interpolation
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.s_user				(s_user),
				.s_rate				(s_rate),
				.s_data0			(s_data0),
				.s_data1			(s_data1),
				.s_valid			(s_valid),
				
				.m_user				(m_user),
				.m_data				(m_data),
				.m_valid			(m_valid)
			);
	
	
	
endmodule



`default_nettype wire


// end of file
