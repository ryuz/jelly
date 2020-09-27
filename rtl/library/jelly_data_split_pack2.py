
num1 = 10
num2 = 10


file_header = '''// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly_data_split_pack2
        #(
'''

file_footer = '''endmodule


`default_nettype wire


// end of file
'''


def main():
    with open('jelly_data_split_pack2.v', 'w') as f:
        f.write(file_header)
        f.write('            parameter NUM           = 1,\n')
        for i in range(num1):
            for j in range(num2):
                f.write('            parameter DATA%d_%d_WIDTH = 0,\n' % (i ,j))
        f.write('            parameter S_REGS        = 1,\n')
#       f.write('            parameter M_REGS        = 1,\n')
        f.write('            \n')
        f.write('            // local\n')
        for i in range(num1):
            for j in range(num2):
                f.write('            parameter DATA%d_%d_BITS  = DATA%d_%d_WIDTH > 0 ? DATA%d_%d_WIDTH : 1' % (i, j, i, j, i, j))
                if i == num1-1 and j == num2-1:
                    f.write('\n')
                else:
                    f.write(',\n')
        f.write('        )\n')
        f.write('        (\n')
        f.write('            input   wire                        reset,\n')
        f.write('            input   wire                        clk,\n')
        f.write('            input   wire                        cke,\n')
        f.write('            \n')
        for i in range(num1):
            for j in range(num2):
                f.write('            input   wire    [DATA%d_%d_BITS-1:0]  s_data%d_%d,\n' % (i, j, i, j))
        f.write('            input   wire                        s_valid,\n')
        f.write('            output  wire                        s_ready,\n')
        for i in range(num1):
            f.write('            \n')
            for j in range(num2):
                f.write('            output  wire    [DATA%d_%d_BITS-1:0]  m%d_data%d,\n' % (i, j, i, j))
            f.write('            output  wire                        m%d_valid,\n' % i)
            f.write('            input   wire                        m%d_ready' % i)
            if i == num1-1:
                f.write('\n')
            else:
                f.write(',\n')
        f.write('        );\n')
        for i in range(num1):
            f.write('    \n')
            f.write('    \n')
            f.write('    // -------------------------------\n')
            f.write('    // pack/unpack%d\n' % i)
            f.write('    // -------------------------------\n')
            f.write('    \n')

            f.write('    localparam DATA%d_WIDTH = DATA%d_0_WIDTH' %(i, i))
            for j in range(1, num1):
                f.write(' + DATA%d_%d_WIDTH' % (i ,j))
            f.write(';\n')
            f.write('    localparam DATA%d_BITS  = DATA%d_WIDTH > 0 ? DATA%d_WIDTH : 1;\n' % (i, i, i))
            f.write('    \n')
            f.write('    wire    [DATA%d_BITS-1:0]  s_data%d;\n' %(i, i))
            f.write('    wire    [DATA%d_BITS-1:0]  m%d_data;\n' %(i, i))
            
            # pack
            f.write('    \n')
            f.write('    jelly_func_pack\n')
            f.write('            #(\n')
            for j in range(num1):
                f.write('                .W%d             (DATA%d_%d_WIDTH)' % (j ,i, j))
                if j == num2-1:
                    f.write('\n')
                else:
                    f.write(',\n')
            f.write('            )\n')
            f.write('    jelly_func_pack_%d\n' % i)
            f.write('            (\n')
            for j in range(num1):
                f.write('                .in%d            (s_data%d_%d),\n' % (j, i, j))
            f.write('                .out            (s_data%d)\n' % (i))
            f.write('            );\n')

            # unpack
            f.write('    \n')
            f.write('    jelly_func_unpack\n')
            f.write('            #(\n')
            for j in range(num1):
                f.write('                .W%d             (DATA%d_%d_WIDTH)' % (j ,i, j))
                if j == num2-1:
                    f.write('\n')
                else:
                    f.write(',\n')
            f.write('            )\n')
            f.write('    jelly_func_unpack_%d\n' % i)
            f.write('            (\n')
            for j in range(num1):
                f.write('                .out%d           (m%d_data%d),\n' % (j, i, j))
            f.write('                .in             (m%d_data)\n' % (i))
            f.write('            );\n')

        # split_pack
        f.write('    \n')
        f.write('    jelly_data_split_pack\n')
        f.write('            #(\n')
        f.write('                .NUM            (NUM),\n')
        for i in range(num1):
            f.write('                .DATA%d_WIDTH    (DATA%d_WIDTH),\n' % (i, i))
        f.write('                .S_REGS         (S_REGS)\n'),
#       f.write('                .M_REGS         (M_REGS)\n'),
        f.write('            )\n'),
        f.write('         i_data_split_pack\n'),
        f.write('            (\n'),
        f.write('                .reset          (reset),\n')
        f.write('                .clk            (clk),\n')
        f.write('                .cke            (cke),\n')
        f.write('                \n')
        for i in range(num1):
            f.write('                .s_data%d        (s_data%d),\n' % ( i, i))
        f.write('                .s_valid        (s_valid),\n')
        f.write('                .s_ready        (s_ready),\n')
        for i in range(num1):
            f.write('                \n')
            f.write('                .m%d_data        (m%d_data),\n' % (i, i))
            f.write('                .m%d_valid       (m%d_valid),\n' % (i, i))
            f.write('                .m%d_ready       (m%d_ready)' % (i, i))
            if i == num1-1:
                f.write('\n')
            else:
                f.write(',\n')
        f.write('            );\n')
        f.write('    \n')

        f.write(file_footer)


if __name__ == "__main__":
    main()

