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
	localparam	ST_NUM          = 26;
	
	localparam	ST_IDLE         = 0;
	localparam	ST_NOP_TX_ACK   = 1;
	localparam	ST_STAT_TX_ACK  = 2;
	localparam	ST_STAT_TX_STAT = 3;
	localparam	ST_DW_RX_ADDR   = 4;
	localparam	ST_DW_RX_DATA   = 5;
	localparam	ST_DW_WRITE     = 6;
	localparam	ST_DW_TX_ACK    = 7;
	localparam	ST_DR_RX_ADDR   = 8;
	localparam	ST_DR_READ      = 9;
	localparam	ST_DR_TX_ACK    = 10;
	localparam	ST_DR_TX_DATA   = 11;
	localparam	ST_MW_RX_SIZE   = 12;
	localparam	ST_MW_RX_ADDR   = 13;
	localparam	ST_MW_SET_ADDR  = 14;
	localparam	ST_MW_WAI_ADDR  = 15;
	localparam	ST_MW_RX_DATA   = 16;
	localparam	ST_MW_WRITE     = 17;
	localparam	ST_MW_TX_ACK    = 18;
	localparam	ST_MR_RX_SIZE   = 19;
	localparam	ST_MR_RX_ADDR   = 20;
	localparam	ST_MR_TX_ACK    = 21;
	localparam	ST_MR_SET_ADDR  = 22;
	localparam	ST_MR_WAI_ADDR  = 23;
	localparam	ST_MR_READ      = 24;
	localparam	ST_MR_TX_DATA   = 25;
		
	wire					uart_rx_en;
	wire	[7:0]			uart_rx_data;
	reg						uart_rx_ready;
	
	reg						uart_tx_en;
	reg		[7:0]			uart_tx_data;
	wire					uart_tx_ready;

	reg		[3:0]			wb_dbg_adr_o;
	reg		[31:0]			wb_dbg_dat_o;
	reg						wb_dbg_we_o;
	reg		[3:0]			wb_dbg_sel_o;
	reg						wb_dbg_stb_o;
	
	reg		[4:0]			state;
	reg		[7:0]			counter;
	
	reg		[7:0]			size;
	reg		[31:0]			address;
	reg		[31:0]			read_data;
	
	
	reg		[3:0]			next_wb_dbg_adr_o;
	reg		[31:0]			next_wb_dbg_dat_o;
	reg						next_wb_dbg_we_o;
	reg		[3:0]			next_wb_dbg_sel_o;
	reg						next_wb_dbg_stb_o;
	
	reg		[4:0]			next_state;
	reg		[7:0]			next_counter;
	
	reg		[7:0]			next_size;
	reg		[31:0]			next_address;
	reg		[31:0]			next_read_data;
	
	
	// FF
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			wb_dbg_adr_o  <= {4{1'bx}};
			wb_dbg_dat_o  <= {32{1'bx}};
			wb_dbg_we_o   <= 1'bx;
			wb_dbg_sel_o  <= {4{1'bx}};
			wb_dbg_stb_o  <= 1'b0;
			state         <= ST_IDLE;
			counter       <= 0;
			size          <= {8{1'bx}};
			address       <= {32{1'bx}};
			read_data     <= {32{1'bx}};
		end
		else begin
			wb_dbg_adr_o  <= next_wb_dbg_adr_o;
			wb_dbg_dat_o  <= next_wb_dbg_dat_o;
			wb_dbg_we_o   <= next_wb_dbg_we_o;
			wb_dbg_sel_o  <= next_wb_dbg_sel_o;
			wb_dbg_stb_o  <= next_wb_dbg_stb_o;
			state         <= next_state;
			counter       <= next_counter;
			size          <= next_size;
			address       <= next_address;
			read_data     <= next_read_data;
		end
	end
	
	// combination
	always @* begin
		// combination logic
		uart_rx_ready = 1'b0;
		uart_tx_en    = 1'b0;
		uart_tx_data  = {8{1'bx}};
		
		// sequential logic
		next_state        = state;
		next_counter      = counter;
		next_wb_dbg_adr_o = wb_dbg_adr_o;
		next_wb_dbg_dat_o = wb_dbg_dat_o;
		next_wb_dbg_we_o  = wb_dbg_we_o;
		next_wb_dbg_sel_o = wb_dbg_sel_o;
		next_wb_dbg_stb_o = wb_dbg_stb_o;
		next_size         = size;
		next_address      = address;
		next_read_data    = read_data;
		
		(* parallel_case *) (* full_case *)
		casex ( state )
		
		//  ---- Idle ----
		ST_IDLE: begin
			uart_rx_ready = 1'b1;
			
			// command recive & analyze
			if ( uart_rx_en ) begin
				case ( uart_rx_data )
				`CMD_NOP:
					begin
						next_state = ST_NOP_TX_ACK;
					end
				
				`CMD_STATUS:
					begin
						// go next state
						next_state = ST_STAT_TX_ACK;
					end
				
				`CMD_DBG_WRITE:
					begin
						// go next state
						next_state = ST_DW_RX_ADDR;
					end
					
				`CMD_DBG_READ:
					begin
						// go next state
						next_state = ST_DR_RX_ADDR;
					end

				`CMD_MEM_WRIT:
					begin
						// go next state
						next_state = ST_MW_RX_SIZE;
					end
					
				`CMD_MEM_READ:
					begin
						// go next state
						next_state = ST_MR_RX_SIZE;
					end
				endcase
			end
		end
		
				
		// ---- Nop ----
		
		// send ack
		ST_NOP_TX_ACK: begin
			// send ack
			uart_tx_en   = 1'b1;
			uart_tx_data = `ACK_NOP;
			if ( uart_tx_ready ) begin
				// go next state
				next_state = ST_IDLE;
			end
		end
		
		
				
		// ---- Status ----

		// status ack
		ST_STAT_TX_ACK : begin
			// send status
			uart_tx_en   = 1'b1;
			uart_tx_data = `ACK_STATUS;
			
			if ( uart_tx_ready ) begin
				// go next state
				next_state = ST_STAT_TX_STAT;
			end
		end
		
		// send status
		ST_STAT_TX_STAT: begin
			uart_tx_en   = 1'b1;
			uart_tx_data = endian;
			
			if ( uart_tx_ready ) begin
				// go next state
				next_state = ST_IDLE;
			end
		end
		
		
		
		// ---- Write debug register ----
		
		// dbg write recv addr
		ST_DW_RX_ADDR: begin
			uart_rx_ready     = 1'b1;
			next_wb_dbg_we_o  = 1'b1;
			next_counter[1:0] = 2'b00;
			
			if ( uart_rx_en ) begin
				// receive sel & adr
				next_wb_dbg_adr_o = uart_rx_data[3:0];
				next_wb_dbg_sel_o = uart_rx_data[7:4];
				
				// go next state
				next_state = ST_DW_RX_DATA;
			end
		end
		
		// dbg write recv data
		ST_DW_RX_DATA: begin
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
					next_state = ST_DW_WRITE;
				end
			end
		end
		
		// dbg write
		ST_DW_WRITE: begin
			if ( wb_dbg_ack_i ) begin
				// write end
				next_wb_dbg_stb_o = 1'b0;
								
				// go next state
				next_state = ST_DW_TX_ACK;
			end
		end

		ST_DW_TX_ACK: begin
			// send ack
			uart_tx_en   = 1'b1;
			uart_tx_data = `ACK_DBG_WRITE;
			
			if ( uart_tx_ready ) begin
				// go next state
				next_state = ST_IDLE;
			end
		end
		
		
		// ---- Read debug register ----
	
		// dbg read
		ST_DR_RX_ADDR: begin
			uart_rx_ready     = 1'b1;
			
			next_wb_dbg_we_o  = 1'b0;
			next_counter[1:0] = 2'b00;
			
			if ( uart_rx_en ) begin
				// receive sel & adr
				next_wb_dbg_adr_o = uart_rx_data[3:0];
				next_wb_dbg_sel_o = uart_rx_data[7:4];
				next_wb_dbg_stb_o = 1'b1;
				
				// go next state
				next_state = ST_DR_READ;
			end
		end
		
		// dbg read
		ST_DR_READ: begin
			// read data
			next_read_data = wb_dbg_dat_i;
			
			if ( wb_dbg_ack_i ) begin
				// read
				next_wb_dbg_stb_o = 1'b0;
								
				// go next state
				next_state = ST_DR_TX_ACK;
			end
		end
		
		ST_DR_TX_ACK: begin
			// send ack
			uart_tx_en   = 1'b1;
			uart_tx_data = `ACK_DBG_READ;
			
			if ( uart_tx_ready ) begin
				// go next state
				next_state = ST_DR_TX_DATA;
			end
		end
		
		ST_DR_TX_DATA: begin
			// send data
			uart_tx_en = 1'b1;
			if ( counter[1:0] == ({2{endian}} ^ 2'b00) ) 		uart_tx_data = read_data[7:0];
			else if ( counter[1:0] == ({2{endian}} ^ 2'b01) )	uart_tx_data = read_data[15:8];
			else if ( counter[1:0] == ({2{endian}} ^ 2'b10) )	uart_tx_data = read_data[23:16];
			else if ( counter[1:0] == ({2{endian}} ^ 2'b11) )	uart_tx_data = read_data[31:24];
			
			if ( uart_tx_ready ) begin
				next_counter = counter + 1;
				if ( counter[1:0] == 2'b11 ) begin
					// go to next state
					next_state = ST_IDLE;
				end
			end
		end
		
		
		
		// ---- Write memory ----
		
		// memory write
		ST_MW_RX_SIZE: begin
			uart_rx_ready     = 1'b1;
			next_counter[1:0] = 2'b00;
			next_size = uart_rx_data;
			
			if ( uart_rx_en ) begin
				// go next state
				next_state = ST_MW_RX_ADDR;
			end
		end
		
		// mem write recv address
		ST_MW_RX_ADDR: begin
			uart_rx_ready = 1'b1;
			
			// receive data
			if ( counter[1:0] == ({2{endian}} ^ 2'b00) ) next_address[7:0]   = uart_rx_data;
			if ( counter[1:0] == ({2{endian}} ^ 2'b01) ) next_address[15:8]  = uart_rx_data;
			if ( counter[1:0] == ({2{endian}} ^ 2'b10) ) next_address[23:16] = uart_rx_data;
			if ( counter[1:0] == ({2{endian}} ^ 2'b11) ) next_address[31:24] = uart_rx_data;
			
			if ( uart_rx_en ) begin
				// counter
				next_counter = counter + 1;
				
				if ( counter[1:0] == 2'b11 ) begin					
					// go next state
					next_counter = 0;
					next_state   = ST_MW_SET_ADDR;
				end
			end
		end
		
		ST_MW_SET_ADDR: begin			
			// write
			next_wb_dbg_adr_o = 4'h2;	// DBG_ADDR
			next_wb_dbg_dat_o = {address[31:2], 2'b00};
			next_wb_dbg_we_o  = 1'b1;
			next_wb_dbg_sel_o = 4'b1111;
			next_wb_dbg_stb_o = 1'b1;
			
			// go next state
			next_state = ST_MW_WAI_ADDR;
		end
		
		ST_MW_WAI_ADDR: begin
			if ( wb_dbg_ack_i ) begin
				// write end
				next_wb_dbg_stb_o = 1'b0;
				
				// go next state
				next_state = ST_MW_RX_DATA;
			end
		end
		
		// recv write data
		ST_MW_RX_DATA: begin
			uart_rx_ready = 1'b1;
			
			next_wb_dbg_adr_o    = 4'h6;	// DBG_DBUS
			next_wb_dbg_dat_o    = {4{uart_rx_data}};
			next_wb_dbg_sel_o[0] = (address[1:0] == ({2{endian}} ^ 2'b00));
			next_wb_dbg_sel_o[1] = (address[1:0] == ({2{endian}} ^ 2'b01));
			next_wb_dbg_sel_o[2] = (address[1:0] == ({2{endian}} ^ 2'b10));
			next_wb_dbg_sel_o[3] = (address[1:0] == ({2{endian}} ^ 2'b11));
			
			if ( uart_rx_en ) begin
				// write
				next_wb_dbg_stb_o = 1'b1;
				
				// go next state
				next_state = ST_MW_WRITE;
			end
		end
		
		ST_MW_WRITE: begin
			if ( wb_dbg_ack_i ) begin
				// write end
				next_wb_dbg_stb_o = 1'b0;
								
				next_counter = counter + 1;
				next_address = address + 1;
				
				if ( counter == size ) begin		
					// go next state
					next_state = ST_MW_TX_ACK;
				end
				else begin
					// go next state
					next_state = ST_MW_SET_ADDR;
				end
			end
		end
		
		ST_MW_TX_ACK: begin
			// send ack
			uart_tx_en   = 1'b1;
			uart_tx_data = `ACK_MEM_WRIT;
			if ( uart_tx_ready ) begin
				// next state
				next_state = ST_IDLE;
			end
		end
		
		
		//  ---- Memory read ----

		// memory read
		ST_MR_RX_SIZE: begin
			uart_rx_ready     = 1'b1;
			next_counter[1:0] = 2'b00;
			next_size = uart_rx_data;
			
			if ( uart_rx_en ) begin
				// go next state
				next_state = ST_MR_RX_ADDR;
			end
		end
		
		// mem read recv address
		ST_MR_RX_ADDR: begin
			uart_rx_ready = 1'b1;

			// receive data
			if ( counter[1:0] == ({2{endian}} ^ 2'b00) ) next_address[7:0]   = uart_rx_data;
			if ( counter[1:0] == ({2{endian}} ^ 2'b01) ) next_address[15:8]  = uart_rx_data;
			if ( counter[1:0] == ({2{endian}} ^ 2'b10) ) next_address[23:16] = uart_rx_data;
			if ( counter[1:0] == ({2{endian}} ^ 2'b11) ) next_address[31:24] = uart_rx_data;
			
			if ( uart_rx_en ) begin
				// counter
				next_counter = counter + 1;
				
				if ( counter[1:0] == 2'b11 ) begin					
					// go next state
					next_state = ST_MR_TX_ACK;
				end
			end
		end
		
		
		ST_MR_TX_ACK:  begin
			// send ack
			uart_tx_en   = 1'b1;
			uart_tx_data = `ACK_MEM_READ;
			next_counter = 0;
			
			if ( uart_tx_ready ) begin
				// go next state
				next_state = ST_MR_SET_ADDR;
			end
		end
		
		ST_MR_SET_ADDR: begin	
			// write
			next_wb_dbg_adr_o = 4'h2;	// DBG_ADDR
			next_wb_dbg_dat_o = {address[31:2], 2'b00};
			next_wb_dbg_we_o  = 1'b1;
			next_wb_dbg_sel_o = 4'b1111;
			next_wb_dbg_stb_o = 1'b1;
			
			// go next state
			next_state = ST_MR_WAI_ADDR;
		end
		
		ST_MR_WAI_ADDR: begin
			if ( wb_dbg_ack_i ) begin
				// read start
				next_wb_dbg_adr_o    = 4'h6;	// DBG_DBUS
				next_wb_dbg_we_o     = 1'b0;
				next_wb_dbg_sel_o[0] = (address[1:0] == ({2{endian}} ^ 2'b00));
				next_wb_dbg_sel_o[1] = (address[1:0] == ({2{endian}} ^ 2'b01));
				next_wb_dbg_sel_o[2] = (address[1:0] == ({2{endian}} ^ 2'b10));
				next_wb_dbg_sel_o[3] = (address[1:0] == ({2{endian}} ^ 2'b11));
				
				// go next state
				next_state = ST_MR_READ;
			end
		end
		
		// read
		ST_MR_READ: begin
			next_read_data = wb_dbg_dat_i;
			if ( wb_dbg_ack_i ) begin
				next_wb_dbg_stb_o = 1'b0;
				
				// go next state
				next_state = ST_MR_TX_DATA;
			end
		end
		
		
		ST_MR_TX_DATA: begin
			uart_tx_en   = 1'b1;
			if ( address[1:0] == ({2{endian}} ^ 2'b00) )		uart_tx_data = read_data[7:0];
			else if ( address[1:0] == ({2{endian}} ^ 2'b01) )	uart_tx_data = read_data[15:8];
			else if ( address[1:0] == ({2{endian}} ^ 2'b10) )	uart_tx_data = read_data[23:16];
			else if ( address[1:0] == ({2{endian}} ^ 2'b11) )	uart_tx_data = read_data[31:24];
			
			if ( uart_tx_ready ) begin
				next_counter = counter + 1;
				next_address = address + 1;
				
				if ( counter == size ) begin					
					// go next state
					next_state = ST_IDLE;
				end
				else begin
					// go next state
					next_state = ST_MR_SET_ADDR;
				end
			end
		end
		endcase
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

