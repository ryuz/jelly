
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
	
	
	
	wire	[0:0]					axi4s_tuser;
	wire							axi4s_tlast;
	wire	[23:0]					axi4s_tdata;
	wire							axi4s_tvalid;
	wire							axi4s_tready;
	
	jelly_axi4s_master_model
			#(
				.AXI4S_DATA_WIDTH	(24),
				.X_NUM				(640),
				.Y_NUM				(480)
			)
		i_axi4s_master_model
			(
				.aresetn			(~reset),
				.aclk				(clk),
				
				.m_axi4s_tuser		(axi4s_tuser),
				.m_axi4s_tlast		(axi4s_tlast),
				.m_axi4s_tdata		(axi4s_tdata),
				.m_axi4s_tvalid		(axi4s_tvalid),
				.m_axi4s_tready		(axi4s_tready)
			);
	
	
	
	jelly_texture_writer_core
			#(
				.COMPONENT_NUM 			(3),
				.COMPONENT_DATA_WIDTH	(8),
				
				.M_AXI4_ID_WIDTH		(6),
				.M_AXI4_ADDR_WIDTH		(32),
				.M_AXI4_DATA_SIZE		(3),		// 8^n (0:8bit, 1:16bit, 2:32bit, 3:64bit, ...)
				
				.BLK_X_SIZE				(2),		// 2^n (0:1, 1:2, 2:4, 3:8, ... )
				.BLK_Y_SIZE				(2),		// 2^n (0:1, 1:2, 2:4, 3:8, ... )
				.STEP_Y_SIZE 			(1),		// 2^n (0:1, 1:2, 2:4, 3:8, ... )
				
				.X_WIDTH				(10),
				.Y_WIDTH				(10),
				
				.STRIDE_WIDTH			(14),
				.SIZE_WIDTH				(24),
				
				.FIFO_ADDR_WIDTH		(10),
				.FIFO_RAM_TYPE		    ("block")
			)
		i_texture_writer_core
			(
				.reset					(reset),
				.clk					(clk),
				
				.endian					(0),
				
				.param_width			(640),
				.param_height			(480),
				.param_stride			(1024*8),
				
				.s_axi4s_tuser			(axi4s_tuser),
				.s_axi4s_tlast			(axi4s_tlast),
				.s_axi4s_tdata			(axi4s_tdata),
				.s_axi4s_tvalid			(axi4s_tvalid),
				.s_axi4s_tready			(axi4s_tready)
			);
	
	
	
endmodule


`default_nettype wire


// end of file
