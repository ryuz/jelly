// ---------------------------------------------------------------------------
//  Jelly
//
//                                 Copyright (C) 2009 by Ryuji Fuchikami 
//                                 http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


module jelly_jbus_monitor
		#(
			parameter				ADDR_WIDTH = 12,
			parameter				DATA_SIZE  = 2,		// 2^n (0:8bit, 1:16bit, 2:32bit ...)
			parameter				DATA_WIDTH = (8 << DATA_SIZE),
			parameter				BLS_WIDTH  = (1 << DATA_SIZE),
			parameter	[8*16:1]	MESSAGE    = "[jbus mon]"
		)
		(
			// system
			input	wire						clk,
			input	wire						reset,
			
			// slave port
			input	wire						jbus_en,
			input	wire						jbus_we,
			input	wire	[ADDR_WIDTH-1:0]	jbus_addr,
			input	wire	[BLS_WIDTH-1:0]		jbus_bls,
			input	wire	[DATA_WIDTH-1:0]	jbus_wdata,
			input	wire	[DATA_WIDTH-1:0]	jbus_rdata,
			input	wire						jbus_ready
		);
	
	reg						read_busy;
	reg	[ADDR_WIDTH-1:0]	read_addr;

	initial begin
		read_busy = 1'b0;
	end
	
	always @(posedge clk) begin
		if ( reset ) begin
			read_busy <= 1'b0;
			read_addr <= {ADDR_WIDTH{1'bx}};
		end
		else begin
			if ( jbus_en & !jbus_we & jbus_ready ) begin
				read_busy <= 1'b1;
				read_addr <= jbus_addr;
			end 
			else if ( jbus_ready ) begin
				read_busy <= 1'b0;
				read_addr <= {ADDR_WIDTH{1'bx}};
			end

			if ( read_busy & jbus_ready ) begin
				$display("%t %s read  adr:%h data:%h", $time, MESSAGE, read_addr, jbus_rdata);
			end

			if ( jbus_en & jbus_we & jbus_ready ) begin
				$display("%t %s write adr:%h data:%h bls:%b", $time, MESSAGE, jbus_addr, jbus_wdata, jbus_bls);
			end
		end
	end

endmodule


// end of file
