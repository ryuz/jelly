// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


// nop           8'h00
// nop                 8'h80
//
// status        8'h01
// status_ack          8'h81 status
//
// dbg_write     8'h02 sel+adr dat0 dat1 dat2 dat3
// dbg_write_ack                                    8'h81
//
// dbg_read      8'h03 sel+adr
// dbg_write_ack                8'h82 dat0 dat1 dat2 dat3
//
// mem_write     8'h04 size adr0 adr1 adr2 adr3 dat0 dat1 dat2 dat3 ....
// mem_write_ack                                                          8'h84
//
// mem_read      8'h05 size adr0 adr1 adr2 adr3 
// mem_write_ack                                 8'h85 dat0 dat1 dat2 dat3 ....


`define CMD_NOP			8'h00
`define CMD_STATUS		8'h01
`define CMD_DBG_WRITE	8'h02
`define CMD_DBG_READ	8'h03
`define CMD_MEM_WRIT	8'h04
`define CMD_MEM_READ	8'h05

`define ACK_NOP			8'h80
`define ACK_STATUS		8'h81
`define ACK_DBG_WRITE	8'h82
`define ACK_DBG_READ	8'h83
`define ACK_MEM_WRIT	8'h84
`define ACK_MEM_READ	8'h85



// debug uart
module jelly_dbg_uart
		(
			reset, clk, endian,
			uart_clk, uart_tx, uart_rx,
			wb_dbg_adr_o, wb_dbg_dat_i, wb_dbg_dat_o, wb_dbg_we_o, wb_dbg_sel_o, wb_dbg_stb_o, wb_dbg_ack_i
		);
	
	parameter	TX_FIFO_PTR_WIDTH = 10;
	parameter	RX_FIFO_PTR_WIDTH = 10;
	
	// system
	input				reset;
	input				clk;
	input				endian;
	
	// uart
	input				uart_clk;
	output				uart_tx;
	input				uart_rx;
	
	// debug port (whishbone)
	output	[3:0]		wb_dbg_adr_o;
	input	[31:0]		wb_dbg_dat_i;
	output	[31:0]		wb_dbg_dat_o;
	output				wb_dbg_we_o;
	output	[3:0]		wb_dbg_sel_o;
	output				wb_dbg_stb_o;
	input				wb_dbg_ack_i;
	
	
	
	// state
	parameter	ST_IDLE         = 0;
	parameter	ST_RETURN_IDLE  = 1;
	parameter	ST_ST_TX_ACK    = 2;
	parameter	ST_DW_RX_ADDR   = 3;
	parameter	ST_DW_RX_DATA   = 4;
	parameter	ST_DW_WRITE     = 5;
	parameter	ST_DR_RX_ADDR   = 6;
	parameter	ST_DR_READ      = 7;
	parameter	ST_DR_TX_DATA   = 8;
	parameter	ST_MW_RX_SIZE   = 9;
	parameter	ST_MW_RX_ADDR   = 10;
	parameter	ST_MW_SET_ADDR  = 11;
	parameter	ST_MW_WAI_ADDR  = 12;
	parameter	ST_MW_RX_DATA   = 13;
	parameter	ST_MW_WRITE     = 14;
	parameter	ST_MR_RX_SIZE   = 15;
	parameter	ST_MR_RX_ADDR   = 16;
	parameter	ST_MR_TX_ACK    = 17;
	parameter	ST_MR_SET_ADDR  = 18;
	parameter	ST_MR_WAI_ADDR  = 19;
	parameter	ST_MR_READ      = 20;
	parameter	ST_MR_TX_DATA   = 21;
	
	
	wire				uart_rx_en;
	wire	[7:0]		uart_rx_data;
	reg					uart_rx_ready;
	
	reg					uart_tx_en;
	reg		[7:0]		uart_tx_data;
	wire				uart_tx_ready;

	reg		[3:0]		wb_dbg_adr_o;
	reg		[31:0]		wb_dbg_dat_o;
	reg					wb_dbg_we_o;
	reg		[3:0]		wb_dbg_sel_o;
	reg					wb_dbg_stb_o;
		
	reg		[21:0]		state;
	reg		[7:0]		counter;
	
	reg		[7:0]		size;
	reg		[31:0]		address;
	reg		[31:0]		data;
	
	reg					next_uart_tx_en;
	reg		[7:0]		next_uart_tx_data;

	reg		[3:0]		next_wb_dbg_adr_o;
	reg		[31:0]		next_wb_dbg_dat_o;
	reg					next_wb_dbg_we_o;
	reg		[3:0]		next_wb_dbg_sel_o;
	reg					next_wb_dbg_stb_o;

	reg		[21:0]		next_state;
	reg		[7:0]		next_counter;

	reg		[7:0]		next_size;
	reg		[31:0]		next_address;
	reg		[31:0]		next_data;
	
	
	// FF
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			uart_tx_en    <= 1'b0;
			wb_dbg_stb_o  <= 1'b0;
			state         <= 1;
			counter       <= 0;
		end
		else begin
			uart_tx_en    <= next_uart_tx_en;
			uart_tx_data  <= next_uart_tx_data;
			wb_dbg_adr_o  <= next_wb_dbg_adr_o;
			wb_dbg_dat_o  <= next_wb_dbg_dat_o;
			wb_dbg_we_o   <= next_wb_dbg_we_o;
			wb_dbg_sel_o  <= next_wb_dbg_sel_o;
			wb_dbg_stb_o  <= next_wb_dbg_stb_o;
			state         <= next_state;
			counter       <= next_counter;
			size          <= next_size;
			address       <= next_address;
			data          <= next_data;
		end
	end
	
	// combination
	always @* begin
		uart_rx_ready     = 1'b0;
		
		next_state        = state;
		next_counter      = counter;
		
		next_uart_tx_en   = uart_tx_en;
		next_uart_tx_data = uart_tx_data;
		
		next_wb_dbg_adr_o = wb_dbg_adr_o;
		next_wb_dbg_dat_o = wb_dbg_dat_o;
		next_wb_dbg_we_o  = wb_dbg_we_o;
		next_wb_dbg_sel_o = wb_dbg_sel_o;
		next_wb_dbg_stb_o = wb_dbg_stb_o;

		next_size         = size;
		next_address      = address;
		next_data         = data;
		
		
		//  ---- Idle ----
		
		// idle
		if ( state[ST_IDLE] ) begin
			uart_rx_ready = 1'b1;
			
			// command recive & analyze
			if ( uart_rx_en ) begin
				case ( uart_rx_data )
				`CMD_NOP:
					begin
						// send ack
						next_uart_tx_en   = 1'b1;
						next_uart_tx_data = `ACK_NOP;	// NOP_ACK;
						
						// go next state
						next_state[ST_IDLE]        = 1'b0;
						next_state[ST_RETURN_IDLE] = 1'b1;
					end
				
				`CMD_STATUS:
					begin
						// send ack
						next_uart_tx_en   = 1'b1;
						next_uart_tx_data = `ACK_STATUS;
						
						// go next state
						next_state[ST_IDLE]      = 1'b0;
						next_state[ST_ST_TX_ACK] = 1'b1;
					end
				
				`CMD_DBG_WRITE:
					begin
						// go next state
						next_state[ST_IDLE]       = 1'b0;
						next_state[ST_DW_RX_ADDR] = 1'b1;
					end
					
				`CMD_DBG_READ:
					begin
						// go next state
						next_state[ST_IDLE]       = 1'b0;
						next_state[ST_DR_RX_ADDR] = 1'b1;						
					end

				`CMD_MEM_WRIT:
					begin
						// go next state
						next_state[ST_IDLE]       = 1'b0;
						next_state[ST_MW_RX_SIZE] = 1'b1;						
					end
					
				`CMD_MEM_READ:
					begin
						// go next state
						next_state[ST_IDLE]       = 1'b0;
						next_state[ST_MR_RX_SIZE] = 1'b1;						
					end
				endcase
			end
		end
		
		// return idle
		if ( state[ST_RETURN_IDLE] ) begin
			if ( !(uart_tx_en & ~uart_tx_ready) ) begin
				next_uart_tx_en = 1'b0;
				
				// go next state
				next_state[ST_RETURN_IDLE] = 1'b0;
				next_state[ST_IDLE]        = 1'b1;
			end
		end
		
		
		// ---- Status ----

		// status ack
		if ( state[ST_ST_TX_ACK] ) begin
			if ( uart_tx_ready ) begin
				// send status
				next_uart_tx_en   = 1'b1;
				next_uart_tx_data = endian;
				
				// go next state
				next_state[ST_ST_TX_ACK]   = 1'b0;
				next_state[ST_RETURN_IDLE] = 1'b1;
			end
		end
		
		
		// ---- Write debug register ----
		
		// dbg write recv addr
		if ( state[ST_DW_RX_ADDR] ) begin
			uart_rx_ready     = 1'b1;
			next_wb_dbg_we_o  = 1'b1;
			next_counter[1:0] = 2'b00;
			
			if ( uart_rx_en ) begin
				// receive sel & adr
				next_wb_dbg_adr_o = uart_rx_data[3:0];
				next_wb_dbg_sel_o = uart_rx_data[7:4];
				
				// go next state
				next_state[ST_DW_RX_ADDR] = 1'b0;
				next_state[ST_DW_RX_DATA] = 1'b1;
			end
		end
		
		// dbg write recv data
		if ( state[ST_DW_RX_DATA] ) begin
			uart_rx_ready = 1'b1;
			if ( uart_rx_en ) begin
				// counter
				next_counter = counter + 1;
				
				// receive data
				if ( counter[1:0] == ({2{endian}} ^ 2'b00) ) next_wb_dbg_dat_o[7:0]   = uart_rx_data;
				if ( counter[1:0] == ({2{endian}} ^ 2'b01) ) next_wb_dbg_dat_o[15:8]  = uart_rx_data;
				if ( counter[1:0] == ({2{endian}} ^ 2'b10) ) next_wb_dbg_dat_o[23:16] = uart_rx_data;
				if ( counter[1:0] == ({2{endian}} ^ 2'b11) ) next_wb_dbg_dat_o[31:24] = uart_rx_data;
				
				if ( counter[1:0] == 2'b11 ) begin
					// write
					next_wb_dbg_stb_o = 1'b1;
					
					// go next state
					next_state[ST_DW_RX_DATA]  = 1'b0;
					next_state[ST_DW_WRITE]    = 1'b1;
				end
			end
		end
		
		// dbg write
		if ( state[ST_DW_WRITE] ) begin
			uart_rx_ready = 1'b0;
			if ( wb_dbg_ack_i ) begin
				// write end
				next_wb_dbg_stb_o = 1'b0;
				
				// send ack
				next_uart_tx_en   = 1'b1;
				next_uart_tx_data = `ACK_DBG_WRITE;
				
				// go next state
				next_state[ST_DW_WRITE]    = 1'b0;
				next_state[ST_RETURN_IDLE] = 1'b1;
			end
		end
		
		
		// ---- Read debug register ----
	
		// dbg read
		if ( state[ST_DR_RX_ADDR] ) begin
			uart_rx_ready     = 1'b1;
			next_wb_dbg_we_o  = 1'b0;
			next_counter[2:0] = 0;
			
			if ( uart_rx_en ) begin
				// receive sel & adr
				next_wb_dbg_adr_o = uart_rx_data[3:0];
				next_wb_dbg_sel_o = uart_rx_data[7:4];
				next_wb_dbg_stb_o = 1'b1;
				
				// go next state
				next_state[ST_DR_RX_ADDR] = 1'b0;
				next_state[ST_DR_READ]    = 1'b1;
			end
		end
		
		// dbg read
		if ( state[ST_DR_READ] ) begin
			uart_rx_ready    = 1'b0;
			
			if ( wb_dbg_ack_i ) begin
				// read
				next_wb_dbg_stb_o = 1'b0;
				next_data         = wb_dbg_dat_i;
				
				// send ack
				next_uart_tx_en   = 1'b1;
				next_uart_tx_data = `ACK_DBG_READ;
				
				// go next state
				next_state[ST_DR_READ]    = 1'b0;
				next_state[ST_DR_TX_DATA] = 1'b1;
			end
		end
		
		if ( state[ST_DR_TX_DATA] ) begin
			uart_rx_ready = 1'b0;
			
			if ( uart_tx_ready ) begin
				// send data
				if ( counter[1:0] == ({2{endian}} ^ 2'b00) ) next_uart_tx_data = data[7:0];
				if ( counter[1:0] == ({2{endian}} ^ 2'b01) ) next_uart_tx_data = data[15:8];
				if ( counter[1:0] == ({2{endian}} ^ 2'b10) ) next_uart_tx_data = data[23:16];
				if ( counter[1:0] == ({2{endian}} ^ 2'b11) ) next_uart_tx_data = data[31:24];
				
				next_counter = counter + 1;
				if ( counter[2:0] == 3'b100 ) begin
					next_uart_tx_en = 1'b0;
					
					// go to next state
					next_state[ST_DR_TX_DATA] = 1'b0;
					next_state[ST_IDLE]       = 1'b1;
				end
			end
		end
		
		
		
		// ---- Write memory ----
		
		// memory write
		if ( state[ST_MW_RX_SIZE] ) begin
			uart_rx_ready     = 1'b1;
			next_counter[1:0] = 2'b00;
			
			if ( uart_rx_en ) begin
				// receive size
				next_size = uart_rx_data;
				
				// go next state
				next_state[ST_MW_RX_SIZE] = 1'b0;
				next_state[ST_MW_RX_ADDR] = 1'b1;
			end
		end
		
		// mem write recv address
		if ( state[ST_MW_RX_ADDR] ) begin
			uart_rx_ready = 1'b1;
			
			if ( uart_rx_en ) begin
				// counter
				next_counter = counter + 1;
				
				// receive data
				if ( counter[1:0] == ({2{endian}} ^ 2'b00) ) next_address[7:0]   = uart_rx_data;
				if ( counter[1:0] == ({2{endian}} ^ 2'b01) ) next_address[15:8]  = uart_rx_data;
				if ( counter[1:0] == ({2{endian}} ^ 2'b10) ) next_address[23:16] = uart_rx_data;
				if ( counter[1:0] == ({2{endian}} ^ 2'b11) ) next_address[31:24] = uart_rx_data;
				
				if ( counter[1:0] == 2'b11 ) begin					
					// go next state
					next_counter = 0;
					next_state[ST_MW_RX_ADDR]  = 1'b0;
					next_state[ST_MW_SET_ADDR] = 1'b1;
				end
			end
		end
		
		if ( state[ST_MW_SET_ADDR] ) begin
			uart_rx_ready = 1'b0;
			
			// write
			next_wb_dbg_adr_o = 4'h2;	// DBG_ADDR
			next_wb_dbg_dat_o = {address[31:2], 2'b00};
			next_wb_dbg_we_o  = 1'b1;
			next_wb_dbg_sel_o = 4'b1111;
			next_wb_dbg_stb_o = 1'b1;
			
			// go next state
			next_state[ST_MW_SET_ADDR] = 1'b0;
			next_state[ST_MW_WAI_ADDR] = 1'b1;
		end
		
		if ( state[ST_MW_WAI_ADDR] ) begin
			uart_rx_ready = 1'b0;
			
			if ( wb_dbg_ack_i ) begin
				// write end
				next_wb_dbg_stb_o = 1'b0;
			
				// go next state
				next_state[ST_MW_WAI_ADDR] = 1'b0;
				next_state[ST_MW_RX_DATA]  = 1'b1;
			end
		end
		
		// mem write recv data
		if ( state[ST_MW_RX_DATA] ) begin
			uart_rx_ready = 1'b1;
			
			next_wb_dbg_adr_o = 4'h6;	// DBG_DBUS
			next_wb_dbg_sel_o[0] = (address[1:0] == ({2{endian}} ^ 2'b00));
			next_wb_dbg_sel_o[1] = (address[1:0] == ({2{endian}} ^ 2'b01));
			next_wb_dbg_sel_o[2] = (address[1:0] == ({2{endian}} ^ 2'b10));
			next_wb_dbg_sel_o[3] = (address[1:0] == ({2{endian}} ^ 2'b11));
			
			if ( uart_rx_en ) begin
				// write
				next_wb_dbg_dat_o    = {4{uart_rx_data}};
				next_wb_dbg_stb_o    = 1'b1;
				
				// go next state
				next_state[ST_MW_RX_DATA] = 1'b0;
				next_state[ST_MW_WRITE]   = 1'b1;
			end
		end
		
		if ( state[ST_MW_WRITE] ) begin
			uart_rx_ready = 1'b0;
			
			if ( wb_dbg_ack_i ) begin
				// write end
				next_wb_dbg_stb_o = 1'b0;
								
				next_counter = counter + 1;
				next_address = address + 1;
				
				if ( counter == size ) begin
					// send ack
					next_uart_tx_en   = 1'b1;
					next_uart_tx_data = `ACK_MEM_WRIT;
					
					// go next state
					next_state[ST_MW_WRITE]    = 1'b0;
					next_state[ST_RETURN_IDLE] = 1'b1;
				end
				else begin
					// go next state
					next_state[ST_MW_WRITE]    = 1'b0;
					next_state[ST_MW_SET_ADDR] = 1'b1;
				end
			end
		end
		

		//  ---- Memory read ----

		// memory read
		if ( state[ST_MR_RX_SIZE] ) begin
			uart_rx_ready     = 1'b1;
			next_counter[1:0] = 2'b00;
			
			if ( uart_rx_en ) begin
				// receive size
				next_size = uart_rx_data;
				
				// go next state
				next_state[ST_MR_RX_SIZE] = 1'b0;
				next_state[ST_MR_RX_ADDR] = 1'b1;
			end
		end
		
		// mem read recv address
		if ( state[ST_MR_RX_ADDR] ) begin
			uart_rx_ready = 1'b1;
			
			if ( uart_rx_en ) begin
				// counter
				next_counter = counter + 1;
				
				// receive data
				if ( counter[1:0] == ({2{endian}} ^ 2'b00) ) next_address[7:0]   = uart_rx_data;
				if ( counter[1:0] == ({2{endian}} ^ 2'b01) ) next_address[15:8]  = uart_rx_data;
				if ( counter[1:0] == ({2{endian}} ^ 2'b10) ) next_address[23:16] = uart_rx_data;
				if ( counter[1:0] == ({2{endian}} ^ 2'b11) ) next_address[31:24] = uart_rx_data;
				
				if ( counter[1:0] == 2'b11 ) begin					
					// send ack
					next_uart_tx_en   = 1'b1;
					next_uart_tx_data = `ACK_MEM_READ;

					// go next state
					next_counter = 0;
					next_state[ST_MR_RX_ADDR] = 1'b0;
					next_state[ST_MR_TX_ACK]  = 1'b1;
				end
			end
		end
		
		if ( state[ST_MR_TX_ACK] ) begin
			uart_rx_ready = 1'b0;
			
			if ( uart_tx_ready ) begin
				next_uart_tx_en   = 1'b0;
				
				// go next state
				next_state[ST_MR_TX_ACK]   = 1'b0;		
				next_state[ST_MR_SET_ADDR] = 1'b1;
			end
		end
		
		if ( state[ST_MR_SET_ADDR] ) begin
			uart_rx_ready = 1'b0;
			
			// write
			next_wb_dbg_adr_o = 4'h2;	// DBG_ADDR
			next_wb_dbg_dat_o = {address[31:2], 2'b00};
			next_wb_dbg_we_o  = 1'b1;
			next_wb_dbg_sel_o = 4'b1111;
			next_wb_dbg_stb_o = 1'b1;
			
			// go next state
			next_state[ST_MR_SET_ADDR] = 1'b0;
			next_state[ST_MR_WAI_ADDR] = 1'b1;
		end
		
		if ( state[ST_MR_WAI_ADDR] ) begin
			uart_rx_ready = 1'b0;
			
			if ( wb_dbg_ack_i ) begin
				// read start
				next_wb_dbg_adr_o    = 4'h6;	// DBG_DBUS
				next_wb_dbg_we_o     = 1'b0;
				next_wb_dbg_sel_o[0] = (address[1:0] == ({2{endian}} ^ 2'b00));
				next_wb_dbg_sel_o[1] = (address[1:0] == ({2{endian}} ^ 2'b01));
				next_wb_dbg_sel_o[2] = (address[1:0] == ({2{endian}} ^ 2'b10));
				next_wb_dbg_sel_o[3] = (address[1:0] == ({2{endian}} ^ 2'b11));
				
				// go next state
				next_state[ST_MR_WAI_ADDR] = 1'b0;
				next_state[ST_MR_READ]     = 1'b1;
			end
		end
		
		// read
		if ( state[ST_MR_READ] ) begin
			uart_rx_ready = 1'b0;
			if ( wb_dbg_ack_i ) begin
				next_wb_dbg_stb_o = 1'b0;
				next_uart_tx_en   = 1'b1;
				if ( address[1:0] == ({2{endian}} ^ 2'b00) ) next_uart_tx_data = wb_dbg_dat_i[7:0];
				if ( address[1:0] == ({2{endian}} ^ 2'b01) ) next_uart_tx_data = wb_dbg_dat_i[15:8];
				if ( address[1:0] == ({2{endian}} ^ 2'b10) ) next_uart_tx_data = wb_dbg_dat_i[23:16];
				if ( address[1:0] == ({2{endian}} ^ 2'b11) ) next_uart_tx_data = wb_dbg_dat_i[31:24];
				
				// go next state
				next_state[ST_MR_READ]    = 1'b0;
				next_state[ST_MR_TX_DATA] = 1'b1;
			end
		end
		
		
		if ( state[ST_MR_TX_DATA] ) begin
			uart_rx_ready = 1'b0;
			
			if ( uart_tx_ready ) begin
				next_uart_tx_en = 1'b0;
				
				next_counter = counter + 1;
				next_address = address + 1;
				
				if ( counter == size ) begin					
					// go next state
					next_state[ST_MR_TX_DATA]  = 1'b0;
					next_state[ST_IDLE]        = 1'b1;
				end
				else begin
					// go next state
					next_state[ST_MR_TX_DATA]  = 1'b0;
					next_state[ST_MR_SET_ADDR] = 1'b1;
				end
			end
		end
	end
	
	
	// UART core
	jelly_uart_core
			#(
				.TX_FIFO_PTR_WIDTH	(TX_FIFO_PTR_WIDTH),
				.RX_FIFO_PTR_WIDTH	(RX_FIFO_PTR_WIDTH)
			)
		i_uart_core
			(
				.reset				(reset),
				.clk				(clk),
				
				.uart_clk			(uart_clk),
				.uart_tx			(uart_tx),
				.uart_rx			(uart_rx),
				
				.tx_en				(uart_tx_en),
				.tx_data			(uart_tx_data),
				.tx_ready			(uart_tx_ready),
				
				.rx_en				(uart_rx_en),
				.rx_data			(uart_rx_data),
				.rx_ready			(uart_rx_ready),
				
				.tx_fifo_free_num	(),
				.rx_fifo_data_num	()
			);


endmodule

