// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



// whishbone x2 clock and width convert bridge
module jelly_wishbone_width_clk_x2
		#(
			parameter	WB_SLAVE_ADR_WIDTH  = 30,
			parameter	WB_SLAVE_DAT_WIDTH  = 32,
			parameter	WB_SLAVE_SEL_WIDTH  = (WB_SLAVE_DAT_WIDTH / 8),
			
			parameter	WB_MASTER_ADR_WIDTH = WB_SLAVE_ADR_WIDTH + 1,
			parameter	WB_MASTER_DAT_WIDTH = (WB_SLAVE_DAT_WIDTH >> 1),
			parameter	WB_MASTER_SEL_WIDTH = (WB_SLAVE_SEL_WIDTH >> 1)
		)
		(
			//system
			input	wire								reset,
			input	wire								clk,
			input	wire								clk_x2,
			
			// endian
			input	wire								endian,
			
			// slave port (WISHBONE)
			input	wire	[WB_SLAVE_ADR_WIDTH-1:0]	wb_slave_adr_i,
			output	reg		[WB_SLAVE_DAT_WIDTH-1:0]	wb_slave_dat_o,
			input	wire	[WB_SLAVE_DAT_WIDTH-1:0]	wb_slave_dat_i,
			input	wire								wb_slave_we_i,
			input	wire	[WB_SLAVE_SEL_WIDTH-1:0]	wb_slave_sel_i,
			input	wire								wb_slave_stb_i,
			output	reg									wb_slave_ack_o,
			
			// master port (WISHBONE)
			output	wire	[WB_MASTER_ADR_WIDTH-1:0]	wb_master_adr_o,
			output	wire	[WB_MASTER_DAT_WIDTH-1:0]	wb_master_dat_o,
			input	wire	[WB_MASTER_DAT_WIDTH-1:0]	wb_master_dat_i,
			output	wire								wb_master_we_o,
			output	wire	[WB_MASTER_SEL_WIDTH-1:0]	wb_master_sel_o,
			output	wire								wb_master_stb_o,
			input	wire								wb_master_ack_i
		);
	
	localparam	DELAY = 1.0;
	
	// remove clock jitter when simutation
	reg									delay_clk;
	reg		[WB_SLAVE_ADR_WIDTH-1:0]	tmp_wb_slave_adr_i;
	reg		[WB_SLAVE_DAT_WIDTH-1:0]	tmp_wb_slave_dat_i;
	reg									tmp_wb_slave_we_i;
	reg		[WB_SLAVE_SEL_WIDTH-1:0]	tmp_wb_slave_sel_i;
	reg									tmp_wb_slave_stb_i;
	wire	[WB_SLAVE_DAT_WIDTH-1:0]	tmp_wb_slave_dat_o;
	wire								tmp_wb_slave_ack_o;
	always @* begin
		delay_clk          <= #DELAY clk;
		tmp_wb_slave_adr_i <= #DELAY wb_slave_adr_i;
		tmp_wb_slave_dat_i <= #DELAY wb_slave_dat_i;
		tmp_wb_slave_we_i  <= #DELAY wb_slave_we_i;
		tmp_wb_slave_sel_i <= #DELAY wb_slave_sel_i;
		tmp_wb_slave_stb_i <= #DELAY wb_slave_stb_i;
		wb_slave_dat_o     <= #DELAY tmp_wb_slave_dat_o;
		wb_slave_ack_o     <= #DELAY tmp_wb_slave_ack_o;
	end
	
	
	// clock phase
	reg				reg_phase;
	always @( posedge clk_x2 ) begin
		reg_phase <= delay_clk;
	end
	
	// control
	reg									reg_2nd;
	reg									reg_end;
	reg		[WB_MASTER_DAT_WIDTH-1:0]	reg_read_dat1;
	reg		[WB_MASTER_DAT_WIDTH-1:0]	reg_read_dat2;
		
	always @( posedge clk_x2 ) begin
		if ( reset ) begin
			reg_2nd       <= 1'b0;
			reg_end       <= 1'b0;
			reg_read_dat1 <= {WB_SLAVE_DAT_WIDTH{1'bx}};
			reg_read_dat2 <= {WB_SLAVE_DAT_WIDTH{1'bx}};
		end
		else begin
			if ( reg_end ) begin
				if ( reg_phase == 1'b1 ) begin
					reg_end  <= 1'b0;
				end
			end
			else begin
				if ( reg_2nd == 1'b0 ) begin
					// 1st word
					reg_read_dat1 <= wb_master_dat_i;
					reg_2nd       <= tmp_wb_slave_stb_i & ((wb_master_sel_o == 0) | wb_master_ack_i);
				end
				else begin
					// 2nd word
					reg_read_dat2 <= wb_master_dat_i;
					if ( (wb_master_sel_o == 0) | wb_master_ack_i ) begin
						reg_2nd <= 1'b0;
						reg_end <= (reg_phase != 1'b1);
					end
				end
			end
		end
	end
	
	wire	[WB_MASTER_DAT_WIDTH-1:0]	read_dat1;
	wire	[WB_MASTER_DAT_WIDTH-1:0]	read_dat2;
	assign read_dat1 = reg_read_dat1;
	assign read_dat2 = reg_end ? reg_read_dat2 : wb_master_dat_i;
	
	wire	[WB_MASTER_DAT_WIDTH-1:0]	write_dat1;
	wire	[WB_MASTER_DAT_WIDTH-1:0]	write_dat2;
	wire	[WB_MASTER_SEL_WIDTH-1:0]	write_sel1;
	wire	[WB_MASTER_SEL_WIDTH-1:0]	write_sel2;
	assign write_dat1 = endian ? tmp_wb_slave_dat_i[WB_MASTER_DAT_WIDTH +: WB_MASTER_DAT_WIDTH] : tmp_wb_slave_dat_i[0 +: WB_MASTER_DAT_WIDTH];
	assign write_dat2 = endian ? tmp_wb_slave_dat_i[0 +: WB_MASTER_DAT_WIDTH] : tmp_wb_slave_dat_i[WB_MASTER_DAT_WIDTH +: WB_MASTER_DAT_WIDTH];
	assign write_sel1 = endian ? tmp_wb_slave_sel_i[WB_MASTER_SEL_WIDTH +: WB_MASTER_SEL_WIDTH] : tmp_wb_slave_sel_i[0 +: WB_MASTER_SEL_WIDTH];
	assign write_sel2 = endian ? tmp_wb_slave_sel_i[0 +: WB_MASTER_SEL_WIDTH] : tmp_wb_slave_sel_i[WB_MASTER_SEL_WIDTH +: WB_MASTER_SEL_WIDTH];
	
	
	assign wb_master_adr_o = {tmp_wb_slave_adr_i, reg_2nd};
	assign wb_master_dat_o = reg_2nd ? write_dat2 : write_dat1;
	assign wb_master_we_o  = tmp_wb_slave_we_i;
	assign wb_master_sel_o = reg_2nd ? write_sel2 : write_sel1;
	assign wb_master_stb_o = tmp_wb_slave_stb_i & (wb_master_sel_o != 0) & !reg_end;
	
	assign tmp_wb_slave_dat_o  = endian ? {read_dat1, read_dat2} : {read_dat2, read_dat1};
	assign tmp_wb_slave_ack_o  = reg_end | (reg_2nd & ((wb_master_sel_o == 0) | wb_master_ack_i));
	
endmodule


// End of file
