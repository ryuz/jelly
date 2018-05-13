
`timescale 1ns / 1ps
`default_nettype none


module tb_demosaic_acpi();
	localparam RATE    = 10.0;
	
	initial begin
		$dumpfile("tb_demosaic_acpi.vcd");
		$dumpvars(0, tb_demosaic_acpi);
	end
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		reset = 1'b1;
	always #(RATE*100)	reset = 1'b0;
	
	
//	parameter	DATA_WIDTH = 8;
	parameter	DATA_WIDTH = 10;
//	parameter	X_NUM      = 640;
//	parameter	Y_NUM      = 396;
	parameter	X_NUM      = 1640;
	parameter	Y_NUM      = 1024;
	parameter	X_WIDTH    = 10;
	parameter	Y_WIDTH    = 9;
	parameter	USE_VALID  = 0;
	
	
	
	wire	[0:0]						axi4s_in_tuser;
	wire								axi4s_in_tlast;
	wire	[DATA_WIDTH-1:0]			axi4s_in_tdata;
	wire								axi4s_in_tvalid;
	wire								axi4s_in_tready;
	
	wire	[0:0]						axi4s_out_tuser;
	wire								axi4s_out_tlast;
	wire	[4*DATA_WIDTH-1:0]			axi4s_out_tdata;
	wire								axi4s_out_tvalid;
	reg									axi4s_out_tready = 1'b1;
	
//	always @(posedge clk) begin
//		axi4s_out_tready <= {$random};
//	end
	
	wire	[DATA_WIDTH-1:0]	axi4s_out_tdata0 = axi4s_out_tdata[0*DATA_WIDTH +: DATA_WIDTH];
	wire	[DATA_WIDTH-1:0]	axi4s_out_tdata1 = axi4s_out_tdata[1*DATA_WIDTH +: DATA_WIDTH];
	wire	[DATA_WIDTH-1:0]	axi4s_out_tdata2 = axi4s_out_tdata[2*DATA_WIDTH +: DATA_WIDTH];
	wire	[DATA_WIDTH-1:0]	axi4s_out_tdata3 = axi4s_out_tdata[3*DATA_WIDTH +: DATA_WIDTH];
	
	
	wire								img_cke;
	
	wire								src_img_line_first;
	wire								src_img_line_last;
	wire								src_img_pixel_first;
	wire								src_img_pixel_last;
	wire								src_img_de;
	wire	[DATA_WIDTH-1:0]			src_img_data;
	wire								src_img_valid;
	
	wire								sink_img_line_first;
	wire								sink_img_line_last;
	wire								sink_img_pixel_first;
	wire								sink_img_pixel_last;
	wire								sink_img_de;
	wire	[4*DATA_WIDTH-1:0]			sink_img_data;
	wire								sink_img_valid;
	
	
	
	// model
	jelly_axi4s_master_model
			#(
				.AXI4S_DATA_WIDTH		(8),
				.X_NUM					(X_NUM),
				.Y_NUM					(Y_NUM),
				.PGM_FILE				("caputure_img.pgm"),
	//			.PGM_FILE				("img_20180513.pgm"),
				.BUSY_RATE				(0),
				.RANDOM_SEED			(123)
			)
		i_axi4s_master_model
			(
				.aresetn				(~reset),
				.aclk					(clk),
				
				.m_axi4s_tuser			(axi4s_in_tuser),
				.m_axi4s_tlast			(axi4s_in_tlast),
//				.m_axi4s_tdata			(axi4s_in_tdata),
				.m_axi4s_tdata			(axi4s_in_tdata[9:2]),
				.m_axi4s_tvalid			(axi4s_in_tvalid),
				.m_axi4s_tready			(axi4s_in_tready)
			);
	assign axi4s_in_tdata[1:0] = 0;
	
	// img
	jelly_axi4s_img
			#(
				.S_DATA_WIDTH			(DATA_WIDTH),
				.M_DATA_WIDTH			(4*DATA_WIDTH),
				.IMG_Y_NUM				(Y_NUM),
				.IMG_Y_WIDTH			(Y_WIDTH),
				.BLANK_Y_WIDTH			(8),
				.IMG_CKE_BUFG			(0)
			)
		jelly_axi4s_img
			(
				.reset					(reset),
				.clk					(clk),
				
				.param_blank_num		(8'hff),
				
				.s_axi4s_tdata			(axi4s_in_tdata),
				.s_axi4s_tlast			(axi4s_in_tlast),
				.s_axi4s_tuser			(axi4s_in_tuser),
				.s_axi4s_tvalid			(axi4s_in_tvalid),
				.s_axi4s_tready			(axi4s_in_tready),
				
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
				.src_img_de				(src_img_de),
				.src_img_data			(src_img_data),
				.src_img_valid			(src_img_valid),
				
				.sink_img_line_first	(sink_img_line_first),
				.sink_img_line_last		(sink_img_line_last),
				.sink_img_pixel_first	(sink_img_pixel_first),
				.sink_img_pixel_last	(sink_img_pixel_last),
				.sink_img_de			(sink_img_de),
				.sink_img_data			(sink_img_data),
				.sink_img_valid			(sink_img_valid)
			);
	
	
	jelly_img_demosaic_acpi_core
			#(
				.USER_WIDTH				(0),
				.DATA_WIDTH				(DATA_WIDTH),
				.MAX_X_NUM				(4096),
	//			.RAM_TYPE				("block"),
				.USE_VALID				(USE_VALID)
			)
		i_img_demosaic_acpi_core
			(
				.reset					(reset),
				.clk					(clk),
				.cke					(img_cke),
				
				.param_phase			(2'b11),
				
				.s_img_line_first		(src_img_line_first),
				.s_img_line_last		(src_img_line_last),
				.s_img_pixel_first		(src_img_pixel_first),
				.s_img_pixel_last		(src_img_pixel_last),
				.s_img_de				(src_img_de),
				.s_img_raw				(src_img_data),
				.s_img_valid			(src_img_valid),
				
				.m_img_line_first		(sink_img_line_first),
				.m_img_line_last		(sink_img_line_last),
				.m_img_pixel_first		(sink_img_pixel_first),
				.m_img_pixel_last		(sink_img_pixel_last),
				.m_img_de				(sink_img_de),
				.m_img_raw				(sink_img_data[DATA_WIDTH*3 +: DATA_WIDTH]),
				.m_img_r				(sink_img_data[DATA_WIDTH*2 +: DATA_WIDTH]),
				.m_img_g				(sink_img_data[DATA_WIDTH*1 +: DATA_WIDTH]),
				.m_img_b				(sink_img_data[DATA_WIDTH*0 +: DATA_WIDTH]),
				.m_img_valid			(sink_img_valid)
			);
	
	
	// G phase dump
	integer		fp_g;
	initial begin
		 fp_g = $fopen("out_g.pgm", "w");
		 $fdisplay(fp_g, "P2");
		 $fdisplay(fp_g, "%1d %1d", X_NUM, Y_NUM*FRAME_NUM);
		 $fdisplay(fp_g, "1023");
	end
	
	always @(posedge clk) begin
		if ( !reset && img_cke && i_img_demosaic_acpi_core.img_g_de && i_img_demosaic_acpi_core.img_g_valid ) begin
			$fdisplay(fp_g, "%1d", i_img_demosaic_acpi_core.img_g_g);
		end
	end
	
	
	
	// image dump
	localparam	FRAME_NUM = 1;
	
	integer		fp_img;
	initial begin
		 fp_img = $fopen("out_img.ppm", "w");
		 $fdisplay(fp_img, "P3");
		 $fdisplay(fp_img, "%1d %1d", X_NUM, Y_NUM*FRAME_NUM);
		 $fdisplay(fp_img, "1023");
	end
	
	integer		count_out = 0;
	always @(posedge clk) begin
		if ( !reset && axi4s_out_tvalid && axi4s_out_tready ) begin
			$fdisplay(fp_img, "%1d %1d %1d",
					axi4s_out_tdata[2*DATA_WIDTH +: DATA_WIDTH],
					axi4s_out_tdata[1*DATA_WIDTH +: DATA_WIDTH],
					axi4s_out_tdata[0*DATA_WIDTH +: DATA_WIDTH]);
			count_out <= count_out + 1;
		end
	end
	
	integer frame_count = 0;
	always @(posedge clk) begin
		if ( !reset && axi4s_out_tuser[0] && axi4s_out_tvalid && axi4s_out_tready ) begin
			$display("frame : %d", frame_count);
			frame_count = frame_count + 1;
			if ( frame_count > FRAME_NUM+1 ) begin
				$finish();
			end
		end
	end
	
	
	integer		count_g   = 0;
	integer		count_rb  = 0;
	always @(posedge clk) begin
		if ( img_cke ) begin
			if ( i_img_demosaic_acpi_core.img_g_de ) begin
				count_g <= count_g + 1;
			end
			
			if ( i_img_demosaic_acpi_core.m_img_de ) begin
				count_rb <= count_rb + 1;
			end
		end
	end
	
endmodule


`default_nettype wire


// end of file
