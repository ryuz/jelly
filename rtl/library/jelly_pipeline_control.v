// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   First-Word Fall-Through mode FIFO
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// pipeline control
module jelly_pipeline_control
		#(
			parameter	PIPELINE_STAGES   = 2,
			parameter	S_DATA_WIDTH      = 8,
			parameter	M_DATA_WIDTH      = 8,
			parameter	INIT_DATA         = {M_DATA_WIDTH{1'bx}},
			parameter	MASTER_REGS       = 1
		)
		(
			input	wire							reset,
			input	wire							clk,
			
			// slave port
			input	wire	[S_DATA_WIDTH-1:0]		s_data,
			input	wire							s_valid,
			output	wire							s_ready,
			
			// master port
			output	wire	[M_DATA_WIDTH-1:0]		m_data,
			output	wire							m_valid,
			input	wire							m_ready,
			
			// internal
			output	wire	[PIPELINE_STAGES-1:0]	stage_cke,
			output	wire	[PIPELINE_STAGES-1:0]	stage_valid,
			input	wire	[PIPELINE_STAGES-1:0]	next_valid,
			output	wire	[S_DATA_WIDTH-1:0]		src_data,
			output	wire							src_valid,
			input	wire	[M_DATA_WIDTH-1:0]		sink_data,
			output	wire							buffered
		);
	
	
	// cke
	integer							i;
	wire							sink_ready_next;
	reg		[PIPELINE_STAGES-1:0]	reg_cke,     next_cke;
	reg								reg_s_ready, next_s_ready;
	always @* begin
		next_cke[PIPELINE_STAGES-1] = (sink_ready_next || (!stage_valid[PIPELINE_STAGES-1] && !next_valid[PIPELINE_STAGES-1]));
		for ( i = PIPELINE_STAGES-2; i >= 0; i = i-1 ) begin
			next_cke[i] = (next_cke[i+1] || (!stage_valid[i] && !next_valid[i]));
		end
		next_s_ready = next_cke[0];
	end
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_cke     <= {PIPELINE_STAGES{1'b1}};
			reg_s_ready <= 1'b1;
		end
		else begin
			reg_cke     <= next_cke;
			reg_s_ready <= next_s_ready;
		end
	end
	
	// valid
	reg		[PIPELINE_STAGES-1:0]	reg_valid;
	always @(posedge clk) begin
		for ( i = 0; i < PIPELINE_STAGES; i = i+1 ) begin
			if ( reset ) begin
				reg_valid[i] <= 1'b0;
			end
			else if ( reg_cke[i] ) begin
				reg_valid[i] <= next_valid[i];
			end
		end
	end
	
	// slave port
	assign s_ready = reg_s_ready;
	
	// master port
	wire						sink_ready;
	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH		(M_DATA_WIDTH),
				.SLAVE_REGS		(1'b1),
				.MASTER_REGS	(MASTER_REGS),
				.INIT_DATA		(INIT_DATA)
			)
		i_pipeline_insert_ff
			(
				.reset			(reset),
				.clk			(clk),
				
				.s_data			(sink_data),
				.s_valid		(stage_valid[PIPELINE_STAGES-1]),
				.s_ready		(sink_ready),
				
				.m_data			(m_data),
				.m_valid		(m_valid),
				.m_ready		(m_ready),
				
				.buffered		(buffered),
				.s_ready_next	(sink_ready_next)
			);
	
	// internal
	assign stage_cke   = reg_cke;
	assign stage_valid = reg_valid;

	assign src_data    = s_data;
	assign src_valid   = s_valid;
	
endmodule


`default_nettype wire


// end of file
