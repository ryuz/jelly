`timescale 1ns / 1ps


module tb_wishbone_cache;
	parameter	RATE       = 20;
		
	initial begin
		$dumpfile("tb_wishbone_cache.vcd");
		$dumpvars(0, tb_wishbone_cache);
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
		
	reg					jbus_slave_en;
	reg		[11:0]		jbus_slave_addr;
	reg		[31:0]		jbus_slave_wdata;
	wire	[31:0]		jbus_slave_rdata;
	reg					jbus_slave_we;
	reg		[3:0]		jbus_slave_sel;
	reg					jbus_slave_valid;
	wire				jbus_slave_ready;
	
	wire	[9:0]		wb_master_adr_o;
	wire	[127:0]		wb_master_dat_i;
	wire	[127:0]		wb_master_dat_o;
	wire				wb_master_we_o;
	wire	[15:0]		wb_master_sel_o;
	wire				wb_master_stb_o;
	wire				wb_master_ack_i;
	
	wire				ram_en;
	wire				ram_we;
	wire	[7:0]		ram_addr;
	wire	[3+127:0]	ram_wdata;
	wire	[3+127:0]	ram_rdata;
	
	jelly_wishbone_cache
			#(
				.LINE_SIZE			(2),	// 2^n (0:1words, 1:2words, 2:4words ...)
				.ARRAY_SIZE			(8),	// 2^n (1:2lines, 2:4lines 3:8lines ...)
				.SLAVE_ADDR_WIDTH	(12),
				.SLAVE_DATA_SIZE	(2)		// 2^n (0:8bit, 1:16bit, 2:32bit ...)
			)
		i_wishbone_cache
			(
				.clk				(clk),
				.reset				(reset),
				.endian				(1'b1),
				
				.jbus_slave_en		(jbus_slave_en),
				.jbus_slave_addr	(jbus_slave_addr),
				.jbus_slave_wdata	(jbus_slave_wdata),
				.jbus_slave_rdata	(jbus_slave_rdata),
				.jbus_slave_we		(jbus_slave_we),
				.jbus_slave_sel		(jbus_slave_sel),
				.jbus_slave_valid	(jbus_slave_valid),
				.jbus_slave_ready	(jbus_slave_ready),
				
				.wb_master_adr_o	(wb_master_adr_o),
				.wb_master_dat_o	(wb_master_dat_o),
				.wb_master_dat_i	(wb_master_dat_i),
				.wb_master_we_o		(wb_master_we_o),
				.wb_master_sel_o	(wb_master_sel_o),
				.wb_master_stb_o	(wb_master_stb_o),
				.wb_master_ack_i	(wb_master_ack_i),
				
				.ram_en				(ram_en),
				.ram_we				(ram_we),
				.ram_addr			(ram_addr),
				.ram_wdata			(ram_wdata),
				.ram_rdata			(ram_rdata)
			);                     
	
	jelly_ram_singleport
			#(
				.ADDR_WIDTH			(8),
				.DATA_WIDTH 		(1+2+128),
				.WRITE_FIRST		(1),				
				.FILLMEM			(1),
				.FILLMEM_DATA		(0)
			)
		i_jelly_ram_singleport
			(
				.clk				(clk),
				.reset				(1'b0),
				
				.en					(ram_en),
				.we					(ram_we),
				.addr				(ram_addr),
				.din				(ram_wdata),
				.dout				(ram_rdata)	
			); 
	
	jelly_wishbone_slave_model
			#(
				.ADR_WIDTH			(10),
				.DAT_SIZE			(4)		// 2^n (0:8bit, 1:16bit, 2:32bit ...)
			)
		i_jbus_slave_model
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
	
	jelly_jbus_tracer
			#(
				.ADDR_WIDTH		(12),
				.DATA_SIZE		(2),				// 2^n (0:8bit, 1:16bit, 2:32bit ...)
				.MESSAGE		("[cpu]")
			)
		i_bus_tracer_cpu
			(
				.clk			(clk),
				.reset			(reset),
				
				.jbus_en		(jbus_slave_en),
				.jbus_addr		(jbus_slave_addr),
				.jbus_wdata		(jbus_slave_wdata),
				.jbus_rdata		(jbus_slave_rdata),
				.jbus_we		(jbus_slave_we),
				.jbus_sel		(jbus_slave_sel),
				.jbus_valid		(jbus_slave_valid),
				.jbus_ready		(jbus_slave_ready)
			);                 
	
	jelly_wishbone_logger
			#(
				.ADR_WIDTH		(10),
				.DAT_SIZE		(4),				// 2^n (0:8bit, 1:16bit, 2:32bit ...)
				.MESSAGE		("[mem]")
			)
		i_wishbone_logger
			(
				.clk			(clk),
				.reset			(reset),
				
				.wb_adr_o		(wb_master_adr_o),
				.wb_dat_o		(wb_master_dat_o),
				.wb_dat_i		(wb_master_dat_i),
				.wb_we_o		(wb_master_we_o),
				.wb_sel_o		(wb_master_sel_o),
				.wb_stb_o		(wb_master_stb_o),
				.wb_ack_i		(wb_master_ack_i)
			);                 
	
	initial begin
		jbus_slave_en    <= 1'b1;
		jbus_slave_addr  <= 0;
		jbus_slave_wdata <= 0;
		jbus_slave_we    <= 0;
		jbus_slave_sel   <= 0;
		jbus_slave_valid <= 0;
	end
	
	reg		[50:0]	test_table	[0:256];
	integer		i;
	initial i = 0;
	always @(posedge clk) begin
		if ( reset ) begin
			i <= 0;
		end
		else begin
			if ( jbus_slave_en & jbus_slave_ready ) begin
				if ( test_table[i][50] != 1'b1 ) begin
					jbus_slave_valid <= test_table[i][49];
					jbus_slave_we    <= test_table[i][48];
					jbus_slave_addr  <= test_table[i][47:36];
					jbus_slave_sel   <= test_table[i][35:32];
					jbus_slave_wdata <= test_table[i][31:0];
					i <= i + 1;
				end
				else begin
					$display("end");
					$finish;
				end
			end
		end
	end
	
	integer	index;
	initial begin
		index = 0;
		test_table[index] = {1'b0, 1'b1, 1'b1, 12'h000, 4'b1111, 32'h0001_0203};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b1, 12'h001, 4'b1111, 32'h0405_0607};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b1, 12'h002, 4'b1111, 32'h0809_0a0b};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b1, 12'h003, 4'b1111, 32'h0c0d_0e0f};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b1, 12'h004, 4'b1111, 32'h1011_1213};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b1, 12'h005, 4'b1111, 32'h1415_1617};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b1, 12'h006, 4'b1111, 32'h1819_1a1b};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b1, 12'h007, 4'b1111, 32'h1c1d_1e1f};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b1, 12'h008, 4'b1111, 32'h2021_2223};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b0, 12'h000, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b0, 12'h001, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b0, 12'h002, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b0, 12'h003, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b0, 12'h004, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b0, 12'h005, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b0, 12'h006, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b0, 12'h007, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b0, 12'h008, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		
		test_table[index] = {1'b0, 1'b1, 1'b1, 12'h000, 4'b1010, 32'haabb_ccdd};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b0, 12'h000, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b1, 12'h000, 4'b1010, 32'haabb_ccdd};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b0, 12'h000, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b0, 12'h000, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b1, 12'h000, 4'b1010, 32'haabb_ccdd};	index = index + 1;
		test_table[index] = {1'b0, 1'b1, 1'b1, 12'h000, 4'b0101, 32'haabb_ccdd};	index = index + 1;
		
		test_table[index] = {1'b0, 1'b0, 1'b0, 12'hxxx, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b0, 1'b0, 1'b0, 12'hxxx, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b0, 1'b0, 1'b0, 12'hxxx, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b0, 1'b0, 1'b0, 12'hxxx, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b0, 1'b0, 1'b0, 12'hxxx, 4'bxxxx, 32'hxxxx_xxxx};	index = index + 1;
		test_table[index] = {1'b1, 1'b0, 1'b0, 12'h000, 4'b0000, 32'h0000_0000};
	end
	
	initial begin
		#(RATE*2000)
			$display("time out");
			$finish;
	end
	
endmodule

