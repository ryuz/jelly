// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// ring bus unit
module jelly_data_crossbar_simple
		#(
			parameter	S_NUM         = 8,
			parameter	S_ID_WIDTH    = 3,
			parameter	M_NUM         = 16,
			parameter	M_ID_WIDTH    = 4,
			parameter	DATA_WIDTH    = 32
		)
		(
			input	wire							reset,
			input	wire							clk,
			input	wire							cke,
			
			input	wire	[S_NUM*M_ID_WIDTH-1:0]	s_id_to,
			input	wire	[S_NUM*DATA_WIDTH-1:0]	s_data,
			input	wire	[S_NUM-1:0]				s_valid,
			
			output	wire	[M_NUM*S_ID_WIDTH-1:0]	m_id_from,
			output	wire	[M_NUM*DATA_WIDTH-1:0]	m_data,
			output	wire	[M_NUM-1:0]				m_valid
		);
	
	genvar		i, j;
	
	
	// switch
	wire	[S_NUM*M_NUM*DATA_WIDTH-1:0]	array_s_data;
	wire	[S_NUM*M_NUM-1:0]				array_s_valid;
	wire	[S_NUM*M_NUM-1:0]				array_s_ready;
	
	generate
	for ( i = 0; i < S_NUM; i = i+1 ) begin : loop_slave
		jelly_data_switch_simple
					#(
						.NUM		(M_NUM),
						.ID_WIDTH	(M_ID_WIDTH),
						.DATA_WIDTH	(DATA_WIDTH)
					)
				i_data_switch_simple
					(
						.reset		(reset),
						.clk		(clk),
						.cke		(1'b1),
						
						.s_id		(s_id_to      [i*M_ID_WIDTH       +: M_ID_WIDTH]),
						.s_data		(s_data       [i*DATA_WIDTH       +: DATA_WIDTH]),
						.s_valid	(s_valid      [i]),
						
						.m_data		(array_s_data [i*M_NUM*DATA_WIDTH +: M_NUM*DATA_WIDTH]),
						.m_valid	(array_s_valid[i*M_NUM            +: M_NUM])
					);
	end
	endgenerate
	
	
	
	// cross
	wire	[M_NUM*S_NUM*DATA_WIDTH-1:0]	array_m_data;
	wire	[M_NUM*S_NUM-1:0]				array_m_valid;
	wire	[M_NUM*S_NUM-1:0]				array_m_ready;
	
	generate
	for ( i = 0; i < M_NUM; i = i+1 ) begin : loop_cross_m
		for ( j = 0; j < S_NUM; j = j+1 ) begin : loop_cross_s
			assign array_m_data [(i*S_NUM+j)*DATA_WIDTH +: DATA_WIDTH] = array_s_data [(j*M_NUM+i)*DATA_WIDTH +: DATA_WIDTH];
			assign array_m_valid[(i*S_NUM+j)]                          = array_s_valid[(j*M_NUM+i)];
				
			assign array_s_ready[(j*M_NUM+i)]                          = array_m_ready[(i*S_NUM+j)];
		end
	end
	endgenerate
	
	
	
	// joint
	generate
	for ( i = 0; i < M_NUM; i = i+1 ) begin : loop_master
		jelly_data_joint_simple
				#(
					.NUM				(S_NUM),
					.ID_WIDTH			(S_ID_WIDTH),
					.DATA_WIDTH			(DATA_WIDTH)
				)
			i_data_joint_simple
				(
					.reset				(reset),
					.clk				(clk),
					.cke				(cke),
					
					.s_data				(array_m_data [i*S_NUM*DATA_WIDTH +: S_NUM*DATA_WIDTH]),
					.s_valid			(array_m_valid[i*S_NUM            +: S_NUM]),
					
					.m_id				(m_id_from    [i*S_ID_WIDTH       +: S_ID_WIDTH]),
					.m_data				(m_data       [i*DATA_WIDTH       +: DATA_WIDTH]),
					.m_valid			(m_valid      [i])
				);
	end
	endgenerate
	
	
endmodule



`default_nettype wire


// end of file
