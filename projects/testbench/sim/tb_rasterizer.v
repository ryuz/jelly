
`timescale 1ns / 1ps
`default_nettype none


module tb_rasterizer();
	localparam RATE    = 10.0;
	localparam WB_RATE = 33.3;
	
	
	initial begin
		$dumpfile("tb_rasterizer.vcd");
		$dumpvars(0, tb_rasterizer);
	end
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		wb_clk = 1'b1;
	always #(WB_RATE/2.0)	wb_clk = ~wb_clk;
	
	reg		reset = 1'b1;
	always #(RATE*100)	reset = 1'b0;
	
	
	parameter	X_WIDTH             = 12;
	parameter	Y_WIDTH             = 12;
	
	parameter	WB_ADR_WIDTH      = 14;
	parameter	WB_DAT_WIDTH      = 32;
	parameter	WB_SEL_WIDTH      = (WB_DAT_WIDTH / 8);
	
	parameter	BANK_NUM          = 2;
	parameter	BANK_ADDR_WIDTH   = 12;
	parameter	PARAMS_ADDR_WIDTH = 10;
	
	parameter	EDGE_NUM          = 12;
	parameter	EDGE_WIDTH        = 32;
	parameter	EDGE_RAM_TYPE     = "distributed";
	
	parameter	POLYGON_NUM       = 6;
	parameter	POLYGON_WIDTH     = 32;
	parameter	POLYGON_PARAM_NUM = 3;
	parameter	POLYGON_RAM_TYPE  = "distributed";
	
	parameter	REGION_NUM        = POLYGON_NUM;
	parameter	REGION_WIDTH      = EDGE_NUM;
	parameter	REGION_RAM_TYPE   = "distributed";
	
	parameter	INIT_CTL_ENABLE     = 1'b0;
	parameter	INIT_CTL_BANK       = 0;
	parameter	INIT_PARAM_WIDTH    = 640-1;
	parameter	INIT_PARAM_HEIGHT   = 480-1;
	
	
	parameter	PARAMS_EDGE_SIZE    = EDGE_NUM*3;
	parameter	PARAMS_POLYGON_SIZE = EDGE_NUM*POLYGON_PARAM_NUM*3;
	parameter	PARAMS_REGION_SIZE  = EDGE_NUM*2;
	
	reg												cke = 1'b1;
	
	wire											start;
	wire											busy = 1;
	
	wire	[X_WIDTH-1:0]							param_width;
	wire	[Y_WIDTH-1:0]							param_height;
	
	wire	[PARAMS_EDGE_SIZE*EDGE_WIDTH-1:0]		params_edge;
	wire	[PARAMS_POLYGON_SIZE*POLYGON_WIDTH-1:0]	params_polygon;
	wire	[PARAMS_REGION_SIZE*REGION_WIDTH-1:0]	params_region;
	
	wire											s_wb_rst_i = reset;
	wire											s_wb_clk_i = wb_clk;
	wire	[WB_ADR_WIDTH-1:0]						s_wb_adr_i;
	wire	[WB_DAT_WIDTH-1:0]						s_wb_dat_o;
	wire	[WB_DAT_WIDTH-1:0]						s_wb_dat_i;
	wire											s_wb_we_i;
	wire	[WB_SEL_WIDTH-1:0]						s_wb_sel_i;
	wire											s_wb_stb_i;
	wire											s_wb_ack_o;
	
	
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
				.EDGE_WIDTH			(EDGE_WIDTH),
				.EDGE_RAM_TYPE		(EDGE_RAM_TYPE),
				
				.POLYGON_NUM		(POLYGON_NUM),
				.POLYGON_PARAM_NUM	(POLYGON_PARAM_NUM),
				.POLYGON_WIDTH		(POLYGON_WIDTH),
				.POLYGON_RAM_TYPE	(POLYGON_RAM_TYPE),
				
				.REGION_NUM			(REGION_NUM),
				.REGION_WIDTH		(REGION_WIDTH),
				.REGION_RAM_TYPE	(REGION_RAM_TYPE),
				
				.INIT_CTL_ENABLE	(INIT_CTL_ENABLE),
				.INIT_CTL_BANK		(INIT_CTL_BANK),
				.INIT_PARAM_WIDTH	(INIT_PARAM_WIDTH),
				.INIT_PARAM_HEIGHT	(INIT_PARAM_HEIGHT)
			)
		i_rasterizer
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
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
	
	
	/*
	jelly_rasterizer_params
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
				.EDGE_WIDTH			(EDGE_WIDTH),
				.EDGE_RAM_TYPE		(EDGE_RAM_TYPE),
				
				.POLYGON_NUM		(POLYGON_NUM),
				.POLYGON_PARAM_NUM	(POLYGON_PARAM_NUM),
				.POLYGON_WIDTH		(POLYGON_WIDTH),
				.POLYGON_RAM_TYPE	(POLYGON_RAM_TYPE),
				
				.REGION_NUM			(REGION_NUM),
				.REGION_WIDTH		(REGION_WIDTH),
				.REGION_RAM_TYPE	(REGION_RAM_TYPE),
				
				.INIT_CTL_ENABLE	(INIT_CTL_ENABLE),
				.INIT_CTL_BANK		(INIT_CTL_BANK),
				.INIT_PARAM_WIDTH	(INIT_PARAM_WIDTH),
				.INIT_PARAM_HEIGHT	(INIT_PARAM_HEIGHT)
			)
		i_rasterizer_params
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.start				(start),
				.busy				(busy),
				
				.param_width		(param_width),
				.param_height		(param_height),
				
				.edge_params		(edge_params),
				.polygon_params		(polygon_params),
				.region_params		(region_params),
				
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
	*/
	
	
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
		reg_wb_dat <= wb_dat_i;
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
	
	
	initial begin
	@(negedge wb_rst_i);
	#100
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
		
		$display("polygon");
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
		
		$display("start");
		wb_write(32'h0000_0000, 32'h0000_0001, 4'b1111);
		
	#1000000
		$finish();
	end
	
	
	
endmodule



`default_nettype wire


// end of file
