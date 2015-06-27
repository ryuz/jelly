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
module jelly_pipeline_insert_ff
		#(
			parameter	DATA_WIDTH  = 8,
			parameter	SLAVE_REGS  = 1,
			parameter	MASTER_REGS = 1,
			parameter	INIT_DATA   = {DATA_WIDTH{1'bx}}
		)
		(
			input	wire						reset,
			input	wire						clk,
			
			// slave port
			input	wire	[DATA_WIDTH-1:0]	s_data,
			input	wire						s_valid,
			output	wire						s_ready,
			
			// master port
			output	wire	[DATA_WIDTH-1:0]	m_data,
			output	wire						m_valid,
			input	wire						m_ready,
			
			// status
			output	wire						buffered
		);
	
	// internal signal
	wire	[DATA_WIDTH-1:0]	internal_data;
	wire						internal_valid;
	wire						internal_ready;
	
	// slave port
	generate
	if ( SLAVE_REGS ) begin
		reg							reg_s_ready;
		reg		[DATA_WIDTH-1:0]	buf_data;
		reg							buf_valid;
		
		always @ ( posedge clk ) begin
			if ( reset ) begin
				reg_s_ready <= 1'b0;
				buf_valid   <= 1'b0;
				buf_data    <= INIT_DATA;
			end
			else begin
				if ( !buf_valid && s_valid && !internal_ready ) begin
					// 次のステージに送れない状況でバッファリング
					reg_s_ready <= 1'b0;
					buf_data    <= s_data;
					buf_valid   <= 1'b1;
				end
				else begin
					if ( internal_ready ) begin
						buf_valid   <= 1'b0;
					end
					if ( !internal_valid || internal_ready ) begin
						reg_s_ready <= 1'b1;
					end
				end
			end
		end
		assign internal_data   = buf_valid ? buf_data : s_data;
		assign internal_valid  = buf_valid ? 1'b1     : s_valid;
		assign s_ready         = reg_s_ready;
		assign buffered        = buf_valid;
	end
	else begin
		assign internal_data   = s_data;
		assign internal_valid  = s_valid;
		assign s_ready         = internal_ready;
		assign buffered        = 1'b0;
	end
	endgenerate
	
	
	// master port
	generate
	if ( MASTER_REGS ) begin
		reg		[DATA_WIDTH-1:0]	reg_m_data;
		reg							reg_m_valid;
		
		always @ ( posedge clk ) begin
			if ( reset ) begin
				reg_m_data  <= INIT_DATA;
				reg_m_valid <= 1'b0;
			end
			else begin
				if ( ~m_valid || m_ready ) begin
					reg_m_data  <= internal_data;
					reg_m_valid <= internal_valid;
				end
			end
		end
		
		assign internal_ready = (!m_valid || m_ready);
		assign m_data         = reg_m_data;
		assign m_valid        = reg_m_valid;
	end
	else begin
		assign internal_ready = m_ready;
		assign m_data         = internal_data;
		assign m_valid        = internal_valid;
	end
	endgenerate
	
endmodule


`default_nettype wire


// end of file
