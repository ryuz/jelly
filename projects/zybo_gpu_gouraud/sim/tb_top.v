// ---------------------------------------------------------------------------
//
//                                      Copyright (C) 2015 by Ryuji Fuchikami
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
		$dumpvars(0, tb_top.i_top.i_gpu_gouraud);
	
	#100000000
		$finish;
	end
	
	
	reg		clk125 = 1'b1;
	always #(RATE125/2.0)	clk125 = ~clk125;
	
	
	// TOP
	top
			#(
				.HDMI_TX	(0)
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
	
	
	integer		fp;
	initial begin
		 fp = $fopen("out_img.ppm", "w");
		 $fdisplay(fp, "P3");
		 $fdisplay(fp, "%d %d", 640, 480);
		 $fdisplay(fp, "255");
	end
	
	always @(posedge vout_clk) begin
		if ( !vout_reset && axi4s_vout_tvalid && axi4s_vout_tready ) begin
			 $fdisplay(fp, "%d %d %d",
			 	axi4s_vout_tdata[8*0 +: 8],
			 	axi4s_vout_tdata[8*1 +: 8],
			 	axi4s_vout_tdata[8*2 +: 8]);
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
		wb_read(32'h4000_0010);
		$display("[bank1]");
		$display("edge");
		wb_write(32'h4000_5000, 32'hfffff74f, 4'b1111);
		wb_write(32'h4000_5004, 32'h0015b1fe, 4'b1111);
		wb_write(32'h4000_5008, 32'h00090905, 4'b1111);
		wb_write(32'h4000_500c, 32'hffffff1b, 4'b1111);
		wb_write(32'h4000_5010, 32'h000243dd, 4'b1111);
		wb_write(32'h4000_5014, 32'hfff8146a, 4'b1111);
		wb_write(32'h4000_5018, 32'hfffff705, 4'b1111);
		wb_write(32'h4000_501c, 32'h00166a2f, 4'b1111);
		wb_write(32'h4000_5020, 32'h000e8a0e, 4'b1111);
		wb_write(32'h4000_5024, 32'hffffff65, 4'b1111);
		wb_write(32'h4000_5028, 32'h00018bac, 4'b1111);
		wb_write(32'h4000_502c, 32'hfffbf927, 4'b1111);
		wb_write(32'h4000_5030, 32'hfffffec5, 4'b1111);
		wb_write(32'h4000_5034, 32'h00031bdb, 4'b1111);
		wb_write(32'h4000_5038, 32'hfff45ade, 4'b1111);
		wb_write(32'h4000_503c, 32'hfffff608, 4'b1111);
		wb_write(32'h4000_5040, 32'h0018e275, 4'b1111);
		wb_write(32'h4000_5044, 32'h00083a84, 4'b1111);
		wb_write(32'h4000_5048, 32'hffffff27, 4'b1111);
		wb_write(32'h4000_504c, 32'h000227f1, 4'b1111);
		wb_write(32'h4000_5050, 32'hfff97d9b, 4'b1111);
		wb_write(32'h4000_5054, 32'hfffff5a6, 4'b1111);
		wb_write(32'h4000_5058, 32'h0019d65f, 4'b1111);
		wb_write(32'h4000_505c, 32'h000fbccd, 4'b1111);
		wb_write(32'h4000_5060, 32'hfffffd02, 4'b1111);
		wb_write(32'h4000_5064, 32'h00077669, 4'b1111);
		wb_write(32'h4000_5068, 32'h0005b10f, 4'b1111);
		wb_write(32'h4000_506c, 32'hfffffd40, 4'b1111);
		wb_write(32'h4000_5070, 32'h0006da24, 4'b1111);
		wb_write(32'h4000_5074, 32'h00048a9f, 4'b1111);
		wb_write(32'h4000_5078, 32'hfffffba3, 4'b1111);
		wb_write(32'h4000_507c, 32'h000ae299, 4'b1111);
		wb_write(32'h4000_5080, 32'h0008a117, 4'b1111);
		wb_write(32'h4000_5084, 32'hfffffbf9, 4'b1111);
		wb_write(32'h4000_5088, 32'h000a0a9b, 4'b1111);
		wb_write(32'h4000_508c, 32'h00075be9, 4'b1111);
		
		
		$display("polygon(tuv)");
		wb_write(32'h4000_6000, 32'h0000000d, 4'b1111);
		wb_write(32'h4000_6004, 32'hffffdf7b, 4'b1111);
		wb_write(32'h4000_6008, 32'h0000a897, 4'b1111);
		wb_write(32'h4000_600c, 32'hffffffec, 4'b1111);
		wb_write(32'h4000_6010, 32'h00003318, 4'b1111);
		wb_write(32'h4000_6014, 32'hffff75c6, 4'b1111);
		wb_write(32'h4000_6018, 32'h00000148, 4'b1111);
		wb_write(32'h4000_601c, 32'hfffccd41, 4'b1111);
		wb_write(32'h4000_6020, 32'hfffeaaba, 4'b1111);
		wb_write(32'h4000_6024, 32'h00000010, 4'b1111);
		wb_write(32'h4000_6028, 32'hffffd7fa, 4'b1111);
		wb_write(32'h4000_602c, 32'h0000ce0e, 4'b1111);
		wb_write(32'h4000_6030, 32'hfffffec3, 4'b1111);
		wb_write(32'h4000_6034, 32'h0003173b, 4'b1111);
		wb_write(32'h4000_6038, 32'h0001e1c4, 4'b1111);
		wb_write(32'h4000_603c, 32'h0000002a, 4'b1111);
		wb_write(32'h4000_6040, 32'hffff95e1, 4'b1111);
		wb_write(32'h4000_6044, 32'h0001907c, 4'b1111);
		wb_write(32'h4000_6048, 32'h00000000, 4'b1111);
		wb_write(32'h4000_604c, 32'h000000b5, 4'b1111);
		wb_write(32'h4000_6050, 32'h00004c70, 4'b1111);
		wb_write(32'h4000_6054, 32'h00000130, 4'b1111);
		wb_write(32'h4000_6058, 32'hfffd0a88, 4'b1111);
		wb_write(32'h4000_605c, 32'hfffe0976, 4'b1111);
		wb_write(32'h4000_6060, 32'hffffffb4, 4'b1111);
		wb_write(32'h4000_6064, 32'h0000c203, 4'b1111);
		wb_write(32'h4000_6068, 32'hfffe0529, 4'b1111);
		wb_write(32'h4000_606c, 32'hfffffe6a, 4'b1111);
		wb_write(32'h4000_6070, 32'h0003f548, 4'b1111);
		wb_write(32'h4000_6074, 32'h0003506a, 4'b1111);
		wb_write(32'h4000_6078, 32'h00000261, 4'b1111);
		wb_write(32'h4000_607c, 32'hfffa1125, 4'b1111);
		wb_write(32'h4000_6080, 32'hfffb7a0a, 4'b1111);
		wb_write(32'h4000_6084, 32'hfffff6fb, 4'b1111);
		wb_write(32'h4000_6088, 32'h00168326, 4'b1111);
		wb_write(32'h4000_608c, 32'h000e9b06, 4'b1111);
		wb_write(32'h4000_6090, 32'h00000000, 4'b1111);
		wb_write(32'h4000_6094, 32'h0000006d, 4'b1111);
		wb_write(32'h4000_6098, 32'h00002ddd, 4'b1111);
		wb_write(32'h4000_609c, 32'hfffffed0, 4'b1111);
		wb_write(32'h4000_60a0, 32'h0002f665, 4'b1111);
		wb_write(32'h4000_60a4, 32'h000259ea, 4'b1111);
		wb_write(32'h4000_60a8, 32'hffffffb4, 4'b1111);
		wb_write(32'h4000_60ac, 32'h0000c072, 4'b1111);
		wb_write(32'h4000_60b0, 32'hfffd5cfe, 4'b1111);
		wb_write(32'h4000_60b4, 32'hffffff52, 4'b1111);
		wb_write(32'h4000_60b8, 32'h0001b244, 4'b1111);
		wb_write(32'h4000_60bc, 32'h00016b9b, 4'b1111);
		wb_write(32'h4000_60c0, 32'hfffffe4d, 4'b1111);
		wb_write(32'h4000_60c4, 32'h00043c98, 4'b1111);
		wb_write(32'h4000_60c8, 32'h00031a5b, 4'b1111);
		wb_write(32'h4000_60cc, 32'hfffffbf7, 4'b1111);
		wb_write(32'h4000_60d0, 32'h000a128d, 4'b1111);
		wb_write(32'h4000_60d4, 32'h00043094, 4'b1111);
		
		
		$display("polygon(rgb)");
		wb_write(32'h4000_6000, 32'h00000000, 4'b1111);
		wb_write(32'h4000_6004, 32'h00000000, 4'b1111);
		wb_write(32'h4000_6008, 32'h00080000, 4'b1111);
		wb_write(32'h4000_600c, 32'h00001f12, 4'b1111);
		wb_write(32'h4000_6010, 32'hffb27169, 4'b1111);
		wb_write(32'h4000_6014, 32'hffdfbf5b, 4'b1111);
		wb_write(32'h4000_6018, 32'hfffffcce, 4'b1111);
		wb_write(32'h4000_601c, 32'h00081753, 4'b1111);
		wb_write(32'h4000_6020, 32'hfff3a761, 4'b1111);
		wb_write(32'h4000_6024, 32'h00000000, 4'b1111);
		wb_write(32'h4000_6028, 32'h00000000, 4'b1111);
		wb_write(32'h4000_602c, 32'h00080000, 4'b1111);
		wb_write(32'h4000_6030, 32'h0000034f, 4'b1111);
		wb_write(32'h4000_6034, 32'hfff7a3fe, 4'b1111);
		wb_write(32'h4000_6038, 32'h001f56fb, 4'b1111);
		wb_write(32'h4000_603c, 32'hffffe525, 4'b1111);
		wb_write(32'h4000_6040, 32'h004309ca, 4'b1111);
		wb_write(32'h4000_6044, 32'h002628fa, 4'b1111);
		wb_write(32'h4000_6048, 32'h00000000, 4'b1111);
		wb_write(32'h4000_604c, 32'h00000000, 4'b1111);
		wb_write(32'h4000_6050, 32'h00080000, 4'b1111);
		wb_write(32'h4000_6054, 32'hfffffa50, 4'b1111);
		wb_write(32'h4000_6058, 32'h000e84be, 4'b1111);
		wb_write(32'h4000_605c, 32'hffda20c3, 4'b1111);
		wb_write(32'h4000_6060, 32'h00001c23, 4'b1111);
		wb_write(32'h4000_6064, 32'hffb9d39c, 4'b1111);
		wb_write(32'h4000_6068, 32'hffda828d, 4'b1111);
		wb_write(32'h4000_606c, 32'h00000000, 4'b1111);
		wb_write(32'h4000_6070, 32'h00000000, 4'b1111);
		wb_write(32'h4000_6074, 32'h00080000, 4'b1111);
		wb_write(32'h4000_6078, 32'hffff465f, 4'b1111);
		wb_write(32'h4000_607c, 32'h01cf51fe, 4'b1111);
		wb_write(32'h4000_6080, 32'h012c8572, 4'b1111);
		wb_write(32'h4000_6084, 32'h00005a34, 4'b1111);
		wb_write(32'h4000_6088, 32'hff1ef80d, 4'b1111);
		wb_write(32'h4000_608c, 32'hff5dba00, 4'b1111);
		wb_write(32'h4000_6090, 32'h00000000, 4'b1111);
		wb_write(32'h4000_6094, 32'h00000000, 4'b1111);
		wb_write(32'h4000_6098, 32'h00080000, 4'b1111);
		wb_write(32'h4000_609c, 32'hfffff99d, 4'b1111);
		wb_write(32'h4000_60a0, 32'h00102c19, 4'b1111);
		wb_write(32'h4000_60a4, 32'hffc75ca1, 4'b1111);
		wb_write(32'h4000_60a8, 32'hffffe338, 4'b1111);
		wb_write(32'h4000_60ac, 32'h0047c2be, 4'b1111);
		wb_write(32'h4000_60b0, 32'h00448cd4, 4'b1111);
		wb_write(32'h4000_60b4, 32'h00000000, 4'b1111);
		wb_write(32'h4000_60b8, 32'h00000000, 4'b1111);
		wb_write(32'h4000_60bc, 32'h00080000, 4'b1111);
		wb_write(32'h4000_60c0, 32'hffffaf23, 4'b1111);
		wb_write(32'h4000_60c4, 32'h00c9d95b, 4'b1111);
		wb_write(32'h4000_60c8, 32'h0053ef20, 4'b1111);
		wb_write(32'h4000_60cc, 32'hffffe669, 4'b1111);
		wb_write(32'h4000_60d0, 32'h003fc301, 4'b1111);
		wb_write(32'h4000_60d4, 32'h003a3af9, 4'b1111);
		
		
		$display("region");
		wb_write(32'h4000_7000, 32'h0000000f, 4'b1111);
		wb_write(32'h4000_7004, 32'h0000000c, 4'b1111);
		wb_write(32'h4000_7008, 32'h000000f0, 4'b1111);
		wb_write(32'h4000_700c, 32'h00000030, 4'b1111);
		wb_write(32'h4000_7010, 32'h00000348, 4'b1111);
		wb_write(32'h4000_7014, 32'h00000240, 4'b1111);
		wb_write(32'h4000_7018, 32'h00000584, 4'b1111);
		wb_write(32'h4000_701c, 32'h00000180, 4'b1111);
		wb_write(32'h4000_7020, 32'h00000c12, 4'b1111);
		wb_write(32'h4000_7024, 32'h00000402, 4'b1111);
		wb_write(32'h4000_7028, 32'h00000a21, 4'b1111);
		wb_write(32'h4000_702c, 32'h00000801, 4'b1111);
		
		$display("start");
		wb_write(32'h4000_0004, 32'h0000_0001, 4'b1111);
		wb_write(32'h4000_0000, 32'h0000_0001, 4'b1111);
		
		wb_read(32'h4000_0010);
		while ( reg_wb_dat != 1 ) begin
			wb_read(32'h4000_0010);
		end
		
		/*
		$display("[bank0]");
		$display("edge");
		wb_write(32'h4000_1000, 32'hfffff74f, 4'b1111);
		wb_write(32'h4000_1004, 32'h0015b1fe, 4'b1111);
		wb_write(32'h4000_1008, 32'h00090905, 4'b1111);
		wb_write(32'h4000_100c, 32'hffffff1b, 4'b1111);
		wb_write(32'h4000_1010, 32'h000243dd, 4'b1111);
		wb_write(32'h4000_1014, 32'hfff8146a, 4'b1111);
		wb_write(32'h4000_1018, 32'hfffff705, 4'b1111);
		wb_write(32'h4000_101c, 32'h00166a2f, 4'b1111);
		wb_write(32'h4000_1020, 32'h000e8a0e, 4'b1111);
		wb_write(32'h4000_1024, 32'hffffff65, 4'b1111);
		wb_write(32'h4000_1028, 32'h00018bac, 4'b1111);
		wb_write(32'h4000_102c, 32'hfffbf927, 4'b1111);
		wb_write(32'h4000_1030, 32'hfffffec5, 4'b1111);
		wb_write(32'h4000_1034, 32'h00031bdb, 4'b1111);
		wb_write(32'h4000_1038, 32'hfff45ade, 4'b1111);
		wb_write(32'h4000_103c, 32'hfffff608, 4'b1111);
		wb_write(32'h4000_1040, 32'h0018e275, 4'b1111);
		wb_write(32'h4000_1044, 32'h00083a84, 4'b1111);
		wb_write(32'h4000_1048, 32'hffffff27, 4'b1111);
		wb_write(32'h4000_104c, 32'h000227f1, 4'b1111);
		wb_write(32'h4000_1050, 32'hfff97d9b, 4'b1111);
		wb_write(32'h4000_1054, 32'hfffff5a6, 4'b1111);
		wb_write(32'h4000_1058, 32'h0019d65f, 4'b1111);
		wb_write(32'h4000_105c, 32'h000fbccd, 4'b1111);
		wb_write(32'h4000_1060, 32'hfffffd02, 4'b1111);
		wb_write(32'h4000_1064, 32'h00077669, 4'b1111);
		wb_write(32'h4000_1068, 32'h0005b10f, 4'b1111);
		wb_write(32'h4000_106c, 32'hfffffd40, 4'b1111);
		wb_write(32'h4000_1070, 32'h0006da24, 4'b1111);
		wb_write(32'h4000_1074, 32'h00048a9f, 4'b1111);
		wb_write(32'h4000_1078, 32'hfffffba3, 4'b1111);
		wb_write(32'h4000_107c, 32'h000ae299, 4'b1111);
		wb_write(32'h4000_1080, 32'h0008a117, 4'b1111);
		wb_write(32'h4000_1084, 32'hfffffbf9, 4'b1111);
		wb_write(32'h4000_1088, 32'h000a0a9b, 4'b1111);
		wb_write(32'h4000_108c, 32'h00075be9, 4'b1111);
		
		
		$display("polygon(tuv)");
		wb_write(32'h4000_2000, 32'h0000000d, 4'b1111);
		wb_write(32'h4000_2004, 32'hffffdf7b, 4'b1111);
		wb_write(32'h4000_2008, 32'h0000a897, 4'b1111);
		wb_write(32'h4000_200c, 32'hffffffec, 4'b1111);
		wb_write(32'h4000_2010, 32'h00003318, 4'b1111);
		wb_write(32'h4000_2014, 32'hffff75c6, 4'b1111);
		wb_write(32'h4000_2018, 32'h00000148, 4'b1111);
		wb_write(32'h4000_201c, 32'hfffccd41, 4'b1111);
		wb_write(32'h4000_2020, 32'hfffeaaba, 4'b1111);
		wb_write(32'h4000_2024, 32'h00000010, 4'b1111);
		wb_write(32'h4000_2028, 32'hffffd7fa, 4'b1111);
		wb_write(32'h4000_202c, 32'h0000ce0e, 4'b1111);
		wb_write(32'h4000_2030, 32'hfffffec3, 4'b1111);
		wb_write(32'h4000_2034, 32'h0003173b, 4'b1111);
		wb_write(32'h4000_2038, 32'h0001e1c4, 4'b1111);
		wb_write(32'h4000_203c, 32'h0000002a, 4'b1111);
		wb_write(32'h4000_2040, 32'hffff95e1, 4'b1111);
		wb_write(32'h4000_2044, 32'h0001907c, 4'b1111);
		wb_write(32'h4000_2048, 32'h00000000, 4'b1111);
		wb_write(32'h4000_204c, 32'h000000b5, 4'b1111);
		wb_write(32'h4000_2050, 32'h00004c70, 4'b1111);
		wb_write(32'h4000_2054, 32'h00000130, 4'b1111);
		wb_write(32'h4000_2058, 32'hfffd0a88, 4'b1111);
		wb_write(32'h4000_205c, 32'hfffe0976, 4'b1111);
		wb_write(32'h4000_2060, 32'hffffffb4, 4'b1111);
		wb_write(32'h4000_2064, 32'h0000c203, 4'b1111);
		wb_write(32'h4000_2068, 32'hfffe0529, 4'b1111);
		wb_write(32'h4000_206c, 32'hfffffe6a, 4'b1111);
		wb_write(32'h4000_2070, 32'h0003f548, 4'b1111);
		wb_write(32'h4000_2074, 32'h0003506a, 4'b1111);
		wb_write(32'h4000_2078, 32'h00000261, 4'b1111);
		wb_write(32'h4000_207c, 32'hfffa1125, 4'b1111);
		wb_write(32'h4000_2080, 32'hfffb7a0a, 4'b1111);
		wb_write(32'h4000_2084, 32'hfffff6fb, 4'b1111);
		wb_write(32'h4000_2088, 32'h00168326, 4'b1111);
		wb_write(32'h4000_208c, 32'h000e9b06, 4'b1111);
		wb_write(32'h4000_2090, 32'h00000000, 4'b1111);
		wb_write(32'h4000_2094, 32'h0000006d, 4'b1111);
		wb_write(32'h4000_2098, 32'h00002ddd, 4'b1111);
		wb_write(32'h4000_209c, 32'hfffffed0, 4'b1111);
		wb_write(32'h4000_20a0, 32'h0002f665, 4'b1111);
		wb_write(32'h4000_20a4, 32'h000259ea, 4'b1111);
		wb_write(32'h4000_20a8, 32'hffffffb4, 4'b1111);
		wb_write(32'h4000_20ac, 32'h0000c072, 4'b1111);
		wb_write(32'h4000_20b0, 32'hfffd5cfe, 4'b1111);
		wb_write(32'h4000_20b4, 32'hffffff52, 4'b1111);
		wb_write(32'h4000_20b8, 32'h0001b244, 4'b1111);
		wb_write(32'h4000_20bc, 32'h00016b9b, 4'b1111);
		wb_write(32'h4000_20c0, 32'hfffffe4d, 4'b1111);
		wb_write(32'h4000_20c4, 32'h00043c98, 4'b1111);
		wb_write(32'h4000_20c8, 32'h00031a5b, 4'b1111);
		wb_write(32'h4000_20cc, 32'hfffffbf7, 4'b1111);
		wb_write(32'h4000_20d0, 32'h000a128d, 4'b1111);
		wb_write(32'h4000_20d4, 32'h00043094, 4'b1111);
		
		
		$display("polygon(rgb)");
		wb_write(32'h4000_2000, 32'h00000000, 4'b1111);
		wb_write(32'h4000_2004, 32'h00000000, 4'b1111);
		wb_write(32'h4000_2008, 32'h00080000, 4'b1111);
		wb_write(32'h4000_200c, 32'h00001f12, 4'b1111);
		wb_write(32'h4000_2010, 32'hffb27169, 4'b1111);
		wb_write(32'h4000_2014, 32'hffdfbf5b, 4'b1111);
		wb_write(32'h4000_2018, 32'hfffffcce, 4'b1111);
		wb_write(32'h4000_201c, 32'h00081753, 4'b1111);
		wb_write(32'h4000_2020, 32'hfff3a761, 4'b1111);
		wb_write(32'h4000_2024, 32'h00000000, 4'b1111);
		wb_write(32'h4000_2028, 32'h00000000, 4'b1111);
		wb_write(32'h4000_202c, 32'h00080000, 4'b1111);
		wb_write(32'h4000_2030, 32'h0000034f, 4'b1111);
		wb_write(32'h4000_2034, 32'hfff7a3fe, 4'b1111);
		wb_write(32'h4000_2038, 32'h001f56fb, 4'b1111);
		wb_write(32'h4000_203c, 32'hffffe525, 4'b1111);
		wb_write(32'h4000_2040, 32'h004309ca, 4'b1111);
		wb_write(32'h4000_2044, 32'h002628fa, 4'b1111);
		wb_write(32'h4000_2048, 32'h00000000, 4'b1111);
		wb_write(32'h4000_204c, 32'h00000000, 4'b1111);
		wb_write(32'h4000_2050, 32'h00080000, 4'b1111);
		wb_write(32'h4000_2054, 32'hfffffa50, 4'b1111);
		wb_write(32'h4000_2058, 32'h000e84be, 4'b1111);
		wb_write(32'h4000_205c, 32'hffda20c3, 4'b1111);
		wb_write(32'h4000_2060, 32'h00001c23, 4'b1111);
		wb_write(32'h4000_2064, 32'hffb9d39c, 4'b1111);
		wb_write(32'h4000_2068, 32'hffda828d, 4'b1111);
		wb_write(32'h4000_206c, 32'h00000000, 4'b1111);
		wb_write(32'h4000_2070, 32'h00000000, 4'b1111);
		wb_write(32'h4000_2074, 32'h00080000, 4'b1111);
		wb_write(32'h4000_2078, 32'hffff465f, 4'b1111);
		wb_write(32'h4000_207c, 32'h01cf51fe, 4'b1111);
		wb_write(32'h4000_2080, 32'h012c8572, 4'b1111);
		wb_write(32'h4000_2084, 32'h00005a34, 4'b1111);
		wb_write(32'h4000_2088, 32'hff1ef80d, 4'b1111);
		wb_write(32'h4000_208c, 32'hff5dba00, 4'b1111);
		wb_write(32'h4000_2090, 32'h00000000, 4'b1111);
		wb_write(32'h4000_2094, 32'h00000000, 4'b1111);
		wb_write(32'h4000_2098, 32'h00080000, 4'b1111);
		wb_write(32'h4000_209c, 32'hfffff99d, 4'b1111);
		wb_write(32'h4000_20a0, 32'h00102c19, 4'b1111);
		wb_write(32'h4000_20a4, 32'hffc75ca1, 4'b1111);
		wb_write(32'h4000_20a8, 32'hffffe338, 4'b1111);
		wb_write(32'h4000_20ac, 32'h0047c2be, 4'b1111);
		wb_write(32'h4000_20b0, 32'h00448cd4, 4'b1111);
		wb_write(32'h4000_20b4, 32'h00000000, 4'b1111);
		wb_write(32'h4000_20b8, 32'h00000000, 4'b1111);
		wb_write(32'h4000_20bc, 32'h00080000, 4'b1111);
		wb_write(32'h4000_20c0, 32'hffffaf23, 4'b1111);
		wb_write(32'h4000_20c4, 32'h00c9d95b, 4'b1111);
		wb_write(32'h4000_20c8, 32'h0053ef20, 4'b1111);
		wb_write(32'h4000_20cc, 32'hffffe669, 4'b1111);
		wb_write(32'h4000_20d0, 32'h003fc301, 4'b1111);
		wb_write(32'h4000_20d4, 32'h003a3af9, 4'b1111);
		
		
		$display("region");
		wb_write(32'h4000_3000, 32'h0000000f, 4'b1111);
		wb_write(32'h4000_3004, 32'h0000000c, 4'b1111);
		wb_write(32'h4000_3008, 32'h000000f0, 4'b1111);
		wb_write(32'h4000_300c, 32'h00000030, 4'b1111);
		wb_write(32'h4000_3010, 32'h00000348, 4'b1111);
		wb_write(32'h4000_3014, 32'h00000240, 4'b1111);
		wb_write(32'h4000_3018, 32'h00000584, 4'b1111);
		wb_write(32'h4000_301c, 32'h00000180, 4'b1111);
		wb_write(32'h4000_3020, 32'h00000c12, 4'b1111);
		wb_write(32'h4000_3024, 32'h00000402, 4'b1111);
		wb_write(32'h4000_3028, 32'h00000a21, 4'b1111);
		wb_write(32'h4000_302c, 32'h00000801, 4'b1111);
		
		$display("start");
		wb_write(32'h4000_0004, 32'h0000_0000, 4'b1111);
		wb_write(32'h4000_0000, 32'h0000_0001, 4'b1111);
		*/
		
	#100000000
		$finish();
	end
	
	
	
endmodule


`default_nettype wire


// end of file
