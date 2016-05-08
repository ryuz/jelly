
`timescale 1ns / 1ps
`default_nettype none


module tb_image();
	localparam RATE    = 10.0;
	
	initial begin
		$dumpfile("tb_image.vcd");
		$dumpvars(0, tb_image);
	end
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		reset = 1'b1;
	always #(RATE*100)	reset = 1'b0;
	
	
	parameter	DATA_WIDTH = 24;
	parameter	X_NUM      = 64;	//640;
	parameter	Y_NUM      = 48;	//480;
	parameter	X_WIDTH    = 10;
	parameter	Y_WIDTH    = 9;
	
	wire	[DATA_WIDTH-1:0]	axi4s_ptn_tdata;
	wire						axi4s_ptn_tlast;
	wire	[0:0]				axi4s_ptn_tuser;
	wire						axi4s_ptn_tvalid;
	wire						axi4s_ptn_tready;
	
	jelly_pattern_generator_axi4s
			#(
				.AXI4S_DATA_WIDTH	(DATA_WIDTH),
				.X_NUM				(X_NUM),
				.Y_NUM				(Y_NUM),
				.X_WIDTH			(X_WIDTH),
				.Y_WIDTH			(Y_WIDTH)
			)
		i_pattern_generator_axi4s
			(
				.aresetn			(~reset),
				.aclk				(clk),
				
				.m_axi4s_tdata		(axi4s_ptn_tdata),
				.m_axi4s_tlast		(axi4s_ptn_tlast),
				.m_axi4s_tuser		(axi4s_ptn_tuser),
				.m_axi4s_tvalid		(axi4s_ptn_tvalid),
				.m_axi4s_tready		(axi4s_ptn_tready)
			);
	
	
	wire	[DATA_WIDTH-1:0]			axi4s_out_tdata;
	wire								axi4s_out_tlast;
	wire	[0:0]						axi4s_out_tuser;
	wire								axi4s_out_tvalid;
	reg									axi4s_out_tready = 1'b1;
	
	
	wire								img_cke;
	
	wire								src_img_line_first;
	wire								src_img_line_last;
	wire								src_img_pixel_first;
	wire								src_img_pixel_last;
	wire	[DATA_WIDTH-1:0]			src_img_data;
	
	wire								sink_img_line_first;
	wire								sink_img_line_last;
	wire								sink_img_pixel_first;
	wire								sink_img_pixel_last;
	wire	[DATA_WIDTH-1:0]			sink_img_data;
	
	
	jelly_axi4s_img
			#(
				.DATA_WIDTH				(DATA_WIDTH),
	//			.IMG_Y_NUM				(Y_NUM),
				.IMG_Y_WIDTH			(Y_WIDTH),
				.IMG_CKE_BUFG			(0)
			)
		jelly_axi4s_img
			(
				.reset					(reset),
				.clk					(clk),
				
				.param_y_num			(Y_NUM),
				
				.s_axi4s_tdata			(axi4s_ptn_tdata),
				.s_axi4s_tlast			(axi4s_ptn_tlast),
				.s_axi4s_tuser			(axi4s_ptn_tuser),
				.s_axi4s_tvalid			(axi4s_ptn_tvalid),
				.s_axi4s_tready			(axi4s_ptn_tready),
				
				.m_axi4s_tdata			(axi4s_out_tdata),
				.m_axi4s_tlast			(axi4s_out_tlast),
				.m_axi4s_tuser			(axi4s_out_tuser),
				.m_axi4s_tvalid			(axi4s_out_tvalid),
				.m_axi4s_tready			(axi4s_out_tready),
				
				
				.img_cke				(img_cke),
				                         
				.src_img_line_first		(src_img_line_first),
				.src_img_line_last		(src_img_line_last),
				.src_img_pixel_first	(src_img_pixel_first),
				.src_img_pixel_last		(src_img_pixel_last),
				.src_img_data			(src_img_data),
				                         
				.sink_img_line_first	(sink_img_line_first),
				.sink_img_line_last		(sink_img_line_last),
				.sink_img_pixel_first	(sink_img_pixel_first),
				.sink_img_pixel_last	(sink_img_pixel_last),
				.sink_img_data			(sink_img_data)
			);
	
	wire								img_blk_line_first;
	wire								img_blk_line_last;
	wire								img_blk_pixel_first;
	wire								img_blk_pixel_last;
	wire	[5*5*DATA_WIDTH-1:0]		img_blk_data;
	
	jelly_img_blk_buffer
			#(
				.DATA_WIDTH				(DATA_WIDTH),
				.LINE_NUM				(5),
				.PIXEL_NUM				(5),
				.PIXEL_CENTER			(2),
				.MAX_Y_NUM				(1024),
				.RAM_TYPE				("block")
			)
		i_img_blk_buffer
			(
				.reset					(reset),
				.clk					(clk),
				.cke					(img_cke),
				
				.param_border_type		(2'b11),
				.param_border_constant	({5{8'haa}}),
				
				.s_img_line_first		(src_img_line_first),
				.s_img_line_last		(src_img_line_last),
				.s_img_pixel_first		(src_img_pixel_first),
				.s_img_pixel_last		(src_img_pixel_last),
				.s_img_data				(src_img_data),
				
				.m_img_line_first		(img_blk_line_first),
				.m_img_line_last		(img_blk_line_last),
				.m_img_pixel_first		(img_blk_pixel_first),
				.m_img_pixel_last		(img_blk_pixel_last),
				.m_img_data				(img_blk_data)
			);
	
	assign sink_img_line_first  = img_blk_line_first;
	assign sink_img_line_last   = img_blk_line_last;
	assign sink_img_pixel_first = img_blk_pixel_first;
	assign sink_img_pixel_last  = img_blk_pixel_last;
	assign sink_img_data        = img_blk_data[(5*2+2)*DATA_WIDTH +: DATA_WIDTH];
	
	
	always @(posedge clk) begin
		axi4s_out_tready <= {$random};
	end
	
	integer	fp;
	initial fp = $fopen("out.txt", "w");
	
	integer	frame = 0;
	
	always @(posedge clk) begin
		if ( !reset & axi4s_out_tvalid & axi4s_out_tready ) begin
			if ( axi4s_out_tuser ) begin
				frame = frame + 1;
				if ( frame > 3 ) begin
					$fclose(fp);
					$finish;
				end
			end
			
			$fdisplay(fp, "%h %b %b", axi4s_out_tdata, axi4s_out_tlast, axi4s_out_tuser);
		end
	end
	
	
endmodule


`default_nettype wire


// end of file
