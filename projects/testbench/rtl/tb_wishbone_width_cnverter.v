`timescale 1ns / 1ps


module tb_wishbone_width_cnverter;

	parameter	RATE             = 20;

	parameter	SLAVE_DAT_SIZE   = 2;	// 2^n (0:8bit, 1:16bit, 2:32bit ...)
	parameter	MASTER_DAT_SIZE  = 1;	// 2^n (0:8bit, 1:16bit, 2:32bit ...)
	parameter	SLAVE_ADR_WIDTH  = 30;
	parameter	SLAVE_DAT_WIDTH  = (8 << SLAVE_DAT_SIZE);
	parameter	SLAVE_SEL_WIDTH  = (1 << SLAVE_DAT_SIZE);
	parameter	MASTER_ADR_WIDTH = SLAVE_ADR_WIDTH + MASTER_DAT_SIZE - SLAVE_DAT_SIZE;
	parameter	MASTER_DAT_WIDTH = (8 << MASTER_DAT_SIZE);
	parameter	MASTER_SEL_WIDTH = (1 << MASTER_DAT_SIZE);

		
	initial begin
		$dumpfile("tb_wishbone_width_cnverter.vcd");
		$dumpvars(0, tb_wishbone_width_cnverter);
	end
	
	// clock
	reg		clk;
	initial begin
		clk    = 1'b1;
	end
	always #(RATE/2) begin
		clk = ~clk;
	end
	
	// reset
	reg		reset;
	initial begin
		#0			reset = 1'b1;
		#(RATE*10)	reset = 1'b0;
	end
	
	wire	[SLAVE_ADR_WIDTH-1:0]	wb_slave_adr_i;
	wire	[SLAVE_DAT_WIDTH-1:0]	wb_slave_dat_o;
	wire	[SLAVE_DAT_WIDTH-1:0]	wb_slave_dat_i;
	wire							wb_slave_we_i;
	wire	[SLAVE_SEL_WIDTH-1:0]	wb_slave_sel_i;
	wire							wb_slave_stb_i;
	wire							wb_slave_ack_o;

	wire	[MASTER_ADR_WIDTH-1:0]	wb_master_adr_o;
	wire	[MASTER_DAT_WIDTH-1:0]	wb_master_dat_o;
	wire	[MASTER_DAT_WIDTH-1:0]	wb_master_dat_i;
	wire							wb_master_we_o;
	wire	[MASTER_SEL_WIDTH-1:0]	wb_master_sel_o;
	wire							wb_master_stb_o;
	wire							wb_master_ack_i;
	
	// width converter
	jelly_wishbone_width_cnverter
			#(
				.SLAVE_DAT_SIZE		(SLAVE_DAT_SIZE),	// 2^n (0:8bit, 1:16bit, 2:32bit ...)
				.MASTER_DAT_SIZE	(MASTER_DAT_SIZE),	// 2^n (0:8bit, 1:16bit, 2:32bit ...)
				.SLAVE_ADR_WIDTH	(SLAVE_ADR_WIDTH)
			)                     
		i_wishbone_width_cnverter
			(
				.clk				(clk),
				.reset				(reset),
				
				.endian				(1'b1),
								
				.wb_slave_adr_i		(wb_slave_adr_i),
				.wb_slave_dat_o		(wb_slave_dat_o),
				.wb_slave_dat_i		(wb_slave_dat_i),
				.wb_slave_we_i		(wb_slave_we_i),
				.wb_slave_sel_i		(wb_slave_sel_i),
				.wb_slave_stb_i		(wb_slave_stb_i),
				.wb_slave_ack_o		(wb_slave_ack_o),
								     				
				.wb_master_adr_o	(wb_master_adr_o),
				.wb_master_dat_o	(wb_master_dat_o),
				.wb_master_dat_i	(wb_master_dat_i),
				.wb_master_we_o		(wb_master_we_o	),
				.wb_master_sel_o	(wb_master_sel_o),
				.wb_master_stb_o	(wb_master_stb_o),
				.wb_master_ack_i	(wb_master_ack_i)
			);                     
	
	jelly_wishbone_master_model
			#(
				.ADR_WIDTH			(MASTER_ADR_WIDTH),
				.DAT_SIZE			(MASTER_DAT_SIZE),
				.TABLE_FILE			("widthconv.dat"),
				.TABLE_SIZE			(256)
			)
		jelly_wishbone_test_model
			(
				.clk				(clk),
				.reset				(reset),
				
				.wb_master_adr_o	(wb_slave_adr_i),
				.wb_master_dat_o	(wb_slave_dat_o),
				.wb_master_dat_i	(wb_slave_dat_i),
				.wb_master_we_o		(wb_slave_we_i),
				.wb_master_sel_o	(wb_slave_sel_i),
				.wb_master_stb_o	(wb_slave_stb_i),
				.wb_master_ack_i	(wb_slave_ack_o)
			);                     
	
	jelly_wishbone_slave_model
			#(
				.ADR_WIDTH			(10),
				.DAT_SIZE			(4)		// 2^n (0:8bit, 1:16bit, 2:32bit ...)
			)
		i_wishbone_slave_model
			(
				.clk				(clk),
				.reset				(reset),
				
				.wb_slave_adr_i		(wb_master_adr_o),
				.wb_slave_dat_i		(wb_master_dat_o),
				.wb_slave_dat_o		(wb_master_dat_i),
				.wb_slave_we_i		(wb_master_we_o),
				.wb_slave_sel_i		(wb_master_sel_o),
				.wb_slave_stb_i		(wb_master_stb_o),
				.wb_slave_ack_o		(wb_master_ack_i)
			);                     
	
	initial begin
		#(RATE*2000)
			$display("time out");
			$finish;
	end
	
endmodule

