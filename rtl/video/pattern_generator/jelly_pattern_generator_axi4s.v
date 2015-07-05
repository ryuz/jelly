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

	reg		[AXI4S_DATA_WIDTH-1:0]	reg_tdata;
	reg								reg_tlast;
	reg		[0:0]					reg_tuser;
	reg								reg_tvalid;
	
	reg		[X_WIDTH-1:0]			x;
	reg		[Y_WIDTH-1:0]			y;
	always @(posedge aclk) begin
		if ( !aresetn ) begin
			reg_tdata  <= {AXI4S_DATA_WIDTH{1'bx}};
			reg_tlast  <= 1'bx;
			reg_tuser  <= 1'bx;
			reg_tvalid <= 1'b0;

			x          <= 0;
			y          <= 0;
		end
		else if ( cke ) begin
			reg_tdata[AXI4S_DATA_WIDTH/2-1:0]                <= x;
			reg_tdata[AXI4S_DATA_WIDTH-1:AXI4S_DATA_WIDTH/2] <= y;
			reg_tlast                                        <= (x == X_NUM-1);
			reg_tuser                                        <= ((x == 0) && (y == 0));
			reg_tvalid                                       <= 1'b1;
			
			if ( reg_tvalid ) begin
				x <= x + 1;
				if ( x == (X_NUM-1) ) begin
					x <= 0;
					y <= y + 1;
					if ( y == (Y_NUM-1) ) begin
						y <= 0;
					end
				end
			end
		end
	end
	
	assign m_axi4s_tuser  = reg_tuser;
	assign m_axi4s_tlast  = reg_tlast;
	assign m_axi4s_tdata  = reg_tdata;
	assign m_axi4s_tvalid = reg_tvalid;
	
endmodule


`default_nettype wire


// end of file
