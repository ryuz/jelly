// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// FIFO
module jelly_texture_writer_fifo
		#(
			parameter	COMPONENT_NUM        = 3,
			parameter	COMPONENT_DATA_WIDTH = 8,
			parameter	COMPONENT_SEL_WIDTH  = COMPONENT_NUM <= 2  ?  1 :
			                                   COMPONENT_NUM <= 4  ?  2 :
			                                   COMPONENT_NUM <= 8  ?  3 :
			                                   COMPONENT_NUM <= 16 ?  4 :
			                                   COMPONENT_NUM <= 32 ?  5 :
			                                   COMPONENT_NUM <= 64 ?  6 : 7,
			
			parameter	DATA_WIDTH           = COMPONENT_NUM * COMPONENT_DATA_WIDTH,
			
			parameter	BLK_X_SIZE           = 2,		// 2^n (0:1, 1:2, 2:4, 3:8, ... )
			parameter	BLK_Y_SIZE           = 2,		// 2^n (0:1, 1:2, 2:4, 3:8, ... )
			parameter	STEP_Y_SIZE          = 1,		// 2^n (0:1, 1:2, 2:4, 3:8, ... )
			
			parameter	X_WIDTH              = 10,
			parameter	Y_WIDTH              = 10,
			
			parameter	ADDR_WIDTH           = 24,
			parameter	STRIDE_WIDTH         = X_WIDTH + BLK_Y_SIZE,
			
			parameter	FIFO_PTR_WIDTH       = 10,
			parameter	FIFO_RAM_TYPE        = "block"
		)
		(
			input	wire								reset,
			input	wire								clk,
			
			input	wire	[X_WIDTH-1:0]				param_width,
			input	wire	[Y_WIDTH-1:0]				param_height,
			input	wire	[STRIDE_WIDTH-1:0]			param_stride,
			
			input	wire								s_start,
			input	wire								s_last,
			input	wire	[DATA_WIDTH-1:0]			s_data,
			input	wire								s_valid,
			output	wire								s_ready,
			
			output	wire	[COMPONENT_SEL_WIDTH-1:0]	m_component,
			output	wire	[ADDR_WIDTH-1:0]			m_addr,
			output	wire	[DATA_WIDTH-1:0]			m_data,
			output	wire								m_last,
			output	wire								m_valid,
			output	wire								m_ready
		);
	
	
	
	// ---------------------------------
	//  FIFO memory
	// ---------------------------------
	
	wire							write_cke;
	wire							write_en;
	wire	[FIFO_PTR_WIDTH-1:0]	write_addr;
	wire	[DATA_WIDTH-1:0]		write_data;
	
	wire							read_cke;
	wire	[FIFO_PTR_WIDTH-1:0]	read_addr;
	wire	[DATA_WIDTH-1:0]		read_data;
	wire							read_update;
	
	reg		[FIFO_PTR_WIDTH:0]		reg_fifo_data_count, next_fifo_data_count;
	
	wire	[FIFO_PTR_WIDTH:0]		next_fifo_free_count = ((1 << FIFO_PTR_WIDTH) - next_fifo_data_count);
	
	always @* begin
		next_fifo_data_count = reg_fifo_data_count;
		
		if ( write_cke && write_en ) begin
			next_fifo_data_count = next_fifo_data_count + 1'b1;
		end
		
		if ( read_cke && read_update ) begin
			next_fifo_data_count = next_fifo_data_count - (param_width << STEP_Y_SIZE);
		end
	end
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_fifo_data_count <= {(FIFO_PTR_WIDTH+1){1'b0}};
		end
		else begin
			reg_fifo_data_count <= next_fifo_data_count;
		end
	end
	
	// ram
	jelly_ram_dualport
			#(
				.DATA_WIDTH		(DATA_WIDTH),
				.ADDR_WIDTH		(FIFO_PTR_WIDTH),
				.DOUT_REGS1		(1'b1),
				.RAM_TYPE		(FIFO_RAM_TYPE)
			)
		i_ram_dualport
			(
				.clk0			(clk),
				.en0			(write_cke),
				.regcke0		(1'b0),
				.we0			(write_en),
				.addr0			(write_addr),
				.din0			(write_data),
				.dout0			(),
				
				.clk1			(clk),
				.en1			(read_cke),
				.regcke1		(read_cke),
				.we1			(1'b0),
				.addr1			(read_addr),
				.din1			({DATA_WIDTH{1'b0}}),
				.dout1			(read_data)
			);
	
	
	// ---------------------------------
	//  FIFO write
	// ---------------------------------
	
	reg								reg_s_ready;
	reg		[FIFO_PTR_WIDTH-1:0]	reg_write_addr;
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_s_ready    <= 1'b0;
			reg_write_addr <= {FIFO_PTR_WIDTH{1'b0}};
		end
		else begin
			reg_s_ready <= (next_fifo_free_count != 0);
			if ( s_ready && s_valid ) begin
				reg_write_addr <= reg_write_addr + 1'b1;
			end
		end
	end
	
	assign s_ready    = reg_s_ready;
	
	assign write_cke  = s_ready;
	assign write_en   = s_valid;
	assign write_addr = reg_write_addr;
	assign write_data = s_data;
	
	
	
	
	// ---------------------------------
	//  FIFO read
	// ---------------------------------
	
	jelly_texture_writer_addr
			#(
				.COMPONENT_NUM		(COMPONENT_NUM),
				.BLK_X_SIZE			(BLK_X_SIZE),
				.BLK_Y_SIZE			(BLK_Y_SIZE),
				.STEP_Y_SIZE		(STEP_Y_SIZE),
				
				.X_WIDTH			(X_WIDTH),
				.Y_WIDTH			(Y_WIDTH),
				
				.SRC_STRIDE_WIDTH	(X_WIDTH),
				.DST_STRIDE_WIDTH	(STRIDE_WIDTH),
				.SRC_ADDR_WIDTH		(FIFO_PTR_WIDTH),
				.DST_ADDR_WIDTH		(ADDR_WIDTH)
			)
		i_texture_writer_addr
			(
				.reset				(reset),
				.clk				(clk),
				
				.enable				(1'b1),
				.busy				(),
				.param_width		(param_width),
				.param_height		(param_height),
				.param_src_stride	(param_width),
				.param_dst_stride	(param_stride),
				
				.m_component		(),
				.m_src_addr			(),
				.m_src_base			(),
				.m_src_blk_last		(),
				.m_dst_addr			(),
				.m_dst_blk_last		(),
				.m_last				(),
				.m_valid			(),
				.m_ready			()
			);
	
	
	
endmodule


`default_nettype wire


// end of file
