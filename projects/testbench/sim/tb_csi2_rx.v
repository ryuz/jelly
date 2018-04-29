
`timescale 1ns / 1ps
`default_nettype none


module tb_csi2_rx();
	localparam RATE    = 1000.0/200.0;
	localparam RATE_HS = 1000.0/91.2;
	
	
	initial begin
		$dumpfile("tb_csi2_rx.vcd");
		$dumpvars(0, tb_csi2_rx);
	
	#2000000
		$finish;
	end
	
	
	reg		reset = 1'b1;
	always #(RATE*100)	reset = 1'b0;
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		hs_clk = 1'b1;
	always #(RATE_HS/2.0)	hs_clk = ~hs_clk;
	
	
	parameter LANE_NUM   = 2;
	parameter DATA_WIDTH = 10;
	
	wire						rxreseths   = reset;
	wire						rxbyteclkhs = hs_clk;
	wire	[LANE_NUM*8-1:0]	rxdatahs;
	wire	[LANE_NUM-1:0]		rxvalidhs;
	wire	[LANE_NUM-1:0]		rxactivehs;
	wire	[LANE_NUM-1:0]		rxsynchs;
	
	wire						aresetn = ~reset;
	wire						aclk    = clk;
	wire	[0:0]				m_axi4s_tuser;
	wire						m_axi4s_tlast;
	wire	[DATA_WIDTH-1:0]	m_axi4s_tdata;
	wire	[0:0]				m_axi4s_tvalid;
	wire						m_axi4s_tready = 1;
	
	jelly_csi2_rx
			#(
				.LANE_NUM			(LANE_NUM),
				.DATA_WIDTH			(DATA_WIDTH)
			)
		i_csi2_rx
			(
				.rxreseths			(rxreseths),
				.rxbyteclkhs		(rxbyteclkhs),
				.rxdatahs			(rxdatahs),
				.rxvalidhs			(rxvalidhs),
				.rxactivehs			(rxactivehs),
				.rxsynchs			(rxsynchs),
				                     
				.aresetn			(aresetn),
				.aclk				(aclk),
				.m_axi4s_tuser		(m_axi4s_tuser),
				.m_axi4s_tlast		(m_axi4s_tlast),
				.m_axi4s_tdata		(m_axi4s_tdata),
				.m_axi4s_tvalid		(m_axi4s_tvalid),
				.m_axi4s_tready		(m_axi4s_tready)
			);
	
	
	reg		[31:0]		rx_data		[0:16*1024*1024-1];
	
	initial begin
		$readmemh("data.hex", rx_data);
	end
	
	integer		data_count = 0;
	always @(posedge hs_clk) begin
		if ( reset ) begin
			data_count <= 0;
		end
		else begin
			data_count <= data_count + 1;
		end
	end
	
	wire			dl0_errsotsynchs;
	wire			dl0_errsoths;
	wire			dl0_rxsynchs;
	wire			dl0_rxactivehs;
	wire			dl0_rxvalidhs;
	wire	[7:0]	dl0_rxdatahs;
	
	wire			dl1_errsotsynchs;
	wire			dl1_errsoths;
	wire			dl1_rxsynchs;
	wire			dl1_rxactivehs;
	wire			dl1_rxvalidhs;
	wire	[7:0]	dl1_rxdatahs;
	
	assign {
				dl0_errsotsynchs,
				dl0_errsoths,
				dl0_rxsynchs,
				dl0_rxactivehs,
				dl0_rxvalidhs,
				dl0_rxdatahs
			} = rx_data[data_count][15:0];
	
	assign {
				dl1_errsotsynchs,
				dl1_errsoths,
				dl1_rxsynchs,
				dl1_rxactivehs,
				dl1_rxvalidhs,
				dl1_rxdatahs
			} = rx_data[data_count+1][31:16];
	
	assign rxdatahs   = {dl1_rxdatahs,   dl0_rxdatahs};
	assign rxvalidhs  = {dl1_rxvalidhs,  dl0_rxvalidhs};
	assign rxactivehs = {dl1_rxactivehs, dl0_rxactivehs};
	assign rxsynchs   = {dl1_rxsynchs,   dl0_rxsynchs};
	
	
	
endmodule


`default_nettype wire


// end of file
