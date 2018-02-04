// ---------------------------------------------------------------------------
//
//                                  Copyright (C) 2015-2018 by Ryuji Fuchikami
//                                      http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_top();
	localparam RATE125 = 1000.0/125.0;
	
	initial begin
		$dumpfile("tb_top.vcd");
		$dumpvars(1, tb_top);
		$dumpvars(1, tb_top.i_top);
//		$dumpvars(0, tb_top.i_top.i_vout_axi4s);
//		$dumpvars(1, tb_top.i_top.i_gpu_gouraud);
//		$dumpvars(1, tb_top.i_top.i_gpu_gouraud.i_rasterizer);
//		$dumpvars(1, tb_top.i_top.i_gpu_gouraud.i_rasterizer.i_rasterizer_core);
	#100000000
		$finish;
	end
	
	parameter	X_NUM = 1920;
	parameter	Y_NUM = 1080;
//	parameter	X_NUM = 640;
//	parameter	Y_NUM = 8;
	
	reg		clk125 = 1'b1;
	always #(RATE125/2.0)	clk125 = ~clk125;
	
	
	// TOP
	top
			#(
				.HDMI_TX	(0),
				.VOUT_X_NUM	(X_NUM),
				.VOUT_Y_NUM	(Y_NUM)
			)
		i_top
			(
				.in_clk125	(clk125),
				
				.led		()
			);
	
	
	
	// èoóÕï€ë∂
	wire			vout_reset        = i_top.vout_reset;
	wire			vout_clk          = i_top.vout_clk;
	wire	[0:0]	axi4s_vout_tuser  = i_top.axi4s_vout_tuser;
	wire			axi4s_vout_tlast  = i_top.axi4s_vout_tlast;
	wire	[23:0]	axi4s_vout_tdata  = i_top.axi4s_vout_tdata;
	wire			axi4s_vout_tvalid = i_top.axi4s_vout_tvalid;
	wire			axi4s_vout_tready = i_top.axi4s_vout_tready;
	
	integer			axi4s_vout_x = 0;
	always @(posedge vout_clk) begin
		if ( axi4s_vout_tvalid & axi4s_vout_tready ) begin
			axi4s_vout_x <= axi4s_vout_x + 1;
			if ( axi4s_vout_tlast ) begin
				axi4s_vout_x <= 0;
			end
		end
	end
	
	
	integer		fp;
	initial begin
		 fp = $fopen("out_img.ppm", "w");
		 $fdisplay(fp, "P3");
		 $fdisplay(fp, "%d %d", X_NUM, Y_NUM);
		 $fdisplay(fp, "255");
	end
	
	always @(posedge vout_clk) begin
		if ( !vout_reset && axi4s_vout_tvalid && axi4s_vout_tready ) begin
			 $fdisplay(fp, "%d %d %d",
			 	axi4s_vout_tdata[8*2 +: 8],
			 	axi4s_vout_tdata[8*1 +: 8],
			 	axi4s_vout_tdata[8*0 +: 8]);
		end
	end
	
	
	
	// VOUT
	wire			vout_vsync = i_top.vout_vsync;
	wire			vout_hsync = i_top.vout_hsync;
	wire			vout_de    = i_top.vout_de;
	wire	[23:0]	vout_data  = i_top.vout_data;
	wire	[3:0]	vout_ctl   = i_top.vout_ctl;
	integer		fp_vout;
	initial begin
		 fp_vout = $fopen("vout_img.ppm", "w");
		 $fdisplay(fp_vout, "P3");
		 $fdisplay(fp_vout, "%d %d", X_NUM, Y_NUM*3);
		 $fdisplay(fp_vout, "255");
	end
	
	always @(posedge vout_clk) begin
		if ( !vout_reset && vout_de ) begin
			 $fdisplay(fp_vout, "%d %d %d",
			 	vout_data[8*2 +: 8],
			 	vout_data[8*1 +: 8],
			 	vout_data[8*0 +: 8]);
		end
	end
	
	
	
	
	// WISHBONE master
	parameter	WB_ADR_WIDTH        = 30;
	parameter	WB_DAT_WIDTH        = 32;
	parameter	WB_SEL_WIDTH        = (WB_DAT_WIDTH / 8);
	
	wire							wb_rst_i = i_top.wb_rst_o;
	wire							wb_clk_i = i_top.wb_clk_o;
	reg		[WB_ADR_WIDTH-1:0]		wb_adr_o;
	wire	[WB_DAT_WIDTH-1:0]		wb_dat_i = i_top.wb_host_dat_i;
	reg		[WB_DAT_WIDTH-1:0]		wb_dat_o;
	reg								wb_we_o;
	reg		[WB_SEL_WIDTH-1:0]		wb_sel_o;
	reg								wb_stb_o = 0;
	wire							wb_ack_i = i_top.wb_host_ack_i;
	
	initial begin
		force i_top.wb_host_adr_o = wb_adr_o;
		force i_top.wb_host_dat_o = wb_dat_o;
		force i_top.wb_host_we_o  = wb_we_o;
		force i_top.wb_host_sel_o = wb_sel_o;
		force i_top.wb_host_stb_o = wb_stb_o;
	end
	
	
	reg		[WB_DAT_WIDTH-1:0]		reg_wb_dat;
	reg								reg_wb_ack;
	always @(posedge wb_clk_i) begin
		if ( ~wb_we_o & wb_stb_o & wb_ack_i ) begin
			reg_wb_dat <= wb_dat_i;
		end
		reg_wb_ack <= wb_ack_i;
	end
	
	
	task wb_write(
				input [31:0]	adr,
				input [31:0]	dat,
				input [3:0]		sel
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
				input [31:0]	adr
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
	
	if ( X_NUM == 1920 ) begin
		// 1080
		wb_write(32'h40001000, 32'hffffcf99, 4'hf);
		wb_write(32'h40001004, 32'h016ad61f, 4'hf);
		wb_write(32'h40001008, 32'h00508aeb, 4'hf);
		wb_write(32'h4000100c, 32'h000008a5, 4'hf);
		wb_write(32'h40001010, 32'hffbf5c5d, 4'hf);
		wb_write(32'h40001014, 32'hff6837cf, 4'hf);
		wb_write(32'h40001018, 32'hffffd262, 4'hf);
		wb_write(32'h4000101c, 32'h0155f2c6, 4'hf);
		wb_write(32'h40001020, 32'h00c97ba1, 4'hf);
		wb_write(32'h40001024, 32'h000005dc, 4'hf);
		wb_write(32'h40001028, 32'hffd43fb6, 4'hf);
		wb_write(32'h4000102c, 32'hffe9d904, 4'hf);
		wb_write(32'h40001030, 32'h00000b9a, 4'hf);
		wb_write(32'h40001034, 32'hffa936b9, 4'hf);
		wb_write(32'h40001038, 32'hff055d80, 4'hf);
		wb_write(32'h4000103c, 32'hffffc8b4, 4'hf);
		wb_write(32'h40001040, 32'h019e83a9, 4'hf);
		wb_write(32'h40001044, 32'h009f8769, 4'hf);
		wb_write(32'h40001048, 32'h00000805, 4'hf);
		wb_write(32'h4000104c, 32'hffc413f7, 4'hf);
		wb_write(32'h40001050, 32'hffabda32, 4'hf);
		wb_write(32'h40001054, 32'hffffcc49, 4'hf);
		wb_write(32'h40001058, 32'h0183a66b, 4'hf);
		wb_write(32'h4000105c, 32'h0137d0f2, 4'hf);
		wb_write(32'h40001060, 32'hfffff2f6, 4'hf);
		wb_write(32'h40001064, 32'h0061d742, 4'hf);
		wb_write(32'h40001068, 32'h003bc7b6, 4'hf);
		wb_write(32'h4000106c, 32'hfffff0cd, 4'hf);
		wb_write(32'h40001070, 32'h00720301, 4'hf);
		wb_write(32'h40001074, 32'h0013edd7, 4'hf);
		wb_write(32'h40001078, 32'hffffecdd, 4'hf);
		wb_write(32'h4000107c, 32'h008f8ae7, 4'hf);
		wb_write(32'h40001080, 32'h0012b29b, 4'hf);
		wb_write(32'h40001084, 32'hffffe9e8, 4'hf);
		wb_write(32'h40001088, 32'h00a5b08b, 4'hf);
		wb_write(32'h4000108c, 32'hffea328e, 4'hf);
		wb_write(32'h40001090, 32'hffffe614, 4'hf);
		wb_write(32'h40001094, 32'h00c24fd2, 4'hf);
		wb_write(32'h40001098, 32'h006e2d45, 4'hf);
		wb_write(32'h4000109c, 32'hfffff371, 4'hf);
		wb_write(32'h400010a0, 32'h005e22ac, 4'hf);
		wb_write(32'h400010a4, 32'h003913e9, 4'hf);
		wb_write(32'h400010a8, 32'hffffe403, 4'hf);
		wb_write(32'h400010ac, 32'h00d1cd47, 4'hf);
		wb_write(32'h400010b0, 32'h0074bf3e, 4'hf);
		wb_write(32'h400010b4, 32'hfffff582, 4'hf);
		wb_write(32'h400010b8, 32'h004ea537, 4'hf);
		wb_write(32'h400010bc, 32'h002e80f0, 4'hf);
		wb_write(32'h400010c0, 32'hfffff399, 4'hf);
		wb_write(32'h400010c4, 32'h005cf472, 4'hf);
		wb_write(32'h400010c8, 32'h002c27ba, 4'hf);
		wb_write(32'h400010cc, 32'hffffe637, 4'hf);
		wb_write(32'h400010d0, 32'h00c14a56, 4'hf);
		wb_write(32'h400010d4, 32'h0041b556, 4'hf);
		wb_write(32'h400010d8, 32'hfffff5a5, 4'hf);
		wb_write(32'h400010dc, 32'h004d9c4a, 4'hf);
		wb_write(32'h400010e0, 32'h0020cd81, 4'hf);
		wb_write(32'h400010e4, 32'hffffe42b, 4'hf);
		wb_write(32'h400010e8, 32'h00d0a27e, 4'hf);
		wb_write(32'h400010ec, 32'h003f68b6, 4'hf);
		wb_write(32'h400010f0, 32'h000000ce, 4'hf);
		wb_write(32'h400010f4, 32'hfff9dae2, 4'hf);
		wb_write(32'h400010f8, 32'h003e1261, 4'hf);
		wb_write(32'h400010fc, 32'h000000ab, 4'hf);
		wb_write(32'h40001100, 32'hfffae3cf, 4'hf);
		wb_write(32'h40001104, 32'h00277d9f, 4'hf);
		wb_write(32'h40001108, 32'h000000f6, 4'hf);
		wb_write(32'h4000110c, 32'hfff8b019, 4'hf);
		wb_write(32'h40001110, 32'h006bcdf4, 4'hf);
		wb_write(32'h40001114, 32'h000000ce, 4'hf);
		wb_write(32'h40001118, 32'hfff9de53, 4'hf);
		wb_write(32'h4000111c, 32'h004ed1cd, 4'hf);
		wb_write(32'h40002000, 32'hffffffb0, 4'hf);
		wb_write(32'h40002004, 32'h00025778, 4'hf);
		wb_write(32'h40002008, 32'h000c18d7, 4'hf);
		wb_write(32'h4000200c, 32'h00000000, 4'hf);
		wb_write(32'h40002010, 32'h00000000, 4'hf);
		wb_write(32'h40002014, 32'h00800000, 4'hf);
		wb_write(32'h40002018, 32'h00006283, 4'hf);
		wb_write(32'h4000201c, 32'hfd1d87e4, 4'hf);
		wb_write(32'h40002020, 32'hff5c0f0e, 4'hf);
		wb_write(32'h40002024, 32'h00001196, 4'hf);
		wb_write(32'h40002028, 32'hff7c8079, 4'hf);
		wb_write(32'h4000202c, 32'hffcb0391, 4'hf);
		wb_write(32'h40002030, 32'hffffff9c, 4'hf);
		wb_write(32'h40002034, 32'h0002ed57, 4'hf);
		wb_write(32'h40002038, 32'h000f0601, 4'hf);
		wb_write(32'h4000203c, 32'h00000000, 4'hf);
		wb_write(32'h40002040, 32'h00000000, 4'hf);
		wb_write(32'h40002044, 32'h00800000, 4'hf);
		wb_write(32'h40002048, 32'hffffed73, 4'hf);
		wb_write(32'h4000204c, 32'h008ac533, 4'hf);
		wb_write(32'h40002050, 32'h0190ae1e, 4'hf);
		wb_write(32'h40002054, 32'hffffa794, 4'hf);
		wb_write(32'h40002058, 32'h0296d31c, 4'hf);
		wb_write(32'h4000205c, 32'h01ff337a, 4'hf);
		wb_write(32'h40002060, 32'h00000000, 4'hf);
		wb_write(32'h40002064, 32'h00000226, 4'hf);
		wb_write(32'h40002068, 32'h000ae755, 4'hf);
		wb_write(32'h4000206c, 32'h00000000, 4'hf);
		wb_write(32'h40002070, 32'h00000000, 4'hf);
		wb_write(32'h40002074, 32'h00800000, 4'hf);
		wb_write(32'h40002078, 32'h00002153, 4'hf);
		wb_write(32'h4000207c, 32'hff072c58, 4'hf);
		wb_write(32'h40002080, 32'hff823981, 4'hf);
		wb_write(32'h40002084, 32'h00004a2d, 4'hf);
		wb_write(32'h40002088, 32'hfdd368bb, 4'hf);
		wb_write(32'h4000208c, 32'hffac0613, 4'hf);
		wb_write(32'h40002090, 32'h00000135, 4'hf);
		wb_write(32'h40002094, 32'hfff6f383, 4'hf);
		wb_write(32'h40002098, 32'h00055c34, 4'hf);
		wb_write(32'h4000209c, 32'h00000000, 4'hf);
		wb_write(32'h400020a0, 32'h00000000, 4'hf);
		wb_write(32'h400020a4, 32'h00800000, 4'hf);
		wb_write(32'h400020a8, 32'h0000ac22, 4'hf);
		wb_write(32'h400020ac, 32'hfaf5af6e, 4'hf);
		wb_write(32'h400020b0, 32'hfd07edf4, 4'hf);
		wb_write(32'h400020b4, 32'hffffb7ca, 4'hf);
		wb_write(32'h400020b8, 32'h021da59d, 4'hf);
		wb_write(32'h400020bc, 32'h014692e0, 4'hf);
		wb_write(32'h400020c0, 32'h00000000, 4'hf);
		wb_write(32'h400020c4, 32'h0000014a, 4'hf);
		wb_write(32'h400020c8, 32'h00068acc, 4'hf);
		wb_write(32'h400020cc, 32'h00000000, 4'hf);
		wb_write(32'h400020d0, 32'h00000000, 4'hf);
		wb_write(32'h400020d4, 32'h00800000, 4'hf);
		wb_write(32'h400020d8, 32'h00002106, 4'hf);
		wb_write(32'h400020dc, 32'hff091188, 4'hf);
		wb_write(32'h400020e0, 32'hfdbbd830, 4'hf);
		wb_write(32'h400020e4, 32'hffffab8f, 4'hf);
		wb_write(32'h400020e8, 32'h02794246, 4'hf);
		wb_write(32'h400020ec, 32'h00acd0ba, 4'hf);
		wb_write(32'h400020f0, 32'h000001e5, 4'hf);
		wb_write(32'h400020f4, 32'hfff1cc16, 4'hf);
		wb_write(32'h400020f8, 32'h00086978, 4'hf);
		wb_write(32'h400020fc, 32'h00000000, 4'hf);
		wb_write(32'h40002100, 32'h00000000, 4'hf);
		wb_write(32'h40002104, 32'h00800000, 4'hf);
		wb_write(32'h40002108, 32'h0000d6d1, 4'hf);
		wb_write(32'h4000210c, 32'hf9b5ae53, 4'hf);
		wb_write(32'h40002110, 32'hfe9a8168, 4'hf);
		wb_write(32'h40002114, 32'h00004378, 4'hf);
		wb_write(32'h40002118, 32'hfe05e805, 4'hf);
		wb_write(32'h4000211c, 32'h00a76ee9, 4'hf);
		wb_write(32'h40002120, 32'hffffed78, 4'hf);
		wb_write(32'h40002124, 32'h008ae908, 4'hf);
		wb_write(32'h40002128, 32'h005b776a, 4'hf);
		wb_write(32'h4000212c, 32'h00000000, 4'hf);
		wb_write(32'h40002130, 32'h00000000, 4'hf);
		wb_write(32'h40002134, 32'h00800000, 4'hf);
		wb_write(32'h40002138, 32'hfff20239, 4'hf);
		wb_write(32'h4000213c, 32'h68e132ce, 4'hf);
		wb_write(32'h40002140, 32'h3b750a80, 4'hf);
		wb_write(32'h40002144, 32'h0006c72e, 4'hf);
		wb_write(32'h40002148, 32'hcd319d95, 4'hf);
		wb_write(32'h4000214c, 32'he23475c0, 4'hf);
		wb_write(32'h40002150, 32'hfffffab7, 4'hf);
		wb_write(32'h40002154, 32'h00279e17, 4'hf);
		wb_write(32'h40002158, 32'h001a1862, 4'hf);
		wb_write(32'h4000215c, 32'h00000000, 4'hf);
		wb_write(32'h40002160, 32'h00000000, 4'hf);
		wb_write(32'h40002164, 32'h00800000, 4'hf);
		wb_write(32'h40002168, 32'hfffe0dd6, 4'hf);
		wb_write(32'h4000216c, 32'h0e95b606, 4'hf);
		wb_write(32'h40002170, 32'h06edd820, 4'hf);
		wb_write(32'h40002174, 32'h00040c15, 4'hf);
		wb_write(32'h40002178, 32'he1a95597, 4'hf);
		wb_write(32'h4000217c, 32'hf6afe400, 4'hf);
		wb_write(32'h40002180, 32'h00000000, 4'hf);
		wb_write(32'h40002184, 32'h000001d7, 4'hf);
		wb_write(32'h40002188, 32'h00095892, 4'hf);
		wb_write(32'h4000218c, 32'h00000000, 4'hf);
		wb_write(32'h40002190, 32'h00000000, 4'hf);
		wb_write(32'h40002194, 32'h00800000, 4'hf);
		wb_write(32'h40002198, 32'hffff72de, 4'hf);
		wb_write(32'h4000219c, 32'h0421e07c, 4'hf);
		wb_write(32'h400021a0, 32'h02716a28, 4'hf);
		wb_write(32'h400021a4, 32'hfffff524, 4'hf);
		wb_write(32'h400021a8, 32'h0052ec26, 4'hf);
		wb_write(32'h400021ac, 32'hfdbd3c54, 4'hf);
		wb_write(32'h400021b0, 32'h0000000f, 4'hf);
		wb_write(32'h400021b4, 32'hffff8f47, 4'hf);
		wb_write(32'h400021b8, 32'h000de806, 4'hf);
		wb_write(32'h400021bc, 32'h00000000, 4'hf);
		wb_write(32'h400021c0, 32'h00000000, 4'hf);
		wb_write(32'h400021c4, 32'h00800000, 4'hf);
		wb_write(32'h400021c8, 32'hffff6d0b, 4'hf);
		wb_write(32'h400021cc, 32'h044d994d, 4'hf);
		wb_write(32'h400021d0, 32'h026515c8, 4'hf);
		wb_write(32'h400021d4, 32'hfffffaf1, 4'hf);
		wb_write(32'h400021d8, 32'h00267dbe, 4'hf);
		wb_write(32'h400021dc, 32'hfeca180c, 4'hf);
		wb_write(32'h400021e0, 32'h00000000, 4'hf);
		wb_write(32'h400021e4, 32'h0000016e, 4'hf);
		wb_write(32'h400021e8, 32'h000744e3, 4'hf);
		wb_write(32'h400021ec, 32'h00000000, 4'hf);
		wb_write(32'h400021f0, 32'h00000000, 4'hf);
		wb_write(32'h400021f4, 32'h00800000, 4'hf);
		wb_write(32'h400021f8, 32'hffff5fc1, 4'hf);
		wb_write(32'h400021fc, 32'h04b1280f, 4'hf);
		wb_write(32'h40002200, 32'h02d81000, 4'hf);
		wb_write(32'h40002204, 32'h00000a44, 4'hf);
		wb_write(32'h40002208, 32'hffb1c726, 4'hf);
		wb_write(32'h4000220c, 32'h04ed97c8, 4'hf);
		wb_write(32'h40002210, 32'h0000000d, 4'hf);
		wb_write(32'h40002214, 32'hffff9e4c, 4'hf);
		wb_write(32'h40002218, 32'h000c7ca9, 4'hf);
		wb_write(32'h4000221c, 32'h00000000, 4'hf);
		wb_write(32'h40002220, 32'h00000000, 4'hf);
		wb_write(32'h40002224, 32'h00800000, 4'hf);
		wb_write(32'h40002228, 32'hffff64a9, 4'hf);
		wb_write(32'h4000222c, 32'h048c6f9b, 4'hf);
		wb_write(32'h40002230, 32'h029421b8, 4'hf);
		wb_write(32'h40002234, 32'h00000403, 4'hf);
		wb_write(32'h40002238, 32'hffe14f8c, 4'hf);
		wb_write(32'h4000223c, 32'h01ecb1ca, 4'hf);
		wb_write(32'h40003000, 32'h0000000f, 4'hf);
		wb_write(32'h40003004, 32'h0000000c, 4'hf);
		wb_write(32'h40003008, 32'h000000f0, 4'hf);
		wb_write(32'h4000300c, 32'h00000030, 4'hf);
		wb_write(32'h40003010, 32'h00000348, 4'hf);
		wb_write(32'h40003014, 32'h00000240, 4'hf);
		wb_write(32'h40003018, 32'h00000584, 4'hf);
		wb_write(32'h4000301c, 32'h00000180, 4'hf);
		wb_write(32'h40003020, 32'h00000c12, 4'hf);
		wb_write(32'h40003024, 32'h00000402, 4'hf);
		wb_write(32'h40003028, 32'h00000a21, 4'hf);
		wb_write(32'h4000302c, 32'h00000801, 4'hf);
		wb_write(32'h40003030, 32'h0000f000, 4'hf);
		wb_write(32'h40003034, 32'h0000c000, 4'hf);
		wb_write(32'h40003038, 32'h000f0000, 4'hf);
		wb_write(32'h4000303c, 32'h00030000, 4'hf);
		wb_write(32'h40003040, 32'h00348000, 4'hf);
		wb_write(32'h40003044, 32'h00240000, 4'hf);
		wb_write(32'h40003048, 32'h00584000, 4'hf);
		wb_write(32'h4000304c, 32'h00180000, 4'hf);
		wb_write(32'h40003050, 32'h00c12000, 4'hf);
		wb_write(32'h40003054, 32'h00402000, 4'hf);
		wb_write(32'h40003058, 32'h00a21000, 4'hf);
		wb_write(32'h4000305c, 32'h00801000, 4'hf);
	end
	
	if ( X_NUM == 640 ) begin
		// VGA
		wb_write(32'h40001000, 32'hffffea7d, 4'hf);
		wb_write(32'h40001004, 32'h0035b2e4, 4'hf);
		wb_write(32'h40001008, 32'h0006f21c, 4'hf);
		wb_write(32'h4000100c, 32'h000003d7, 4'hf);
		wb_write(32'h40001010, 32'hfff67ca8, 4'hf);
		wb_write(32'h40001014, 32'hffe3a0ba, 4'hf);
		wb_write(32'h40001018, 32'hffffebba, 4'hf);
		wb_write(32'h4000101c, 32'h00329a74, 4'hf);
		wb_write(32'h40001020, 32'h001f598b, 4'hf);
		wb_write(32'h40001024, 32'h0000029a, 4'hf);
		wb_write(32'h40001028, 32'hfff99518, 4'hf);
		wb_write(32'h4000102c, 32'hfffcb5b8, 4'hf);
		wb_write(32'h40001030, 32'h00000528, 4'hf);
		wb_write(32'h40001034, 32'hfff335a8, 4'hf);
		wb_write(32'h40001038, 32'hffd0aa68, 4'hf);
		wb_write(32'h4000103c, 32'hffffe76d, 4'hf);
		wb_write(32'h40001040, 32'h003d575a, 4'hf);
		wb_write(32'h40001044, 32'h00154504, 4'hf);
		wb_write(32'h40001048, 32'h00000391, 4'hf);
		wb_write(32'h4000104c, 32'hfff72f0b, 4'hf);
		wb_write(32'h40001050, 32'hfff0dc68, 4'hf);
		wb_write(32'h40001054, 32'hffffe904, 4'hf);
		wb_write(32'h40001058, 32'h00395df7, 4'hf);
		wb_write(32'h4000105c, 32'h00340e36, 4'hf);
		wb_write(32'h40001060, 32'hfffffa35, 4'hf);
		wb_write(32'h40001064, 32'h000e80f3, 4'hf);
		wb_write(32'h40001068, 32'h00096670, 4'hf);
		wb_write(32'h4000106c, 32'hfffff93e, 4'hf);
		wb_write(32'h40001070, 32'h0010e700, 4'hf);
		wb_write(32'h40001074, 32'h00011f68, 4'hf);
		wb_write(32'h40001078, 32'hfffff77f, 4'hf);
		wb_write(32'h4000107c, 32'h00154476, 4'hf);
		wb_write(32'h40001080, 32'h0000251b, 4'hf);
		wb_write(32'h40001084, 32'hfffff62e, 4'hf);
		wb_write(32'h40001088, 32'h00188b76, 4'hf);
		wb_write(32'h4000108c, 32'hfff798a4, 4'hf);
		wb_write(32'h40001090, 32'hfffff47b, 4'hf);
		wb_write(32'h40001094, 32'h001cc0de, 4'hf);
		wb_write(32'h40001098, 32'h0010f48d, 4'hf);
		wb_write(32'h4000109c, 32'hfffffa6b, 4'hf);
		wb_write(32'h400010a0, 32'h000dee5a, 4'hf);
		wb_write(32'h400010a4, 32'h0008f1f7, 4'hf);
		wb_write(32'h400010a8, 32'hfffff390, 4'hf);
		wb_write(32'h400010ac, 32'h001f0b75, 4'hf);
		wb_write(32'h400010b0, 32'h0011e33a, 4'hf);
		wb_write(32'h400010b4, 32'hfffffb56, 4'hf);
		wb_write(32'h400010b8, 32'h000ba3c3, 4'hf);
		wb_write(32'h400010bc, 32'h00073e1a, 4'hf);
		wb_write(32'h400010c0, 32'hfffffa7e, 4'hf);
		wb_write(32'h400010c4, 32'h000dbdde, 4'hf);
		wb_write(32'h400010c8, 32'h00066c1f, 4'hf);
		wb_write(32'h400010cc, 32'hfffff489, 4'hf);
		wb_write(32'h400010d0, 32'h001c9e50, 4'hf);
		wb_write(32'h400010d4, 32'h00083a06, 4'hf);
		wb_write(32'h400010d8, 32'hfffffb65, 4'hf);
		wb_write(32'h400010dc, 32'h000b7d2e, 4'hf);
		wb_write(32'h400010e0, 32'h00049311, 4'hf);
		wb_write(32'h400010e4, 32'hfffff3a2, 4'hf);
		wb_write(32'h400010e8, 32'h001edf00, 4'hf);
		wb_write(32'h400010ec, 32'h00075e38, 4'hf);
		wb_write(32'h400010f0, 32'h0000005c, 4'hf);
		wb_write(32'h400010f4, 32'hffff0d81, 4'hf);
		wb_write(32'h400010f8, 32'h000c6452, 4'hf);
		wb_write(32'h400010fc, 32'h0000004d, 4'hf);
		wb_write(32'h40001100, 32'hffff3416, 4'hf);
		wb_write(32'h40001104, 32'h0007ef05, 4'hf);
		wb_write(32'h40001108, 32'h0000006e, 4'hf);
		wb_write(32'h4000110c, 32'hfffee10c, 4'hf);
		wb_write(32'h40001110, 32'h00157227, 4'hf);
		wb_write(32'h40001114, 32'h0000005b, 4'hf);
		wb_write(32'h40001118, 32'hffff1188, 4'hf);
		wb_write(32'h4000111c, 32'h000fb765, 4'hf);
		wb_write(32'h40002000, 32'hffffff4a, 4'hf);
		wb_write(32'h40002004, 32'h0001c5cc, 4'hf);
		wb_write(32'h40002008, 32'h000bccf2, 4'hf);
		wb_write(32'h4000200c, 32'h00000000, 4'hf);
		wb_write(32'h40002010, 32'h00000000, 4'hf);
		wb_write(32'h40002014, 32'h00800000, 4'hf);
		wb_write(32'h40002018, 32'h0000dda6, 4'hf);
		wb_write(32'h4000201c, 32'hfdd6b55f, 4'hf);
		wb_write(32'h40002020, 32'hffb869e8, 4'hf);
		wb_write(32'h40002024, 32'h00002793, 4'hf);
		wb_write(32'h40002028, 32'hff9df4d2, 4'hf);
		wb_write(32'h4000202c, 32'hffdb811c, 4'hf);
		wb_write(32'h40002030, 32'hffffff1e, 4'hf);
		wb_write(32'h40002034, 32'h00023382, 4'hf);
		wb_write(32'h40002038, 32'h000ea7c1, 4'hf);
		wb_write(32'h4000203c, 32'h00000000, 4'hf);
		wb_write(32'h40002040, 32'h00000000, 4'hf);
		wb_write(32'h40002044, 32'h00800000, 4'hf);
		wb_write(32'h40002048, 32'hffffd642, 4'hf);
		wb_write(32'h4000204c, 32'h00678b52, 4'hf);
		wb_write(32'h40002050, 32'h017f4954, 4'hf);
		wb_write(32'h40002054, 32'hffff390c, 4'hf);
		wb_write(32'h40002058, 32'h01f09e7f, 4'hf);
		wb_write(32'h4000205c, 32'h01ac4d66, 4'hf);
		wb_write(32'h40002060, 32'h00000000, 4'hf);
		wb_write(32'h40002064, 32'h000004d5, 4'hf);
		wb_write(32'h40002068, 32'h000ae755, 4'hf);
		wb_write(32'h4000206c, 32'h00000000, 4'hf);
		wb_write(32'h40002070, 32'h00000000, 4'hf);
		wb_write(32'h40002074, 32'h00800000, 4'hf);
		wb_write(32'h40002078, 32'h00004afc, 4'hf);
		wb_write(32'h4000207c, 32'hff470668, 4'hf);
		wb_write(32'h40002080, 32'hffa17833, 4'hf);
		wb_write(32'h40002084, 32'h0000a6e5, 4'hf);
		wb_write(32'h40002088, 32'hfe5e2684, 4'hf);
		wb_write(32'h4000208c, 32'hfff19075, 4'hf);
		wb_write(32'h40002090, 32'h000002b8, 4'hf);
		wb_write(32'h40002094, 32'hfff93646, 4'hf);
		wb_write(32'h40002098, 32'h00067e7a, 4'hf);
		wb_write(32'h4000209c, 32'h00000000, 4'hf);
		wb_write(32'h400020a0, 32'h00000000, 4'hf);
		wb_write(32'h400020a4, 32'h00800000, 4'hf);
		wb_write(32'h400020a8, 32'h0001834d, 4'hf);
		wb_write(32'h400020ac, 32'hfc3947f9, 4'hf);
		wb_write(32'h400020b0, 32'hfda94e34, 4'hf);
		wb_write(32'h400020b4, 32'hffff5d85, 4'hf);
		wb_write(32'h400020b8, 32'h019658e1, 4'hf);
		wb_write(32'h400020bc, 32'h0102df96, 4'hf);
		wb_write(32'h400020c0, 32'h00000000, 4'hf);
		wb_write(32'h400020c4, 32'h000002e6, 4'hf);
		wb_write(32'h400020c8, 32'h00068acc, 4'hf);
		wb_write(32'h400020cc, 32'h00000000, 4'hf);
		wb_write(32'h400020d0, 32'h00000000, 4'hf);
		wb_write(32'h400020d4, 32'h00800000, 4'hf);
		wb_write(32'h400020d8, 32'h00004a4f, 4'hf);
		wb_write(32'h400020dc, 32'hff47e734, 4'hf);
		wb_write(32'h400020e0, 32'hfddacea0, 4'hf);
		wb_write(32'h400020e4, 32'hffff4201, 4'hf);
		wb_write(32'h400020e8, 32'h01dadfbe, 4'hf);
		wb_write(32'h400020ec, 32'h005da644, 4'hf);
		wb_write(32'h400020f0, 32'h00000445, 4'hf);
		wb_write(32'h400020f4, 32'hfff55712, 4'hf);
		wb_write(32'h400020f8, 32'h000a3104, 4'hf);
		wb_write(32'h400020fc, 32'h00000000, 4'hf);
		wb_write(32'h40002100, 32'h00000000, 4'hf);
		wb_write(32'h40002104, 32'h00800000, 4'hf);
		wb_write(32'h40002108, 32'h0001e356, 4'hf);
		wb_write(32'h4000210c, 32'hfb49781a, 4'hf);
		wb_write(32'h40002110, 32'hff63e5a4, 4'hf);
		wb_write(32'h40002114, 32'h000097ce, 4'hf);
		wb_write(32'h40002118, 32'hfe84500b, 4'hf);
		wb_write(32'h4000211c, 32'h00e6af78, 4'hf);
		wb_write(32'h40002120, 32'hffffd64e, 4'hf);
		wb_write(32'h40002124, 32'h00681250, 4'hf);
		wb_write(32'h40002128, 32'h004a17ad, 4'hf);
		wb_write(32'h4000212c, 32'h00000000, 4'hf);
		wb_write(32'h40002130, 32'h00000000, 4'hf);
		wb_write(32'h40002134, 32'h00800000, 4'hf);
		wb_write(32'h40002138, 32'hffe08507, 4'hf);
		wb_write(32'h4000213c, 32'h4e93a2b7, 4'hf);
		wb_write(32'h40002140, 32'h2e571480, 4'hf);
		wb_write(32'h40002144, 32'h000f4024, 4'hf);
		wb_write(32'h40002148, 32'hd9f070cd, 4'hf);
		wb_write(32'h4000214c, 32'he88f36a0, 4'hf);
		wb_write(32'h40002150, 32'hfffff41b, 4'hf);
		wb_write(32'h40002154, 32'h001db053, 4'hf);
		wb_write(32'h40002158, 32'h00152378, 4'hf);
		wb_write(32'h4000215c, 32'h00000000, 4'hf);
		wb_write(32'h40002160, 32'h00000000, 4'hf);
		wb_write(32'h40002164, 32'h00800000, 4'hf);
		wb_write(32'h40002168, 32'hfffb9f20, 4'hf);
		wb_write(32'h4000216c, 32'h0aec84cc, 4'hf);
		wb_write(32'h40002170, 32'h051acff0, 4'hf);
		wb_write(32'h40002174, 32'h00091b2f, 4'hf);
		wb_write(32'h40002178, 32'he944ed73, 4'hf);
		wb_write(32'h4000217c, 32'hfa7b3778, 4'hf);
		wb_write(32'h40002180, 32'h00000000, 4'hf);
		wb_write(32'h40002184, 32'h00000424, 4'hf);
		wb_write(32'h40002188, 32'h00095892, 4'hf);
		wb_write(32'h4000218c, 32'h00000000, 4'hf);
		wb_write(32'h40002190, 32'h00000000, 4'hf);
		wb_write(32'h40002194, 32'h00800000, 4'hf);
		wb_write(32'h40002198, 32'hfffec272, 4'hf);
		wb_write(32'h4000219c, 32'h03187e55, 4'hf);
		wb_write(32'h400021a0, 32'h01ed196c, 4'hf);
		wb_write(32'h400021a4, 32'hffffe790, 4'hf);
		wb_write(32'h400021a8, 32'h00406ad4, 4'hf);
		wb_write(32'h400021ac, 32'hfdb30da8, 4'hf);
		wb_write(32'h400021b0, 32'h00000022, 4'hf);
		wb_write(32'h400021b4, 32'hffffaa7f, 4'hf);
		wb_write(32'h400021b8, 32'h000df643, 4'hf);
		wb_write(32'h400021bc, 32'h00000000, 4'hf);
		wb_write(32'h400021c0, 32'h00000000, 4'hf);
		wb_write(32'h400021c4, 32'h00800000, 4'hf);
		wb_write(32'h400021c8, 32'hfffeb559, 4'hf);
		wb_write(32'h400021cc, 32'h0339540d, 4'hf);
		wb_write(32'h400021d0, 32'h01db4fee, 4'hf);
		wb_write(32'h400021d4, 32'hfffff49e, 4'hf);
		wb_write(32'h400021d8, 32'h001db2cd, 4'hf);
		wb_write(32'h400021dc, 32'hfec559ec, 4'hf);
		wb_write(32'h400021e0, 32'h00000000, 4'hf);
		wb_write(32'h400021e4, 32'h00000339, 4'hf);
		wb_write(32'h400021e8, 32'h000744e3, 4'hf);
		wb_write(32'h400021ec, 32'h00000000, 4'hf);
		wb_write(32'h400021f0, 32'h00000000, 4'hf);
		wb_write(32'h400021f4, 32'h00800000, 4'hf);
		wb_write(32'h400021f8, 32'hfffe9772, 4'hf);
		wb_write(32'h400021fc, 32'h0383d600, 4'hf);
		wb_write(32'h40002200, 32'h0241d488, 4'hf);
		wb_write(32'h40002204, 32'h0000171a, 4'hf);
		wb_write(32'h40002208, 32'hffc37a96, 4'hf);
		wb_write(32'h4000220c, 32'h04f73808, 4'hf);
		wb_write(32'h40002210, 32'h0000001e, 4'hf);
		wb_write(32'h40002214, 32'hffffb48c, 4'hf);
		wb_write(32'h40002218, 32'h000c8972, 4'hf);
		wb_write(32'h4000221c, 32'h00000000, 4'hf);
		wb_write(32'h40002220, 32'h00000000, 4'hf);
		wb_write(32'h40002224, 32'h00800000, 4'hf);
		wb_write(32'h40002228, 32'hfffea27c, 4'hf);
		wb_write(32'h4000222c, 32'h036868fb, 4'hf);
		wb_write(32'h40002230, 32'h02027ff4, 4'hf);
		wb_write(32'h40002234, 32'h00000908, 4'hf);
		wb_write(32'h40002238, 32'hffe8119c, 4'hf);
		wb_write(32'h4000223c, 32'h01f07560, 4'hf);
		wb_write(32'h40003000, 32'h0000000f, 4'hf);
		wb_write(32'h40003004, 32'h0000000c, 4'hf);
		wb_write(32'h40003008, 32'h000000f0, 4'hf);
		wb_write(32'h4000300c, 32'h00000030, 4'hf);
		wb_write(32'h40003010, 32'h00000348, 4'hf);
		wb_write(32'h40003014, 32'h00000240, 4'hf);
		wb_write(32'h40003018, 32'h00000584, 4'hf);
		wb_write(32'h4000301c, 32'h00000180, 4'hf);
		wb_write(32'h40003020, 32'h00000c12, 4'hf);
		wb_write(32'h40003024, 32'h00000402, 4'hf);
		wb_write(32'h40003028, 32'h00000a21, 4'hf);
		wb_write(32'h4000302c, 32'h00000801, 4'hf);
		wb_write(32'h40003030, 32'h0000f000, 4'hf);
		wb_write(32'h40003034, 32'h0000c000, 4'hf);
		wb_write(32'h40003038, 32'h000f0000, 4'hf);
		wb_write(32'h4000303c, 32'h00030000, 4'hf);
		wb_write(32'h40003040, 32'h00348000, 4'hf);
		wb_write(32'h40003044, 32'h00240000, 4'hf);
		wb_write(32'h40003048, 32'h00584000, 4'hf);
		wb_write(32'h4000304c, 32'h00180000, 4'hf);
		wb_write(32'h40003050, 32'h00c12000, 4'hf);
		wb_write(32'h40003054, 32'h00402000, 4'hf);
		wb_write(32'h40003058, 32'h00a21000, 4'hf);
		wb_write(32'h4000305c, 32'h00801000, 4'hf);
	end
	
	#100
		$display("start");
		wb_write(32'h4000_0004, 32'h0000_0000, 4'b1111);
		wb_write(32'h4000_0000, 32'h0000_0001, 4'b1111);
	
	#100000000
		$finish();
	end
	
	
	
endmodule


`default_nettype wire


// end of file
