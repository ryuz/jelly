
`timescale 1ns / 1ps
`default_nettype none


module tb_texture_cache_unit();
	localparam RATE    = 1000.0/200.0;
	
	initial begin
		$dumpfile("tb_texture_cache_unit.vcd");
		$dumpvars(0, tb_texture_cache_unit);
		
		#100000;
			$finish;
	end
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		reset = 1'b1;
	initial #(RATE*100.5)	reset = 1'b0;
	
	
	parameter	S_ADDR_X_WIDTH   = 10;
	parameter	S_ADDR_Y_WIDTH   = 9;
	parameter	S_DATA_WIDTH     = 24;
	
	parameter	TAG_ADDR_WIDTH   = 6;
	
	parameter	BLK_ADDR_X_WIDTH = 2;
	parameter	BLK_ADDR_Y_WIDTH = 2;
	
	parameter	M_ADDR_X_WIDTH   = S_ADDR_X_WIDTH - BLK_ADDR_X_WIDTH;
	parameter	M_ADDR_Y_WIDTH   = S_ADDR_Y_WIDTH - BLK_ADDR_Y_WIDTH;
	
	parameter	M_DATA_WIDE_SIZE = 1;
	parameter	M_DATA_WIDTH     = (S_DATA_WIDTH << M_DATA_WIDE_SIZE);
	
	
	wire							endian = 0;
	
	wire							clear_start = 0;
	wire							ckear_busy;
	
	wire	[S_ADDR_X_WIDTH-1:0]	param_width  = 640;
	wire	[S_ADDR_X_WIDTH-1:0]	param_height = 480;
	
	
	reg		[S_ADDR_X_WIDTH-1:0]	s_araddrx;
	reg		[S_ADDR_Y_WIDTH-1:0]	s_araddry;
	reg								s_arvalid;
	wire							s_arready;
	
	wire	[S_DATA_WIDTH-1:0]		s_rdata;
	wire							s_rvalid;
	wire							s_rready = 1;
	
	
	wire	[M_ADDR_X_WIDTH-1:0]	m_araddrx;
	wire	[M_ADDR_Y_WIDTH-1:0]	m_araddry;
	wire							m_arvalid;
	wire							m_arready = 1;
	
	reg								m_rlast  = 0;
	reg		[M_DATA_WIDTH-1:0]		m_rdata  = 0;
	reg								m_rvalid = 0;
	
	jelly_texture_cache_unit
			#(
				.S_ADDR_X_WIDTH		(S_ADDR_X_WIDTH),
				.S_ADDR_Y_WIDTH		(S_ADDR_Y_WIDTH),
				.S_DATA_WIDTH		(S_DATA_WIDTH),
				.TAG_ADDR_WIDTH		(TAG_ADDR_WIDTH),
				.BLK_ADDR_X_WIDTH	(BLK_ADDR_X_WIDTH),
				.BLK_ADDR_Y_WIDTH	(BLK_ADDR_Y_WIDTH),
				.M_DATA_WIDE_SIZE	(M_DATA_WIDE_SIZE)
			)
		i_texture_cache_unit
			(
				.reset				(reset),
				.clk				(clk),
				                     
				.endian				(endian),
				                     
				.clear_start		(clear_start),
				.ckear_busy			(ckear_busy),
				                     
				.param_width		(param_width),
				.param_height		(param_height),
				                     
				.s_araddrx			(s_araddrx),
				.s_araddry			(s_araddry),
				.s_arvalid			(s_arvalid),
				.s_arready			(s_arready),
				                     
				.s_rdata			(s_rdata),
				.s_rvalid			(s_rvalid),
				.s_rready			(s_rready),
				                     
				.m_araddrx			(m_araddrx),
				.m_araddry			(m_araddry),
				.m_arvalid			(m_arvalid),
				.m_arready			(m_arready),
				                     
				.m_rlast			(m_rlast),
				.m_rdata			(m_rdata),
				.m_rvalid			(m_rvalid)
			);
	
	
	always @(posedge clk) begin
		if ( reset ) begin
			s_araddrx <= 32;
			s_araddry <= 32;
			s_arvalid <= 1'b0;
		end
		else begin
			if ( s_arvalid && s_arready ) begin
				s_araddrx <= s_araddrx + 1;
				s_araddry <= s_araddry + 1;
			end
			s_arvalid <= 1'b1;
		end
	end
	
	
	reg			reg_busy;
	integer		reg_count;
	always @(posedge clk) begin
		if ( reset ) begin
			reg_busy <= 0;
			m_rlast  <= 0;
			m_rdata  <= 0;
			m_rvalid <= 0;
		end
		else begin
			if ( m_arvalid && m_arready ) begin
				reg_busy  <= 1;
				reg_count <= 0;
				m_rlast   <= 0;
				m_rdata   <= {{m_araddry, 2'b00, m_araddry, 2'b01}, {m_araddry, 2'b00, m_araddry, 2'b01}};
				m_rvalid  <= 1'b1;
			end
			else begin
				if ( reg_busy ) begin
					if ( reg_count == 4*2-1 ) begin
						m_rlast  <= 0;
						m_rdata  <= 0;
						m_rvalid  <= 1'b0;
					end
					else begin
						reg_count <= reg_count + 1;
						m_rlast   <= (reg_count == 4*2-2);
						m_rdata   <= m_rdata + {24'h2, 24'h2};
						m_rvalid  <= 1'b1;
					end
				end
			end
		end
	end
	
	
	
	
endmodule


`default_nettype wire


// end of file
