
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
	
	
	
	parameter	WB_ADR_WIDTH      = 12;
	parameter	WB_DAT_WIDTH      = 32;
	parameter	WB_SEL_WIDTH      = (WB_DAT_WIDTH / 8);
	
	parameter	BANK_NUM          = 2;
	parameter	BANK_ADDR_WIDTH   = 10;
	parameter	PARAMS_ADDR_WIDTH = 8;
	
	parameter	EDGE_NUM          = 12;
	parameter	EDGE_WIDTH        = 32;
	parameter	EDGE_PARAM_NUM    = EDGE_NUM*2;
	parameter	EDGE_RAM_TYPE     = "distributed";
	
	parameter	POLYGON_NUM       = 6;
	parameter	POLYGON_WIDTH     = 32;
	parameter	POLYGON_PARAM_NUM = POLYGON_NUM*3;
	parameter	POLYGON_RAM_TYPE  = "distributed";
	
	parameter	REGION_NUM        = POLYGON_NUM;
	parameter	REGION_WIDTH      = EDGE_NUM;
	parameter	REGION_PARAM_NUM  = REGION_NUM*2;
	parameter	REGION_RAM_TYPE   = "distributed";
	
	parameter	INIT_ENABLE       = 1'b0;
	parameter	INIT_BANK         = 0;
	
	reg												cke = 1'b1;
	
	wire											start;
	wire											busy = 1;
	
	wire	[EDGE_PARAM_NUM   *EDGE_WIDTH-1:0]		edge_params;
	wire	[POLYGON_PARAM_NUM*POLYGON_WIDTH-1:0]	polygon_params;
	wire	[REGION_PARAM_NUM *REGION_WIDTH-1:0]	region_params;
	
	wire											s_wb_rst_i = reset;
	wire											s_wb_clk_i = wb_clk;
	wire	[WB_ADR_WIDTH-1:0]						s_wb_adr_i;
	wire	[WB_DAT_WIDTH-1:0]						s_wb_dat_o;
	wire	[WB_DAT_WIDTH-1:0]						s_wb_dat_i;
	wire											s_wb_we_i;
	wire	[WB_SEL_WIDTH-1:0]						s_wb_sel_i;
	wire											s_wb_stb_i;
	wire											s_wb_ack_o;
	
	
	jelly_rasterizer_params
			#(
				.WB_ADR_WIDTH      	(WB_ADR_WIDTH      	),
				.WB_DAT_WIDTH      	(WB_DAT_WIDTH      	),
				.WB_SEL_WIDTH      	(WB_SEL_WIDTH      	),
				                     
				.BANK_NUM          	(BANK_NUM          	),
				.BANK_ADDR_WIDTH   	(BANK_ADDR_WIDTH   	),
				.PARAMS_ADDR_WIDTH 	(PARAMS_ADDR_WIDTH 	),
				                     
				.EDGE_NUM          	(EDGE_NUM          	),
				.EDGE_WIDTH        	(EDGE_WIDTH        	),
				.EDGE_PARAM_NUM    	(EDGE_PARAM_NUM    	),
				.EDGE_RAM_TYPE     	(EDGE_RAM_TYPE     	),
				                     
				.POLYGON_NUM       	(POLYGON_NUM       	),
				.POLYGON_WIDTH     	(POLYGON_WIDTH     	),
				.POLYGON_PARAM_NUM 	(POLYGON_PARAM_NUM 	),
				.POLYGON_RAM_TYPE  	(POLYGON_RAM_TYPE  	),
				                     
				.REGION_NUM        	(REGION_NUM        	),
				.REGION_WIDTH      	(REGION_WIDTH      	),
				.REGION_PARAM_NUM  	(REGION_PARAM_NUM  	),
				.REGION_RAM_TYPE   	(REGION_RAM_TYPE   	)
			)
		i_rasterizer_params
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				                     
				.start				(start			),
				.busy				(busy			),
				                     
				.edge_params		(edge_params	),
				.polygon_params		(polygon_params	),
				.region_params		(region_params	),
				                     
				.s_wb_rst_i			(s_wb_rst_i		),
				.s_wb_clk_i			(s_wb_clk_i		),
				.s_wb_adr_i			(s_wb_adr_i		),
				.s_wb_dat_o			(s_wb_dat_o		),
				.s_wb_dat_i			(s_wb_dat_i		),
				.s_wb_we_i			(s_wb_we_i		),
				.s_wb_sel_i			(s_wb_sel_i		),
				.s_wb_stb_i			(s_wb_stb_i		),
				.s_wb_ack_o			(s_wb_ack_o		)
			);
	
	
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
		wb_write(32'h400, 32'hfffff74f, 4'b1111);
		wb_write(32'h404, 32'h0015b1fe, 4'b1111);
		wb_write(32'h408, 32'h00090905, 4'b1111);
		wb_write(32'h40c, 32'hffffff1b, 4'b1111);
		wb_write(32'h410, 32'h000243dd, 4'b1111);
		wb_write(32'h414, 32'hfff8146a, 4'b1111);
		wb_write(32'h418, 32'hfffff705, 4'b1111);
		wb_write(32'h41c, 32'h00166a2f, 4'b1111);
		wb_write(32'h420, 32'h000e8a0e, 4'b1111);
		wb_write(32'h424, 32'hffffff65, 4'b1111);
		wb_write(32'h428, 32'h00018bac, 4'b1111);
		wb_write(32'h42c, 32'hfffbf927, 4'b1111);
		wb_write(32'h430, 32'hfffffec5, 4'b1111);
		wb_write(32'h434, 32'h00031bdb, 4'b1111);
		wb_write(32'h438, 32'hfff45ade, 4'b1111);
		wb_write(32'h43c, 32'hfffff608, 4'b1111);
		wb_write(32'h440, 32'h0018e275, 4'b1111);
		wb_write(32'h444, 32'h00083a84, 4'b1111);
		wb_write(32'h448, 32'hffffff27, 4'b1111);
		wb_write(32'h44c, 32'h000227f1, 4'b1111);
		wb_write(32'h450, 32'hfff97d9b, 4'b1111);
		wb_write(32'h454, 32'hfffff5a6, 4'b1111);
		wb_write(32'h458, 32'h0019d65f, 4'b1111);
		wb_write(32'h45c, 32'h000fbccd, 4'b1111);
		wb_write(32'h460, 32'hfffffd02, 4'b1111);
		wb_write(32'h464, 32'h00077669, 4'b1111);
		wb_write(32'h468, 32'h0005b10f, 4'b1111);
		wb_write(32'h46c, 32'hfffffd40, 4'b1111);
		wb_write(32'h470, 32'h0006da24, 4'b1111);
		wb_write(32'h474, 32'h00048a9f, 4'b1111);
		wb_write(32'h478, 32'hfffffba3, 4'b1111);
		wb_write(32'h47c, 32'h000ae299, 4'b1111);
		wb_write(32'h480, 32'h0008a117, 4'b1111);
		wb_write(32'h484, 32'hfffffbf9, 4'b1111);
		wb_write(32'h488, 32'h000a0a9b, 4'b1111);
		wb_write(32'h48c, 32'h00075be9, 4'b1111);
		
		$display("polygon");
		wb_write(32'h800, 32'h0000000d, 4'b1111);
		wb_write(32'h804, 32'hffffdf7b, 4'b1111);
		wb_write(32'h808, 32'h0000a897, 4'b1111);
		wb_write(32'h80c, 32'hffffffec, 4'b1111);
		wb_write(32'h810, 32'h00003318, 4'b1111);
		wb_write(32'h814, 32'hffff75c6, 4'b1111);
		wb_write(32'h818, 32'h00000148, 4'b1111);
		wb_write(32'h81c, 32'hfffccd41, 4'b1111);
		wb_write(32'h820, 32'hfffeaaba, 4'b1111);
		wb_write(32'h824, 32'h00000010, 4'b1111);
		wb_write(32'h828, 32'hffffd7fa, 4'b1111);
		wb_write(32'h82c, 32'h0000ce0e, 4'b1111);
		wb_write(32'h830, 32'hfffffec3, 4'b1111);
		wb_write(32'h834, 32'h0003173b, 4'b1111);
		wb_write(32'h838, 32'h0001e1c4, 4'b1111);
		wb_write(32'h83c, 32'h0000002a, 4'b1111);
		wb_write(32'h840, 32'hffff95e1, 4'b1111);
		wb_write(32'h844, 32'h0001907c, 4'b1111);
		wb_write(32'h848, 32'h00000000, 4'b1111);
		wb_write(32'h84c, 32'h000000b5, 4'b1111);
		wb_write(32'h850, 32'h00004c70, 4'b1111);
		wb_write(32'h854, 32'h00000130, 4'b1111);
		wb_write(32'h858, 32'hfffd0a88, 4'b1111);
		wb_write(32'h85c, 32'hfffe0976, 4'b1111);
		wb_write(32'h860, 32'hffffffb4, 4'b1111);
		wb_write(32'h864, 32'h0000c203, 4'b1111);
		wb_write(32'h868, 32'hfffe0529, 4'b1111);
		wb_write(32'h86c, 32'hfffffe6a, 4'b1111);
		wb_write(32'h870, 32'h0003f548, 4'b1111);
		wb_write(32'h874, 32'h0003506a, 4'b1111);
		wb_write(32'h878, 32'h00000261, 4'b1111);
		wb_write(32'h87c, 32'hfffa1125, 4'b1111);
		wb_write(32'h880, 32'hfffb7a0a, 4'b1111);
		wb_write(32'h884, 32'hfffff6fb, 4'b1111);
		wb_write(32'h888, 32'h00168326, 4'b1111);
		wb_write(32'h88c, 32'h000e9b06, 4'b1111);
		wb_write(32'h890, 32'h00000000, 4'b1111);
		wb_write(32'h894, 32'h0000006d, 4'b1111);
		wb_write(32'h898, 32'h00002ddd, 4'b1111);
		wb_write(32'h89c, 32'hfffffed0, 4'b1111);
		wb_write(32'h8a0, 32'h0002f665, 4'b1111);
		wb_write(32'h8a4, 32'h000259ea, 4'b1111);
		wb_write(32'h8a8, 32'hffffffb4, 4'b1111);
		wb_write(32'h8ac, 32'h0000c072, 4'b1111);
		wb_write(32'h8b0, 32'hfffd5cfe, 4'b1111);
		wb_write(32'h8b4, 32'hffffff52, 4'b1111);
		wb_write(32'h8b8, 32'h0001b244, 4'b1111);
		wb_write(32'h8bc, 32'h00016b9b, 4'b1111);
		wb_write(32'h8b0, 32'hfffffe4d, 4'b1111);
		wb_write(32'h8c4, 32'h00043c98, 4'b1111);
		wb_write(32'h8c8, 32'h00031a5b, 4'b1111);
		wb_write(32'h6cc, 32'hfffffbf7, 4'b1111);
		wb_write(32'h6c0, 32'h000a128d, 4'b1111);
		wb_write(32'h6c4, 32'h00043094, 4'b1111);
		
		$display("region");
		wb_write(32'hc00, 32'h0000000f, 4'b1111);
		wb_write(32'hc04, 32'h0000000c, 4'b1111);
		wb_write(32'hc08, 32'h000000f0, 4'b1111);
		wb_write(32'hc0c, 32'h00000030, 4'b1111);
		wb_write(32'hc10, 32'h00000348, 4'b1111);
		wb_write(32'hc14, 32'h00000240, 4'b1111);
		wb_write(32'hc18, 32'h00000584, 4'b1111);
		wb_write(32'hc1c, 32'h00000180, 4'b1111);
		wb_write(32'hc20, 32'h00000c12, 4'b1111);
		wb_write(32'hc24, 32'h00000402, 4'b1111);
		wb_write(32'hc28, 32'h00000a21, 4'b1111);
		wb_write(32'hc2c, 32'h00000801, 4'b1111);
		
		$display("start");
		wb_write(32'h0000_0000, 32'h0000_0001, 4'b1111);
		
	#10000
		$finish();
	end
	
	
	
endmodule



`default_nettype wire


// end of file
