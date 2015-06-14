// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    I2C
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


`define SPI_STATUS		3'b000
`define SPI_CONTROL		3'b001
`define SPI_SEND		3'b010
`define SPI_RECV		3'b011
`define SPI_DIVIDER		3'b100


// SPI
module jelly_spi
		#(
			parameter							DIVIDER_WIDTH = 16,
			parameter							DIVIDER_INIT  = 100,
			
			parameter							WB_ADR_WIDTH  = 3,
			parameter							WB_DAT_WIDTH  = 32,
			parameter							WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8)
		)
		(
			// system
			input	wire						reset,
			input	wire						clk,
			
			// SPI
			output	wire						spi_cs_n,
			output	wire						spi_clk,
			output	wire						spi_di,
			input	wire						spi_do,
			
			// WISHBONE
			input	wire	[WB_ADR_WIDTH-1:0]	wb_adr_i,
			output	wire	[WB_DAT_WIDTH-1:0]	wb_dat_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_dat_i,
			input	wire						wb_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	wb_sel_i,
			input	wire						wb_stb_i,
			output	wire						wb_ack_o,
			
			output	wire						irq
		);
	
	
	// -------------------------
	//   Core
	// -------------------------
	
	reg		[DIVIDER_WIDTH-1:0]	clk_dvider;
	reg							reg_spi_cs_n;
	wire	[7:0]				tx_data;
	wire						tx_valid;
	wire	[7:0]				rx_data;
	wire						rx_valid;
	wire						busy;
	
	jelly_spi_core
			#(
				.DIVIDER_WIDTH		(DIVIDER_WIDTH)
			)
		i_spi_core
			(
				.reset				(reset),
				.clk				(clk),
				
				.clk_dvider			(clk_dvider),
				
				.spi_clk			(spi_clk),
				.spi_di				(spi_di),
				.spi_do				(spi_do),
				
				.tx_data			(tx_data),
				.tx_valid			(tx_valid),
				.tx_ready			(),
				.rx_data			(rx_data),
				.rx_valid			(rx_valid),
				
				.busy				(busy)
			);
	
	
	// -------------------------
	//  register
	// -------------------------
	
	always @(posedge clk) begin
		if ( reset ) begin
			clk_dvider   <= DIVIDER_INIT;
			reg_spi_cs_n <= 1'b1;
		end
		else begin
			if ( wb_stb_i & wb_we_i ) begin
				if ( wb_adr_i == `SPI_CONTROL ) begin
					reg_spi_cs_n <= wb_dat_i[0];
				end
				if ( wb_adr_i == `SPI_DIVIDER ) begin
					clk_dvider   <= wb_dat_i;
				end
			end
		end
	end
	
	assign tx_valid = (wb_adr_i == `SPI_SEND) & wb_stb_i & wb_we_i & wb_sel_i[0];
	assign tx_data  = wb_dat_i[7:0];
	
	assign wb_dat_o  = (wb_adr_i == `SPI_STATUS)  ? busy       :
					   (wb_adr_i == `SPI_RECV)    ? rx_data    :
					   (wb_adr_i == `SPI_DIVIDER) ? clk_dvider : 0;	
	assign wb_ack_o  = wb_stb_i;
	
	assign spi_cs_n  = reg_spi_cs_n;
	
	assign irq       = rx_valid;
	
endmodule


`default_nettype wire


// end of file
