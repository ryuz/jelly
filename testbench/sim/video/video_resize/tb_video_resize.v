
`timescale 1ns / 1ps
`default_nettype none


module tb_video_resize();
	localparam RATE  = 10.0;
	
	initial begin
		$dumpfile("tb_video_resize.vcd");
		$dumpvars(0, tb_video_resize);
	
	#10000000
		$finish;
	end
	
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		reset = 1'b1;
	initial begin
		#(RATE*100);
		@(posedge clk)	reset <= 1'b0;
	end
	
	
	
	localparam	FRAME_NUM = 10;
	
	localparam	X_NUM = 128;
	localparam	Y_NUM = 128;
	
	
	
	
	parameter	TUSER_WIDTH   = 1;
	parameter	COMPONENT_NUM = 3;
	parameter	DATA_WIDTH    = 8;
	parameter	TDATA_WIDTH   = COMPONENT_NUM*DATA_WIDTH;
	parameter	M_SLAVE_REGS  = 1;
	parameter	M_MASTER_REGS = 1;
	
	wire						aresetn = ~reset;
	wire						aclk    = clk;
	wire						aclken  = 1'b1;
	
	reg							param_enable = 1;
	
	wire	[TUSER_WIDTH-1:0]	s_axi4s_tuser;
	wire						s_axi4s_tlast;
	wire	[TDATA_WIDTH-1:0]	s_axi4s_tdata;
	wire						s_axi4s_tvalid;
	wire						s_axi4s_tready;
	
	wire	[TUSER_WIDTH-1:0]	m_axi4s_tuser;
	wire						m_axi4s_tlast;
	wire	[TDATA_WIDTH-1:0]	m_axi4s_tdata;
	wire						m_axi4s_tvalid;
	reg							m_axi4s_tready = 1;
	always @(posedge clk) begin
		m_axi4s_tready <= {$random()};
	end
	
	// model
	jelly_axi4s_master_model
			#(
				.AXI4S_DATA_WIDTH	(TDATA_WIDTH),
				.X_NUM				(128),
				.Y_NUM				(128),
				.PPM_FILE			("lena_128x128.ppm"),
				.BUSY_RATE			(50),
				.RANDOM_SEED		(7)
			)
		i_axi4s_master_model
			(
				.aresetn			(aresetn),
				.aclk				(aclk),
				
				.m_axi4s_tuser		(s_axi4s_tuser),
				.m_axi4s_tlast		(s_axi4s_tlast),
				.m_axi4s_tdata		(s_axi4s_tdata),
				.m_axi4s_tvalid		(s_axi4s_tvalid),
				.m_axi4s_tready		(s_axi4s_tready)
			);
	
	
	// core
	
	wire	[TUSER_WIDTH-1:0]	axi4s_v_tuser;
	wire						axi4s_v_tlast;
	wire	[TDATA_WIDTH-1:0]	axi4s_v_tdata;
	wire						axi4s_v_tvalid;
	wire						axi4s_v_tready;
	
	jelly_video_resize_half_v_core
			#(
				.TUSER_WIDTH		(TUSER_WIDTH),
				.COMPONENT_NUM		(COMPONENT_NUM),
				.DATA_WIDTH			(DATA_WIDTH),
				.M_SLAVE_REGS		(M_SLAVE_REGS),
				.M_MASTER_REGS		(M_MASTER_REGS)
			)
		i_video_resize_half_v_core
			(
				.aresetn			(aresetn),
				.aclk				(aclk),
				.aclken				(aclken),
				
				.param_enable		(param_enable),
				
				.s_axi4s_tuser		(s_axi4s_tuser),
				.s_axi4s_tlast		(s_axi4s_tlast),
				.s_axi4s_tdata		(s_axi4s_tdata),
				.s_axi4s_tvalid		(s_axi4s_tvalid),
				.s_axi4s_tready		(s_axi4s_tready),
				
				.m_axi4s_tuser		(axi4s_v_tuser),
				.m_axi4s_tlast		(axi4s_v_tlast),
				.m_axi4s_tdata		(axi4s_v_tdata),
				.m_axi4s_tvalid		(axi4s_v_tvalid),
				.m_axi4s_tready		(axi4s_v_tready)
			);
	
	
	
	jelly_video_resize_half_h_core
			#(
				.TUSER_WIDTH		(TUSER_WIDTH),
				.COMPONENT_NUM		(COMPONENT_NUM),
				.DATA_WIDTH			(DATA_WIDTH),
				.TDATA_WIDTH		(TDATA_WIDTH),
				.M_SLAVE_REGS		(M_SLAVE_REGS),
				.M_MASTER_REGS		(M_MASTER_REGS)
			)
		i_video_resize_half_h_core
			(
				.aresetn			(aresetn),
				.aclk				(aclk),
				.aclken				(aclken),
				
				.param_enable		(param_enable),
				
				.s_axi4s_tuser		(axi4s_v_tuser),
				.s_axi4s_tlast		(axi4s_v_tlast),
				.s_axi4s_tdata		(axi4s_v_tdata),
				.s_axi4s_tvalid		(axi4s_v_tvalid),
				.s_axi4s_tready		(axi4s_v_tready),
				
				.m_axi4s_tuser		(m_axi4s_tuser),
				.m_axi4s_tlast		(m_axi4s_tlast),
				.m_axi4s_tdata		(m_axi4s_tdata),
				.m_axi4s_tvalid		(m_axi4s_tvalid),
				.m_axi4s_tready		(m_axi4s_tready)
			);
	
	
	// dump
	integer		fp_img;
	initial begin
		 fp_img = $fopen("out_img.ppm", "w");
		 $fdisplay(fp_img, "P3");
		 $fdisplay(fp_img, "%d %d", X_NUM/2, Y_NUM*FRAME_NUM);
		 $fdisplay(fp_img, "255");
	end
	
	always @(posedge clk) begin
		if ( !reset && m_axi4s_tvalid && m_axi4s_tready ) begin
			 $fdisplay(fp_img, "%d %d %d", m_axi4s_tdata[0*8 +: 8], m_axi4s_tdata[1*8 +: 8], m_axi4s_tdata[2*8 +: 8]);
		end
	end
	
	integer frame_count = 0;
	always @(posedge clk) begin
		if ( !reset && m_axi4s_tuser[0] && m_axi4s_tvalid && m_axi4s_tready ) begin
			$display("frame : %d", frame_count);
			frame_count = frame_count + 1;
			if ( frame_count > FRAME_NUM+1 ) begin
				$finish();
			end
		end
	end
	
	
	
endmodule


`default_nettype wire


// end of file
