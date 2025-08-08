
# リニアなデータをディスプレイ表示用にガンマ補正するテーブルを生成

import numpy as np

gamma = 2.2

print("""

`timescale 1ns / 1ps
`default_nettype none

module gamma_table
        (
            input   var logic   [9:0]       addr    ,
            output  var logic   [7:0]       data    
        );
    
    always_comb begin
        case ( addr )
""")

for i in range(1024):
    x = i / 1023.0
    y = int(np.around(np.clip(255 * (x ** (1.0 / gamma)), 0, 255)))
    print(f"        10'd{i:<5} : data = {y};")

print("""\
        default : data = 8'h00;
        endcase
    end
endmodule

`default_nettype wire

""")

