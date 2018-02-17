
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
	
	
	parameter	RATE_WIDTH    = 4;
	parameter	COMPONENT_NUM = 1;
	parameter	DATA_WIDTH    = 8;
	parameter	DATA_SIGNED   = 0;
	parameter	USER_WIDTH    = COMPONENT_NUM*DATA_WIDTH;
	
	// local
	parameter	USER_BITS     = USER_WIDTH > 0 ? USER_WIDTH : 1;
	
	reg										cke = 1;
	
	reg		[USER_BITS-1:0]					s_user;
	reg		[RATE_WIDTH-1:0]				s_rate  = 4'b0100;
	reg		[COMPONENT_NUM*DATA_WIDTH-1:0]	s_data0 = 9'h000; // 24'h7f_ff_00;
	reg		[COMPONENT_NUM*DATA_WIDTH-1:0]	s_data1 = 9'h0ff; // 24'h80_00_ff;
	reg										s_valid = 0;
	wire	[USER_BITS-1:0]					m_user;
	wire	[COMPONENT_NUM*DATA_WIDTH-1:0]	m_data;
	wire									m_valid;
	
	wire									error_flag = cke && m_valid && (m_user != m_data);
	integer									error;
	always @* begin
		error = 0;
		if ( error_flag ) begin
			 error = m_data > m_user ? m_data - m_user : m_user - m_data;
		end
	end
	
	always @(posedge clk) begin
		if ( reset ) begin
			s_rate  <=  4'b0000;
			s_valid <= 1'b0;
		end
		else if ( cke ) begin
			s_valid <= 1'b1;
//			s_rate  <= s_rate + s_valid;
			
			s_rate  <= {$random()};
			s_data0 <= $random();
			s_data1 <= $random();
		end
	end
	
	
	integer								i;
	wire	signed	[RATE_WIDTH:0]		r1  = {1'b0, s_rate};
	wire	signed	[RATE_WIDTH:0]		r0  = (1 << RATE_WIDTH) - r1;
	reg		signed	[DATA_WIDTH-1:0]	sd0, sd1;
	reg				[DATA_WIDTH-1:0]	ud0, ud1;
	integer								d0;
	integer								d1;
	integer								rounding = 0; // (1 << (RATE_WIDTH-1));
	
	always @* begin
		for ( i = 0; i < COMPONENT_NUM; i = i+1 ) begin
			sd0 = s_data0[i*DATA_WIDTH +: DATA_WIDTH];
			sd1 = s_data1[i*DATA_WIDTH +: DATA_WIDTH];
			ud0 = s_data0[i*DATA_WIDTH +: DATA_WIDTH];
			ud1 = s_data1[i*DATA_WIDTH +: DATA_WIDTH];
			if ( DATA_SIGNED ) begin
				d0 = sd0 * r0;
				d1 = sd1 * r1;
			end
			else begin
				d0 = ud0 * r0;
				d1 = ud1 * r1;
			end
			
			s_user[i*DATA_WIDTH +: DATA_WIDTH] = ((d0+d1+rounding) >>> RATE_WIDTH);
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
