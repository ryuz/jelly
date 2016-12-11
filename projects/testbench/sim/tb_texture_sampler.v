
`timescale 1ns / 1ps
`default_nettype none


module tb_texture_sampler();
	localparam RATE    = 1000.0/200.0;
	
	initial begin
		$dumpfile("tb_texture_sampler.vcd");
		$dumpvars(2, tb_texture_sampler);

//	#870000;
//		$dumpfile("tb_texture_sampler.vcd");
//		$dumpvars(0, tb_texture_sampler);
		
		#30000000;
			$display("!!!!TIME OUT!!!!");
			$finish;
	end
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		reset = 1'b1;
	initial #(RATE*100.5)	reset = 1'b0;
	
	
	
	parameter	COMPONENT_NUM                 = 3;
	parameter	DATA_WIDTH                    = 8;
	parameter	ADDR_WIDTH                    = 24;
	parameter	ADDR_X_WIDTH                  = 12;
	parameter	ADDR_Y_WIDTH                  = 12;
	
	parameter	USE_BORDER                    = 1;
	parameter	BORDER_DATA                   = {(COMPONENT_NUM*DATA_WIDTH){1'b0}};
	
	parameter	SAMPLER1D_NUM                 = 0;
	
	parameter	SAMPLER2D_NUM                 = 8;
//	parameter	SAMPLER2D_NUM                 = 32*2;
	parameter	SAMPLER2D_USER_WIDTH          = 0;
	parameter	SAMPLER2D_X_INT_WIDTH         = ADDR_X_WIDTH;
	parameter	SAMPLER2D_X_FRAC_WIDTH        = 4;
	parameter	SAMPLER2D_Y_INT_WIDTH         = ADDR_Y_WIDTH;
	parameter	SAMPLER2D_Y_FRAC_WIDTH        = 4;
	parameter	SAMPLER2D_COEFF_INT_WIDTH     = 1;
	parameter	SAMPLER2D_COEFF_FRAC_WIDTH    = SAMPLER2D_X_FRAC_WIDTH + SAMPLER2D_Y_FRAC_WIDTH;
	parameter	SAMPLER2D_S_REGS              = 1;
	parameter	SAMPLER2D_M_REGS              = 1;
	parameter	SAMPLER2D_USER_FIFO_PTR_WIDTH = 6;
	parameter	SAMPLER2D_USER_FIFO_RAM_TYPE  = "distributed";
	parameter	SAMPLER2D_USER_FIFO_M_REGS    = 0;
	parameter	SAMPLER2D_X_WIDTH             = SAMPLER2D_X_INT_WIDTH + SAMPLER2D_X_FRAC_WIDTH;
	parameter	SAMPLER2D_Y_WIDTH             = SAMPLER2D_Y_INT_WIDTH + SAMPLER2D_Y_FRAC_WIDTH;
	parameter	SAMPLER2D_COEFF_WIDTH         = SAMPLER2D_COEFF_INT_WIDTH + SAMPLER2D_COEFF_FRAC_WIDTH;
	parameter	SAMPLER2D_USER_BITS           = SAMPLER2D_USER_WIDTH > 0 ? SAMPLER2D_USER_WIDTH : 1;
	
	parameter	SAMPLER3D_NUM                 = 0;
	
	parameter	L1_CACHE_NUM                  = SAMPLER1D_NUM + SAMPLER2D_NUM + SAMPLER3D_NUM;
	parameter	L1_TAG_ADDR_WIDTH             = 10;
	parameter	L1_BLK_X_SIZE                 = 2;	// 0:1pixel; 1:2pixel; 2:4pixel; 3:8pixel ...
	parameter	L1_BLK_Y_SIZE                 = 2;	// 0:1pixel; 1:2pixel; 2:4pixel; 3:8pixel ...
	parameter	L1_TAG_RAM_TYPE               = "distributed";
	parameter	L1_MEM_RAM_TYPE               = "block";
	parameter	L1_DATA_WIDE_SIZE             = 2;
	
	parameter	L2_CACHE_X_SIZE               = 2;
	parameter	L2_CACHE_Y_SIZE               = 2;
	parameter	L2_CACHE_NUM                  = (1 << (L2_CACHE_X_SIZE + L2_CACHE_Y_SIZE));
	parameter	L2_TAG_ADDR_WIDTH             = 4;
	parameter	L2_BLK_X_SIZE                 = 3;	// 0:1pixel; 1:2pixel; 2:4pixel; 3:8pixel ...
	parameter	L2_BLK_Y_SIZE                 = 3;	// 0:1pixel; 1:2pixel; 2:4pixel; 3:8pixel ...
	parameter	L2_TAG_RAM_TYPE               = "distributed";
	parameter	L2_MEM_RAM_TYPE               = "block";
	
	parameter	M_AXI4_ID_WIDTH               = 6;
	parameter	M_AXI4_ADDR_WIDTH             = 32;
	parameter	M_AXI4_DATA_SIZE              = 3;	// 0:8bit; 1:16bit; 2:32bit; 3:64bit ...
	parameter	M_AXI4_DATA_WIDTH             = (8 << M_AXI4_DATA_SIZE);
	parameter	M_AXI4_LEN_WIDTH              = 8;
	parameter	M_AXI4_QOS_WIDTH              = 4;
	parameter	M_AXI4_ARID                   = {M_AXI4_ID_WIDTH{1'b0}};
	parameter	M_AXI4_ARSIZE                 = M_AXI4_DATA_SIZE;
	parameter	M_AXI4_ARBURST                = 2'b01;
	parameter	M_AXI4_ARLOCK                 = 1'b0;
	parameter	M_AXI4_ARCACHE                = 4'b0001;
	parameter	M_AXI4_ARPROT                 = 3'b000;
	parameter	M_AXI4_ARQOS                  = 0;
	parameter	M_AXI4_ARREGION               = 4'b0000;
	parameter	M_AXI4_REGS                   = 1;
	
	parameter	DEVICE                        = "RTL";
	
	
	initial begin
		i_axi4_slave_model.read_memh("axi4_mem.txt");
	end
	
	
	
	// 2D sampler
	wire	[SAMPLER2D_NUM*SAMPLER2D_USER_BITS-1:0]			s_sampler2d_user;
	wire	[SAMPLER2D_NUM*SAMPLER2D_X_WIDTH-1:0]			s_sampler2d_x;
	wire	[SAMPLER2D_NUM*SAMPLER2D_Y_WIDTH-1:0]			s_sampler2d_y;
	wire	[SAMPLER2D_NUM-1:0]								s_sampler2d_valid;
	wire	[SAMPLER2D_NUM-1:0]								s_sampler2d_ready;
	
	wire	[SAMPLER2D_NUM*SAMPLER2D_USER_BITS-1:0]			m_sampler2d_user;
	wire	[SAMPLER2D_NUM*COMPONENT_NUM*DATA_WIDTH-1:0]	m_sampler2d_data;
	wire	[SAMPLER2D_NUM-1:0]								m_sampler2d_valid;
	wire	[SAMPLER2D_NUM-1:0]								m_sampler2d_ready;
	
	
	parameter	LINE_SIZE     = 640;
	parameter	UNIT_SIZE     = (LINE_SIZE + (SAMPLER2D_NUM-1)) / SAMPLER2D_NUM;
	
	wire	[SAMPLER2D_NUM*(SAMPLER2D_Y_WIDTH+SAMPLER2D_X_WIDTH)-1:0]	s_samoler2d_packet;
	
	reg		[SAMPLER2D_Y_WIDTH-1:0]					src_x;
	reg		[SAMPLER2D_X_WIDTH-1:0]					src_y;
	reg												src_valid;
	wire											src_ready;
	
	wire	[COMPONENT_NUM*DATA_WIDTH-1:0]			sink_data;
	wire											sink_valid;
	reg												sink_ready = 1;
	
	integer		m00, m01, m02;
	integer		m10, m11, m12;
	initial begin
		m00 = $rtoi(16 *  0.7071);
		m01 = $rtoi(16 * -0.7071);
		m02 = $rtoi(16 * 263.42);
		m10 = $rtoi(16 * 0.7071);
		m11 = $rtoi(16 * 0.707);
		m12 = $rtoi(16 * -155.97);
	end
	
	wire		[SAMPLER2D_Y_WIDTH-1:0]				src_x_tmp = m00 * src_x + m01 * src_y + m02;
	wire		[SAMPLER2D_X_WIDTH-1:0]				src_y_tmp = m10 * src_x + m11 * src_y + m12;
//	wire		[SAMPLER2D_Y_WIDTH-1:0]				src_x_tmp = 16 * src_x;
//	wire		[SAMPLER2D_X_WIDTH-1:0]				src_y_tmp = 16 * src_y;
	
	always @(posedge clk) begin
		if ( reset ) begin
			src_x     <= 0;
			src_y     <= 0;
			src_valid <= 0;
		end
		else begin
			src_valid <= 1;
			if ( src_valid && src_ready ) begin
				src_x <= src_x + 1;
				if ( src_x == 640-1 ) begin
					src_x <= 0;
					src_y <= src_y + 1;
					if ( src_y == 480-1 ) begin
						src_x <= 0;
						src_y <= 0;
						src_valid <= 0;
					end
				end
			end
		end
	end
	
	
	jelly_data_scatter
			#(
				.PORT_NUM		(SAMPLER2D_NUM),
				.DATA_WIDTH		(SAMPLER2D_Y_WIDTH+SAMPLER2D_X_WIDTH),
				.LINE_SIZE		(LINE_SIZE),
				.UNIT_SIZE		(UNIT_SIZE),
				.FIFO_PTR_WIDTH	(12)
			)
		i_data_scatter
			(
				.reset			(reset),
				.clk			(clk),
				
				.s_data			({src_y_tmp, src_x_tmp}),
				.s_valid		(src_valid),
				.s_ready		(src_ready),
				
				.m_data			(s_samoler2d_packet),
				.m_valid		(s_sampler2d_valid),
				.m_ready		(s_sampler2d_ready)
			);
	
	genvar	i;
	generate
	for ( i = 0; i < SAMPLER2D_NUM; i = i+1 ) begin : loop_packet
		assign s_sampler2d_x[i*SAMPLER2D_X_WIDTH +: SAMPLER2D_X_WIDTH] = s_samoler2d_packet[i*(SAMPLER2D_Y_WIDTH+SAMPLER2D_X_WIDTH)+0                 +: SAMPLER2D_X_WIDTH];
		assign s_sampler2d_y[i*SAMPLER2D_Y_WIDTH +: SAMPLER2D_Y_WIDTH] = s_samoler2d_packet[i*(SAMPLER2D_Y_WIDTH+SAMPLER2D_X_WIDTH)+SAMPLER2D_X_WIDTH +: SAMPLER2D_Y_WIDTH];
	end
	endgenerate
	
	
	jelly_data_gather
			#(
				.PORT_NUM		(SAMPLER2D_NUM),
				.DATA_WIDTH		(COMPONENT_NUM*DATA_WIDTH),
				.LINE_SIZE		(LINE_SIZE),
				.UNIT_SIZE		(UNIT_SIZE),
				.FIFO_PTR_WIDTH	(12)
			)
		i_data_gather
			(
				.reset			(reset),
				.clk			(clk),
				
				.s_data			(m_sampler2d_data),
				.s_valid		(m_sampler2d_valid),
				.s_ready		(m_sampler2d_ready),
				
				.m_data			(sink_data),
				.m_valid		(sink_valid),
				.m_ready		(sink_ready)
			);
	
	
	integer		fp;
	initial begin
		fp = $fopen("out.ppm");
		$fdisplay(fp, "P3");
		$fdisplay(fp, "640 480");
		$fdisplay(fp, "255");
		$display("file open");
	end
	
	always @(posedge clk) begin
		if ( !reset ) begin
			if ( sink_valid && sink_ready ) begin
				$fdisplay(fp,  "%d %d %d", sink_data[7:0], sink_data[15:8], sink_data[23:16]);
			end
		end
	end
	
	
	
	
	
	
	// -----------------------------------------
	//  core
	// -----------------------------------------
	
	wire	[M_AXI4_ID_WIDTH-1:0]							axi4_arid;
	wire	[M_AXI4_ADDR_WIDTH-1:0]							axi4_araddr;
	wire	[M_AXI4_LEN_WIDTH-1:0]							axi4_arlen;
	wire	[2:0]											axi4_arsize;
	wire	[1:0]											axi4_arburst;
	wire	[0:0]											axi4_arlock;
	wire	[3:0]											axi4_arcache;
	wire	[2:0]											axi4_arprot;
	wire	[M_AXI4_QOS_WIDTH-1:0]							axi4_arqos;
	wire	[3:0]											axi4_arregion;
	wire													axi4_arvalid;
	wire													axi4_arready;
	wire	[M_AXI4_ID_WIDTH-1:0]							axi4_rid;
	wire	[M_AXI4_DATA_WIDTH-1:0]							axi4_rdata;
	wire	[1:0]											axi4_rresp;
	wire													axi4_rlast;
	wire													axi4_rvalid;
	wire													axi4_rready;
	
	jelly_texture_sampler
			#(
				.COMPONENT_NUM					(COMPONENT_NUM					),
				.DATA_WIDTH						(DATA_WIDTH						),
				.ADDR_WIDTH						(ADDR_WIDTH						),
				.ADDR_X_WIDTH					(ADDR_X_WIDTH					),
				.ADDR_Y_WIDTH					(ADDR_Y_WIDTH					),
				                                
				.USE_BORDER						(USE_BORDER						),
				.BORDER_DATA					(BORDER_DATA					),
				                                
				.SAMPLER1D_NUM					(SAMPLER1D_NUM					),
				                                
				.SAMPLER2D_NUM					(SAMPLER2D_NUM					),
				.SAMPLER2D_USER_WIDTH			(SAMPLER2D_USER_WIDTH			),
				.SAMPLER2D_X_INT_WIDTH			(SAMPLER2D_X_INT_WIDTH			),
				.SAMPLER2D_X_FRAC_WIDTH			(SAMPLER2D_X_FRAC_WIDTH			),
				.SAMPLER2D_Y_INT_WIDTH			(SAMPLER2D_Y_INT_WIDTH			),
				.SAMPLER2D_Y_FRAC_WIDTH			(SAMPLER2D_Y_FRAC_WIDTH			),
				.SAMPLER2D_COEFF_INT_WIDTH		(SAMPLER2D_COEFF_INT_WIDTH		),
				.SAMPLER2D_COEFF_FRAC_WIDTH		(SAMPLER2D_COEFF_FRAC_WIDTH		),
				.SAMPLER2D_S_REGS				(SAMPLER2D_S_REGS				),
				.SAMPLER2D_M_REGS				(SAMPLER2D_M_REGS				),
				.SAMPLER2D_USER_FIFO_PTR_WIDTH	(SAMPLER2D_USER_FIFO_PTR_WIDTH	),
				.SAMPLER2D_USER_FIFO_RAM_TYPE	(SAMPLER2D_USER_FIFO_RAM_TYPE	),
				.SAMPLER2D_USER_FIFO_M_REGS		(SAMPLER2D_USER_FIFO_M_REGS		),
				.SAMPLER2D_X_WIDTH				(SAMPLER2D_X_WIDTH				),
				.SAMPLER2D_Y_WIDTH				(SAMPLER2D_Y_WIDTH				),
				.SAMPLER2D_COEFF_WIDTH			(SAMPLER2D_COEFF_WIDTH			),
				.SAMPLER2D_USER_BITS			(SAMPLER2D_USER_BITS			),
				                                
				.SAMPLER3D_NUM					(SAMPLER3D_NUM					),
				                                
				.L1_CACHE_NUM					(L1_CACHE_NUM					),
				.L2_CACHE_X_SIZE				(L2_CACHE_X_SIZE				),
				.L2_CACHE_Y_SIZE				(L2_CACHE_Y_SIZE				),
				.L2_CACHE_NUM					(L2_CACHE_NUM					),
				                                
				.L1_TAG_ADDR_WIDTH				(L1_TAG_ADDR_WIDTH				),
				.L1_BLK_X_SIZE					(L1_BLK_X_SIZE					),
				.L1_BLK_Y_SIZE					(L1_BLK_Y_SIZE					),
				.L1_TAG_RAM_TYPE				(L1_TAG_RAM_TYPE				),
				.L1_MEM_RAM_TYPE				(L1_MEM_RAM_TYPE				),
				.L1_DATA_WIDE_SIZE				(L1_DATA_WIDE_SIZE				),
				                                
				.L2_TAG_ADDR_WIDTH				(L2_TAG_ADDR_WIDTH				),
				.L2_BLK_X_SIZE					(L2_BLK_X_SIZE					),
				.L2_BLK_Y_SIZE					(L2_BLK_Y_SIZE					),
				.L2_TAG_RAM_TYPE				(L2_TAG_RAM_TYPE				),
				.L2_MEM_RAM_TYPE				(L2_MEM_RAM_TYPE				),
				
				.M_AXI4_ID_WIDTH				(M_AXI4_ID_WIDTH),
				.M_AXI4_ADDR_WIDTH				(M_AXI4_ADDR_WIDTH),
				.M_AXI4_DATA_SIZE				(M_AXI4_DATA_SIZE),
				.M_AXI4_DATA_WIDTH				(M_AXI4_DATA_WIDTH),
				.M_AXI4_LEN_WIDTH				(M_AXI4_LEN_WIDTH),
				.M_AXI4_QOS_WIDTH				(M_AXI4_QOS_WIDTH),
				.M_AXI4_ARID					(M_AXI4_ARID),
				.M_AXI4_ARSIZE					(M_AXI4_ARSIZE),
				.M_AXI4_ARBURST					(M_AXI4_ARBURST),
				.M_AXI4_ARLOCK					(M_AXI4_ARLOCK),
				.M_AXI4_ARCACHE					(M_AXI4_ARCACHE),
				.M_AXI4_ARPROT					(M_AXI4_ARPROT),
				.M_AXI4_ARQOS					(M_AXI4_ARQOS),
				.M_AXI4_ARREGION				(M_AXI4_ARREGION),
				.M_AXI4_REGS					(M_AXI4_REGS),
				
				.DEVICE							(DEVICE),
				
				.L1_LOG_ENABLE					(0),
				.L2_LOG_ENABLE					(1)
			)
		i_texture_sampler
			(
				.reset							(reset),
				.clk							(clk),
				
				.endian							(1'b0),
				
				.param_addr						({32'h000a_0000, 32'h0005_0000, 32'h0000_0000}),
				.param_width					(640),
				.param_height					(480),
				.param_stride					(640*8),
				
				.clear_start					(0),
				.clear_busy						(),
				
				
				.s_sampler2d_user				(s_sampler2d_user),
				.s_sampler2d_x					(s_sampler2d_x),
				.s_sampler2d_y					(s_sampler2d_y),
				.s_sampler2d_valid				(s_sampler2d_valid),
				.s_sampler2d_ready				(s_sampler2d_ready),
				
				.m_sampler2d_user				(m_sampler2d_user),
				.m_sampler2d_data				(m_sampler2d_data),
				.m_sampler2d_valid				(m_sampler2d_valid),
				.m_sampler2d_ready				(m_sampler2d_ready),
				
				.m_axi4_arid					(axi4_arid),
				.m_axi4_araddr					(axi4_araddr),
				.m_axi4_arlen					(axi4_arlen),
				.m_axi4_arsize					(axi4_arsize),
				.m_axi4_arburst					(axi4_arburst),
				.m_axi4_arlock					(axi4_arlock),
				.m_axi4_arcache					(axi4_arcache),
				.m_axi4_arprot					(axi4_arprot),
				.m_axi4_arqos					(axi4_arqos),
				.m_axi4_arregion				(axi4_arregion),
				.m_axi4_arvalid					(axi4_arvalid),
				.m_axi4_arready					(axi4_arready),
				.m_axi4_rid						(axi4_rid),
				.m_axi4_rdata					(axi4_rdata),
				.m_axi4_rresp					(axi4_rresp),
				.m_axi4_rlast					(axi4_rlast),
				.m_axi4_rvalid					(axi4_rvalid),
				.m_axi4_rready					(axi4_rready)
			);
	
	
	jelly_axi4_slave_model
			#(
				.AXI_ID_WIDTH					(M_AXI4_ID_WIDTH),
				.AXI_ADDR_WIDTH					(M_AXI4_ADDR_WIDTH),
				.AXI_QOS_WIDTH					(M_AXI4_QOS_WIDTH),
				.AXI_LEN_WIDTH					(M_AXI4_LEN_WIDTH),
				.AXI_DATA_SIZE					(M_AXI4_DATA_SIZE),
				.MEM_WIDTH						(17),
				
				.WRITE_LOG_FILE					(""),
				.READ_LOG_FILE					("axi4_read.txt"),
				
				.AW_DELAY						(0),
				.AR_DELAY						(0),
				
				.AW_FIFO_PTR_WIDTH				(4),
				.W_FIFO_PTR_WIDTH				(4),
				.B_FIFO_PTR_WIDTH				(4),
				.AR_FIFO_PTR_WIDTH				(4),
				.R_FIFO_PTR_WIDTH				(4),
				
				.AW_BUSY_RATE					(0),
				.W_BUSY_RATE					(0),
				.B_BUSY_RATE					(0),
				.AR_BUSY_RATE					(0),
				.R_BUSY_RATE					(0)
			)
		i_axi4_slave_model
			(
				.aresetn						(~reset),
				.aclk							(clk),
				
				.s_axi4_awid					(),
				.s_axi4_awaddr					(),
				.s_axi4_awlen					(),
				.s_axi4_awsize					(),
				.s_axi4_awburst					(),
				.s_axi4_awlock					(),
				.s_axi4_awcache					(),
				.s_axi4_awprot					(),
				.s_axi4_awqos					(),
				.s_axi4_awvalid					(0),
				.s_axi4_awready					(),
				.s_axi4_wdata					(),
				.s_axi4_wstrb					(),
				.s_axi4_wlast					(),
				.s_axi4_wvalid					(0),
				.s_axi4_wready					(),
				.s_axi4_bid						(),
				.s_axi4_bresp					(),
				.s_axi4_bvalid					(),
				.s_axi4_bready					(0),
				
				.s_axi4_arid					(axi4_arid),
				.s_axi4_araddr					(axi4_araddr),
				.s_axi4_arlen					(axi4_arlen),
				.s_axi4_arsize					(axi4_arsize),
				.s_axi4_arburst					(axi4_arburst),
				.s_axi4_arlock					(axi4_arlock),
				.s_axi4_arcache					(axi4_arcache),
				.s_axi4_arprot					(axi4_arprot),
				.s_axi4_arqos					(axi4_arqos),
				.s_axi4_arvalid					(axi4_arvalid),
				.s_axi4_arready					(axi4_arready),
				.s_axi4_rid						(axi4_rid),
				.s_axi4_rdata					(axi4_rdata),
				.s_axi4_rresp					(axi4_rresp),
				.s_axi4_rlast					(axi4_rlast),
				.s_axi4_rvalid					(axi4_rvalid),
				.s_axi4_rready					(axi4_rready)
			);
	
	
	integer		read_num		[0:24'hff_ffff];
	integer		n;
	initial begin
		for ( n = 0; n <= 24'hff_ffff; n = n+1 ) begin
			read_num[n] = 0;
		end
	end
	
	always @(posedge clk) begin
		if ( !reset ) begin
			if ( axi4_arvalid && axi4_arready ) begin
				if ( read_num[axi4_araddr] != 0 ) begin
					$display("%h : %d", axi4_araddr, read_num[axi4_araddr]);
				end
				read_num[axi4_araddr] = read_num[axi4_araddr] + 1;
			end
		end
	end
	
endmodule


`default_nettype wire


// end of file
