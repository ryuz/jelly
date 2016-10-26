// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_img_to_axi4s
		#(
			parameter	DATA_WIDTH = 8,
			parameter	USE_DE     = 1
		)
		(
			input	wire						reset,
			input	wire						clk,
			input	wire						cke,
			
			input	wire						s_img_line_first,
			input	wire						s_img_line_last,
			input	wire						s_img_pixel_first,
			input	wire						s_img_pixel_last,
			input	wire	[DATA_WIDTH-1:0]	s_img_data,
			input	wire						s_img_de,
			
			output	wire	[DATA_WIDTH-1:0]	m_axi4s_tdata,
			output	wire						m_axi4s_tlast,
			output	wire	[0:0]				m_axi4s_tuser,
			output	wire						m_axi4s_tvalid
		);
	
	reg							reg_de;
	reg		[DATA_WIDTH-1:0]	reg_tdata;
	reg							reg_tlast;
	reg							reg_tuser;
	reg							reg_tvalid;
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_de     <= 1'b0;
			reg_tdata  <= {DATA_WIDTH{1'bx}};
			reg_tlast  <= 1'bx;
			reg_tuser  <= 1'bx;
			reg_tvalid <= 1'b0;
		end
		else if ( cke ) begin
			reg_tdata  <= s_img_data;
			reg_tlast  <= s_img_pixel_last;
			reg_tuser  <= (s_img_line_first && s_img_pixel_first);
			
			if ( USE_DE ) begin
				reg_tvalid <= s_img_de;
			end
			else begin
				// auto create de
				if ( s_img_line_first ) begin
					reg_de <= 1'b1;
				end
				else if ( s_img_line_last ) begin
					reg_de <= 1'b0;
				end
				reg_tvalid <= (s_img_line_first || s_img_line_last || reg_de);
			end
		end
		else begin
			reg_tvalid <= 1'b0;
		end
	end
	
	assign m_axi4s_tdata  = reg_tdata;
	assign m_axi4s_tlast  = reg_tlast;
	assign m_axi4s_tuser  = reg_tuser;
	assign m_axi4s_tvalid = reg_tvalid;
	
endmodule


`default_nettype wire


// end of file
