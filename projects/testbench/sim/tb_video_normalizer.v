
`timescale 1ns / 1ps
`default_nettype none


module tb_video_normalizer();
	localparam RATE  = 10.0;
	
	initial begin
		$dumpfile("tb_video_normalizer.vcd");
		$dumpvars(0, tb_video_normalizer);
	
	#10000000
		$finish;
	end
	
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		reset = 1'b1;
	always #(RATE*100)	reset = 1'b0;
	
	
	localparam	X_NUM = 128/2;
	localparam	Y_NUM = 128;
	
	
	parameter	TUSER_WIDTH   = 1;
	parameter	TDATA_WIDTH   = 24;
	parameter	X_WIDTH       = 12;
	parameter	Y_WIDTH       = 12;
	parameter	TIMER_WIDTH   = 32;
	parameter	S_SLAVE_REGS  = 1;
	parameter	S_MASTER_REGS = 1;
	parameter	M_SLAVE_REGS  = 1;
	parameter	M_MASTER_REGS = 1;
	
	wire						aresetn = ~reset;
	wire						aclk    = clk;
	reg							aclken  = 1;
	
	reg							param_enable  = 1;
	reg		[X_WIDTH-1:0]		param_width   = X_NUM;
	reg		[Y_WIDTH-1:0]		param_height  = Y_NUM;
	reg		[TDATA_WIDTH-1:0]	param_fill    = 24'h00ff00;
	reg		[TIMER_WIDTH-1:0]	param_timeout = 64;
	
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
	
	
	// model
	jelly_axi4s_master_model
			#(
				.AXI4S_DATA_WIDTH	(TDATA_WIDTH),
				.X_NUM				(128),
				.Y_NUM				(128),
				.PPM_FILE			("lena_128x128.ppm"),
				.BUSY_RATE			(0),
				.RANDOM_SEED		(0)
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
	jelly_video_normalizer_core
			#(
				.TUSER_WIDTH		(TUSER_WIDTH),
				.TDATA_WIDTH		(TDATA_WIDTH),
				.X_WIDTH			(X_WIDTH),
				.Y_WIDTH			(Y_WIDTH),
				.TIMER_WIDTH		(TIMER_WIDTH),
				.S_SLAVE_REGS		(S_SLAVE_REGS),
				.S_MASTER_REGS		(S_MASTER_REGS),
				.M_SLAVE_REGS		(M_SLAVE_REGS),
				.M_MASTER_REGS		(M_MASTER_REGS)
			)
		i_video_normalizer_core
			(
				.aresetn			(aresetn),
				.aclk				(aclk),
				.aclken				(aclken),
				
				.param_enable		(param_enable),
				.param_width		(param_width),
				.param_height		(param_height),
				.param_fill			(param_fill),
				.param_timeout		(param_timeout),
				
				.s_axi4s_tuser		(s_axi4s_tuser),
				.s_axi4s_tlast		(s_axi4s_tlast),
				.s_axi4s_tdata		(s_axi4s_tdata),
				.s_axi4s_tvalid		(s_axi4s_tvalid),
				.s_axi4s_tready		(s_axi4s_tready),
				
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
		 $fdisplay(fp_img, "%d %d", X_NUM, Y_NUM*5);
		 $fdisplay(fp_img, "255");
	end
	
	always @(posedge clk) begin
		if ( !reset && m_axi4s_tvalid && m_axi4s_tready ) begin
			 $fdisplay(fp_img, "%d %d %d", m_axi4s_tdata[0*8 +: 8], m_axi4s_tdata[1*8 +: 8], m_axi4s_tdata[2*8 +: 8]);
		end
	end
	
	
	
	
	/*
	integer fp;
	initial fp = $fopen("out.txt", "w");
	always @(posedge clk) begin
		if (!reset && aclken && m_axi4s_tvalid && m_axi4s_tready ) begin
			$fdisplay(fp, "%b %b %h", m_axi4s_tuser, m_axi4s_tlast, m_axi4s_tdata);
		end
	end
	*/
	
	
endmodule


`default_nettype wire


// end of file
