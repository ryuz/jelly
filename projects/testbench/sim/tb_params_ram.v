
`timescale 1ns / 1ps
`default_nettype none


module tb_params_ram();
	localparam RATE = 10.0;
	
	initial begin
		$dumpfile("tb_params_ram.vcd");
		$dumpvars(0, tb_params_ram);
	end
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		reset = 1'b1;
	always #(RATE*10)	reset = 1'b0;
	
	
	parameter	NUM        = 5;
	parameter	BANK_WIDTH = 1;
	parameter	DATA_WIDTH = 32;
	parameter	ADDR_WIDTH = NUM <=     2 ?  1 :
	                         NUM <=     4 ?  2 :
	                         NUM <=     8 ?  3 :
	                         NUM <=    16 ?  4 :
	                         NUM <=    32 ?  5 :
	                         NUM <=    64 ?  6 :
	                         NUM <=   128 ?  7 :
	                         NUM <=   256 ?  8 :
	                         NUM <=   512 ?  9 :
	                         NUM <=  1024 ? 10 :
	                         NUM <=  2048 ? 11 :
	                         NUM <=  4096 ? 12 :
	                         NUM <=  8192 ? 13 :
	                         NUM <= 16384 ? 14 :
	                         NUM <= 32768 ? 15 : 16;	// ˆê•”ˆ—Œn‚Å $clog2 ‚ª³‚µ‚­“®‚©‚È‚¢‚Ì‚Å
	parameter	WRITE_ONLY   = 1;
	parameter	DOUT_REGS    = 0;
	parameter	RAM_TYPE     = "distributed";
	parameter	INIT_PARAMS  = {(NUM*DATA_WIDTH){1'b0}};
	
	parameter	BANK_BITS    = BANK_WIDTH > 0 ? BANK_WIDTH : 1;
	
	
	reg									start;
	wire								busy;
	
	reg		[BANK_BITS-1:0]				bank;
	wire	[NUM*DATA_WIDTH-1:0]		params;
	
	wire								mem_clk    = clk;
	reg									mem_en     = 1'b1;
	reg									mem_regcke = 1'b1;
	reg									mem_we     = 1'b0;
	reg		[BANK_WIDTH+ADDR_WIDTH-1:0]	mem_addr;
	reg		[DATA_WIDTH-1:0]			mem_din;
	wire	[DATA_WIDTH-1:0]			mem_dout;
	
	jelly_params_ram
			#(
				.NUM			(NUM),
				.BANK_WIDTH		(BANK_WIDTH),
				.DATA_WIDTH		(DATA_WIDTH),
				.WRITE_ONLY		(WRITE_ONLY),
				.DOUT_REGS		(DOUT_REGS),
				.RAM_TYPE		(RAM_TYPE),
				.INIT_PARAMS	(INIT_PARAMS)
			)
		i_params_ram
			(
				.reset			(reset),
				.clk			(clk),
				
				.start			(start),
				.busy			(busy),
				
				.bank			(bank),
				.params			(params),
				
				.mem_clk		(mem_clk),
				.mem_en			(mem_en),
				.mem_regcke		(mem_regcke),
				.mem_we			(mem_we),
				.mem_addr		(mem_addr),
				.mem_din		(mem_din),
				.mem_dout		(mem_dout)
			);
	
	initial begin
		@(negedge reset);
		@(posedge clk);
		@(posedge clk);
		
		@(posedge clk)
			mem_we    <= 1'b1;
			mem_addr  <= 4'h0;
			mem_din   <= 32'h0101;
		@(posedge clk)
			mem_we    <= 1'b1;
			mem_addr  <= 4'h1;
			mem_din   <= 32'h0102;
		@(posedge clk)
			mem_we    <= 1'b1;
			mem_addr  <= 4'h2;
			mem_din   <= 32'h0103;
		@(posedge clk)
			mem_we    <= 1'b1;
			mem_addr  <= 4'h3;
			mem_din   <= 32'h0104;
		@(posedge clk)
			mem_we    <= 1'b1;
			mem_addr  <= 4'h4;
			mem_din   <= 32'h0105;
		
		@(posedge clk)
			mem_we    <= 1'b1;
			mem_addr  <= 4'h8;
			mem_din   <= 32'h0201;
		@(posedge clk)
			mem_we    <= 1'b1;
			mem_addr  <= 4'h9;
			mem_din   <= 32'h0202;
		@(posedge clk)
			mem_we    <= 1'b1;
			mem_addr  <= 4'ha;
			mem_din   <= 32'h0203;
		@(posedge clk)
			mem_we    <= 1'b1;
			mem_addr  <= 4'hb;
			mem_din   <= 32'h0204;
		@(posedge clk)
			mem_we    <= 1'b1;
			mem_addr  <= 4'hc;
			mem_din   <= 32'h0205;
		@(posedge clk)
			mem_we    <= 1'b0;
			
			
		@(posedge clk)
			start     <= 1'b1;
			bank      <= 0;
		@(posedge clk);
			start     <= 1'b0;
		
		#1000
			$finish();
	end
	
	
endmodule


`default_nettype wire


// end of file
