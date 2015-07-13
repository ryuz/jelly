// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   First-Word Fall-Through mode FIFO
//
//                                 Copyright (C) 2008-2010 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// First-Word Fall-Through read
module jelly_fifo_read_fwtf
		#(
			parameter	DATA_WIDTH  = 8,
			parameter	PTR_WIDTH   = 8,
			parameter	DOUT_REGS   = 0
		)
		(
			input	wire						reset,
			input	wire						clk,
			
			output	wire						rd_en,
			output	wire						rd_regcke,
			input	wire	[DATA_WIDTH-1:0]	rd_data,
			input	wire						rd_empty,
			input	wire	[PTR_WIDTH:0]		rd_count,
			
			output	wire	[DATA_WIDTH-1:0]	m_data,
			output	wire						m_valid,
			input	wire						m_ready,
			output	wire	[PTR_WIDTH:0]		m_count
		);
	
	localparam PIPELINE_STAGES = 1 + DOUT_REGS;

	wire	[PIPELINE_STAGES-1:0]	stage_cke;
	wire	[PIPELINE_STAGES-1:0]	stage_valid;
	wire							buffered;
	
	jelly_pipeline_control
			#(
				.PIPELINE_STAGES	(PIPELINE_STAGES),
				.S_DATA_WIDTH		(1),
				.M_DATA_WIDTH		(DATA_WIDTH),
				.AUTO_VALID			(1)
			)
		i_pipeline_control
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1'b1),
				
				.s_data				(1'b0),
				.s_valid			(!rd_empty),
				.s_ready			(),
				
				.m_data				(m_data),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.stage_cke			(stage_cke),
				.stage_valid		(stage_valid),
				.next_valid			({PIPELINE_STAGES{1'bx}}),
				.src_data			(),
				.src_valid			(),
				.sink_data			(rd_data),
				.buffered			(buffered)
			);
			
	assign rd_en   = stage_cke[0];
		
	generate
	if ( DOUT_REGS ) begin
		assign rd_regcke = stage_cke[1];
		assign m_count   = rd_count + m_valid + buffered + stage_valid[0] + stage_valid[1];
	end
	else begin
		assign rd_regcke = 1'b0;		
		assign m_count   = rd_count + m_valid + buffered + stage_valid[0];
	end
	endgenerate
	
	
/*	
	reg							reg_rd_en;
	reg							reg_rd_valid;
	
	reg		[DATA_WIDTH-1:0]	reg_data;
	reg							reg_valid;
	reg		[DATA_WIDTH-1:0]	buf_data;
	reg							buf_valid;
	always @(posedge clk) begin
		if ( reset ) begin
			reg_rd_en    <= 1'b0;
			reg_rd_valid <= 1'b0;
			reg_data     <= {DATA_WIDTH{1'bx}};
			reg_valid    <= 1'b0;
			buf_data     <= {DATA_WIDTH{1'bx}};
			buf_valid    <= 1'b0;
		end
		else begin
			reg_rd_en    <= !rd_empty && (!buf_valid || !reg_valid);
			reg_rd_valid <= reg_rd_en;
			
			if ( reg_valid && !m_ready ) begin
				buf_data  <= rd_data;
				buf_valid <= reg_rd_valid;
			end
			
			if ( !reg_valid || m_ready ) begin
				if ( buf_valid ) begin
					reg_data  <= buf_data;
					reg_valid <= buf_valid;
					buf_valid <= 1'b0;
				end
				else begin
					reg_data  <= rd_data;
					reg_valid <= reg_rd_valid;
				end
			end
		end
	end
	
	assign rd_en = reg_rd_en;
	
	assign m_data  = reg_data;
	assign m_valid = reg_valid;
	assign m_count = rd_count + reg_rd_valid + buf_valid + reg_valid;
*/
	
endmodule


`default_nettype wire


// end of file
