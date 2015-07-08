// pattern generator


`timescale 1ns / 1ps
`default_nettype none


module jelly_pattern_generator_axi4s
		#(
			parameter	AXI4S_DATA_WIDTH = 32,
			parameter	X_NUM            = 640,
			parameter	Y_NUM            = 480,
			parameter	X_WIDTH          = 12,
			parameter	Y_WIDTH          = 12
		)
		(
			input	wire							aresetn,
			input	wire							aclk,
			
			output	wire	[AXI4S_DATA_WIDTH-1:0]	m_axi4s_tdata,
			output	wire							m_axi4s_tlast,
			output	wire	[0:0]					m_axi4s_tuser,
			output	wire							m_axi4s_tvalid,
			input	wire							m_axi4s_tready
		);
	
	
	wire		cke = (!m_axi4s_tvalid || m_axi4s_tready);
	
	reg		[X_WIDTH-1:0]			st1_x;
	reg		[Y_WIDTH-1:0]			st1_y;
	reg								st1_valid;
	
	reg		[AXI4S_DATA_WIDTH-1:0]	st2_tdata;
	reg								st2_tlast;
	reg		[0:0]					st2_tuser;
	reg								st2_tvalid;
	
	always @(posedge aclk) begin
		if ( !aresetn ) begin
			st1_x      <= 0;
			st1_y      <= 0;
			st1_valid  <= 1'b0;
			
			st2_tdata  <= {AXI4S_DATA_WIDTH{1'bx}};
			st2_tlast  <= 1'bx;
			st2_tuser  <= 1'bx;
			st2_tvalid <= 1'b0;

		end
		else if ( cke ) begin
			st1_valid <= {$random};//1'b1;
			if ( st1_valid ) begin
				st1_x <= st1_x + 1'b1;
				if ( st1_x == (X_NUM-1) ) begin
					st1_x <= 0;
					st1_y <= st1_y + 1'b1;
					if ( st1_y == (Y_NUM-1) ) begin
						st1_y <= 0;
					end
				end
			end
			
			st2_tdata[AXI4S_DATA_WIDTH/2-1:0]                <= st1_x;
			st2_tdata[AXI4S_DATA_WIDTH-1:AXI4S_DATA_WIDTH/2] <= st1_y;
			st2_tlast                                        <= (st1_x == X_NUM-1);
			st2_tuser                                        <= ((st1_x == 0) && (st1_y == 0));
			st2_tvalid                                       <= st1_valid;
		end
	end

	assign m_axi4s_tdata  = st2_tdata;
	assign m_axi4s_tlast  = st2_tlast;
	assign m_axi4s_tuser  = st2_tuser;
	assign m_axi4s_tvalid = st2_tvalid;
	
endmodule


`default_nettype wire


// end of file
