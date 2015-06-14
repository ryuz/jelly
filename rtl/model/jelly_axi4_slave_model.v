


`timescale 1ns / 1ps
`default_nettype none


module jelly_axi4_slave_model
		#(
			parameter	AXI_ID_WIDTH          = 4,
			parameter	AXI_ADDR_WIDTH        = 32,
			parameter	AXI_QOS_WIDTH         = 4,
			parameter	AXI_LEN_WIDTH         = 8,
			parameter	AXI_DATA_SIZE         = 2,		// 0:8bit, 1:16bit, 2:32bit, 4:64bit...
			parameter	AXI_DATA_WIDTH        = (8 << AXI_DATA_SIZE),
			parameter	AXI_STRB_WIDTH        = (1 << AXI_DATA_SIZE),
			parameter	MEM_SIZE              = 4096
		)
		(
			input	wire							aresetn,
			input	wire							aclk,
			
			input	wire	[AXI_ID_WIDTH-1:0]		s_axi4_awid,
			input	wire	[AXI_ADDR_WIDTH-1:0]	s_axi4_awaddr,
			input	wire	[AXI_LEN_WIDTH-1:0]		s_axi4_awlen,
			input	wire	[2:0]					s_axi4_awsize,
			input	wire	[1:0]					s_axi4_awburst,
			input	wire	[0:0]					s_axi4_awlock,
			input	wire	[3:0]					s_axi4_awcache,
			input	wire	[2:0]					s_axi4_awprot,
			input	wire	[AXI_QOS_WIDTH-1:0]		s_axi4_awqos,
			input	wire							s_axi4_awvalid,
			output	wire							s_axi4_awready,
			
			input	wire	[AXI_DATA_WIDTH-1:0]	s_axi4_wdata,
			input	wire	[AXI_STRB_WIDTH-1:0]	s_axi4_wstrb,
			input	wire							s_axi4_wlast,
			input	wire							s_axi4_wvalid,
			output	wire							s_axi4_wready,
			
			output	wire	[AXI_ID_WIDTH-1:0]		s_axi4_bid,
			output	wire	[1:0]					s_axi4_bresp,
			output	wire							s_axi4_bvalid,
			input	wire							s_axi4_bready,
			
			input	wire	[AXI_ID_WIDTH-1:0]		s_axi4_arid,
			input	wire	[AXI_ADDR_WIDTH-1:0]	s_axi4_araddr,
			input	wire	[AXI_LEN_WIDTH-1:0]		s_axi4_arlen,
			input	wire	[2:0]					s_axi4_arsize,
			input	wire	[1:0]					s_axi4_arburst,
			input	wire	[0:0]					s_axi4_arlock,
			input	wire	[3:0]					s_axi4_arcache,
			input	wire	[2:0]					s_axi4_arprot,
			input	wire	[AXI_QOS_WIDTH-1:0]		s_axi4_arqos,
			input	wire		 					s_axi4_arvalid,
			output	wire		 					s_axi4_arready,
			
			output	wire	[AXI_ID_WIDTH-1:0]		s_axi4_rid,
			output	wire	[AXI_DATA_WIDTH-1:0]	s_axi4_rdata,
			output	wire	[1:0]					s_axi4_rresp,
			output	wire							s_axi4_rlast,
			output	wire							s_axi4_rvalid,
			input	wire							s_axi4_rready
		);
	
	// memory
	reg		[AXI_DATA_WIDTH-1:0]	mem		[MEM_SIZE-1:0];
	
	// write
	reg								reg_awbusy;
	reg		[AXI_ID_WIDTH-1:0]		reg_awid;
	reg		[AXI_ADDR_WIDTH-1:0]	reg_awaddr;
	reg		[AXI_LEN_WIDTH-1:0]		reg_awlen;
	reg								reg_bvalid;
	
	always @( posedge aclk ) begin
		if ( !aresetn ) begin
			reg_awbusy <= 1'b0;
			reg_awid   <= 0;
			reg_awaddr <= 0;
			reg_awlen  <= 0;
			reg_bvalid <= 1'b0;
		end
		else begin
			if ( s_axi4_bready ) begin
				reg_bvalid <= 1'b0;
			end
			
			if ( s_axi4_awready && s_axi4_wready ) begin
				reg_awbusy <= 1'b1;
				reg_awid   <= s_axi4_awid;
				reg_awaddr <= s_axi4_awaddr;
				reg_awlen  <= s_axi4_awlen;
				if ( s_axi4_wvalid && s_axi4_wready ) begin
					if ( s_axi4_awlen == 0 ) begin
						reg_bvalid <= 1'b1;
						reg_awbusy <= 1'b0;
					end
					else begin
						reg_awlen  <= s_axi4_awlen - 1;
						reg_awaddr <= s_axi4_awaddr + (1 << AXI_DATA_SIZE);
					end
				end
			end
			else if ( s_axi4_wvalid && s_axi4_wready ) begin
				if ( reg_awlen == 0 ) begin
					reg_bvalid <= 1'b1;
					reg_awbusy <= 1'b0;
				end
				else begin
					reg_awlen  <= reg_awlen - 1;
					reg_awaddr <= reg_awaddr + (1 << AXI_DATA_SIZE);
				end
			end
		end
	end
	
	// memory write
	wire	[AXI_ADDR_WIDTH-1:0]	sig_awaddr = reg_awbusy ? reg_awaddr : s_axi4_awaddr;
	integer							i;
	always @( posedge aclk ) begin
		if ( aresetn && s_axi4_wvalid && s_axi4_wready ) begin
			if ( (sig_awaddr >> AXI_DATA_SIZE) < MEM_SIZE ) begin
				for ( i = 0; i < AXI_STRB_WIDTH; i = i + 1 ) begin
					if ( s_axi4_wstrb[i] ) begin
						mem[sig_awaddr >> AXI_DATA_SIZE][i*8 +: 8] <= s_axi4_wdata[i*8 +: 8];
					end
				end
			end
		end
	end
	
	// write assign
	assign s_axi4_awready = !reg_awbusy && !(s_axi4_bvalid && !s_axi4_bready);
	assign s_axi4_wready  = (reg_awbusy || s_axi4_awvalid) && !(s_axi4_bvalid && !s_axi4_bready);
	
	assign s_axi4_bid     = s_axi4_bvalid ? reg_awid : {AXI_ID_WIDTH{1'bx}};
	assign s_axi4_bresp   = s_axi4_bvalid ? 2'b00 : 2'bxx;
	assign s_axi4_bvalid  = reg_bvalid;
	
	
	
	// read
	reg								reg_arbusy;
	reg		[AXI_ID_WIDTH-1:0]		reg_arid;
	reg		[AXI_ADDR_WIDTH-1:0]	reg_araddr;
	reg		[AXI_LEN_WIDTH-1:0]		reg_arlen;
	reg								reg_rlast;
	reg		[AXI_DATA_WIDTH-1:0]	reg_rdata;
	reg								reg_rvalid;
	
	always @( posedge aclk ) begin
		if ( !aresetn ) begin
			reg_arbusy <= 0;
			reg_arid   <= 0; 
			reg_araddr <= 0;
			reg_arlen  <= 0;
			reg_rlast  <= 0;
			reg_rdata  <= 0;
			reg_rvalid <= 0;
		end
		else begin
			if ( s_axi4_rvalid & s_axi4_rready ) begin
				reg_araddr <= reg_araddr + (1 << AXI_DATA_SIZE);
				reg_arlen  <= reg_arlen - 1'b1;
				reg_rlast  <= ((reg_arlen - 1'b1) == 0);
				if ( reg_rlast ) begin
					reg_arbusy <= 1'b0;
					reg_rvalid <= 1'b0;
				end
			end
			
			if ( s_axi4_arvalid & s_axi4_arready ) begin
				reg_arbusy <= (s_axi4_arlen != 0);
				reg_arid   <= s_axi4_arid;
				reg_araddr <= s_axi4_araddr;
				reg_arlen  <= s_axi4_arlen;
				
				reg_rlast  <= (s_axi4_arlen == 0);
				reg_rvalid <= 1'b1;
			end
		end
	end
	
	
	assign s_axi4_arready = !reg_arbusy || (reg_rlast && s_axi4_rvalid && s_axi4_rready);
	
	assign s_axi4_rid     = s_axi4_rvalid ? reg_arid : {AXI_ID_WIDTH{1'bx}};
//	assign s_axi4_rdata   = (s_axi4_rvalid && ((reg_araddr >> AXI_DATA_SIZE) < MEM_SIZE)) ? mem[reg_araddr >> AXI_DATA_SIZE] : {AXI_DATA_WIDTH{1'bx}};
//	assign s_axi4_rdata   = mem[reg_araddr >> AXI_DATA_SIZE];
	assign s_axi4_rdata   = reg_araddr;
	assign s_axi4_rresp   = s_axi4_rvalid ? 2'b00 : 2'bxx;
	assign s_axi4_rlast   = s_axi4_rvalid ? reg_rlast : 1'bx;
	assign s_axi4_rvalid  = reg_rvalid;
	
endmodule


`default_nettype wire


// end of file
