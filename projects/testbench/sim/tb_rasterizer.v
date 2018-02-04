
`timescale 1ns / 1ps
`default_nettype none


module tb_rasterizer();
	localparam RATE    = 10.0;
	localparam WB_RATE = 33.3;
	
	
	initial begin
		$dumpfile("tb_rasterizer.vcd");
		$dumpvars(1, tb_rasterizer);
	end
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		wb_clk = 1'b1;
	always #(WB_RATE/2.0)	wb_clk = ~wb_clk;
	
	reg		reset = 1'b1;
	always #(RATE*100)	reset = 1'b0;
	
	
	parameter	X_NUM               = 640;
	parameter	Y_NUM               = 480;
	
	parameter	X_WIDTH             = 12;
	parameter	Y_WIDTH             = 12;
	
	parameter	WB_ADR_WIDTH        = 14;
	parameter	WB_DAT_WIDTH        = 32;
	parameter	WB_SEL_WIDTH        = (WB_DAT_WIDTH / 8);
	
	parameter	BANK_NUM            = 2;
	parameter	BANK_ADDR_WIDTH     = 12;
	parameter	PARAMS_ADDR_WIDTH   = 10;
	
	parameter	EDGE_NUM            = 12*2;
	parameter	POLYGON_NUM         = 6*2;
	parameter	SHADER_PARAM_NUM    = 4;
	
	parameter	EDGE_PARAM_WIDTH    = 32;
	parameter	EDGE_RAM_TYPE       = "distributed";
	
	parameter	SHADER_PARAM_WIDTH  = 32;
	parameter	SHADER_PARAM_Q      = 24;
	parameter	SHADER_RAM_TYPE     = "distributed";
	
	parameter	REGION_PARAM_WIDTH  = EDGE_NUM;
	parameter	REGION_RAM_TYPE     = "distributed";
	
	parameter	CULLING_ONLY        = 0;
	parameter	Z_SORT_MIN          = 0;	// 1Ç≈è¨Ç≥Ç¢ílóDêÊ(Zé≤âúå¸Ç´)
	
	parameter	INIT_CTL_ENABLE     = 1'b0;
	parameter	INIT_CTL_BANK       = 0;
	parameter	INIT_PARAM_WIDTH    = X_NUM-1;
	parameter	INIT_PARAM_HEIGHT   = Y_NUM-1;
	parameter	INIT_PARAM_CULLING  = 2'b01;
	
	
	parameter	PARAMS_EDGE_SIZE    = EDGE_NUM*3;
	parameter	PARAMS_SHADER_SIZE  = POLYGON_NUM*SHADER_PARAM_WIDTH*3;
	parameter	PARAMS_REGION_SIZE  = POLYGON_NUM*2;
	
	
	parameter	INDEX_WIDTH         = POLYGON_NUM <=     2 ?  1 :
	                                  POLYGON_NUM <=     4 ?  2 :
	                                  POLYGON_NUM <=     8 ?  3 :
	                                  POLYGON_NUM <=    16 ?  4 :
	                                  POLYGON_NUM <=    32 ?  5 :
	                                  POLYGON_NUM <=    64 ?  6 :
	                                  POLYGON_NUM <=   128 ?  7 :
	                                  POLYGON_NUM <=   256 ?  8 :
	                                  POLYGON_NUM <=   512 ?  9 :
	                                  POLYGON_NUM <=  1024 ? 10 :
	                                  POLYGON_NUM <=  2048 ? 11 :
	                                  POLYGON_NUM <=  4096 ? 12 :
	                                  POLYGON_NUM <=  8192 ? 13 :
	                                  POLYGON_NUM <= 16384 ? 14 :
	                                  POLYGON_NUM <= 32768 ? 15 : 16;
	
	
	
	reg												cke = 1'b1;
//	always @(posedge clk) begin
//		cke <= {$random()};
//	end
	
//	wire												start;
//	wire												busy = 1;
	
//	wire	[X_WIDTH-1:0]								param_width;
//	wire	[Y_WIDTH-1:0]								param_height;
//	wire	[PARAMS_EDGE_SIZE*EDGE_PARAM_WIDTH-1:0]		params_edge;
//	wire	[PARAMS_SHADER_SIZE*SHADER_PARAM_WIDTH-1:0]	params_polygon;
//	wire	[PARAMS_REGION_SIZE*REGION_PARAM_WIDTH-1:0]	params_region;
	
	wire												m_frame_start;
	wire												m_line_end;
	wire												m_polygon_enable;
	wire	[INDEX_WIDTH-1:0]							m_polygon_index;
	wire	[SHADER_PARAM_NUM*SHADER_PARAM_WIDTH-1:0]	m_shader_params;
	wire												m_valid;
	
	wire												s_wb_rst_i = reset;
	wire												s_wb_clk_i = wb_clk;
	wire	[WB_ADR_WIDTH-1:0]							s_wb_adr_i;
	wire	[WB_DAT_WIDTH-1:0]							s_wb_dat_o;
	wire	[WB_DAT_WIDTH-1:0]							s_wb_dat_i;
	wire												s_wb_we_i;
	wire	[WB_SEL_WIDTH-1:0]							s_wb_sel_i;
	wire												s_wb_stb_i;
	wire												s_wb_ack_o;
	
	
	jelly_rasterizer
			#(
				.X_WIDTH			(X_WIDTH),
				.Y_WIDTH			(Y_WIDTH),
				
				.WB_ADR_WIDTH		(WB_ADR_WIDTH),
				.WB_DAT_WIDTH		(WB_DAT_WIDTH),
				.WB_SEL_WIDTH		(WB_SEL_WIDTH),
				
				.BANK_NUM			(BANK_NUM),
				.BANK_ADDR_WIDTH	(BANK_ADDR_WIDTH),
				.PARAMS_ADDR_WIDTH	(PARAMS_ADDR_WIDTH),
				
				.EDGE_NUM			(EDGE_NUM),
				.POLYGON_NUM		(POLYGON_NUM),
				.SHADER_PARAM_NUM	(SHADER_PARAM_NUM),
				
				.EDGE_PARAM_WIDTH	(EDGE_PARAM_WIDTH),
				.EDGE_RAM_TYPE		(EDGE_RAM_TYPE),
				
				.SHADER_PARAM_WIDTH	(SHADER_PARAM_WIDTH),
				.SHADER_RAM_TYPE	(SHADER_RAM_TYPE),
				
				.REGION_PARAM_WIDTH	(REGION_PARAM_WIDTH),
				.REGION_RAM_TYPE	(REGION_RAM_TYPE),
				
				.CULLING_ONLY		(CULLING_ONLY),
				.Z_SORT_MIN			(Z_SORT_MIN),
				
				.INIT_CTL_ENABLE	(INIT_CTL_ENABLE),
				.INIT_CTL_BANK		(INIT_CTL_BANK),
				.INIT_PARAM_WIDTH	(INIT_PARAM_WIDTH),
				.INIT_PARAM_HEIGHT	(INIT_PARAM_HEIGHT),
				.INIT_PARAM_CULLING	(INIT_PARAM_CULLING)
			)
		i_rasterizer
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.m_frame_start		(m_frame_start),
				.m_line_end			(m_line_end),
				.m_polygon_enable	(m_polygon_enable),
				.m_polygon_index	(m_polygon_index),
				.m_shader_params	(m_shader_params),
				.m_valid			(m_valid),
				
				.s_wb_rst_i			(s_wb_rst_i),
				.s_wb_clk_i			(s_wb_clk_i),
				.s_wb_adr_i			(s_wb_adr_i),
				.s_wb_dat_o			(s_wb_dat_o),
				.s_wb_dat_i			(s_wb_dat_i),
				.s_wb_we_i			(s_wb_we_i),
				.s_wb_sel_i			(s_wb_sel_i),
				.s_wb_stb_i			(s_wb_stb_i),
				.s_wb_ack_o			(s_wb_ack_o)
			);
	
	integer		fp;
	initial begin
		 fp = $fopen("out_img.ppm", "w");
		 $fdisplay(fp, "P3");
		 $fdisplay(fp, "%d %d", X_NUM, Y_NUM);
		 $fdisplay(fp, "255");
	end
	
	wire	signed	[31:0]		m_shader_p0 = m_shader_params[32*0 +: 32];
	wire	signed	[31:0]		m_shader_p1 = m_shader_params[32*1 +: 32];
	wire	signed	[31:0]		m_shader_p2 = m_shader_params[32*2 +: 32];
	wire	signed	[31:0]		m_shader_p3 = m_shader_params[32*3 +: 32];
	real						rel_p0, rel_p1, rel_p2;
	reg				[7:0]		int_u, int_v, int_t;
	reg				[7:0]		int_r, int_g, int_b;
	always @* begin
		rel_p0 = m_shader_p1;
		rel_p1 = m_shader_p2;
		rel_p2 = m_shader_p3;
		rel_p0 = rel_p0 / (1 << SHADER_PARAM_Q);
		rel_p1 = rel_p1 / (1 << SHADER_PARAM_Q);
		rel_p2 = rel_p2 / (1 << SHADER_PARAM_Q);
		
		if ( rel_p0 > 1.0 ) rel_p0 = 1.0;
		if ( rel_p0 < 0.0 ) rel_p0 = 0.0;
		if ( rel_p1 > 1.0 ) rel_p1 = 1.0;
		if ( rel_p1 < 0.0 ) rel_p1 = 0.0;
		if ( rel_p2 > 1.0 ) rel_p2 = 1.0;
		if ( rel_p2 < 0.0 ) rel_p2 = 0.0;
		
		int_r = rel_p0 * 255.0;
		int_g = rel_p1 * 255.0;
		int_b = rel_p2 * 255.0;
		
		if ( rel_p0 == 0 ) rel_p0 = 0.00000001;
		rel_p0 = 1.0 / rel_p0;
		rel_p1 = rel_p1 * rel_p0;
		rel_p2 = rel_p2 * rel_p0;
		
		int_t = rel_p0 * 255.0;
		int_u = rel_p1 * 255.0;
		int_v = rel_p2 * 255.0;
	end
	
	
	always @(posedge clk) begin
		if ( !reset && cke && m_valid ) begin
			if ( &m_polygon_enable ) begin
//				 $fdisplay(fp, "%d %d %d", int_u, int_v, 255);
				 $fdisplay(fp, "%d %d %d", int_r, int_g, int_b);
			end
			else begin
				 $fdisplay(fp, "0 0 0");
			end
		end
	end
	
	
	
	
	
	////////////
	wire	[0:0]			axi4s_gpu_tuser;
	wire					axi4s_gpu_tlast;
	wire	[23:0]			axi4s_gpu_tdata;
	wire					axi4s_gpu_tvalid;
	wire					axi4s_gpu_tready = 1;
	
	jelly_gpu_gouraud
			#(
				.WB_ADR_WIDTH		(14),
				.WB_DAT_WIDTH		(32),
				
				.COMPONENT_NUM		(3),
				.DATA_WIDTH			(8),
				
				.AXI4S_TUSER_WIDTH	(1),
				.AXI4S_TDATA_WIDTH	(24),
				
				.X_WIDTH			(12),
				.Y_WIDTH			(12),
				
				.BANK_NUM			(2),
				.BANK_ADDR_WIDTH	(12),
				.PARAMS_ADDR_WIDTH	(10),
				
				.EDGE_NUM			(12*2),
				.POLYGON_NUM		(6*2),
				.SHADER_PARAM_NUM	(4),
				
				.EDGE_PARAM_WIDTH	(32),
				.EDGE_RAM_TYPE		("distributed"),
				
				.SHADER_PARAM_WIDTH	(32),
				.SHADER_PARAM_Q		(24),
				.SHADER_RAM_TYPE	("distributed"),
				
				.REGION_RAM_TYPE	("distributed"),
				
				.CULLING_ONLY		(0),
				.Z_SORT_MIN			(0),
				
				.INIT_CTL_ENABLE	(1'b0),
				.INIT_CTL_BANK		(0),
				.INIT_PARAM_WIDTH	(X_NUM-1),
				.INIT_PARAM_HEIGHT	(Y_NUM-1),
				.INIT_PARAM_CULLING	(2'b01)
			)
		i_gpu_gouraud
			(
				.reset				(reset),
				.clk				(clk),
				
				.s_wb_rst_i			(s_wb_rst_i),
				.s_wb_clk_i			(s_wb_clk_i),
				.s_wb_adr_i			(s_wb_adr_i[0 +: 14]),
				.s_wb_dat_o			(),
				.s_wb_dat_i			(s_wb_dat_i),
				.s_wb_we_i			(s_wb_we_i),
				.s_wb_sel_i			(s_wb_sel_i),
				.s_wb_stb_i			(s_wb_stb_i),
				.s_wb_ack_o			(),
				
				.m_axi4s_tuser		(axi4s_gpu_tuser),
				.m_axi4s_tlast		(axi4s_gpu_tlast),
				.m_axi4s_tdata		(axi4s_gpu_tdata),
				.m_axi4s_tvalid		(axi4s_gpu_tvalid),
				.m_axi4s_tready		(axi4s_gpu_tready)
			);
	
	integer		fp_gpu;
	initial begin
		 fp_gpu = $fopen("gpu_img.ppm", "w");
		 $fdisplay(fp_gpu, "P3");
		 $fdisplay(fp_gpu, "%d %d", X_NUM, Y_NUM);
		 $fdisplay(fp_gpu, "255");
	end
	
	always @(posedge clk) begin
		if ( !reset && axi4s_gpu_tvalid && axi4s_gpu_tready ) begin
			 $fdisplay(fp_gpu, "%d %d %d",
			 	axi4s_gpu_tdata[8*0 +: 8],
			 	axi4s_gpu_tdata[8*1 +: 8],
			 	axi4s_gpu_tdata[8*2 +: 8]);
		end
	end
	
	
	
	
	
	
	
	
	
	
	// WISHBONE master
	wire							wb_rst_i = s_wb_rst_i;
	wire							wb_clk_i = s_wb_clk_i;
	reg		[WB_ADR_WIDTH-1:0]		wb_adr_o;
	wire	[WB_DAT_WIDTH-1:0]		wb_dat_i;
	reg		[WB_DAT_WIDTH-1:0]		wb_dat_o;
	reg								wb_we_o;
	reg		[WB_SEL_WIDTH-1:0]		wb_sel_o;
	reg								wb_stb_o = 0;
	wire							wb_ack_i;
	
	assign s_wb_adr_i = wb_adr_o;
	assign s_wb_dat_i = wb_dat_o;
	assign s_wb_we_i  = wb_we_o;
	assign s_wb_sel_i = wb_sel_o;
	assign s_wb_stb_i = wb_stb_o;
	assign wb_dat_i   = s_wb_dat_o;
	assign wb_ack_i   = s_wb_ack_o;
	
	
	
	reg		[WB_DAT_WIDTH-1:0]		reg_wb_dat;
	reg								reg_wb_ack;
	always @(posedge wb_clk_i) begin
		if ( ~wb_we_o & wb_stb_o & wb_stb_o ) begin
			reg_wb_dat <= wb_dat_i;
		end
		reg_wb_ack <= wb_ack_i;
	end
	
	task wb_write(
				input [WB_ADR_WIDTH-1:0]	adr,
				input [WB_DAT_WIDTH-1:0]	dat,
				input [WB_SEL_WIDTH-1:0]	sel
			);
	begin
		$display("WISHBONE_WRITE(adr:%h dat:%h sel:%b)", adr, dat, sel);
		@(negedge wb_clk_i);
			wb_adr_o = (adr >> 2);
			wb_dat_o = dat;
			wb_sel_o = sel;
			wb_we_o  = 1'b1;
			wb_stb_o = 1'b1;
		@(negedge wb_clk_i);
			while ( reg_wb_ack == 1'b0 ) begin
				@(negedge wb_clk_i);
			end
			wb_adr_o = {WB_ADR_WIDTH{1'bx}};
			wb_dat_o = {WB_DAT_WIDTH{1'bx}};
			wb_sel_o = {WB_SEL_WIDTH{1'bx}};
			wb_we_o  = 1'bx;
			wb_stb_o = 1'b0;
	end
	endtask
	
	
	task wb_read(
				input [WB_ADR_WIDTH-1:0]	adr
			);
	begin
		@(negedge wb_clk_i);
			wb_adr_o = (adr >> 2);
			wb_dat_o = {WB_DAT_WIDTH{1'bx}};
			wb_sel_o = {WB_SEL_WIDTH{1'b1}};
			wb_we_o  = 1'b0;
			wb_stb_o = 1'b1;
		@(negedge wb_clk_i);
			while ( reg_wb_ack == 1'b0 ) begin
				@(negedge wb_clk_i);
			end
			wb_adr_o = {WB_ADR_WIDTH{1'bx}};
			wb_dat_o = {WB_DAT_WIDTH{1'bx}};
			wb_sel_o = {WB_SEL_WIDTH{1'bx}};
			wb_we_o  = 1'bx;
			wb_stb_o = 1'b0;
			$display("WISHBONE_READ(adr:%h dat:%h)", adr, reg_wb_dat);
	end
	endtask
	
	
	initial begin
	@(negedge wb_rst_i);
	#100
	
$display("[edge]");
wb_write(32'h00001000, 32'hfffff6da, 4'b1111);
wb_write(32'h00001004, 32'h0016d63d, 4'b1111);
wb_write(32'h00001008, 32'h0007a1e0, 4'b1111);
wb_write(32'h0000100c, 32'h000001a2, 4'b1111);
wb_write(32'h00001010, 32'hfffbf46c, 4'b1111);
wb_write(32'h00001014, 32'hfff57dd8, 4'b1111);
wb_write(32'h00001018, 32'hfffff761, 4'b1111);
wb_write(32'h0000101c, 32'h001584c4, 4'b1111);
wb_write(32'h00001020, 32'h000be9cd, 4'b1111);
wb_write(32'h00001024, 32'h0000011b, 4'b1111);
wb_write(32'h00001028, 32'hfffd45e5, 4'b1111);
wb_write(32'h0000102c, 32'hfffa20dc, 4'b1111);
wb_write(32'h00001030, 32'h00000232, 4'b1111);
wb_write(32'h00001034, 32'hfffa8de9, 4'b1111);
wb_write(32'h00001038, 32'hfff12801, 4'b1111);
wb_write(32'h0000103c, 32'hfffff58d, 4'b1111);
wb_write(32'h00001040, 32'h001a153b, 4'b1111);
wb_write(32'h00001044, 32'h000b3fef, 4'b1111);
wb_write(32'h00001048, 32'h00000185, 4'b1111);
wb_write(32'h0000104c, 32'hfffc3e5d, 4'b1111);
wb_write(32'h00001050, 32'hfff72755, 4'b1111);
wb_write(32'h00001054, 32'hfffff63a, 4'b1111);
wb_write(32'h00001058, 32'h001864c7, 4'b1111);
wb_write(32'h0000105c, 32'h0010ae84, 4'b1111);
wb_write(32'h00001060, 32'hfffffd8a, 4'b1111);
wb_write(32'h00001064, 32'h00062952, 4'b1111);
wb_write(32'h00001068, 32'h0000e190, 4'b1111);
wb_write(32'h0000106c, 32'hfffffd20, 4'b1111);
wb_write(32'h00001070, 32'h000730da, 4'b1111);
wb_write(32'h00001074, 32'h00004210, 4'b1111);
wb_write(32'h00001078, 32'hfffffc63, 4'b1111);
wb_write(32'h0000107c, 32'h00090955, 4'b1111);
wb_write(32'h00001080, 32'h00003786, 4'b1111);
wb_write(32'h00001084, 32'hfffffbd3, 4'b1111);
wb_write(32'h00001088, 32'h000a6fd8, 4'b1111);
wb_write(32'h0000108c, 32'hffff96e8, 4'b1111);
wb_write(32'h00001090, 32'hfffffb1a, 4'b1111);
wb_write(32'h00001094, 32'h000c3a0e, 4'b1111);
wb_write(32'h00001098, 32'h00069a49, 4'b1111);
wb_write(32'h0000109c, 32'hfffffda0, 4'b1111);
wb_write(32'h000010a0, 32'h0005ed62, 4'b1111);
wb_write(32'h000010a4, 32'h000375d3, 4'b1111);
wb_write(32'h000010a8, 32'hfffffab6, 4'b1111);
wb_write(32'h000010ac, 32'h000d33aa, 4'b1111);
wb_write(32'h000010b0, 32'h00070c91, 4'b1111);
wb_write(32'h000010b4, 32'hfffffe04, 4'b1111);
wb_write(32'h000010b8, 32'h0004f3c6, 4'b1111);
wb_write(32'h000010bc, 32'h0002dcf3, 4'b1111);
wb_write(32'h000010c0, 32'hfffffda9, 4'b1111);
wb_write(32'h000010c4, 32'h0005d678, 4'b1111);
wb_write(32'h000010c8, 32'h00033849, 4'b1111);
wb_write(32'h000010cc, 32'hfffffb20, 4'b1111);
wb_write(32'h000010d0, 32'h000c2b3e, 4'b1111);
wb_write(32'h000010d4, 32'h0004edec, 4'b1111);
wb_write(32'h000010d8, 32'hfffffe0b, 4'b1111);
wb_write(32'h000010dc, 32'h0004e1d0, 4'b1111);
wb_write(32'h000010e0, 32'h0002a0f9, 4'b1111);
wb_write(32'h000010e4, 32'hfffffabe, 4'b1111);
wb_write(32'h000010e8, 32'h000d1fe6, 4'b1111);
wb_write(32'h000010ec, 32'h000506b0, 4'b1111);
wb_write(32'h000010f0, 32'h00000027, 4'b1111);
wb_write(32'h000010f4, 32'hffff992f, 4'b1111);
wb_write(32'h000010f8, 32'h00051322, 4'b1111);
wb_write(32'h000010fc, 32'h00000020, 4'b1111);
wb_write(32'h00001100, 32'hffffab25, 4'b1111);
wb_write(32'h00001104, 32'h000408e7, 4'b1111);
wb_write(32'h00001108, 32'h0000002f, 4'b1111);
wb_write(32'h0000110c, 32'hffff856b, 4'b1111);
wb_write(32'h00001110, 32'h000695f2, 4'b1111);
wb_write(32'h00001114, 32'h00000026, 4'b1111);
wb_write(32'h00001118, 32'hffff9c55, 4'b1111);
wb_write(32'h0000111c, 32'h0005551b, 4'b1111);

$display("[shader]");
wb_write(32'h00002000, 32'hfffffe54, 4'b1111);
wb_write(32'h00002004, 32'h00042b2c, 4'b1111);
wb_write(32'h00002008, 32'h000da096, 4'b1111);
wb_write(32'h0000200c, 32'h00000000, 4'b1111);
wb_write(32'h00002010, 32'h00000000, 4'b1111);
wb_write(32'h00002014, 32'h00800000, 4'b1111);
wb_write(32'h00002018, 32'h00020945, 4'b1111);
wb_write(32'h0000201c, 32'hfaeac6f2, 4'b1111);
wb_write(32'h00002020, 32'hfe4da64a, 4'b1111);
wb_write(32'h00002024, 32'h00005d13, 4'b1111);
wb_write(32'h00002028, 32'hff196977, 4'b1111);
wb_write(32'h0000202c, 32'hfea96f26, 4'b1111);
wb_write(32'h00002030, 32'hfffffded, 4'b1111);
wb_write(32'h00002034, 32'h00052bfd, 4'b1111);
wb_write(32'h00002038, 32'h0010ec86, 4'b1111);
wb_write(32'h0000203c, 32'h00000000, 4'b1111);
wb_write(32'h00002040, 32'h00000000, 4'b1111);
wb_write(32'h00002044, 32'h00800000, 4'b1111);
wb_write(32'h00002048, 32'hffff9dd4, 4'b1111);
wb_write(32'h0000204c, 32'h00f38594, 4'b1111);
wb_write(32'h00002050, 32'h02981d28, 4'b1111);
wb_write(32'h00002054, 32'hfffe2c1a, 4'b1111);
wb_write(32'h00002058, 32'h048ff337, 4'b1111);
wb_write(32'h0000205c, 32'h02f81b94, 4'b1111);
wb_write(32'h00002060, 32'h00000000, 4'b1111);
wb_write(32'h00002064, 32'h00000b5e, 4'b1111);
wb_write(32'h00002068, 32'h0004c709, 4'b1111);
wb_write(32'h0000206c, 32'h00000000, 4'b1111);
wb_write(32'h00002070, 32'h00000000, 4'b1111);
wb_write(32'h00002074, 32'h00800000, 4'b1111);
wb_write(32'h00002078, 32'h0000b05a, 4'b1111);
wb_write(32'h0000207c, 32'hfe4cf7af, 4'b1111);
wb_write(32'h00002080, 32'hfc5b491c, 4'b1111);
wb_write(32'h00002084, 32'h00018880, 4'b1111);
wb_write(32'h00002088, 32'hfc294ecf, 4'b1111);
wb_write(32'h0000208c, 32'h0072015a, 4'b1111);
wb_write(32'h00002090, 32'h00000666, 4'b1111);
wb_write(32'h00002094, 32'hfff00659, 4'b1111);
wb_write(32'h00002098, 32'h00027652, 4'b1111);
wb_write(32'h0000209c, 32'h00000000, 4'b1111);
wb_write(32'h000020a0, 32'h00000000, 4'b1111);
wb_write(32'h000020a4, 32'h00800000, 4'b1111);
wb_write(32'h000020a8, 32'h00038ed7, 4'b1111);
wb_write(32'h000020ac, 32'hf71e8182, 4'b1111);
wb_write(32'h000020b0, 32'hfb1452d8, 4'b1111);
wb_write(32'h000020b4, 32'hfffe81e3, 4'b1111);
wb_write(32'h000020b8, 32'h03bba069, 4'b1111);
wb_write(32'h000020bc, 32'h01182390, 4'b1111);
wb_write(32'h000020c0, 32'h00000000, 4'b1111);
wb_write(32'h000020c4, 32'h000006d2, 4'b1111);
wb_write(32'h000020c8, 32'h0002ddd2, 4'b1111);
wb_write(32'h000020cc, 32'h00000000, 4'b1111);
wb_write(32'h000020d0, 32'h00000000, 4'b1111);
wb_write(32'h000020d4, 32'h00800000, 4'b1111);
wb_write(32'h000020d8, 32'h0000aec2, 4'b1111);
wb_write(32'h000020dc, 32'hfe4f0b36, 4'b1111);
wb_write(32'h000020e0, 32'hfb9c2080, 4'b1111);
wb_write(32'h000020e4, 32'hfffe412c, 4'b1111);
wb_write(32'h000020e8, 32'h045ccc05, 4'b1111);
wb_write(32'h000020ec, 32'h00d39eb9, 4'b1111);
wb_write(32'h000020f0, 32'h00000a0b, 4'b1111);
wb_write(32'h000020f4, 32'hffe6ece5, 4'b1111);
wb_write(32'h000020f8, 32'h0003dd33, 4'b1111);
wb_write(32'h000020fc, 32'h00000000, 4'b1111);
wb_write(32'h00002100, 32'h00000000, 4'b1111);
wb_write(32'h00002104, 32'h00800000, 4'b1111);
wb_write(32'h00002108, 32'h000470b2, 4'b1111);
wb_write(32'h0000210c, 32'hf4ea841b, 4'b1111);
wb_write(32'h00002110, 32'hfc4cd834, 4'b1111);
wb_write(32'h00002114, 32'h00016502, 4'b1111);
wb_write(32'h00002118, 32'hfc831146, 4'b1111);
wb_write(32'h0000211c, 32'h00df8825, 4'b1111);
wb_write(32'h00002120, 32'hffff9df1, 4'b1111);
wb_write(32'h00002124, 32'h00f4c11c, 4'b1111);
wb_write(32'h00002128, 32'h0091cdad, 4'b1111);
wb_write(32'h0000212c, 32'h00000000, 4'b1111);
wb_write(32'h00002130, 32'h00000000, 4'b1111);
wb_write(32'h00002134, 32'h00800000, 4'b1111);
wb_write(32'h00002138, 32'hffb5f77a, 4'b1111);
wb_write(32'h0000213c, 32'hb8ca886e, 4'b1111);
wb_write(32'h00002140, 32'h63ee6700, 4'b1111);
wb_write(32'h00002144, 32'h0023dd7f, 4'b1111);
wb_write(32'h00002148, 32'ha67dc025, 4'b1111);
wb_write(32'h0000214c, 32'hccd66300, 4'b1111);
wb_write(32'h00002150, 32'hffffe406, 4'b1111);
wb_write(32'h00002154, 32'h0045d45c, 4'b1111);
wb_write(32'h00002158, 32'h0029991f, 4'b1111);
wb_write(32'h0000215c, 32'h00000000, 4'b1111);
wb_write(32'h00002160, 32'h00000000, 4'b1111);
wb_write(32'h00002164, 32'h00800000, 4'b1111);
wb_write(32'h00002168, 32'hfff5b3f8, 4'b1111);
wb_write(32'h0000216c, 32'h19b0bf1e, 4'b1111);
wb_write(32'h00002170, 32'h0e236000, 4'b1111);
wb_write(32'h00002174, 32'h00156a62, 4'b1111);
wb_write(32'h00002178, 32'hca8af120, 4'b1111);
wb_write(32'h0000217c, 32'heb5f7cc0, 4'b1111);
wb_write(32'h00002180, 32'h00000000, 4'b1111);
wb_write(32'h00002184, 32'h000009be, 4'b1111);
wb_write(32'h00002188, 32'h00041851, 4'b1111);
wb_write(32'h0000218c, 32'h00000000, 4'b1111);
wb_write(32'h00002190, 32'h00000000, 4'b1111);
wb_write(32'h00002194, 32'h00800000, 4'b1111);
wb_write(32'h00002198, 32'hfffd152f, 4'b1111);
wb_write(32'h0000219c, 32'h0747c3b3, 4'b1111);
wb_write(32'h000021a0, 32'h04373df0, 4'b1111);
wb_write(32'h000021a4, 32'hffffc688, 4'b1111);
wb_write(32'h000021a8, 32'h00977cf4, 4'b1111);
wb_write(32'h000021ac, 32'hf9872380, 4'b1111);
wb_write(32'h000021b0, 32'h00000050, 4'b1111);
wb_write(32'h000021b4, 32'hffff36d0, 4'b1111);
wb_write(32'h000021b8, 32'h000e8b89, 4'b1111);
wb_write(32'h000021bc, 32'h00000000, 4'b1111);
wb_write(32'h000021c0, 32'h00000000, 4'b1111);
wb_write(32'h000021c4, 32'h00800000, 4'b1111);
wb_write(32'h000021c8, 32'hfffcf661, 4'b1111);
wb_write(32'h000021cc, 32'h0794fd4c, 4'b1111);
wb_write(32'h000021d0, 32'h040d91b8, 4'b1111);
wb_write(32'h000021d4, 32'hffffe53b, 4'b1111);
wb_write(32'h000021d8, 32'h0045d7e5, 4'b1111);
wb_write(32'h000021dc, 32'hfd376ab8, 4'b1111);
wb_write(32'h000021e0, 32'h00000000, 4'b1111);
wb_write(32'h000021e4, 32'h00000794, 4'b1111);
wb_write(32'h000021e8, 32'h00032f5c, 4'b1111);
wb_write(32'h000021ec, 32'h00000000, 4'b1111);
wb_write(32'h000021f0, 32'h00000000, 4'b1111);
wb_write(32'h000021f4, 32'h00800000, 4'b1111);
wb_write(32'h000021f8, 32'hfffcb00f, 4'b1111);
wb_write(32'h000021fc, 32'h084434d8, 4'b1111);
wb_write(32'h00002200, 32'h04d14160, 4'b1111);
wb_write(32'h00002204, 32'h00003655, 4'b1111);
wb_write(32'h00002208, 32'hff71a97b, 4'b1111);
wb_write(32'h0000220c, 32'h086f3740, 4'b1111);
wb_write(32'h00002210, 32'h00000048, 4'b1111);
wb_write(32'h00002214, 32'hffff4af0, 4'b1111);
wb_write(32'h00002218, 32'h000d0f7b, 4'b1111);
wb_write(32'h0000221c, 32'h00000000, 4'b1111);
wb_write(32'h00002220, 32'h00000000, 4'b1111);
wb_write(32'h00002224, 32'h00800000, 4'b1111);
wb_write(32'h00002228, 32'hfffcca06, 4'b1111);
wb_write(32'h0000222c, 32'h0803b2c8, 4'b1111);
wb_write(32'h00002230, 32'h045584f8, 4'b1111);
wb_write(32'h00002234, 32'h0000153e, 4'b1111);
wb_write(32'h00002238, 32'hffc7b660, 4'b1111);
wb_write(32'h0000223c, 32'h03a39cd8, 4'b1111);

$display("[region]");
wb_write(32'h00003000, 32'h0000000f, 4'b1111);
wb_write(32'h00003004, 32'h0000000c, 4'b1111);
wb_write(32'h00003008, 32'h000000f0, 4'b1111);
wb_write(32'h0000300c, 32'h00000030, 4'b1111);
wb_write(32'h00003010, 32'h00000348, 4'b1111);
wb_write(32'h00003014, 32'h00000240, 4'b1111);
wb_write(32'h00003018, 32'h00000584, 4'b1111);
wb_write(32'h0000301c, 32'h00000180, 4'b1111);
wb_write(32'h00003020, 32'h00000c12, 4'b1111);
wb_write(32'h00003024, 32'h00000402, 4'b1111);
wb_write(32'h00003028, 32'h00000a21, 4'b1111);
wb_write(32'h0000302c, 32'h00000801, 4'b1111);
wb_write(32'h00003030, 32'h0000f000, 4'b1111);
wb_write(32'h00003034, 32'h0000c000, 4'b1111);
wb_write(32'h00003038, 32'h000f0000, 4'b1111);
wb_write(32'h0000303c, 32'h00030000, 4'b1111);
wb_write(32'h00003040, 32'h00348000, 4'b1111);
wb_write(32'h00003044, 32'h00240000, 4'b1111);
wb_write(32'h00003048, 32'h00584000, 4'b1111);
wb_write(32'h0000304c, 32'h00180000, 4'b1111);
wb_write(32'h00003050, 32'h00c12000, 4'b1111);
wb_write(32'h00003054, 32'h00402000, 4'b1111);
wb_write(32'h00003058, 32'h00a21000, 4'b1111);
wb_write(32'h0000305c, 32'h00801000, 4'b1111);
	
	
	/*
		$display("edge");
		wb_write(32'h1000, 32'hfffff74f, 4'b1111);
		wb_write(32'h1004, 32'h0015b1fe, 4'b1111);
		wb_write(32'h1008, 32'h00090905, 4'b1111);
		wb_write(32'h100c, 32'hffffff1b, 4'b1111);
		wb_write(32'h1010, 32'h000243dd, 4'b1111);
		wb_write(32'h1014, 32'hfff8146a, 4'b1111);
		wb_write(32'h1018, 32'hfffff705, 4'b1111);
		wb_write(32'h101c, 32'h00166a2f, 4'b1111);
		wb_write(32'h1020, 32'h000e8a0e, 4'b1111);
		wb_write(32'h1024, 32'hffffff65, 4'b1111);
		wb_write(32'h1028, 32'h00018bac, 4'b1111);
		wb_write(32'h102c, 32'hfffbf927, 4'b1111);
		wb_write(32'h1030, 32'hfffffec5, 4'b1111);
		wb_write(32'h1034, 32'h00031bdb, 4'b1111);
		wb_write(32'h1038, 32'hfff45ade, 4'b1111);
		wb_write(32'h103c, 32'hfffff608, 4'b1111);
		wb_write(32'h1040, 32'h0018e275, 4'b1111);
		wb_write(32'h1044, 32'h00083a84, 4'b1111);
		wb_write(32'h1048, 32'hffffff27, 4'b1111);
		wb_write(32'h104c, 32'h000227f1, 4'b1111);
		wb_write(32'h1050, 32'hfff97d9b, 4'b1111);
		wb_write(32'h1054, 32'hfffff5a6, 4'b1111);
		wb_write(32'h1058, 32'h0019d65f, 4'b1111);
		wb_write(32'h105c, 32'h000fbccd, 4'b1111);
		wb_write(32'h1060, 32'hfffffd02, 4'b1111);
		wb_write(32'h1064, 32'h00077669, 4'b1111);
		wb_write(32'h1068, 32'h0005b10f, 4'b1111);
		wb_write(32'h106c, 32'hfffffd40, 4'b1111);
		wb_write(32'h1070, 32'h0006da24, 4'b1111);
		wb_write(32'h1074, 32'h00048a9f, 4'b1111);
		wb_write(32'h1078, 32'hfffffba3, 4'b1111);
		wb_write(32'h107c, 32'h000ae299, 4'b1111);
		wb_write(32'h1080, 32'h0008a117, 4'b1111);
		wb_write(32'h1084, 32'hfffffbf9, 4'b1111);
		wb_write(32'h1088, 32'h000a0a9b, 4'b1111);
		wb_write(32'h108c, 32'h00075be9, 4'b1111);
		
		
		$display("polygon(tuv)");
		wb_write(32'h2000, 32'h0000000d, 4'b1111);
		wb_write(32'h2004, 32'hffffdf7b, 4'b1111);
		wb_write(32'h2008, 32'h0000a897, 4'b1111);
		wb_write(32'h200c, 32'hffffffec, 4'b1111);
		wb_write(32'h2010, 32'h00003318, 4'b1111);
		wb_write(32'h2014, 32'hffff75c6, 4'b1111);
		wb_write(32'h2018, 32'h00000148, 4'b1111);
		wb_write(32'h201c, 32'hfffccd41, 4'b1111);
		wb_write(32'h2020, 32'hfffeaaba, 4'b1111);
		wb_write(32'h2024, 32'h00000010, 4'b1111);
		wb_write(32'h2028, 32'hffffd7fa, 4'b1111);
		wb_write(32'h202c, 32'h0000ce0e, 4'b1111);
		wb_write(32'h2030, 32'hfffffec3, 4'b1111);
		wb_write(32'h2034, 32'h0003173b, 4'b1111);
		wb_write(32'h2038, 32'h0001e1c4, 4'b1111);
		wb_write(32'h203c, 32'h0000002a, 4'b1111);
		wb_write(32'h2040, 32'hffff95e1, 4'b1111);
		wb_write(32'h2044, 32'h0001907c, 4'b1111);
		wb_write(32'h2048, 32'h00000000, 4'b1111);
		wb_write(32'h204c, 32'h000000b5, 4'b1111);
		wb_write(32'h2050, 32'h00004c70, 4'b1111);
		wb_write(32'h2054, 32'h00000130, 4'b1111);
		wb_write(32'h2058, 32'hfffd0a88, 4'b1111);
		wb_write(32'h205c, 32'hfffe0976, 4'b1111);
		wb_write(32'h2060, 32'hffffffb4, 4'b1111);
		wb_write(32'h2064, 32'h0000c203, 4'b1111);
		wb_write(32'h2068, 32'hfffe0529, 4'b1111);
		wb_write(32'h206c, 32'hfffffe6a, 4'b1111);
		wb_write(32'h2070, 32'h0003f548, 4'b1111);
		wb_write(32'h2074, 32'h0003506a, 4'b1111);
		wb_write(32'h2078, 32'h00000261, 4'b1111);
		wb_write(32'h207c, 32'hfffa1125, 4'b1111);
		wb_write(32'h2080, 32'hfffb7a0a, 4'b1111);
		wb_write(32'h2084, 32'hfffff6fb, 4'b1111);
		wb_write(32'h2088, 32'h00168326, 4'b1111);
		wb_write(32'h208c, 32'h000e9b06, 4'b1111);
		wb_write(32'h2090, 32'h00000000, 4'b1111);
		wb_write(32'h2094, 32'h0000006d, 4'b1111);
		wb_write(32'h2098, 32'h00002ddd, 4'b1111);
		wb_write(32'h209c, 32'hfffffed0, 4'b1111);
		wb_write(32'h20a0, 32'h0002f665, 4'b1111);
		wb_write(32'h20a4, 32'h000259ea, 4'b1111);
		wb_write(32'h20a8, 32'hffffffb4, 4'b1111);
		wb_write(32'h20ac, 32'h0000c072, 4'b1111);
		wb_write(32'h20b0, 32'hfffd5cfe, 4'b1111);
		wb_write(32'h20b4, 32'hffffff52, 4'b1111);
		wb_write(32'h20b8, 32'h0001b244, 4'b1111);
		wb_write(32'h20bc, 32'h00016b9b, 4'b1111);
		wb_write(32'h20c0, 32'hfffffe4d, 4'b1111);
		wb_write(32'h20c4, 32'h00043c98, 4'b1111);
		wb_write(32'h20c8, 32'h00031a5b, 4'b1111);
		wb_write(32'h20cc, 32'hfffffbf7, 4'b1111);
		wb_write(32'h20d0, 32'h000a128d, 4'b1111);
		wb_write(32'h20d4, 32'h00043094, 4'b1111);
		
		
		$display("polygon(rgb)");
		wb_write(32'h2000, 32'h00000000, 4'b1111);
		wb_write(32'h2004, 32'h00000000, 4'b1111);
		wb_write(32'h2008, 32'h00080000, 4'b1111);
		wb_write(32'h200c, 32'h00001f12, 4'b1111);
		wb_write(32'h2010, 32'hffb27169, 4'b1111);
		wb_write(32'h2014, 32'hffdfbf5b, 4'b1111);
		wb_write(32'h2018, 32'hfffffcce, 4'b1111);
		wb_write(32'h201c, 32'h00081753, 4'b1111);
		wb_write(32'h2020, 32'hfff3a761, 4'b1111);
		wb_write(32'h2024, 32'h00000000, 4'b1111);
		wb_write(32'h2028, 32'h00000000, 4'b1111);
		wb_write(32'h202c, 32'h00080000, 4'b1111);
		wb_write(32'h2030, 32'h0000034f, 4'b1111);
		wb_write(32'h2034, 32'hfff7a3fe, 4'b1111);
		wb_write(32'h2038, 32'h001f56fb, 4'b1111);
		wb_write(32'h203c, 32'hffffe525, 4'b1111);
		wb_write(32'h2040, 32'h004309ca, 4'b1111);
		wb_write(32'h2044, 32'h002628fa, 4'b1111);
		wb_write(32'h2048, 32'h00000000, 4'b1111);
		wb_write(32'h204c, 32'h00000000, 4'b1111);
		wb_write(32'h2050, 32'h00080000, 4'b1111);
		wb_write(32'h2054, 32'hfffffa50, 4'b1111);
		wb_write(32'h2058, 32'h000e84be, 4'b1111);
		wb_write(32'h205c, 32'hffda20c3, 4'b1111);
		wb_write(32'h2060, 32'h00001c23, 4'b1111);
		wb_write(32'h2064, 32'hffb9d39c, 4'b1111);
		wb_write(32'h2068, 32'hffda828d, 4'b1111);
		wb_write(32'h206c, 32'h00000000, 4'b1111);
		wb_write(32'h2070, 32'h00000000, 4'b1111);
		wb_write(32'h2074, 32'h00080000, 4'b1111);
		wb_write(32'h2078, 32'hffff465f, 4'b1111);
		wb_write(32'h207c, 32'h01cf51fe, 4'b1111);
		wb_write(32'h2080, 32'h012c8572, 4'b1111);
		wb_write(32'h2084, 32'h00005a34, 4'b1111);
		wb_write(32'h2088, 32'hff1ef80d, 4'b1111);
		wb_write(32'h208c, 32'hff5dba00, 4'b1111);
		wb_write(32'h2090, 32'h00000000, 4'b1111);
		wb_write(32'h2094, 32'h00000000, 4'b1111);
		wb_write(32'h2098, 32'h00080000, 4'b1111);
		wb_write(32'h209c, 32'hfffff99d, 4'b1111);
		wb_write(32'h20a0, 32'h00102c19, 4'b1111);
		wb_write(32'h20a4, 32'hffc75ca1, 4'b1111);
		wb_write(32'h20a8, 32'hffffe338, 4'b1111);
		wb_write(32'h20ac, 32'h0047c2be, 4'b1111);
		wb_write(32'h20b0, 32'h00448cd4, 4'b1111);
		wb_write(32'h20b4, 32'h00000000, 4'b1111);
		wb_write(32'h20b8, 32'h00000000, 4'b1111);
		wb_write(32'h20bc, 32'h00080000, 4'b1111);
		wb_write(32'h20c0, 32'hffffaf23, 4'b1111);
		wb_write(32'h20c4, 32'h00c9d95b, 4'b1111);
		wb_write(32'h20c8, 32'h0053ef20, 4'b1111);
		wb_write(32'h20cc, 32'hffffe669, 4'b1111);
		wb_write(32'h20d0, 32'h003fc301, 4'b1111);
		wb_write(32'h20d4, 32'h003a3af9, 4'b1111);
		
		
		$display("region");
		wb_write(32'h3000, 32'h0000000f, 4'b1111);
		wb_write(32'h3004, 32'h0000000c, 4'b1111);
		wb_write(32'h3008, 32'h000000f0, 4'b1111);
		wb_write(32'h300c, 32'h00000030, 4'b1111);
		wb_write(32'h3010, 32'h00000348, 4'b1111);
		wb_write(32'h3014, 32'h00000240, 4'b1111);
		wb_write(32'h3018, 32'h00000584, 4'b1111);
		wb_write(32'h301c, 32'h00000180, 4'b1111);
		wb_write(32'h3020, 32'h00000c12, 4'b1111);
		wb_write(32'h3024, 32'h00000402, 4'b1111);
		wb_write(32'h3028, 32'h00000a21, 4'b1111);
		wb_write(32'h302c, 32'h00000801, 4'b1111);
	*/
	
		$display("start");
		wb_write(32'h0000_0000, 32'h0000_0001, 4'b1111);
		
		
		$display("read");
		wb_read(32'h00*4); 		// REG_ADDR_CTL_ENABLE             
		wb_read(32'h01*4);		// REG_ADDR_CTL_BANK 
		wb_read(32'h02*4);		// REG_ADDR_PARAM_WIDTH            
		wb_read(32'h03*4);		// REG_ADDR_PARAM_HEIGHT           
		wb_read(32'h04*4);		// REG_ADDR_PARAM_CULLING          
		wb_read(32'h11*4);		// REG_ADDR_PARAMS_BANK            
		
		wb_read(32'h20*4);		// REG_ADDR_CFG_SHADER_TYPE
		wb_read(32'h21*4);		// REG_ADDR_CFG_VERSION            
		wb_read(32'h22*4);		// REG_ADDR_CFG_BANK_ADDR_WIDTH    
		wb_read(32'h23*4);		// REG_ADDR_CFG_PARAMS_ADDR_WIDTH  
		wb_read(32'h24*4);		// REG_ADDR_CFG_BANK_NUM           
		wb_read(32'h25*4);		// REG_ADDR_CFG_EDGE_NUM           
		wb_read(32'h26*4);		// REG_ADDR_CFG_POLYGON_NUM        
		wb_read(32'h27*4);		// REG_ADDR_CFG_SHADER_PARAM_NUM   
		wb_read(32'h28*4);		// REG_ADDR_CFG_EDGE_PARAM_WIDTH   
		wb_read(32'h29*4);		// REG_ADDR_CFG_SHADER_PARAM_WIDTH 
		wb_read(32'h2a*4);		// REG_ADDR_CFG_REGION_PARAM_WIDTH 
		wb_read(32'h2b*4);		// REG_ADDR_CFG_SHADER_PARAM_Q     
	
	#10000000
		$finish();
	end
	
	
	
endmodule



`default_nettype wire


// end of file
