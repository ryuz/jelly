
`timescale 1ns / 1ps
`default_nettype none


module tb_texture_writer();
	localparam RATE    = 1000.0/200.0;
	
	initial begin
		$dumpfile("tb_texture_writer.vcd");
		$dumpvars(0, tb_texture_writer);
		
		#1000000;
//			$display("!!!!TIME OUT!!!!");
			$finish;
	end
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		reset = 1'b1;
	initial #(RATE*100.5)	reset = 1'b0;
	
	
	// ƒ‰ƒ“ƒ_ƒ€ BUSY
	localparam	RAND_BUSY = 1;
	
	
	// -----------------------------------------
	//  TOP
	// -----------------------------------------
	
	parameter	STRIDE_WIDTH    = 14;
	parameter	SIZE_WIDTH      = 24;
	
	parameter	COMPONENT_NUM   = 3;
	parameter	COMPONENT_WIDTH = COMPONENT_NUM <= 2 ?  1 :
	                              COMPONENT_NUM <= 4 ?  2 : 3;
	parameter	STEP_SIZE       = 2;		// 2^n (0:1, 1:2, 2:4, 3:8... )
	parameter	BLK_X_SIZE      = 4;		// 2^n (0:1, 1:2, 2:4, 3:8... )
	parameter	BLK_Y_SIZE      = 3;		// 2^n (0:1, 1:2, 2:4, 3:8... )
	
	jelly_texture_writer_addr
			#(
//				.STRIDE_WIDTH		(STRIDE_WIDTH),	
//				.SIZE_WIDTH			(SIZE_WIDTH),
//				.COMPONENT_NUM		(COMPONENT_NUM),
//				.STEP_SIZE			(STEP_SIZE),
//				.BLK_X_SIZE			(BLK_X_SIZE),
//				.BLK_Y_SIZE			(BLK_Y_SIZE)
				
				.X_WIDTH			(4),
				.Y_WIDTH			(4),
				.SRC_STRIDE_WIDTH	(5),
				.DST_STRIDE_WIDTH	(5+2)
			)
		jelly_texture_writer_addr
			(
				.reset				(reset),
				.clk				(clk),
				
				.enable				(1'b1),
				.busy				(),
				
				.param_width		(12),
				.param_height		(12),
				.param_src_stride	(16),
				.param_dst_stride	(64),
				
				.m_last				(),
				.m_component		(),
//				.m_addr				(),
				.m_valid			(),
				.m_ready			(1'b1)
			);
	
	
	
	/*
	jelly_axi4s_master_model
		#(
			parameter	AXI4S_DATA_WIDTH = 32,
			parameter	X_NUM            = 640,
			parameter	Y_NUM            = 480
		)
		(
			input	wire							aresetn,
			input	wire							aclk,
			
			output	wire	[0:0]					m_axi4s_tuser,
			output	wire							m_axi4s_tlast,
			output	wire	[AXI4S_DATA_WIDTH-1:0]	m_axi4s_tdata,
			output	wire							m_axi4s_tvalid,
			input	wire							m_axi4s_tready
		);
	*/
	
endmodule


`default_nettype wire


// end of file
