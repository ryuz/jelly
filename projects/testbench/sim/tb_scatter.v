
`timescale 1ns / 1ps
`default_nettype none


module tb_scatter();
	localparam RATE    = 10.0;
	
	initial begin
		$dumpfile("tb_scatter.vcd");
		$dumpvars(0, tb_scatter);
	end
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		reset = 1'b1;
	always #(RATE*100)	reset = 1'b0;
	
	parameter	PORT_NUM   = 16;
	parameter	DATA_WIDTH = 16;
	parameter	LINE_SIZE  = 640;
	parameter	UNIT_SIZE  = (LINE_SIZE + (PORT_NUM-1)) / PORT_NUM;
	
	reg		[DATA_WIDTH-1:0]			src_data;
	reg									src_valid;
	wire								src_ready;
	
	wire	[PORT_NUM*DATA_WIDTH-1:0]	port_data;
	wire	[PORT_NUM-1:0]				port_valid;
	wire	[PORT_NUM-1:0]				port_ready;
	
	wire	[DATA_WIDTH-1:0]			sink_data;
	wire								sink_valid;
	reg									sink_ready = 1;
	
	jelly_data_scatter
			#(
				.PORT_NUM		(PORT_NUM),
				.DATA_WIDTH		(DATA_WIDTH),
				.LINE_SIZE		(LINE_SIZE),
				.UNIT_SIZE		(UNIT_SIZE)
			)
		i_data_scatter
			(
				.reset			(reset),
				.clk			(clk),
				
				.s_data			(src_data),
				.s_valid		(src_valid),
				.s_ready		(src_ready),
				
				.m_data			(port_data),
				.m_valid		(port_valid),
				.m_ready		(port_ready)
			);
	
	
	jelly_data_gather
			#(
				.PORT_NUM		(PORT_NUM),
				.DATA_WIDTH		(DATA_WIDTH),
				.LINE_SIZE		(LINE_SIZE),
				.UNIT_SIZE		(UNIT_SIZE)
			)
		i_data_gather
			(
				.reset			(reset),
				.clk			(clk),
				
				.s_data			(port_data),
				.s_valid		(port_valid),
				.s_ready		(port_ready),
				
				.m_data			(sink_data),
				.m_valid		(sink_valid),
				.m_ready		(sink_ready)
			);
	
	always @(posedge clk) begin
		if ( reset ) begin
			src_data  <= 0;
			src_valid <= 0;
		end
		else begin
			if ( src_valid && src_ready ) begin
				src_data <= src_data + 1;
			end
			src_valid <= 1;
		end
	end
	
	
endmodule


`default_nettype wire


// end of file
