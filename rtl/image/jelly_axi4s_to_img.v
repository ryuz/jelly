// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_axi4s_to_img
		#(
			parameter	DATA_WIDTH   = 8,
			parameter	IMG_Y_WIDTH  = 9,
			parameter	IMG_Y_NUM    = 480,
			parameter	IMG_CKE_BUFG = 0
		)
		(
			input	wire								reset,
			input	wire								clk,
			input	wire								cke,
			
			input	wire	[IMG_Y_WIDTH-1:0]			param_y_num,
			
			input	wire	[DATA_WIDTH-1:0]			s_axi4s_tdata,
			input	wire								s_axi4s_tlast,
			input	wire	[0:0]						s_axi4s_tuser,
			input	wire								s_axi4s_tvalid,
			output	wire								s_axi4s_tready,
			
			output	wire								m_img_cke,
			output	wire								m_img_line_first,
			output	wire								m_img_line_last,
			output	wire								m_img_pixel_first,
			output	wire								m_img_pixel_last,
			output	wire	[DATA_WIDTH-1:0]			m_img_data,
			output	wire								m_img_de
		);
	
	
	reg							reg_cke;
	reg							reg_line_first;
	reg							reg_line_last;
	reg							reg_pixel_first;
	reg							reg_pixel_last;
	reg		[DATA_WIDTH-1:0]	reg_data;
	reg							reg_de;
	reg		[IMG_Y_WIDTH-1:0]	reg_y_count;
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_cke         <= 1'b0;
			reg_line_first  <= 1'b0;
			reg_line_last   <= 1'b0;
			reg_pixel_first <= 1'b0;
			reg_pixel_last  <= 1'b0;
			reg_data        <= {DATA_WIDTH{1'bx}};
			reg_de          <= 1'b0;
			reg_y_count     <= {IMG_Y_WIDTH{1'bx}};
		end
		else begin
			reg_cke <= (cke && (s_axi4s_tvalid && s_axi4s_tready));
			
			if ( s_axi4s_tvalid && s_axi4s_tready ) begin
				reg_pixel_first <= 1'b0;
				if ( reg_pixel_last ) begin
					reg_line_first  <= 1'b0;
					reg_line_last   <= 1'b0;
					reg_pixel_first <= 1'b1;
					reg_y_count     <= reg_y_count + 1;
					if ( (reg_y_count + 1'b1) == (param_y_num - 1'b1) ) begin
						reg_line_last <= 1'b1;
					end
					
					if ( reg_line_last ) begin
						reg_de <= 1'b0;
					end
				end
				
				if ( s_axi4s_tuser ) begin
					reg_line_first  <= 1'b1;
					reg_pixel_first <= 1'b1;
					reg_y_count     <= {IMG_Y_WIDTH{1'b0}};
					reg_de          <= 1'b1;
				end
				
				reg_pixel_last <= s_axi4s_tlast;
				reg_data       <= s_axi4s_tdata;
			end
		end
	end
	
	// Žd‘g‚Ýã cke ‚Ì fanout ‚ª‘å‚«‚­‚È‚é‚Ì‚ÅBUFG‚ðŽg‚¦‚é‚æ‚¤‚É‚µ‚Ä‚¨‚­
	generate
	if ( IMG_CKE_BUFG ) begin
		BUFG
			i_bufg
				(
					.I	(reg_cke),
					.O	(m_img_cke)
				);
	end
	else begin
		assign m_img_cke = reg_cke;
	end
	endgenerate
	
	assign s_axi4s_tready    = cke;
	
	assign m_img_line_first  = reg_line_first;
	assign m_img_line_last   = reg_line_last;
	assign m_img_pixel_first = reg_pixel_first;
	assign m_img_pixel_last  = reg_pixel_last;
	assign m_img_data        = reg_data;
	assign m_img_de          = reg_de;
	
endmodule


`default_nettype wire


// end of file
