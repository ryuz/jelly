`timescale 1ns / 1ps


`define IRC_ADR_ENABLE				0
`define IRC_ADR_MASK				1
`define IRC_ADR_REQ_FACTOR_ID		2
`define IRC_ADR_REQ_PRIORITY		3
`define IRC_ADR_FACTOR_NUM			4
`define IRC_ADR_PRIORITY_MAX		5
`define IRC_ADR_FACTOR_BASE			8



module tb_irc;
	parameter	RATE       = 10;
	
	
	initial begin
		$dumpfile("tb_irc.vcd");
		$dumpvars(0, tb_irc);
	end
	
	
	// reset
	reg		reset;
	initial begin
		#0			reset = 1'b1;
		#(RATE*10)	reset = 1'b0;
	end
	
	
	// clock
	reg		clk;
	initial begin
		clk    = 1'b1;
	end
	always #(RATE/2) begin
		clk = ~clk;
	end
	
	
	
	reg		[2:0]	in_interrupt;
	wire			cpu_irq;
	
	reg		[15:0]	wb_adr_i;
	wire	[31:0]	wb_dat_o;
	reg		[31:0]	wb_dat_i;
	reg				wb_we_i;
	reg		[3:0]	wb_sel_i;
	reg				wb_stb_i;
	wire			wb_ack_o;
	
	jelly_irc
			#(
				.FACTOR_ID_WIDTH	(2),
				.FACTOR_NUM			(3),
				.PRIORITY_WIDTH		(4),
				
				.WB_ADR_WIDTH		(16),
				.WB_DAT_WIDTH		(32)
			)
		i_irc
			(
				.clk				(clk),
				.reset				(reset),
				
				.in_interrupt		(in_interrupt),
				
				.cpu_irq			(cpu_irq),
				.cpu_irq_ack		(1'b0),
				
				.wb_adr_i			(wb_adr_i),
				.wb_dat_o			(wb_dat_o),
				.wb_dat_i			(wb_dat_i),
				.wb_we_i			(wb_we_i),
				.wb_sel_i			(wb_sel_i),
				.wb_stb_i			(wb_stb_i),
				.wb_ack_o			(wb_ack_o)
			);
	
	task wb_write;
	input	[15:0]	addr;
	input	[31:0]	data;
	begin
		@(negedge clk)	wb_adr_i = addr;
						wb_dat_i = data;
						wb_we_i  = 1'b1;
						wb_sel_i = 4'b1111;
						wb_stb_i = 1'b1;
		
		@(posedge clk)
						$display("write[%h] : %h", addr, data);
						
		@(negedge clk)	wb_adr_i = {16{1'bx}};
						wb_dat_i = {32{1'bx}};
						wb_we_i  = 1'bx;
						wb_sel_i = 4'bxxxx;
						wb_stb_i = 1'b0;
	end
	endtask

	task wb_read;
	input	[15:0]	addr;
	begin
		@(negedge clk)	wb_adr_i = addr;
						wb_dat_i = {32{1'bx}};
						wb_we_i  = 1'b0;
						wb_sel_i = 4'b1111;
						wb_stb_i = 1'b1;
		
		@(posedge clk)
						$display("read[%h] : %h", addr, wb_dat_o);
		
		@(negedge clk)	wb_adr_i = {16{1'bx}};
						wb_dat_i = {32{1'bx}};
						wb_we_i  = 1'bx;
						wb_sel_i = 4'bxxxx;
						wb_stb_i = 1'b0;
	end
	endtask
	
	
	initial begin
		#(0)
						in_interrupt = 0;
						wb_stb_i     = 1'b0;
		
		
					// initialize irc 
		#(RATE * 20)
						wb_write(0, 0);			// disable
						wb_write(1, 7);			// mask

						wb_write(11 + 4*0, 3);	// fac0: pri
						wb_write(11 + 4*1, 2);	// fac0: pri
						wb_write(11 + 4*2, 1);	// fac0: pri
						
						wb_write(8  + 4*0, 1);	// fac0: enable
						wb_write(8  + 4*1, 1);	// fac1: enable
						wb_write(8  + 4*2, 1);	// fac2: enable

						wb_write(0, 1);			// enable

					// start
		#(RATE * 20)	in_interrupt[1] = 1'b1;
		#(RATE * 2)		in_interrupt[1] = 1'b0;
		
		#(RATE * 20)	in_interrupt[0] = 1'b1;
		#(RATE * 2)		in_interrupt[0] = 1'b0;

		#(RATE * 20)	in_interrupt[2] = 1'b1;
		#(RATE * 2)		in_interrupt[2] = 1'b0;
		
		
		#(RATE * 100)	$finish;
	end
	
	
endmodule

