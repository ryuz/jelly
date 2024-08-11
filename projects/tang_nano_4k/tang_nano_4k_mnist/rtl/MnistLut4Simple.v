`timescale 1ns / 1ps



module MnistLut4Simple
        #(
            parameter USER_WIDTH = 0,
            parameter INIT_REG   = 1'bx,
            parameter DEVICE     = "RTL",
            
            parameter USER_BITS  = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input  wire                  reset,
            input  wire                  clk,
            input  wire                  cke,
            
            input  wire [USER_BITS-1:0]  in_user,
            input  wire [      784-1:0]  in_data,
            input  wire                  in_valid,
            
            output wire [USER_BITS-1:0]  out_user,
            output wire [       10-1:0]  out_data,
            output wire                  out_valid
        );
    
    
    wire  [USER_BITS-1:0]  layer0_user;
    wire  [      256-1:0]  layer0_data;
    wire                   layer0_valid;
    
    MnistLut4Simple_sub0
            #(
                .INIT_REG   (INIT_REG),
                .DEVICE     (DEVICE)
            )
        i_MnistLut4Simple_sub0
            (
                .reset      (reset),
                .clk        (clk),
                .cke        (cke),
                
                .in_data    (in_data),
                .out_data   (layer0_data)
             );
    
    assign layer0_user  = in_user;
    assign layer0_valid = in_valid;
    
    
    wire  [USER_BITS-1:0]  layer1_user;
    wire  [       64-1:0]  layer1_data;
    wire                   layer1_valid;
    
    MnistLut4Simple_sub1
            #(
                .INIT_REG   (INIT_REG),
                .DEVICE     (DEVICE)
            )
        i_MnistLut4Simple_sub1
            (
                .reset      (reset),
                .clk        (clk),
                .cke        (cke),
                
                .in_data    (layer0_data),
                .out_data   (layer1_data)
             );
    
    assign layer1_user  = in_user;
    assign layer1_valid = in_valid;
    
    
    wire  [USER_BITS-1:0]  layer2_user;
    wire  [      256-1:0]  layer2_data;
    wire                   layer2_valid;
    
    MnistLut4Simple_sub2
            #(
                .INIT_REG   (INIT_REG),
                .DEVICE     (DEVICE)
            )
        i_MnistLut4Simple_sub2
            (
                .reset      (reset),
                .clk        (clk),
                .cke        (cke),
                
                .in_data    (layer1_data),
                .out_data   (layer2_data)
             );
    
    assign layer2_user  = in_user;
    assign layer2_valid = in_valid;
    
    
    wire  [USER_BITS-1:0]  layer3_user;
    wire  [       64-1:0]  layer3_data;
    wire                   layer3_valid;
    
    MnistLut4Simple_sub3
            #(
                .INIT_REG   (INIT_REG),
                .DEVICE     (DEVICE)
            )
        i_MnistLut4Simple_sub3
            (
                .reset      (reset),
                .clk        (clk),
                .cke        (cke),
                
                .in_data    (layer2_data),
                .out_data   (layer3_data)
             );
    
    assign layer3_user  = in_user;
    assign layer3_valid = in_valid;
    
    
    wire  [USER_BITS-1:0]  layer4_user;
    wire  [      256-1:0]  layer4_data;
    wire                   layer4_valid;
    
    MnistLut4Simple_sub4
            #(
                .INIT_REG   (INIT_REG),
                .DEVICE     (DEVICE)
            )
        i_MnistLut4Simple_sub4
            (
                .reset      (reset),
                .clk        (clk),
                .cke        (cke),
                
                .in_data    (layer3_data),
                .out_data   (layer4_data)
             );
    
    assign layer4_user  = in_user;
    assign layer4_valid = in_valid;
    
    
    wire  [USER_BITS-1:0]  layer5_user;
    wire  [       64-1:0]  layer5_data;
    wire                   layer5_valid;
    
    MnistLut4Simple_sub5
            #(
                .INIT_REG   (INIT_REG),
                .DEVICE     (DEVICE)
            )
        i_MnistLut4Simple_sub5
            (
                .reset      (reset),
                .clk        (clk),
                .cke        (cke),
                
                .in_data    (layer4_data),
                .out_data   (layer5_data)
             );
    
    assign layer5_user  = in_user;
    assign layer5_valid = in_valid;
    
    
    wire  [USER_BITS-1:0]  layer6_user;
    wire  [      160-1:0]  layer6_data;
    wire                   layer6_valid;
    
    MnistLut4Simple_sub6
            #(
                .INIT_REG   (INIT_REG),
                .DEVICE     (DEVICE)
            )
        i_MnistLut4Simple_sub6
            (
                .reset      (reset),
                .clk        (clk),
                .cke        (cke),
                
                .in_data    (layer5_data),
                .out_data   (layer6_data)
             );
    
    assign layer6_user  = in_user;
    assign layer6_valid = in_valid;
    
    
    wire  [USER_BITS-1:0]  layer7_user;
    wire  [       40-1:0]  layer7_data;
    wire                   layer7_valid;
    
    MnistLut4Simple_sub7
            #(
                .INIT_REG   (INIT_REG),
                .DEVICE     (DEVICE)
            )
        i_MnistLut4Simple_sub7
            (
                .reset      (reset),
                .clk        (clk),
                .cke        (cke),
                
                .in_data    (layer6_data),
                .out_data   (layer7_data)
             );
    
    assign layer7_user  = in_user;
    assign layer7_valid = in_valid;
    
    
    wire  [USER_BITS-1:0]  layer8_user;
    wire  [       10-1:0]  layer8_data;
    wire                   layer8_valid;
    
    MnistLut4Simple_sub8
            #(
                .INIT_REG   (INIT_REG),
                .DEVICE     (DEVICE)
            )
        i_MnistLut4Simple_sub8
            (
                .reset      (reset),
                .clk        (clk),
                .cke        (cke),
                
                .in_data    (layer7_data),
                .out_data   (layer8_data)
             );
    
    assign layer8_user  = in_user;
    assign layer8_valid = in_valid;
    
    
    assign out_data  = layer8_data;
    assign out_user  = layer8_user;
    assign out_valid = layer8_valid;
    
endmodule




module MnistLut4Simple_sub0
        #(
            parameter INIT_REG = 1'bx,
            parameter DEVICE   = "RTL"
        )
        (
            input  wire         reset,
            input  wire         clk,
            input  wire         cke,
            
            input  wire [783:0]  in_data,
            output wire [255:0]  out_data
        );
    
    
    // LUT : 0
    wire [15:0] lut_0_table = 16'b0101010001010101;
    wire [3:0] lut_0_select = {
                             in_data[3],
                             in_data[2],
                             in_data[1],
                             in_data[0]};
    
    wire lut_0_out = lut_0_table[lut_0_select];
    
    assign out_data[0] = lut_0_out;
    
    
    
    // LUT : 1
    wire [15:0] lut_1_table = 16'b1111111111111010;
    wire [3:0] lut_1_select = {
                             in_data[7],
                             in_data[6],
                             in_data[5],
                             in_data[4]};
    
    wire lut_1_out = lut_1_table[lut_1_select];
    
    assign out_data[1] = lut_1_out;
    
    
    
    // LUT : 2
    wire [15:0] lut_2_table = 16'b0011001100000010;
    wire [3:0] lut_2_select = {
                             in_data[11],
                             in_data[10],
                             in_data[9],
                             in_data[8]};
    
    wire lut_2_out = lut_2_table[lut_2_select];
    
    assign out_data[2] = lut_2_out;
    
    
    
    // LUT : 3
    wire [15:0] lut_3_table = 16'b0000010000000100;
    wire [3:0] lut_3_select = {
                             in_data[15],
                             in_data[14],
                             in_data[13],
                             in_data[12]};
    
    wire lut_3_out = lut_3_table[lut_3_select];
    
    assign out_data[3] = lut_3_out;
    
    
    
    // LUT : 4
    wire [15:0] lut_4_table = 16'b0000101100001111;
    wire [3:0] lut_4_select = {
                             in_data[19],
                             in_data[18],
                             in_data[17],
                             in_data[16]};
    
    wire lut_4_out = lut_4_table[lut_4_select];
    
    assign out_data[4] = lut_4_out;
    
    
    
    // LUT : 5
    wire [15:0] lut_5_table = 16'b1101000000010001;
    wire [3:0] lut_5_select = {
                             in_data[23],
                             in_data[22],
                             in_data[21],
                             in_data[20]};
    
    wire lut_5_out = lut_5_table[lut_5_select];
    
    assign out_data[5] = lut_5_out;
    
    
    
    // LUT : 6
    wire [15:0] lut_6_table = 16'b0000000000010001;
    wire [3:0] lut_6_select = {
                             in_data[27],
                             in_data[26],
                             in_data[25],
                             in_data[24]};
    
    wire lut_6_out = lut_6_table[lut_6_select];
    
    assign out_data[6] = lut_6_out;
    
    
    
    // LUT : 7
    wire [15:0] lut_7_table = 16'b1111111111111011;
    wire [3:0] lut_7_select = {
                             in_data[31],
                             in_data[30],
                             in_data[29],
                             in_data[28]};
    
    wire lut_7_out = lut_7_table[lut_7_select];
    
    assign out_data[7] = lut_7_out;
    
    
    
    // LUT : 8
    wire [15:0] lut_8_table = 16'b1111111111111110;
    wire [3:0] lut_8_select = {
                             in_data[35],
                             in_data[34],
                             in_data[33],
                             in_data[32]};
    
    wire lut_8_out = lut_8_table[lut_8_select];
    
    assign out_data[8] = lut_8_out;
    
    
    
    // LUT : 9
    wire [15:0] lut_9_table = 16'b1111111111111010;
    wire [3:0] lut_9_select = {
                             in_data[39],
                             in_data[38],
                             in_data[37],
                             in_data[36]};
    
    wire lut_9_out = lut_9_table[lut_9_select];
    
    assign out_data[9] = lut_9_out;
    
    
    
    // LUT : 10
    wire [15:0] lut_10_table = 16'b1111111111111100;
    wire [3:0] lut_10_select = {
                             in_data[43],
                             in_data[42],
                             in_data[41],
                             in_data[40]};
    
    wire lut_10_out = lut_10_table[lut_10_select];
    
    assign out_data[10] = lut_10_out;
    
    
    
    // LUT : 11
    wire [15:0] lut_11_table = 16'b0111011100110000;
    wire [3:0] lut_11_select = {
                             in_data[47],
                             in_data[46],
                             in_data[45],
                             in_data[44]};
    
    wire lut_11_out = lut_11_table[lut_11_select];
    
    assign out_data[11] = lut_11_out;
    
    
    
    // LUT : 12
    wire [15:0] lut_12_table = 16'b0000000000000001;
    wire [3:0] lut_12_select = {
                             in_data[51],
                             in_data[50],
                             in_data[49],
                             in_data[48]};
    
    wire lut_12_out = lut_12_table[lut_12_select];
    
    assign out_data[12] = lut_12_out;
    
    
    
    // LUT : 13
    wire [15:0] lut_13_table = 16'b1000100010001110;
    wire [3:0] lut_13_select = {
                             in_data[55],
                             in_data[54],
                             in_data[53],
                             in_data[52]};
    
    wire lut_13_out = lut_13_table[lut_13_select];
    
    assign out_data[13] = lut_13_out;
    
    
    
    // LUT : 14
    wire [15:0] lut_14_table = 16'b0000000000000011;
    wire [3:0] lut_14_select = {
                             in_data[59],
                             in_data[58],
                             in_data[57],
                             in_data[56]};
    
    wire lut_14_out = lut_14_table[lut_14_select];
    
    assign out_data[14] = lut_14_out;
    
    
    
    // LUT : 15
    wire [15:0] lut_15_table = 16'b1000101010101110;
    wire [3:0] lut_15_select = {
                             in_data[63],
                             in_data[62],
                             in_data[61],
                             in_data[60]};
    
    wire lut_15_out = lut_15_table[lut_15_select];
    
    assign out_data[15] = lut_15_out;
    
    
    
    // LUT : 16
    wire [15:0] lut_16_table = 16'b0000000000000001;
    wire [3:0] lut_16_select = {
                             in_data[67],
                             in_data[66],
                             in_data[65],
                             in_data[64]};
    
    wire lut_16_out = lut_16_table[lut_16_select];
    
    assign out_data[16] = lut_16_out;
    
    
    
    // LUT : 17
    wire [15:0] lut_17_table = 16'b1111111111111110;
    wire [3:0] lut_17_select = {
                             in_data[71],
                             in_data[70],
                             in_data[69],
                             in_data[68]};
    
    wire lut_17_out = lut_17_table[lut_17_select];
    
    assign out_data[17] = lut_17_out;
    
    
    
    // LUT : 18
    wire [15:0] lut_18_table = 16'b0000000000000001;
    wire [3:0] lut_18_select = {
                             in_data[75],
                             in_data[74],
                             in_data[73],
                             in_data[72]};
    
    wire lut_18_out = lut_18_table[lut_18_select];
    
    assign out_data[18] = lut_18_out;
    
    
    
    // LUT : 19
    wire [15:0] lut_19_table = 16'b0000000000000001;
    wire [3:0] lut_19_select = {
                             in_data[79],
                             in_data[78],
                             in_data[77],
                             in_data[76]};
    
    wire lut_19_out = lut_19_table[lut_19_select];
    
    assign out_data[19] = lut_19_out;
    
    
    
    // LUT : 20
    wire [15:0] lut_20_table = 16'b0001000100010001;
    wire [3:0] lut_20_select = {
                             in_data[83],
                             in_data[82],
                             in_data[81],
                             in_data[80]};
    
    wire lut_20_out = lut_20_table[lut_20_select];
    
    assign out_data[20] = lut_20_out;
    
    
    
    // LUT : 21
    wire [15:0] lut_21_table = 16'b1111111111110010;
    wire [3:0] lut_21_select = {
                             in_data[87],
                             in_data[86],
                             in_data[85],
                             in_data[84]};
    
    wire lut_21_out = lut_21_table[lut_21_select];
    
    assign out_data[21] = lut_21_out;
    
    
    
    // LUT : 22
    wire [15:0] lut_22_table = 16'b0000000000000001;
    wire [3:0] lut_22_select = {
                             in_data[91],
                             in_data[90],
                             in_data[89],
                             in_data[88]};
    
    wire lut_22_out = lut_22_table[lut_22_select];
    
    assign out_data[22] = lut_22_out;
    
    
    
    // LUT : 23
    wire [15:0] lut_23_table = 16'b1111111111111110;
    wire [3:0] lut_23_select = {
                             in_data[95],
                             in_data[94],
                             in_data[93],
                             in_data[92]};
    
    wire lut_23_out = lut_23_table[lut_23_select];
    
    assign out_data[23] = lut_23_out;
    
    
    
    // LUT : 24
    wire [15:0] lut_24_table = 16'b1111111111111110;
    wire [3:0] lut_24_select = {
                             in_data[99],
                             in_data[98],
                             in_data[97],
                             in_data[96]};
    
    wire lut_24_out = lut_24_table[lut_24_select];
    
    assign out_data[24] = lut_24_out;
    
    
    
    // LUT : 25
    wire [15:0] lut_25_table = 16'b0000000000000001;
    wire [3:0] lut_25_select = {
                             in_data[103],
                             in_data[102],
                             in_data[101],
                             in_data[100]};
    
    wire lut_25_out = lut_25_table[lut_25_select];
    
    assign out_data[25] = lut_25_out;
    
    
    
    // LUT : 26
    wire [15:0] lut_26_table = 16'b1111111111111111;
    wire [3:0] lut_26_select = {
                             in_data[107],
                             in_data[106],
                             in_data[105],
                             in_data[104]};
    
    wire lut_26_out = lut_26_table[lut_26_select];
    
    assign out_data[26] = lut_26_out;
    
    
    
    // LUT : 27
    wire [15:0] lut_27_table = 16'b0000010100000100;
    wire [3:0] lut_27_select = {
                             in_data[111],
                             in_data[110],
                             in_data[109],
                             in_data[108]};
    
    wire lut_27_out = lut_27_table[lut_27_select];
    
    assign out_data[27] = lut_27_out;
    
    
    
    // LUT : 28
    wire [15:0] lut_28_table = 16'b0000000001110001;
    wire [3:0] lut_28_select = {
                             in_data[115],
                             in_data[114],
                             in_data[113],
                             in_data[112]};
    
    wire lut_28_out = lut_28_table[lut_28_select];
    
    assign out_data[28] = lut_28_out;
    
    
    
    // LUT : 29
    wire [15:0] lut_29_table = 16'b1111111111110000;
    wire [3:0] lut_29_select = {
                             in_data[119],
                             in_data[118],
                             in_data[117],
                             in_data[116]};
    
    wire lut_29_out = lut_29_table[lut_29_select];
    
    assign out_data[29] = lut_29_out;
    
    
    
    // LUT : 30
    wire [15:0] lut_30_table = 16'b0000000000000001;
    wire [3:0] lut_30_select = {
                             in_data[123],
                             in_data[122],
                             in_data[121],
                             in_data[120]};
    
    wire lut_30_out = lut_30_table[lut_30_select];
    
    assign out_data[30] = lut_30_out;
    
    
    
    // LUT : 31
    wire [15:0] lut_31_table = 16'b0000000000000001;
    wire [3:0] lut_31_select = {
                             in_data[127],
                             in_data[126],
                             in_data[125],
                             in_data[124]};
    
    wire lut_31_out = lut_31_table[lut_31_select];
    
    assign out_data[31] = lut_31_out;
    
    
    
    // LUT : 32
    wire [15:0] lut_32_table = 16'b0000000000000001;
    wire [3:0] lut_32_select = {
                             in_data[131],
                             in_data[130],
                             in_data[129],
                             in_data[128]};
    
    wire lut_32_out = lut_32_table[lut_32_select];
    
    assign out_data[32] = lut_32_out;
    
    
    
    // LUT : 33
    wire [15:0] lut_33_table = 16'b1111111111111110;
    wire [3:0] lut_33_select = {
                             in_data[135],
                             in_data[134],
                             in_data[133],
                             in_data[132]};
    
    wire lut_33_out = lut_33_table[lut_33_select];
    
    assign out_data[33] = lut_33_out;
    
    
    
    // LUT : 34
    wire [15:0] lut_34_table = 16'b0001000100010001;
    wire [3:0] lut_34_select = {
                             in_data[139],
                             in_data[138],
                             in_data[137],
                             in_data[136]};
    
    wire lut_34_out = lut_34_table[lut_34_select];
    
    assign out_data[34] = lut_34_out;
    
    
    
    // LUT : 35
    wire [15:0] lut_35_table = 16'b0000000011110100;
    wire [3:0] lut_35_select = {
                             in_data[143],
                             in_data[142],
                             in_data[141],
                             in_data[140]};
    
    wire lut_35_out = lut_35_table[lut_35_select];
    
    assign out_data[35] = lut_35_out;
    
    
    
    // LUT : 36
    wire [15:0] lut_36_table = 16'b0000100011101111;
    wire [3:0] lut_36_select = {
                             in_data[147],
                             in_data[146],
                             in_data[145],
                             in_data[144]};
    
    wire lut_36_out = lut_36_table[lut_36_select];
    
    assign out_data[36] = lut_36_out;
    
    
    
    // LUT : 37
    wire [15:0] lut_37_table = 16'b0000000000001011;
    wire [3:0] lut_37_select = {
                             in_data[151],
                             in_data[150],
                             in_data[149],
                             in_data[148]};
    
    wire lut_37_out = lut_37_table[lut_37_select];
    
    assign out_data[37] = lut_37_out;
    
    
    
    // LUT : 38
    wire [15:0] lut_38_table = 16'b0000000000000001;
    wire [3:0] lut_38_select = {
                             in_data[155],
                             in_data[154],
                             in_data[153],
                             in_data[152]};
    
    wire lut_38_out = lut_38_table[lut_38_select];
    
    assign out_data[38] = lut_38_out;
    
    
    
    // LUT : 39
    wire [15:0] lut_39_table = 16'b1111111011111110;
    wire [3:0] lut_39_select = {
                             in_data[159],
                             in_data[158],
                             in_data[157],
                             in_data[156]};
    
    wire lut_39_out = lut_39_table[lut_39_select];
    
    assign out_data[39] = lut_39_out;
    
    
    
    // LUT : 40
    wire [15:0] lut_40_table = 16'b1111111111111110;
    wire [3:0] lut_40_select = {
                             in_data[163],
                             in_data[162],
                             in_data[161],
                             in_data[160]};
    
    wire lut_40_out = lut_40_table[lut_40_select];
    
    assign out_data[40] = lut_40_out;
    
    
    
    // LUT : 41
    wire [15:0] lut_41_table = 16'b0000111100001110;
    wire [3:0] lut_41_select = {
                             in_data[167],
                             in_data[166],
                             in_data[165],
                             in_data[164]};
    
    wire lut_41_out = lut_41_table[lut_41_select];
    
    assign out_data[41] = lut_41_out;
    
    
    
    // LUT : 42
    wire [15:0] lut_42_table = 16'b0000000011110101;
    wire [3:0] lut_42_select = {
                             in_data[171],
                             in_data[170],
                             in_data[169],
                             in_data[168]};
    
    wire lut_42_out = lut_42_table[lut_42_select];
    
    assign out_data[42] = lut_42_out;
    
    
    
    // LUT : 43
    wire [15:0] lut_43_table = 16'b0000000011111111;
    wire [3:0] lut_43_select = {
                             in_data[175],
                             in_data[174],
                             in_data[173],
                             in_data[172]};
    
    wire lut_43_out = lut_43_table[lut_43_select];
    
    assign out_data[43] = lut_43_out;
    
    
    
    // LUT : 44
    wire [15:0] lut_44_table = 16'b0000000100000001;
    wire [3:0] lut_44_select = {
                             in_data[179],
                             in_data[178],
                             in_data[177],
                             in_data[176]};
    
    wire lut_44_out = lut_44_table[lut_44_select];
    
    assign out_data[44] = lut_44_out;
    
    
    
    // LUT : 45
    wire [15:0] lut_45_table = 16'b1111111111111110;
    wire [3:0] lut_45_select = {
                             in_data[183],
                             in_data[182],
                             in_data[181],
                             in_data[180]};
    
    wire lut_45_out = lut_45_table[lut_45_select];
    
    assign out_data[45] = lut_45_out;
    
    
    
    // LUT : 46
    wire [15:0] lut_46_table = 16'b1010111011101110;
    wire [3:0] lut_46_select = {
                             in_data[187],
                             in_data[186],
                             in_data[185],
                             in_data[184]};
    
    wire lut_46_out = lut_46_table[lut_46_select];
    
    assign out_data[46] = lut_46_out;
    
    
    
    // LUT : 47
    wire [15:0] lut_47_table = 16'b0101111111011110;
    wire [3:0] lut_47_select = {
                             in_data[191],
                             in_data[190],
                             in_data[189],
                             in_data[188]};
    
    wire lut_47_out = lut_47_table[lut_47_select];
    
    assign out_data[47] = lut_47_out;
    
    
    
    // LUT : 48
    wire [15:0] lut_48_table = 16'b1111111111111110;
    wire [3:0] lut_48_select = {
                             in_data[195],
                             in_data[194],
                             in_data[193],
                             in_data[192]};
    
    wire lut_48_out = lut_48_table[lut_48_select];
    
    assign out_data[48] = lut_48_out;
    
    
    
    // LUT : 49
    wire [15:0] lut_49_table = 16'b0000000000000001;
    wire [3:0] lut_49_select = {
                             in_data[199],
                             in_data[198],
                             in_data[197],
                             in_data[196]};
    
    wire lut_49_out = lut_49_table[lut_49_select];
    
    assign out_data[49] = lut_49_out;
    
    
    
    // LUT : 50
    wire [15:0] lut_50_table = 16'b1111111111111110;
    wire [3:0] lut_50_select = {
                             in_data[203],
                             in_data[202],
                             in_data[201],
                             in_data[200]};
    
    wire lut_50_out = lut_50_table[lut_50_select];
    
    assign out_data[50] = lut_50_out;
    
    
    
    // LUT : 51
    wire [15:0] lut_51_table = 16'b1111111011111110;
    wire [3:0] lut_51_select = {
                             in_data[207],
                             in_data[206],
                             in_data[205],
                             in_data[204]};
    
    wire lut_51_out = lut_51_table[lut_51_select];
    
    assign out_data[51] = lut_51_out;
    
    
    
    // LUT : 52
    wire [15:0] lut_52_table = 16'b1110110010100000;
    wire [3:0] lut_52_select = {
                             in_data[211],
                             in_data[210],
                             in_data[209],
                             in_data[208]};
    
    wire lut_52_out = lut_52_table[lut_52_select];
    
    assign out_data[52] = lut_52_out;
    
    
    
    // LUT : 53
    wire [15:0] lut_53_table = 16'b1000100010100000;
    wire [3:0] lut_53_select = {
                             in_data[215],
                             in_data[214],
                             in_data[213],
                             in_data[212]};
    
    wire lut_53_out = lut_53_table[lut_53_select];
    
    assign out_data[53] = lut_53_out;
    
    
    
    // LUT : 54
    wire [15:0] lut_54_table = 16'b1111111111111100;
    wire [3:0] lut_54_select = {
                             in_data[219],
                             in_data[218],
                             in_data[217],
                             in_data[216]};
    
    wire lut_54_out = lut_54_table[lut_54_select];
    
    assign out_data[54] = lut_54_out;
    
    
    
    // LUT : 55
    wire [15:0] lut_55_table = 16'b0011001100010001;
    wire [3:0] lut_55_select = {
                             in_data[223],
                             in_data[222],
                             in_data[221],
                             in_data[220]};
    
    wire lut_55_out = lut_55_table[lut_55_select];
    
    assign out_data[55] = lut_55_out;
    
    
    
    // LUT : 56
    wire [15:0] lut_56_table = 16'b0000000011111100;
    wire [3:0] lut_56_select = {
                             in_data[227],
                             in_data[226],
                             in_data[225],
                             in_data[224]};
    
    wire lut_56_out = lut_56_table[lut_56_select];
    
    assign out_data[56] = lut_56_out;
    
    
    
    // LUT : 57
    wire [15:0] lut_57_table = 16'b1111111111111110;
    wire [3:0] lut_57_select = {
                             in_data[231],
                             in_data[230],
                             in_data[229],
                             in_data[228]};
    
    wire lut_57_out = lut_57_table[lut_57_select];
    
    assign out_data[57] = lut_57_out;
    
    
    
    // LUT : 58
    wire [15:0] lut_58_table = 16'b1111111111111000;
    wire [3:0] lut_58_select = {
                             in_data[235],
                             in_data[234],
                             in_data[233],
                             in_data[232]};
    
    wire lut_58_out = lut_58_table[lut_58_select];
    
    assign out_data[58] = lut_58_out;
    
    
    
    // LUT : 59
    wire [15:0] lut_59_table = 16'b0101000100000001;
    wire [3:0] lut_59_select = {
                             in_data[239],
                             in_data[238],
                             in_data[237],
                             in_data[236]};
    
    wire lut_59_out = lut_59_table[lut_59_select];
    
    assign out_data[59] = lut_59_out;
    
    
    
    // LUT : 60
    wire [15:0] lut_60_table = 16'b1111111111111110;
    wire [3:0] lut_60_select = {
                             in_data[243],
                             in_data[242],
                             in_data[241],
                             in_data[240]};
    
    wire lut_60_out = lut_60_table[lut_60_select];
    
    assign out_data[60] = lut_60_out;
    
    
    
    // LUT : 61
    wire [15:0] lut_61_table = 16'b0000001100000011;
    wire [3:0] lut_61_select = {
                             in_data[247],
                             in_data[246],
                             in_data[245],
                             in_data[244]};
    
    wire lut_61_out = lut_61_table[lut_61_select];
    
    assign out_data[61] = lut_61_out;
    
    
    
    // LUT : 62
    wire [15:0] lut_62_table = 16'b1111111111111110;
    wire [3:0] lut_62_select = {
                             in_data[251],
                             in_data[250],
                             in_data[249],
                             in_data[248]};
    
    wire lut_62_out = lut_62_table[lut_62_select];
    
    assign out_data[62] = lut_62_out;
    
    
    
    // LUT : 63
    wire [15:0] lut_63_table = 16'b1111111111111111;
    wire [3:0] lut_63_select = {
                             in_data[255],
                             in_data[254],
                             in_data[253],
                             in_data[252]};
    
    wire lut_63_out = lut_63_table[lut_63_select];
    
    assign out_data[63] = lut_63_out;
    
    
    
    // LUT : 64
    wire [15:0] lut_64_table = 16'b0000000100000101;
    wire [3:0] lut_64_select = {
                             in_data[259],
                             in_data[258],
                             in_data[257],
                             in_data[256]};
    
    wire lut_64_out = lut_64_table[lut_64_select];
    
    assign out_data[64] = lut_64_out;
    
    
    
    // LUT : 65
    wire [15:0] lut_65_table = 16'b1001111111111110;
    wire [3:0] lut_65_select = {
                             in_data[263],
                             in_data[262],
                             in_data[261],
                             in_data[260]};
    
    wire lut_65_out = lut_65_table[lut_65_select];
    
    assign out_data[65] = lut_65_out;
    
    
    
    // LUT : 66
    wire [15:0] lut_66_table = 16'b0101000100000011;
    wire [3:0] lut_66_select = {
                             in_data[267],
                             in_data[266],
                             in_data[265],
                             in_data[264]};
    
    wire lut_66_out = lut_66_table[lut_66_select];
    
    assign out_data[66] = lut_66_out;
    
    
    
    // LUT : 67
    wire [15:0] lut_67_table = 16'b1111110111101110;
    wire [3:0] lut_67_select = {
                             in_data[271],
                             in_data[270],
                             in_data[269],
                             in_data[268]};
    
    wire lut_67_out = lut_67_table[lut_67_select];
    
    assign out_data[67] = lut_67_out;
    
    
    
    // LUT : 68
    wire [15:0] lut_68_table = 16'b1111111111111100;
    wire [3:0] lut_68_select = {
                             in_data[275],
                             in_data[274],
                             in_data[273],
                             in_data[272]};
    
    wire lut_68_out = lut_68_table[lut_68_select];
    
    assign out_data[68] = lut_68_out;
    
    
    
    // LUT : 69
    wire [15:0] lut_69_table = 16'b1111111111101110;
    wire [3:0] lut_69_select = {
                             in_data[279],
                             in_data[278],
                             in_data[277],
                             in_data[276]};
    
    wire lut_69_out = lut_69_table[lut_69_select];
    
    assign out_data[69] = lut_69_out;
    
    
    
    // LUT : 70
    wire [15:0] lut_70_table = 16'b1111110111110101;
    wire [3:0] lut_70_select = {
                             in_data[283],
                             in_data[282],
                             in_data[281],
                             in_data[280]};
    
    wire lut_70_out = lut_70_table[lut_70_select];
    
    assign out_data[70] = lut_70_out;
    
    
    
    // LUT : 71
    wire [15:0] lut_71_table = 16'b1111111111111110;
    wire [3:0] lut_71_select = {
                             in_data[287],
                             in_data[286],
                             in_data[285],
                             in_data[284]};
    
    wire lut_71_out = lut_71_table[lut_71_select];
    
    assign out_data[71] = lut_71_out;
    
    
    
    // LUT : 72
    wire [15:0] lut_72_table = 16'b0011111111111110;
    wire [3:0] lut_72_select = {
                             in_data[291],
                             in_data[290],
                             in_data[289],
                             in_data[288]};
    
    wire lut_72_out = lut_72_table[lut_72_select];
    
    assign out_data[72] = lut_72_out;
    
    
    
    // LUT : 73
    wire [15:0] lut_73_table = 16'b0000110011101111;
    wire [3:0] lut_73_select = {
                             in_data[295],
                             in_data[294],
                             in_data[293],
                             in_data[292]};
    
    wire lut_73_out = lut_73_table[lut_73_select];
    
    assign out_data[73] = lut_73_out;
    
    
    
    // LUT : 74
    wire [15:0] lut_74_table = 16'b0000000000000001;
    wire [3:0] lut_74_select = {
                             in_data[299],
                             in_data[298],
                             in_data[297],
                             in_data[296]};
    
    wire lut_74_out = lut_74_table[lut_74_select];
    
    assign out_data[74] = lut_74_out;
    
    
    
    // LUT : 75
    wire [15:0] lut_75_table = 16'b1000000010000001;
    wire [3:0] lut_75_select = {
                             in_data[303],
                             in_data[302],
                             in_data[301],
                             in_data[300]};
    
    wire lut_75_out = lut_75_table[lut_75_select];
    
    assign out_data[75] = lut_75_out;
    
    
    
    // LUT : 76
    wire [15:0] lut_76_table = 16'b0101010101010101;
    wire [3:0] lut_76_select = {
                             in_data[307],
                             in_data[306],
                             in_data[305],
                             in_data[304]};
    
    wire lut_76_out = lut_76_table[lut_76_select];
    
    assign out_data[76] = lut_76_out;
    
    
    
    // LUT : 77
    wire [15:0] lut_77_table = 16'b0000000011111100;
    wire [3:0] lut_77_select = {
                             in_data[311],
                             in_data[310],
                             in_data[309],
                             in_data[308]};
    
    wire lut_77_out = lut_77_table[lut_77_select];
    
    assign out_data[77] = lut_77_out;
    
    
    
    // LUT : 78
    wire [15:0] lut_78_table = 16'b1111111111111110;
    wire [3:0] lut_78_select = {
                             in_data[315],
                             in_data[314],
                             in_data[313],
                             in_data[312]};
    
    wire lut_78_out = lut_78_table[lut_78_select];
    
    assign out_data[78] = lut_78_out;
    
    
    
    // LUT : 79
    wire [15:0] lut_79_table = 16'b1111111111111110;
    wire [3:0] lut_79_select = {
                             in_data[319],
                             in_data[318],
                             in_data[317],
                             in_data[316]};
    
    wire lut_79_out = lut_79_table[lut_79_select];
    
    assign out_data[79] = lut_79_out;
    
    
    
    // LUT : 80
    wire [15:0] lut_80_table = 16'b1100000011001111;
    wire [3:0] lut_80_select = {
                             in_data[323],
                             in_data[322],
                             in_data[321],
                             in_data[320]};
    
    wire lut_80_out = lut_80_table[lut_80_select];
    
    assign out_data[80] = lut_80_out;
    
    
    
    // LUT : 81
    wire [15:0] lut_81_table = 16'b0000001100001011;
    wire [3:0] lut_81_select = {
                             in_data[327],
                             in_data[326],
                             in_data[325],
                             in_data[324]};
    
    wire lut_81_out = lut_81_table[lut_81_select];
    
    assign out_data[81] = lut_81_out;
    
    
    
    // LUT : 82
    wire [15:0] lut_82_table = 16'b1111111111111100;
    wire [3:0] lut_82_select = {
                             in_data[331],
                             in_data[330],
                             in_data[329],
                             in_data[328]};
    
    wire lut_82_out = lut_82_table[lut_82_select];
    
    assign out_data[82] = lut_82_out;
    
    
    
    // LUT : 83
    wire [15:0] lut_83_table = 16'b1111111111111110;
    wire [3:0] lut_83_select = {
                             in_data[335],
                             in_data[334],
                             in_data[333],
                             in_data[332]};
    
    wire lut_83_out = lut_83_table[lut_83_select];
    
    assign out_data[83] = lut_83_out;
    
    
    
    // LUT : 84
    wire [15:0] lut_84_table = 16'b0000000000000000;
    wire [3:0] lut_84_select = {
                             in_data[339],
                             in_data[338],
                             in_data[337],
                             in_data[336]};
    
    wire lut_84_out = lut_84_table[lut_84_select];
    
    assign out_data[84] = lut_84_out;
    
    
    
    // LUT : 85
    wire [15:0] lut_85_table = 16'b0000000000000011;
    wire [3:0] lut_85_select = {
                             in_data[343],
                             in_data[342],
                             in_data[341],
                             in_data[340]};
    
    wire lut_85_out = lut_85_table[lut_85_select];
    
    assign out_data[85] = lut_85_out;
    
    
    
    // LUT : 86
    wire [15:0] lut_86_table = 16'b0000000000000001;
    wire [3:0] lut_86_select = {
                             in_data[347],
                             in_data[346],
                             in_data[345],
                             in_data[344]};
    
    wire lut_86_out = lut_86_table[lut_86_select];
    
    assign out_data[86] = lut_86_out;
    
    
    
    // LUT : 87
    wire [15:0] lut_87_table = 16'b0010111010101110;
    wire [3:0] lut_87_select = {
                             in_data[351],
                             in_data[350],
                             in_data[349],
                             in_data[348]};
    
    wire lut_87_out = lut_87_table[lut_87_select];
    
    assign out_data[87] = lut_87_out;
    
    
    
    // LUT : 88
    wire [15:0] lut_88_table = 16'b1111111111111110;
    wire [3:0] lut_88_select = {
                             in_data[355],
                             in_data[354],
                             in_data[353],
                             in_data[352]};
    
    wire lut_88_out = lut_88_table[lut_88_select];
    
    assign out_data[88] = lut_88_out;
    
    
    
    // LUT : 89
    wire [15:0] lut_89_table = 16'b0000000000001010;
    wire [3:0] lut_89_select = {
                             in_data[359],
                             in_data[358],
                             in_data[357],
                             in_data[356]};
    
    wire lut_89_out = lut_89_table[lut_89_select];
    
    assign out_data[89] = lut_89_out;
    
    
    
    // LUT : 90
    wire [15:0] lut_90_table = 16'b0000000100000001;
    wire [3:0] lut_90_select = {
                             in_data[363],
                             in_data[362],
                             in_data[361],
                             in_data[360]};
    
    wire lut_90_out = lut_90_table[lut_90_select];
    
    assign out_data[90] = lut_90_out;
    
    
    
    // LUT : 91
    wire [15:0] lut_91_table = 16'b1111111111110001;
    wire [3:0] lut_91_select = {
                             in_data[367],
                             in_data[366],
                             in_data[365],
                             in_data[364]};
    
    wire lut_91_out = lut_91_table[lut_91_select];
    
    assign out_data[91] = lut_91_out;
    
    
    
    // LUT : 92
    wire [15:0] lut_92_table = 16'b0000000000000001;
    wire [3:0] lut_92_select = {
                             in_data[371],
                             in_data[370],
                             in_data[369],
                             in_data[368]};
    
    wire lut_92_out = lut_92_table[lut_92_select];
    
    assign out_data[92] = lut_92_out;
    
    
    
    // LUT : 93
    wire [15:0] lut_93_table = 16'b1000000011001111;
    wire [3:0] lut_93_select = {
                             in_data[375],
                             in_data[374],
                             in_data[373],
                             in_data[372]};
    
    wire lut_93_out = lut_93_table[lut_93_select];
    
    assign out_data[93] = lut_93_out;
    
    
    
    // LUT : 94
    wire [15:0] lut_94_table = 16'b0001000100000011;
    wire [3:0] lut_94_select = {
                             in_data[379],
                             in_data[378],
                             in_data[377],
                             in_data[376]};
    
    wire lut_94_out = lut_94_table[lut_94_select];
    
    assign out_data[94] = lut_94_out;
    
    
    
    // LUT : 95
    wire [15:0] lut_95_table = 16'b0101010111010101;
    wire [3:0] lut_95_select = {
                             in_data[383],
                             in_data[382],
                             in_data[381],
                             in_data[380]};
    
    wire lut_95_out = lut_95_table[lut_95_select];
    
    assign out_data[95] = lut_95_out;
    
    
    
    // LUT : 96
    wire [15:0] lut_96_table = 16'b1111111111111110;
    wire [3:0] lut_96_select = {
                             in_data[387],
                             in_data[386],
                             in_data[385],
                             in_data[384]};
    
    wire lut_96_out = lut_96_table[lut_96_select];
    
    assign out_data[96] = lut_96_out;
    
    
    
    // LUT : 97
    wire [15:0] lut_97_table = 16'b1111110111111101;
    wire [3:0] lut_97_select = {
                             in_data[391],
                             in_data[390],
                             in_data[389],
                             in_data[388]};
    
    wire lut_97_out = lut_97_table[lut_97_select];
    
    assign out_data[97] = lut_97_out;
    
    
    
    // LUT : 98
    wire [15:0] lut_98_table = 16'b0000000000000010;
    wire [3:0] lut_98_select = {
                             in_data[395],
                             in_data[394],
                             in_data[393],
                             in_data[392]};
    
    wire lut_98_out = lut_98_table[lut_98_select];
    
    assign out_data[98] = lut_98_out;
    
    
    
    // LUT : 99
    wire [15:0] lut_99_table = 16'b0000000000000001;
    wire [3:0] lut_99_select = {
                             in_data[399],
                             in_data[398],
                             in_data[397],
                             in_data[396]};
    
    wire lut_99_out = lut_99_table[lut_99_select];
    
    assign out_data[99] = lut_99_out;
    
    
    
    // LUT : 100
    wire [15:0] lut_100_table = 16'b1111111111111100;
    wire [3:0] lut_100_select = {
                             in_data[403],
                             in_data[402],
                             in_data[401],
                             in_data[400]};
    
    wire lut_100_out = lut_100_table[lut_100_select];
    
    assign out_data[100] = lut_100_out;
    
    
    
    // LUT : 101
    wire [15:0] lut_101_table = 16'b1111110001110100;
    wire [3:0] lut_101_select = {
                             in_data[407],
                             in_data[406],
                             in_data[405],
                             in_data[404]};
    
    wire lut_101_out = lut_101_table[lut_101_select];
    
    assign out_data[101] = lut_101_out;
    
    
    
    // LUT : 102
    wire [15:0] lut_102_table = 16'b0000000101001111;
    wire [3:0] lut_102_select = {
                             in_data[411],
                             in_data[410],
                             in_data[409],
                             in_data[408]};
    
    wire lut_102_out = lut_102_table[lut_102_select];
    
    assign out_data[102] = lut_102_out;
    
    
    
    // LUT : 103
    wire [15:0] lut_103_table = 16'b0000000000000011;
    wire [3:0] lut_103_select = {
                             in_data[415],
                             in_data[414],
                             in_data[413],
                             in_data[412]};
    
    wire lut_103_out = lut_103_table[lut_103_select];
    
    assign out_data[103] = lut_103_out;
    
    
    
    // LUT : 104
    wire [15:0] lut_104_table = 16'b0000000100000001;
    wire [3:0] lut_104_select = {
                             in_data[419],
                             in_data[418],
                             in_data[417],
                             in_data[416]};
    
    wire lut_104_out = lut_104_table[lut_104_select];
    
    assign out_data[104] = lut_104_out;
    
    
    
    // LUT : 105
    wire [15:0] lut_105_table = 16'b1111111111110000;
    wire [3:0] lut_105_select = {
                             in_data[423],
                             in_data[422],
                             in_data[421],
                             in_data[420]};
    
    wire lut_105_out = lut_105_table[lut_105_select];
    
    assign out_data[105] = lut_105_out;
    
    
    
    // LUT : 106
    wire [15:0] lut_106_table = 16'b1111111111011110;
    wire [3:0] lut_106_select = {
                             in_data[427],
                             in_data[426],
                             in_data[425],
                             in_data[424]};
    
    wire lut_106_out = lut_106_table[lut_106_select];
    
    assign out_data[106] = lut_106_out;
    
    
    
    // LUT : 107
    wire [15:0] lut_107_table = 16'b0000000000000001;
    wire [3:0] lut_107_select = {
                             in_data[431],
                             in_data[430],
                             in_data[429],
                             in_data[428]};
    
    wire lut_107_out = lut_107_table[lut_107_select];
    
    assign out_data[107] = lut_107_out;
    
    
    
    // LUT : 108
    wire [15:0] lut_108_table = 16'b0001000100000011;
    wire [3:0] lut_108_select = {
                             in_data[435],
                             in_data[434],
                             in_data[433],
                             in_data[432]};
    
    wire lut_108_out = lut_108_table[lut_108_select];
    
    assign out_data[108] = lut_108_out;
    
    
    
    // LUT : 109
    wire [15:0] lut_109_table = 16'b0000000000101111;
    wire [3:0] lut_109_select = {
                             in_data[439],
                             in_data[438],
                             in_data[437],
                             in_data[436]};
    
    wire lut_109_out = lut_109_table[lut_109_select];
    
    assign out_data[109] = lut_109_out;
    
    
    
    // LUT : 110
    wire [15:0] lut_110_table = 16'b0000000100010001;
    wire [3:0] lut_110_select = {
                             in_data[443],
                             in_data[442],
                             in_data[441],
                             in_data[440]};
    
    wire lut_110_out = lut_110_table[lut_110_select];
    
    assign out_data[110] = lut_110_out;
    
    
    
    // LUT : 111
    wire [15:0] lut_111_table = 16'b0000000000000001;
    wire [3:0] lut_111_select = {
                             in_data[447],
                             in_data[446],
                             in_data[445],
                             in_data[444]};
    
    wire lut_111_out = lut_111_table[lut_111_select];
    
    assign out_data[111] = lut_111_out;
    
    
    
    // LUT : 112
    wire [15:0] lut_112_table = 16'b1111111100000001;
    wire [3:0] lut_112_select = {
                             in_data[451],
                             in_data[450],
                             in_data[449],
                             in_data[448]};
    
    wire lut_112_out = lut_112_table[lut_112_select];
    
    assign out_data[112] = lut_112_out;
    
    
    
    // LUT : 113
    wire [15:0] lut_113_table = 16'b1111111111111110;
    wire [3:0] lut_113_select = {
                             in_data[455],
                             in_data[454],
                             in_data[453],
                             in_data[452]};
    
    wire lut_113_out = lut_113_table[lut_113_select];
    
    assign out_data[113] = lut_113_out;
    
    
    
    // LUT : 114
    wire [15:0] lut_114_table = 16'b0100010011111111;
    wire [3:0] lut_114_select = {
                             in_data[459],
                             in_data[458],
                             in_data[457],
                             in_data[456]};
    
    wire lut_114_out = lut_114_table[lut_114_select];
    
    assign out_data[114] = lut_114_out;
    
    
    
    // LUT : 115
    wire [15:0] lut_115_table = 16'b0001001100001011;
    wire [3:0] lut_115_select = {
                             in_data[463],
                             in_data[462],
                             in_data[461],
                             in_data[460]};
    
    wire lut_115_out = lut_115_table[lut_115_select];
    
    assign out_data[115] = lut_115_out;
    
    
    
    // LUT : 116
    wire [15:0] lut_116_table = 16'b1110111011101000;
    wire [3:0] lut_116_select = {
                             in_data[467],
                             in_data[466],
                             in_data[465],
                             in_data[464]};
    
    wire lut_116_out = lut_116_table[lut_116_select];
    
    assign out_data[116] = lut_116_out;
    
    
    
    // LUT : 117
    wire [15:0] lut_117_table = 16'b1111111111111110;
    wire [3:0] lut_117_select = {
                             in_data[471],
                             in_data[470],
                             in_data[469],
                             in_data[468]};
    
    wire lut_117_out = lut_117_table[lut_117_select];
    
    assign out_data[117] = lut_117_out;
    
    
    
    // LUT : 118
    wire [15:0] lut_118_table = 16'b0000000000000001;
    wire [3:0] lut_118_select = {
                             in_data[475],
                             in_data[474],
                             in_data[473],
                             in_data[472]};
    
    wire lut_118_out = lut_118_table[lut_118_select];
    
    assign out_data[118] = lut_118_out;
    
    
    
    // LUT : 119
    wire [15:0] lut_119_table = 16'b1111000011110011;
    wire [3:0] lut_119_select = {
                             in_data[479],
                             in_data[478],
                             in_data[477],
                             in_data[476]};
    
    wire lut_119_out = lut_119_table[lut_119_select];
    
    assign out_data[119] = lut_119_out;
    
    
    
    // LUT : 120
    wire [15:0] lut_120_table = 16'b1111110100000000;
    wire [3:0] lut_120_select = {
                             in_data[483],
                             in_data[482],
                             in_data[481],
                             in_data[480]};
    
    wire lut_120_out = lut_120_table[lut_120_select];
    
    assign out_data[120] = lut_120_out;
    
    
    
    // LUT : 121
    wire [15:0] lut_121_table = 16'b1111111111111110;
    wire [3:0] lut_121_select = {
                             in_data[487],
                             in_data[486],
                             in_data[485],
                             in_data[484]};
    
    wire lut_121_out = lut_121_table[lut_121_select];
    
    assign out_data[121] = lut_121_out;
    
    
    
    // LUT : 122
    wire [15:0] lut_122_table = 16'b0101000100010001;
    wire [3:0] lut_122_select = {
                             in_data[491],
                             in_data[490],
                             in_data[489],
                             in_data[488]};
    
    wire lut_122_out = lut_122_table[lut_122_select];
    
    assign out_data[122] = lut_122_out;
    
    
    
    // LUT : 123
    wire [15:0] lut_123_table = 16'b0000001000101111;
    wire [3:0] lut_123_select = {
                             in_data[495],
                             in_data[494],
                             in_data[493],
                             in_data[492]};
    
    wire lut_123_out = lut_123_table[lut_123_select];
    
    assign out_data[123] = lut_123_out;
    
    
    
    // LUT : 124
    wire [15:0] lut_124_table = 16'b0000000000000001;
    wire [3:0] lut_124_select = {
                             in_data[499],
                             in_data[498],
                             in_data[497],
                             in_data[496]};
    
    wire lut_124_out = lut_124_table[lut_124_select];
    
    assign out_data[124] = lut_124_out;
    
    
    
    // LUT : 125
    wire [15:0] lut_125_table = 16'b1111111111111110;
    wire [3:0] lut_125_select = {
                             in_data[503],
                             in_data[502],
                             in_data[501],
                             in_data[500]};
    
    wire lut_125_out = lut_125_table[lut_125_select];
    
    assign out_data[125] = lut_125_out;
    
    
    
    // LUT : 126
    wire [15:0] lut_126_table = 16'b0000000000000100;
    wire [3:0] lut_126_select = {
                             in_data[507],
                             in_data[506],
                             in_data[505],
                             in_data[504]};
    
    wire lut_126_out = lut_126_table[lut_126_select];
    
    assign out_data[126] = lut_126_out;
    
    
    
    // LUT : 127
    wire [15:0] lut_127_table = 16'b0000000100000001;
    wire [3:0] lut_127_select = {
                             in_data[511],
                             in_data[510],
                             in_data[509],
                             in_data[508]};
    
    wire lut_127_out = lut_127_table[lut_127_select];
    
    assign out_data[127] = lut_127_out;
    
    
    
    // LUT : 128
    wire [15:0] lut_128_table = 16'b1111111111101000;
    wire [3:0] lut_128_select = {
                             in_data[515],
                             in_data[514],
                             in_data[513],
                             in_data[512]};
    
    wire lut_128_out = lut_128_table[lut_128_select];
    
    assign out_data[128] = lut_128_out;
    
    
    
    // LUT : 129
    wire [15:0] lut_129_table = 16'b0011001100010011;
    wire [3:0] lut_129_select = {
                             in_data[519],
                             in_data[518],
                             in_data[517],
                             in_data[516]};
    
    wire lut_129_out = lut_129_table[lut_129_select];
    
    assign out_data[129] = lut_129_out;
    
    
    
    // LUT : 130
    wire [15:0] lut_130_table = 16'b1111111111111110;
    wire [3:0] lut_130_select = {
                             in_data[523],
                             in_data[522],
                             in_data[521],
                             in_data[520]};
    
    wire lut_130_out = lut_130_table[lut_130_select];
    
    assign out_data[130] = lut_130_out;
    
    
    
    // LUT : 131
    wire [15:0] lut_131_table = 16'b1111111111111110;
    wire [3:0] lut_131_select = {
                             in_data[527],
                             in_data[526],
                             in_data[525],
                             in_data[524]};
    
    wire lut_131_out = lut_131_table[lut_131_select];
    
    assign out_data[131] = lut_131_out;
    
    
    
    // LUT : 132
    wire [15:0] lut_132_table = 16'b0100010101000101;
    wire [3:0] lut_132_select = {
                             in_data[531],
                             in_data[530],
                             in_data[529],
                             in_data[528]};
    
    wire lut_132_out = lut_132_table[lut_132_select];
    
    assign out_data[132] = lut_132_out;
    
    
    
    // LUT : 133
    wire [15:0] lut_133_table = 16'b1111111111111110;
    wire [3:0] lut_133_select = {
                             in_data[535],
                             in_data[534],
                             in_data[533],
                             in_data[532]};
    
    wire lut_133_out = lut_133_table[lut_133_select];
    
    assign out_data[133] = lut_133_out;
    
    
    
    // LUT : 134
    wire [15:0] lut_134_table = 16'b1111111111111110;
    wire [3:0] lut_134_select = {
                             in_data[539],
                             in_data[538],
                             in_data[537],
                             in_data[536]};
    
    wire lut_134_out = lut_134_table[lut_134_select];
    
    assign out_data[134] = lut_134_out;
    
    
    
    // LUT : 135
    wire [15:0] lut_135_table = 16'b1111111111111110;
    wire [3:0] lut_135_select = {
                             in_data[543],
                             in_data[542],
                             in_data[541],
                             in_data[540]};
    
    wire lut_135_out = lut_135_table[lut_135_select];
    
    assign out_data[135] = lut_135_out;
    
    
    
    // LUT : 136
    wire [15:0] lut_136_table = 16'b0000000010101010;
    wire [3:0] lut_136_select = {
                             in_data[547],
                             in_data[546],
                             in_data[545],
                             in_data[544]};
    
    wire lut_136_out = lut_136_table[lut_136_select];
    
    assign out_data[136] = lut_136_out;
    
    
    
    // LUT : 137
    wire [15:0] lut_137_table = 16'b1111111111111110;
    wire [3:0] lut_137_select = {
                             in_data[551],
                             in_data[550],
                             in_data[549],
                             in_data[548]};
    
    wire lut_137_out = lut_137_table[lut_137_select];
    
    assign out_data[137] = lut_137_out;
    
    
    
    // LUT : 138
    wire [15:0] lut_138_table = 16'b0000000000000001;
    wire [3:0] lut_138_select = {
                             in_data[555],
                             in_data[554],
                             in_data[553],
                             in_data[552]};
    
    wire lut_138_out = lut_138_table[lut_138_select];
    
    assign out_data[138] = lut_138_out;
    
    
    
    // LUT : 139
    wire [15:0] lut_139_table = 16'b0001000100010001;
    wire [3:0] lut_139_select = {
                             in_data[559],
                             in_data[558],
                             in_data[557],
                             in_data[556]};
    
    wire lut_139_out = lut_139_table[lut_139_select];
    
    assign out_data[139] = lut_139_out;
    
    
    
    // LUT : 140
    wire [15:0] lut_140_table = 16'b1111111111111110;
    wire [3:0] lut_140_select = {
                             in_data[563],
                             in_data[562],
                             in_data[561],
                             in_data[560]};
    
    wire lut_140_out = lut_140_table[lut_140_select];
    
    assign out_data[140] = lut_140_out;
    
    
    
    // LUT : 141
    wire [15:0] lut_141_table = 16'b0111111101111110;
    wire [3:0] lut_141_select = {
                             in_data[567],
                             in_data[566],
                             in_data[565],
                             in_data[564]};
    
    wire lut_141_out = lut_141_table[lut_141_select];
    
    assign out_data[141] = lut_141_out;
    
    
    
    // LUT : 142
    wire [15:0] lut_142_table = 16'b1100000000000001;
    wire [3:0] lut_142_select = {
                             in_data[571],
                             in_data[570],
                             in_data[569],
                             in_data[568]};
    
    wire lut_142_out = lut_142_table[lut_142_select];
    
    assign out_data[142] = lut_142_out;
    
    
    
    // LUT : 143
    wire [15:0] lut_143_table = 16'b0000000010101010;
    wire [3:0] lut_143_select = {
                             in_data[575],
                             in_data[574],
                             in_data[573],
                             in_data[572]};
    
    wire lut_143_out = lut_143_table[lut_143_select];
    
    assign out_data[143] = lut_143_out;
    
    
    
    // LUT : 144
    wire [15:0] lut_144_table = 16'b0000000000000001;
    wire [3:0] lut_144_select = {
                             in_data[579],
                             in_data[578],
                             in_data[577],
                             in_data[576]};
    
    wire lut_144_out = lut_144_table[lut_144_select];
    
    assign out_data[144] = lut_144_out;
    
    
    
    // LUT : 145
    wire [15:0] lut_145_table = 16'b1111111111111110;
    wire [3:0] lut_145_select = {
                             in_data[583],
                             in_data[582],
                             in_data[581],
                             in_data[580]};
    
    wire lut_145_out = lut_145_table[lut_145_select];
    
    assign out_data[145] = lut_145_out;
    
    
    
    // LUT : 146
    wire [15:0] lut_146_table = 16'b0000000000000001;
    wire [3:0] lut_146_select = {
                             in_data[587],
                             in_data[586],
                             in_data[585],
                             in_data[584]};
    
    wire lut_146_out = lut_146_table[lut_146_select];
    
    assign out_data[146] = lut_146_out;
    
    
    
    // LUT : 147
    wire [15:0] lut_147_table = 16'b0000100010101111;
    wire [3:0] lut_147_select = {
                             in_data[591],
                             in_data[590],
                             in_data[589],
                             in_data[588]};
    
    wire lut_147_out = lut_147_table[lut_147_select];
    
    assign out_data[147] = lut_147_out;
    
    
    
    // LUT : 148
    wire [15:0] lut_148_table = 16'b0000000000000011;
    wire [3:0] lut_148_select = {
                             in_data[595],
                             in_data[594],
                             in_data[593],
                             in_data[592]};
    
    wire lut_148_out = lut_148_table[lut_148_select];
    
    assign out_data[148] = lut_148_out;
    
    
    
    // LUT : 149
    wire [15:0] lut_149_table = 16'b1111111011111110;
    wire [3:0] lut_149_select = {
                             in_data[599],
                             in_data[598],
                             in_data[597],
                             in_data[596]};
    
    wire lut_149_out = lut_149_table[lut_149_select];
    
    assign out_data[149] = lut_149_out;
    
    
    
    // LUT : 150
    wire [15:0] lut_150_table = 16'b1010111011111110;
    wire [3:0] lut_150_select = {
                             in_data[603],
                             in_data[602],
                             in_data[601],
                             in_data[600]};
    
    wire lut_150_out = lut_150_table[lut_150_select];
    
    assign out_data[150] = lut_150_out;
    
    
    
    // LUT : 151
    wire [15:0] lut_151_table = 16'b1111111111111110;
    wire [3:0] lut_151_select = {
                             in_data[607],
                             in_data[606],
                             in_data[605],
                             in_data[604]};
    
    wire lut_151_out = lut_151_table[lut_151_select];
    
    assign out_data[151] = lut_151_out;
    
    
    
    // LUT : 152
    wire [15:0] lut_152_table = 16'b0000000000000001;
    wire [3:0] lut_152_select = {
                             in_data[611],
                             in_data[610],
                             in_data[609],
                             in_data[608]};
    
    wire lut_152_out = lut_152_table[lut_152_select];
    
    assign out_data[152] = lut_152_out;
    
    
    
    // LUT : 153
    wire [15:0] lut_153_table = 16'b0000000100000001;
    wire [3:0] lut_153_select = {
                             in_data[615],
                             in_data[614],
                             in_data[613],
                             in_data[612]};
    
    wire lut_153_out = lut_153_table[lut_153_select];
    
    assign out_data[153] = lut_153_out;
    
    
    
    // LUT : 154
    wire [15:0] lut_154_table = 16'b0000000000001011;
    wire [3:0] lut_154_select = {
                             in_data[619],
                             in_data[618],
                             in_data[617],
                             in_data[616]};
    
    wire lut_154_out = lut_154_table[lut_154_select];
    
    assign out_data[154] = lut_154_out;
    
    
    
    // LUT : 155
    wire [15:0] lut_155_table = 16'b0000000000000001;
    wire [3:0] lut_155_select = {
                             in_data[623],
                             in_data[622],
                             in_data[621],
                             in_data[620]};
    
    wire lut_155_out = lut_155_table[lut_155_select];
    
    assign out_data[155] = lut_155_out;
    
    
    
    // LUT : 156
    wire [15:0] lut_156_table = 16'b0000000000000001;
    wire [3:0] lut_156_select = {
                             in_data[627],
                             in_data[626],
                             in_data[625],
                             in_data[624]};
    
    wire lut_156_out = lut_156_table[lut_156_select];
    
    assign out_data[156] = lut_156_out;
    
    
    
    // LUT : 157
    wire [15:0] lut_157_table = 16'b0000000000000001;
    wire [3:0] lut_157_select = {
                             in_data[631],
                             in_data[630],
                             in_data[629],
                             in_data[628]};
    
    wire lut_157_out = lut_157_table[lut_157_select];
    
    assign out_data[157] = lut_157_out;
    
    
    
    // LUT : 158
    wire [15:0] lut_158_table = 16'b0010000000000001;
    wire [3:0] lut_158_select = {
                             in_data[635],
                             in_data[634],
                             in_data[633],
                             in_data[632]};
    
    wire lut_158_out = lut_158_table[lut_158_select];
    
    assign out_data[158] = lut_158_out;
    
    
    
    // LUT : 159
    wire [15:0] lut_159_table = 16'b1111111111111110;
    wire [3:0] lut_159_select = {
                             in_data[639],
                             in_data[638],
                             in_data[637],
                             in_data[636]};
    
    wire lut_159_out = lut_159_table[lut_159_select];
    
    assign out_data[159] = lut_159_out;
    
    
    
    // LUT : 160
    wire [15:0] lut_160_table = 16'b1111000011110000;
    wire [3:0] lut_160_select = {
                             in_data[643],
                             in_data[642],
                             in_data[641],
                             in_data[640]};
    
    wire lut_160_out = lut_160_table[lut_160_select];
    
    assign out_data[160] = lut_160_out;
    
    
    
    // LUT : 161
    wire [15:0] lut_161_table = 16'b0000000011111010;
    wire [3:0] lut_161_select = {
                             in_data[647],
                             in_data[646],
                             in_data[645],
                             in_data[644]};
    
    wire lut_161_out = lut_161_table[lut_161_select];
    
    assign out_data[161] = lut_161_out;
    
    
    
    // LUT : 162
    wire [15:0] lut_162_table = 16'b0000000000000001;
    wire [3:0] lut_162_select = {
                             in_data[651],
                             in_data[650],
                             in_data[649],
                             in_data[648]};
    
    wire lut_162_out = lut_162_table[lut_162_select];
    
    assign out_data[162] = lut_162_out;
    
    
    
    // LUT : 163
    wire [15:0] lut_163_table = 16'b0000000000000001;
    wire [3:0] lut_163_select = {
                             in_data[655],
                             in_data[654],
                             in_data[653],
                             in_data[652]};
    
    wire lut_163_out = lut_163_table[lut_163_select];
    
    assign out_data[163] = lut_163_out;
    
    
    
    // LUT : 164
    wire [15:0] lut_164_table = 16'b0000000000000001;
    wire [3:0] lut_164_select = {
                             in_data[659],
                             in_data[658],
                             in_data[657],
                             in_data[656]};
    
    wire lut_164_out = lut_164_table[lut_164_select];
    
    assign out_data[164] = lut_164_out;
    
    
    
    // LUT : 165
    wire [15:0] lut_165_table = 16'b0000000000000001;
    wire [3:0] lut_165_select = {
                             in_data[663],
                             in_data[662],
                             in_data[661],
                             in_data[660]};
    
    wire lut_165_out = lut_165_table[lut_165_select];
    
    assign out_data[165] = lut_165_out;
    
    
    
    // LUT : 166
    wire [15:0] lut_166_table = 16'b1111111111111110;
    wire [3:0] lut_166_select = {
                             in_data[667],
                             in_data[666],
                             in_data[665],
                             in_data[664]};
    
    wire lut_166_out = lut_166_table[lut_166_select];
    
    assign out_data[166] = lut_166_out;
    
    
    
    // LUT : 167
    wire [15:0] lut_167_table = 16'b1111111011111111;
    wire [3:0] lut_167_select = {
                             in_data[671],
                             in_data[670],
                             in_data[669],
                             in_data[668]};
    
    wire lut_167_out = lut_167_table[lut_167_select];
    
    assign out_data[167] = lut_167_out;
    
    
    
    // LUT : 168
    wire [15:0] lut_168_table = 16'b0000000001001110;
    wire [3:0] lut_168_select = {
                             in_data[675],
                             in_data[674],
                             in_data[673],
                             in_data[672]};
    
    wire lut_168_out = lut_168_table[lut_168_select];
    
    assign out_data[168] = lut_168_out;
    
    
    
    // LUT : 169
    wire [15:0] lut_169_table = 16'b1111111111111110;
    wire [3:0] lut_169_select = {
                             in_data[679],
                             in_data[678],
                             in_data[677],
                             in_data[676]};
    
    wire lut_169_out = lut_169_table[lut_169_select];
    
    assign out_data[169] = lut_169_out;
    
    
    
    // LUT : 170
    wire [15:0] lut_170_table = 16'b1111111011111110;
    wire [3:0] lut_170_select = {
                             in_data[683],
                             in_data[682],
                             in_data[681],
                             in_data[680]};
    
    wire lut_170_out = lut_170_table[lut_170_select];
    
    assign out_data[170] = lut_170_out;
    
    
    
    // LUT : 171
    wire [15:0] lut_171_table = 16'b0000000100010001;
    wire [3:0] lut_171_select = {
                             in_data[687],
                             in_data[686],
                             in_data[685],
                             in_data[684]};
    
    wire lut_171_out = lut_171_table[lut_171_select];
    
    assign out_data[171] = lut_171_out;
    
    
    
    // LUT : 172
    wire [15:0] lut_172_table = 16'b1111111111111100;
    wire [3:0] lut_172_select = {
                             in_data[691],
                             in_data[690],
                             in_data[689],
                             in_data[688]};
    
    wire lut_172_out = lut_172_table[lut_172_select];
    
    assign out_data[172] = lut_172_out;
    
    
    
    // LUT : 173
    wire [15:0] lut_173_table = 16'b0000000000000001;
    wire [3:0] lut_173_select = {
                             in_data[695],
                             in_data[694],
                             in_data[693],
                             in_data[692]};
    
    wire lut_173_out = lut_173_table[lut_173_select];
    
    assign out_data[173] = lut_173_out;
    
    
    
    // LUT : 174
    wire [15:0] lut_174_table = 16'b0011001100110010;
    wire [3:0] lut_174_select = {
                             in_data[699],
                             in_data[698],
                             in_data[697],
                             in_data[696]};
    
    wire lut_174_out = lut_174_table[lut_174_select];
    
    assign out_data[174] = lut_174_out;
    
    
    
    // LUT : 175
    wire [15:0] lut_175_table = 16'b0000000011110000;
    wire [3:0] lut_175_select = {
                             in_data[703],
                             in_data[702],
                             in_data[701],
                             in_data[700]};
    
    wire lut_175_out = lut_175_table[lut_175_select];
    
    assign out_data[175] = lut_175_out;
    
    
    
    // LUT : 176
    wire [15:0] lut_176_table = 16'b1111111111111110;
    wire [3:0] lut_176_select = {
                             in_data[707],
                             in_data[706],
                             in_data[705],
                             in_data[704]};
    
    wire lut_176_out = lut_176_table[lut_176_select];
    
    assign out_data[176] = lut_176_out;
    
    
    
    // LUT : 177
    wire [15:0] lut_177_table = 16'b1111111111111110;
    wire [3:0] lut_177_select = {
                             in_data[711],
                             in_data[710],
                             in_data[709],
                             in_data[708]};
    
    wire lut_177_out = lut_177_table[lut_177_select];
    
    assign out_data[177] = lut_177_out;
    
    
    
    // LUT : 178
    wire [15:0] lut_178_table = 16'b1111111111111110;
    wire [3:0] lut_178_select = {
                             in_data[715],
                             in_data[714],
                             in_data[713],
                             in_data[712]};
    
    wire lut_178_out = lut_178_table[lut_178_select];
    
    assign out_data[178] = lut_178_out;
    
    
    
    // LUT : 179
    wire [15:0] lut_179_table = 16'b1111111111111110;
    wire [3:0] lut_179_select = {
                             in_data[719],
                             in_data[718],
                             in_data[717],
                             in_data[716]};
    
    wire lut_179_out = lut_179_table[lut_179_select];
    
    assign out_data[179] = lut_179_out;
    
    
    
    // LUT : 180
    wire [15:0] lut_180_table = 16'b1111111111111101;
    wire [3:0] lut_180_select = {
                             in_data[723],
                             in_data[722],
                             in_data[721],
                             in_data[720]};
    
    wire lut_180_out = lut_180_table[lut_180_select];
    
    assign out_data[180] = lut_180_out;
    
    
    
    // LUT : 181
    wire [15:0] lut_181_table = 16'b0000000000000000;
    wire [3:0] lut_181_select = {
                             in_data[727],
                             in_data[726],
                             in_data[725],
                             in_data[724]};
    
    wire lut_181_out = lut_181_table[lut_181_select];
    
    assign out_data[181] = lut_181_out;
    
    
    
    // LUT : 182
    wire [15:0] lut_182_table = 16'b1111111111111111;
    wire [3:0] lut_182_select = {
                             in_data[731],
                             in_data[730],
                             in_data[729],
                             in_data[728]};
    
    wire lut_182_out = lut_182_table[lut_182_select];
    
    assign out_data[182] = lut_182_out;
    
    
    
    // LUT : 183
    wire [15:0] lut_183_table = 16'b0000000000000001;
    wire [3:0] lut_183_select = {
                             in_data[735],
                             in_data[734],
                             in_data[733],
                             in_data[732]};
    
    wire lut_183_out = lut_183_table[lut_183_select];
    
    assign out_data[183] = lut_183_out;
    
    
    
    // LUT : 184
    wire [15:0] lut_184_table = 16'b0000000000000001;
    wire [3:0] lut_184_select = {
                             in_data[739],
                             in_data[738],
                             in_data[737],
                             in_data[736]};
    
    wire lut_184_out = lut_184_table[lut_184_select];
    
    assign out_data[184] = lut_184_out;
    
    
    
    // LUT : 185
    wire [15:0] lut_185_table = 16'b0000000000000001;
    wire [3:0] lut_185_select = {
                             in_data[743],
                             in_data[742],
                             in_data[741],
                             in_data[740]};
    
    wire lut_185_out = lut_185_table[lut_185_select];
    
    assign out_data[185] = lut_185_out;
    
    
    
    // LUT : 186
    wire [15:0] lut_186_table = 16'b1111111111111110;
    wire [3:0] lut_186_select = {
                             in_data[747],
                             in_data[746],
                             in_data[745],
                             in_data[744]};
    
    wire lut_186_out = lut_186_table[lut_186_select];
    
    assign out_data[186] = lut_186_out;
    
    
    
    // LUT : 187
    wire [15:0] lut_187_table = 16'b1111111111111111;
    wire [3:0] lut_187_select = {
                             in_data[751],
                             in_data[750],
                             in_data[749],
                             in_data[748]};
    
    wire lut_187_out = lut_187_table[lut_187_select];
    
    assign out_data[187] = lut_187_out;
    
    
    
    // LUT : 188
    wire [15:0] lut_188_table = 16'b0001000100010001;
    wire [3:0] lut_188_select = {
                             in_data[755],
                             in_data[754],
                             in_data[753],
                             in_data[752]};
    
    wire lut_188_out = lut_188_table[lut_188_select];
    
    assign out_data[188] = lut_188_out;
    
    
    
    // LUT : 189
    wire [15:0] lut_189_table = 16'b0111000100010000;
    wire [3:0] lut_189_select = {
                             in_data[759],
                             in_data[758],
                             in_data[757],
                             in_data[756]};
    
    wire lut_189_out = lut_189_table[lut_189_select];
    
    assign out_data[189] = lut_189_out;
    
    
    
    // LUT : 190
    wire [15:0] lut_190_table = 16'b0000000011110000;
    wire [3:0] lut_190_select = {
                             in_data[763],
                             in_data[762],
                             in_data[761],
                             in_data[760]};
    
    wire lut_190_out = lut_190_table[lut_190_select];
    
    assign out_data[190] = lut_190_out;
    
    
    
    // LUT : 191
    wire [15:0] lut_191_table = 16'b1111111111111111;
    wire [3:0] lut_191_select = {
                             in_data[767],
                             in_data[766],
                             in_data[765],
                             in_data[764]};
    
    wire lut_191_out = lut_191_table[lut_191_select];
    
    assign out_data[191] = lut_191_out;
    
    
    
    // LUT : 192
    wire [15:0] lut_192_table = 16'b0000000000000001;
    wire [3:0] lut_192_select = {
                             in_data[771],
                             in_data[770],
                             in_data[769],
                             in_data[768]};
    
    wire lut_192_out = lut_192_table[lut_192_select];
    
    assign out_data[192] = lut_192_out;
    
    
    
    // LUT : 193
    wire [15:0] lut_193_table = 16'b0000000000000001;
    wire [3:0] lut_193_select = {
                             in_data[775],
                             in_data[774],
                             in_data[773],
                             in_data[772]};
    
    wire lut_193_out = lut_193_table[lut_193_select];
    
    assign out_data[193] = lut_193_out;
    
    
    
    // LUT : 194
    wire [15:0] lut_194_table = 16'b0000000000000001;
    wire [3:0] lut_194_select = {
                             in_data[779],
                             in_data[778],
                             in_data[777],
                             in_data[776]};
    
    wire lut_194_out = lut_194_table[lut_194_select];
    
    assign out_data[194] = lut_194_out;
    
    
    
    // LUT : 195
    wire [15:0] lut_195_table = 16'b1111111111111110;
    wire [3:0] lut_195_select = {
                             in_data[783],
                             in_data[782],
                             in_data[781],
                             in_data[780]};
    
    wire lut_195_out = lut_195_table[lut_195_select];
    
    assign out_data[195] = lut_195_out;
    
    
    
    // LUT : 196
    wire [15:0] lut_196_table = 16'b0100011001001111;
    wire [3:0] lut_196_select = {
                             in_data[3],
                             in_data[2],
                             in_data[1],
                             in_data[0]};
    
    wire lut_196_out = lut_196_table[lut_196_select];
    
    assign out_data[196] = lut_196_out;
    
    
    
    // LUT : 197
    wire [15:0] lut_197_table = 16'b1101111100011001;
    wire [3:0] lut_197_select = {
                             in_data[7],
                             in_data[6],
                             in_data[5],
                             in_data[4]};
    
    wire lut_197_out = lut_197_table[lut_197_select];
    
    assign out_data[197] = lut_197_out;
    
    
    
    // LUT : 198
    wire [15:0] lut_198_table = 16'b0101000010110011;
    wire [3:0] lut_198_select = {
                             in_data[11],
                             in_data[10],
                             in_data[9],
                             in_data[8]};
    
    wire lut_198_out = lut_198_table[lut_198_select];
    
    assign out_data[198] = lut_198_out;
    
    
    
    // LUT : 199
    wire [15:0] lut_199_table = 16'b0000000000000000;
    wire [3:0] lut_199_select = {
                             in_data[15],
                             in_data[14],
                             in_data[13],
                             in_data[12]};
    
    wire lut_199_out = lut_199_table[lut_199_select];
    
    assign out_data[199] = lut_199_out;
    
    
    
    // LUT : 200
    wire [15:0] lut_200_table = 16'b0111001001111100;
    wire [3:0] lut_200_select = {
                             in_data[19],
                             in_data[18],
                             in_data[17],
                             in_data[16]};
    
    wire lut_200_out = lut_200_table[lut_200_select];
    
    assign out_data[200] = lut_200_out;
    
    
    
    // LUT : 201
    wire [15:0] lut_201_table = 16'b1110010011100011;
    wire [3:0] lut_201_select = {
                             in_data[23],
                             in_data[22],
                             in_data[21],
                             in_data[20]};
    
    wire lut_201_out = lut_201_table[lut_201_select];
    
    assign out_data[201] = lut_201_out;
    
    
    
    // LUT : 202
    wire [15:0] lut_202_table = 16'b0111111101110011;
    wire [3:0] lut_202_select = {
                             in_data[27],
                             in_data[26],
                             in_data[25],
                             in_data[24]};
    
    wire lut_202_out = lut_202_table[lut_202_select];
    
    assign out_data[202] = lut_202_out;
    
    
    
    // LUT : 203
    wire [15:0] lut_203_table = 16'b0000000000000000;
    wire [3:0] lut_203_select = {
                             in_data[31],
                             in_data[30],
                             in_data[29],
                             in_data[28]};
    
    wire lut_203_out = lut_203_table[lut_203_select];
    
    assign out_data[203] = lut_203_out;
    
    
    
    // LUT : 204
    wire [15:0] lut_204_table = 16'b1111010111110000;
    wire [3:0] lut_204_select = {
                             in_data[35],
                             in_data[34],
                             in_data[33],
                             in_data[32]};
    
    wire lut_204_out = lut_204_table[lut_204_select];
    
    assign out_data[204] = lut_204_out;
    
    
    
    // LUT : 205
    wire [15:0] lut_205_table = 16'b0000000000000000;
    wire [3:0] lut_205_select = {
                             in_data[39],
                             in_data[38],
                             in_data[37],
                             in_data[36]};
    
    wire lut_205_out = lut_205_table[lut_205_select];
    
    assign out_data[205] = lut_205_out;
    
    
    
    // LUT : 206
    wire [15:0] lut_206_table = 16'b0000000000000000;
    wire [3:0] lut_206_select = {
                             in_data[43],
                             in_data[42],
                             in_data[41],
                             in_data[40]};
    
    wire lut_206_out = lut_206_table[lut_206_select];
    
    assign out_data[206] = lut_206_out;
    
    
    
    // LUT : 207
    wire [15:0] lut_207_table = 16'b1111111111111111;
    wire [3:0] lut_207_select = {
                             in_data[47],
                             in_data[46],
                             in_data[45],
                             in_data[44]};
    
    wire lut_207_out = lut_207_table[lut_207_select];
    
    assign out_data[207] = lut_207_out;
    
    
    
    // LUT : 208
    wire [15:0] lut_208_table = 16'b1111111111111111;
    wire [3:0] lut_208_select = {
                             in_data[51],
                             in_data[50],
                             in_data[49],
                             in_data[48]};
    
    wire lut_208_out = lut_208_table[lut_208_select];
    
    assign out_data[208] = lut_208_out;
    
    
    
    // LUT : 209
    wire [15:0] lut_209_table = 16'b0010101100000010;
    wire [3:0] lut_209_select = {
                             in_data[55],
                             in_data[54],
                             in_data[53],
                             in_data[52]};
    
    wire lut_209_out = lut_209_table[lut_209_select];
    
    assign out_data[209] = lut_209_out;
    
    
    
    // LUT : 210
    wire [15:0] lut_210_table = 16'b1111111111110010;
    wire [3:0] lut_210_select = {
                             in_data[59],
                             in_data[58],
                             in_data[57],
                             in_data[56]};
    
    wire lut_210_out = lut_210_table[lut_210_select];
    
    assign out_data[210] = lut_210_out;
    
    
    
    // LUT : 211
    wire [15:0] lut_211_table = 16'b1111111111111110;
    wire [3:0] lut_211_select = {
                             in_data[63],
                             in_data[62],
                             in_data[61],
                             in_data[60]};
    
    wire lut_211_out = lut_211_table[lut_211_select];
    
    assign out_data[211] = lut_211_out;
    
    
    
    // LUT : 212
    wire [15:0] lut_212_table = 16'b1111111111111110;
    wire [3:0] lut_212_select = {
                             in_data[67],
                             in_data[66],
                             in_data[65],
                             in_data[64]};
    
    wire lut_212_out = lut_212_table[lut_212_select];
    
    assign out_data[212] = lut_212_out;
    
    
    
    // LUT : 213
    wire [15:0] lut_213_table = 16'b1111111111011100;
    wire [3:0] lut_213_select = {
                             in_data[71],
                             in_data[70],
                             in_data[69],
                             in_data[68]};
    
    wire lut_213_out = lut_213_table[lut_213_select];
    
    assign out_data[213] = lut_213_out;
    
    
    
    // LUT : 214
    wire [15:0] lut_214_table = 16'b1111111111111110;
    wire [3:0] lut_214_select = {
                             in_data[75],
                             in_data[74],
                             in_data[73],
                             in_data[72]};
    
    wire lut_214_out = lut_214_table[lut_214_select];
    
    assign out_data[214] = lut_214_out;
    
    
    
    // LUT : 215
    wire [15:0] lut_215_table = 16'b1111111111111110;
    wire [3:0] lut_215_select = {
                             in_data[79],
                             in_data[78],
                             in_data[77],
                             in_data[76]};
    
    wire lut_215_out = lut_215_table[lut_215_select];
    
    assign out_data[215] = lut_215_out;
    
    
    
    // LUT : 216
    wire [15:0] lut_216_table = 16'b0001000100000001;
    wire [3:0] lut_216_select = {
                             in_data[83],
                             in_data[82],
                             in_data[81],
                             in_data[80]};
    
    wire lut_216_out = lut_216_table[lut_216_select];
    
    assign out_data[216] = lut_216_out;
    
    
    
    // LUT : 217
    wire [15:0] lut_217_table = 16'b1111111100001111;
    wire [3:0] lut_217_select = {
                             in_data[87],
                             in_data[86],
                             in_data[85],
                             in_data[84]};
    
    wire lut_217_out = lut_217_table[lut_217_select];
    
    assign out_data[217] = lut_217_out;
    
    
    
    // LUT : 218
    wire [15:0] lut_218_table = 16'b1111111111111010;
    wire [3:0] lut_218_select = {
                             in_data[91],
                             in_data[90],
                             in_data[89],
                             in_data[88]};
    
    wire lut_218_out = lut_218_table[lut_218_select];
    
    assign out_data[218] = lut_218_out;
    
    
    
    // LUT : 219
    wire [15:0] lut_219_table = 16'b0000000000000001;
    wire [3:0] lut_219_select = {
                             in_data[95],
                             in_data[94],
                             in_data[93],
                             in_data[92]};
    
    wire lut_219_out = lut_219_table[lut_219_select];
    
    assign out_data[219] = lut_219_out;
    
    
    
    // LUT : 220
    wire [15:0] lut_220_table = 16'b1111111111111110;
    wire [3:0] lut_220_select = {
                             in_data[99],
                             in_data[98],
                             in_data[97],
                             in_data[96]};
    
    wire lut_220_out = lut_220_table[lut_220_select];
    
    assign out_data[220] = lut_220_out;
    
    
    
    // LUT : 221
    wire [15:0] lut_221_table = 16'b0000000000000001;
    wire [3:0] lut_221_select = {
                             in_data[103],
                             in_data[102],
                             in_data[101],
                             in_data[100]};
    
    wire lut_221_out = lut_221_table[lut_221_select];
    
    assign out_data[221] = lut_221_out;
    
    
    
    // LUT : 222
    wire [15:0] lut_222_table = 16'b0000000000000000;
    wire [3:0] lut_222_select = {
                             in_data[107],
                             in_data[106],
                             in_data[105],
                             in_data[104]};
    
    wire lut_222_out = lut_222_table[lut_222_select];
    
    assign out_data[222] = lut_222_out;
    
    
    
    // LUT : 223
    wire [15:0] lut_223_table = 16'b0000000000000001;
    wire [3:0] lut_223_select = {
                             in_data[111],
                             in_data[110],
                             in_data[109],
                             in_data[108]};
    
    wire lut_223_out = lut_223_table[lut_223_select];
    
    assign out_data[223] = lut_223_out;
    
    
    
    // LUT : 224
    wire [15:0] lut_224_table = 16'b1111111100001100;
    wire [3:0] lut_224_select = {
                             in_data[115],
                             in_data[114],
                             in_data[113],
                             in_data[112]};
    
    wire lut_224_out = lut_224_table[lut_224_select];
    
    assign out_data[224] = lut_224_out;
    
    
    
    // LUT : 225
    wire [15:0] lut_225_table = 16'b1111111111111100;
    wire [3:0] lut_225_select = {
                             in_data[119],
                             in_data[118],
                             in_data[117],
                             in_data[116]};
    
    wire lut_225_out = lut_225_table[lut_225_select];
    
    assign out_data[225] = lut_225_out;
    
    
    
    // LUT : 226
    wire [15:0] lut_226_table = 16'b0000000000000001;
    wire [3:0] lut_226_select = {
                             in_data[123],
                             in_data[122],
                             in_data[121],
                             in_data[120]};
    
    wire lut_226_out = lut_226_table[lut_226_select];
    
    assign out_data[226] = lut_226_out;
    
    
    
    // LUT : 227
    wire [15:0] lut_227_table = 16'b1111111111111110;
    wire [3:0] lut_227_select = {
                             in_data[127],
                             in_data[126],
                             in_data[125],
                             in_data[124]};
    
    wire lut_227_out = lut_227_table[lut_227_select];
    
    assign out_data[227] = lut_227_out;
    
    
    
    // LUT : 228
    wire [15:0] lut_228_table = 16'b0000000000000001;
    wire [3:0] lut_228_select = {
                             in_data[131],
                             in_data[130],
                             in_data[129],
                             in_data[128]};
    
    wire lut_228_out = lut_228_table[lut_228_select];
    
    assign out_data[228] = lut_228_out;
    
    
    
    // LUT : 229
    wire [15:0] lut_229_table = 16'b0000000000000001;
    wire [3:0] lut_229_select = {
                             in_data[135],
                             in_data[134],
                             in_data[133],
                             in_data[132]};
    
    wire lut_229_out = lut_229_table[lut_229_select];
    
    assign out_data[229] = lut_229_out;
    
    
    
    // LUT : 230
    wire [15:0] lut_230_table = 16'b0101010001010101;
    wire [3:0] lut_230_select = {
                             in_data[139],
                             in_data[138],
                             in_data[137],
                             in_data[136]};
    
    wire lut_230_out = lut_230_table[lut_230_select];
    
    assign out_data[230] = lut_230_out;
    
    
    
    // LUT : 231
    wire [15:0] lut_231_table = 16'b0000000000000001;
    wire [3:0] lut_231_select = {
                             in_data[143],
                             in_data[142],
                             in_data[141],
                             in_data[140]};
    
    wire lut_231_out = lut_231_table[lut_231_select];
    
    assign out_data[231] = lut_231_out;
    
    
    
    // LUT : 232
    wire [15:0] lut_232_table = 16'b1111111111111111;
    wire [3:0] lut_232_select = {
                             in_data[147],
                             in_data[146],
                             in_data[145],
                             in_data[144]};
    
    wire lut_232_out = lut_232_table[lut_232_select];
    
    assign out_data[232] = lut_232_out;
    
    
    
    // LUT : 233
    wire [15:0] lut_233_table = 16'b0000000100000001;
    wire [3:0] lut_233_select = {
                             in_data[151],
                             in_data[150],
                             in_data[149],
                             in_data[148]};
    
    wire lut_233_out = lut_233_table[lut_233_select];
    
    assign out_data[233] = lut_233_out;
    
    
    
    // LUT : 234
    wire [15:0] lut_234_table = 16'b1111111111111110;
    wire [3:0] lut_234_select = {
                             in_data[155],
                             in_data[154],
                             in_data[153],
                             in_data[152]};
    
    wire lut_234_out = lut_234_table[lut_234_select];
    
    assign out_data[234] = lut_234_out;
    
    
    
    // LUT : 235
    wire [15:0] lut_235_table = 16'b0000000000000001;
    wire [3:0] lut_235_select = {
                             in_data[159],
                             in_data[158],
                             in_data[157],
                             in_data[156]};
    
    wire lut_235_out = lut_235_table[lut_235_select];
    
    assign out_data[235] = lut_235_out;
    
    
    
    // LUT : 236
    wire [15:0] lut_236_table = 16'b0000000000000001;
    wire [3:0] lut_236_select = {
                             in_data[163],
                             in_data[162],
                             in_data[161],
                             in_data[160]};
    
    wire lut_236_out = lut_236_table[lut_236_select];
    
    assign out_data[236] = lut_236_out;
    
    
    
    // LUT : 237
    wire [15:0] lut_237_table = 16'b1111111111111010;
    wire [3:0] lut_237_select = {
                             in_data[167],
                             in_data[166],
                             in_data[165],
                             in_data[164]};
    
    wire lut_237_out = lut_237_table[lut_237_select];
    
    assign out_data[237] = lut_237_out;
    
    
    
    // LUT : 238
    wire [15:0] lut_238_table = 16'b0000000000000000;
    wire [3:0] lut_238_select = {
                             in_data[171],
                             in_data[170],
                             in_data[169],
                             in_data[168]};
    
    wire lut_238_out = lut_238_table[lut_238_select];
    
    assign out_data[238] = lut_238_out;
    
    
    
    // LUT : 239
    wire [15:0] lut_239_table = 16'b0000000000000001;
    wire [3:0] lut_239_select = {
                             in_data[175],
                             in_data[174],
                             in_data[173],
                             in_data[172]};
    
    wire lut_239_out = lut_239_table[lut_239_select];
    
    assign out_data[239] = lut_239_out;
    
    
    
    // LUT : 240
    wire [15:0] lut_240_table = 16'b0000000111111111;
    wire [3:0] lut_240_select = {
                             in_data[179],
                             in_data[178],
                             in_data[177],
                             in_data[176]};
    
    wire lut_240_out = lut_240_table[lut_240_select];
    
    assign out_data[240] = lut_240_out;
    
    
    
    // LUT : 241
    wire [15:0] lut_241_table = 16'b1111111010101000;
    wire [3:0] lut_241_select = {
                             in_data[183],
                             in_data[182],
                             in_data[181],
                             in_data[180]};
    
    wire lut_241_out = lut_241_table[lut_241_select];
    
    assign out_data[241] = lut_241_out;
    
    
    
    // LUT : 242
    wire [15:0] lut_242_table = 16'b1010101010100000;
    wire [3:0] lut_242_select = {
                             in_data[187],
                             in_data[186],
                             in_data[185],
                             in_data[184]};
    
    wire lut_242_out = lut_242_table[lut_242_select];
    
    assign out_data[242] = lut_242_out;
    
    
    
    // LUT : 243
    wire [15:0] lut_243_table = 16'b0101111111111110;
    wire [3:0] lut_243_select = {
                             in_data[191],
                             in_data[190],
                             in_data[189],
                             in_data[188]};
    
    wire lut_243_out = lut_243_table[lut_243_select];
    
    assign out_data[243] = lut_243_out;
    
    
    
    // LUT : 244
    wire [15:0] lut_244_table = 16'b0101000011110101;
    wire [3:0] lut_244_select = {
                             in_data[195],
                             in_data[194],
                             in_data[193],
                             in_data[192]};
    
    wire lut_244_out = lut_244_table[lut_244_select];
    
    assign out_data[244] = lut_244_out;
    
    
    
    // LUT : 245
    wire [15:0] lut_245_table = 16'b1111111111111110;
    wire [3:0] lut_245_select = {
                             in_data[199],
                             in_data[198],
                             in_data[197],
                             in_data[196]};
    
    wire lut_245_out = lut_245_table[lut_245_select];
    
    assign out_data[245] = lut_245_out;
    
    
    
    // LUT : 246
    wire [15:0] lut_246_table = 16'b1111111111111110;
    wire [3:0] lut_246_select = {
                             in_data[203],
                             in_data[202],
                             in_data[201],
                             in_data[200]};
    
    wire lut_246_out = lut_246_table[lut_246_select];
    
    assign out_data[246] = lut_246_out;
    
    
    
    // LUT : 247
    wire [15:0] lut_247_table = 16'b1111111111111110;
    wire [3:0] lut_247_select = {
                             in_data[207],
                             in_data[206],
                             in_data[205],
                             in_data[204]};
    
    wire lut_247_out = lut_247_table[lut_247_select];
    
    assign out_data[247] = lut_247_out;
    
    
    
    // LUT : 248
    wire [15:0] lut_248_table = 16'b1111111011101000;
    wire [3:0] lut_248_select = {
                             in_data[211],
                             in_data[210],
                             in_data[209],
                             in_data[208]};
    
    wire lut_248_out = lut_248_table[lut_248_select];
    
    assign out_data[248] = lut_248_out;
    
    
    
    // LUT : 249
    wire [15:0] lut_249_table = 16'b1111111111010000;
    wire [3:0] lut_249_select = {
                             in_data[215],
                             in_data[214],
                             in_data[213],
                             in_data[212]};
    
    wire lut_249_out = lut_249_table[lut_249_select];
    
    assign out_data[249] = lut_249_out;
    
    
    
    // LUT : 250
    wire [15:0] lut_250_table = 16'b0000000000001111;
    wire [3:0] lut_250_select = {
                             in_data[219],
                             in_data[218],
                             in_data[217],
                             in_data[216]};
    
    wire lut_250_out = lut_250_table[lut_250_select];
    
    assign out_data[250] = lut_250_out;
    
    
    
    // LUT : 251
    wire [15:0] lut_251_table = 16'b1111111111111110;
    wire [3:0] lut_251_select = {
                             in_data[223],
                             in_data[222],
                             in_data[221],
                             in_data[220]};
    
    wire lut_251_out = lut_251_table[lut_251_select];
    
    assign out_data[251] = lut_251_out;
    
    
    
    // LUT : 252
    wire [15:0] lut_252_table = 16'b1111111111111111;
    wire [3:0] lut_252_select = {
                             in_data[227],
                             in_data[226],
                             in_data[225],
                             in_data[224]};
    
    wire lut_252_out = lut_252_table[lut_252_select];
    
    assign out_data[252] = lut_252_out;
    
    
    
    // LUT : 253
    wire [15:0] lut_253_table = 16'b1111111111111110;
    wire [3:0] lut_253_select = {
                             in_data[231],
                             in_data[230],
                             in_data[229],
                             in_data[228]};
    
    wire lut_253_out = lut_253_table[lut_253_select];
    
    assign out_data[253] = lut_253_out;
    
    
    
    // LUT : 254
    wire [15:0] lut_254_table = 16'b0000010011111110;
    wire [3:0] lut_254_select = {
                             in_data[235],
                             in_data[234],
                             in_data[233],
                             in_data[232]};
    
    wire lut_254_out = lut_254_table[lut_254_select];
    
    assign out_data[254] = lut_254_out;
    
    
    
    // LUT : 255
    wire [15:0] lut_255_table = 16'b1110000000000000;
    wire [3:0] lut_255_select = {
                             in_data[239],
                             in_data[238],
                             in_data[237],
                             in_data[236]};
    
    wire lut_255_out = lut_255_table[lut_255_select];
    
    assign out_data[255] = lut_255_out;
    
    
endmodule



module MnistLut4Simple_sub1
        #(
            parameter INIT_REG = 1'bx,
            parameter DEVICE   = "RTL"
        )
        (
            input  wire         reset,
            input  wire         clk,
            input  wire         cke,
            
            input  wire [255:0]  in_data,
            output wire [63:0]  out_data
        );
    
    
    // LUT : 0
    wire [15:0] lut_0_table = 16'b1111111101010100;
    wire [3:0] lut_0_select = {
                             in_data[3],
                             in_data[2],
                             in_data[1],
                             in_data[0]};
    
    wire lut_0_out = lut_0_table[lut_0_select];
    
    assign out_data[0] = lut_0_out;
    
    
    
    // LUT : 1
    wire [15:0] lut_1_table = 16'b1111111111111111;
    wire [3:0] lut_1_select = {
                             in_data[7],
                             in_data[6],
                             in_data[5],
                             in_data[4]};
    
    wire lut_1_out = lut_1_table[lut_1_select];
    
    assign out_data[1] = lut_1_out;
    
    
    
    // LUT : 2
    wire [15:0] lut_2_table = 16'b1111111111001101;
    wire [3:0] lut_2_select = {
                             in_data[11],
                             in_data[10],
                             in_data[9],
                             in_data[8]};
    
    wire lut_2_out = lut_2_table[lut_2_select];
    
    assign out_data[2] = lut_2_out;
    
    
    
    // LUT : 3
    wire [15:0] lut_3_table = 16'b0000000011111110;
    wire [3:0] lut_3_select = {
                             in_data[15],
                             in_data[14],
                             in_data[13],
                             in_data[12]};
    
    wire lut_3_out = lut_3_table[lut_3_select];
    
    assign out_data[3] = lut_3_out;
    
    
    
    // LUT : 4
    wire [15:0] lut_4_table = 16'b0100110111011111;
    wire [3:0] lut_4_select = {
                             in_data[19],
                             in_data[18],
                             in_data[17],
                             in_data[16]};
    
    wire lut_4_out = lut_4_table[lut_4_select];
    
    assign out_data[4] = lut_4_out;
    
    
    
    // LUT : 5
    wire [15:0] lut_5_table = 16'b0000111100000000;
    wire [3:0] lut_5_select = {
                             in_data[23],
                             in_data[22],
                             in_data[21],
                             in_data[20]};
    
    wire lut_5_out = lut_5_table[lut_5_select];
    
    assign out_data[5] = lut_5_out;
    
    
    
    // LUT : 6
    wire [15:0] lut_6_table = 16'b1011101111111011;
    wire [3:0] lut_6_select = {
                             in_data[27],
                             in_data[26],
                             in_data[25],
                             in_data[24]};
    
    wire lut_6_out = lut_6_table[lut_6_select];
    
    assign out_data[6] = lut_6_out;
    
    
    
    // LUT : 7
    wire [15:0] lut_7_table = 16'b0001000000000000;
    wire [3:0] lut_7_select = {
                             in_data[31],
                             in_data[30],
                             in_data[29],
                             in_data[28]};
    
    wire lut_7_out = lut_7_table[lut_7_select];
    
    assign out_data[7] = lut_7_out;
    
    
    
    // LUT : 8
    wire [15:0] lut_8_table = 16'b0000000000100010;
    wire [3:0] lut_8_select = {
                             in_data[35],
                             in_data[34],
                             in_data[33],
                             in_data[32]};
    
    wire lut_8_out = lut_8_table[lut_8_select];
    
    assign out_data[8] = lut_8_out;
    
    
    
    // LUT : 9
    wire [15:0] lut_9_table = 16'b0000000011000000;
    wire [3:0] lut_9_select = {
                             in_data[39],
                             in_data[38],
                             in_data[37],
                             in_data[36]};
    
    wire lut_9_out = lut_9_table[lut_9_select];
    
    assign out_data[9] = lut_9_out;
    
    
    
    // LUT : 10
    wire [15:0] lut_10_table = 16'b0000000101010111;
    wire [3:0] lut_10_select = {
                             in_data[43],
                             in_data[42],
                             in_data[41],
                             in_data[40]};
    
    wire lut_10_out = lut_10_table[lut_10_select];
    
    assign out_data[10] = lut_10_out;
    
    
    
    // LUT : 11
    wire [15:0] lut_11_table = 16'b1110010011001100;
    wire [3:0] lut_11_select = {
                             in_data[47],
                             in_data[46],
                             in_data[45],
                             in_data[44]};
    
    wire lut_11_out = lut_11_table[lut_11_select];
    
    assign out_data[11] = lut_11_out;
    
    
    
    // LUT : 12
    wire [15:0] lut_12_table = 16'b0101000101010000;
    wire [3:0] lut_12_select = {
                             in_data[51],
                             in_data[50],
                             in_data[49],
                             in_data[48]};
    
    wire lut_12_out = lut_12_table[lut_12_select];
    
    assign out_data[12] = lut_12_out;
    
    
    
    // LUT : 13
    wire [15:0] lut_13_table = 16'b1100111011001110;
    wire [3:0] lut_13_select = {
                             in_data[55],
                             in_data[54],
                             in_data[53],
                             in_data[52]};
    
    wire lut_13_out = lut_13_table[lut_13_select];
    
    assign out_data[13] = lut_13_out;
    
    
    
    // LUT : 14
    wire [15:0] lut_14_table = 16'b1111100011111011;
    wire [3:0] lut_14_select = {
                             in_data[59],
                             in_data[58],
                             in_data[57],
                             in_data[56]};
    
    wire lut_14_out = lut_14_table[lut_14_select];
    
    assign out_data[14] = lut_14_out;
    
    
    
    // LUT : 15
    wire [15:0] lut_15_table = 16'b1000111100001011;
    wire [3:0] lut_15_select = {
                             in_data[63],
                             in_data[62],
                             in_data[61],
                             in_data[60]};
    
    wire lut_15_out = lut_15_table[lut_15_select];
    
    assign out_data[15] = lut_15_out;
    
    
    
    // LUT : 16
    wire [15:0] lut_16_table = 16'b0011110100100101;
    wire [3:0] lut_16_select = {
                             in_data[67],
                             in_data[66],
                             in_data[65],
                             in_data[64]};
    
    wire lut_16_out = lut_16_table[lut_16_select];
    
    assign out_data[16] = lut_16_out;
    
    
    
    // LUT : 17
    wire [15:0] lut_17_table = 16'b1010101011101110;
    wire [3:0] lut_17_select = {
                             in_data[71],
                             in_data[70],
                             in_data[69],
                             in_data[68]};
    
    wire lut_17_out = lut_17_table[lut_17_select];
    
    assign out_data[17] = lut_17_out;
    
    
    
    // LUT : 18
    wire [15:0] lut_18_table = 16'b0000111011111100;
    wire [3:0] lut_18_select = {
                             in_data[75],
                             in_data[74],
                             in_data[73],
                             in_data[72]};
    
    wire lut_18_out = lut_18_table[lut_18_select];
    
    assign out_data[18] = lut_18_out;
    
    
    
    // LUT : 19
    wire [15:0] lut_19_table = 16'b1111111111111101;
    wire [3:0] lut_19_select = {
                             in_data[79],
                             in_data[78],
                             in_data[77],
                             in_data[76]};
    
    wire lut_19_out = lut_19_table[lut_19_select];
    
    assign out_data[19] = lut_19_out;
    
    
    
    // LUT : 20
    wire [15:0] lut_20_table = 16'b0000001000001110;
    wire [3:0] lut_20_select = {
                             in_data[83],
                             in_data[82],
                             in_data[81],
                             in_data[80]};
    
    wire lut_20_out = lut_20_table[lut_20_select];
    
    assign out_data[20] = lut_20_out;
    
    
    
    // LUT : 21
    wire [15:0] lut_21_table = 16'b1111111100111111;
    wire [3:0] lut_21_select = {
                             in_data[87],
                             in_data[86],
                             in_data[85],
                             in_data[84]};
    
    wire lut_21_out = lut_21_table[lut_21_select];
    
    assign out_data[21] = lut_21_out;
    
    
    
    // LUT : 22
    wire [15:0] lut_22_table = 16'b1111111110101000;
    wire [3:0] lut_22_select = {
                             in_data[91],
                             in_data[90],
                             in_data[89],
                             in_data[88]};
    
    wire lut_22_out = lut_22_table[lut_22_select];
    
    assign out_data[22] = lut_22_out;
    
    
    
    // LUT : 23
    wire [15:0] lut_23_table = 16'b0000101000101111;
    wire [3:0] lut_23_select = {
                             in_data[95],
                             in_data[94],
                             in_data[93],
                             in_data[92]};
    
    wire lut_23_out = lut_23_table[lut_23_select];
    
    assign out_data[23] = lut_23_out;
    
    
    
    // LUT : 24
    wire [15:0] lut_24_table = 16'b1111010101010000;
    wire [3:0] lut_24_select = {
                             in_data[99],
                             in_data[98],
                             in_data[97],
                             in_data[96]};
    
    wire lut_24_out = lut_24_table[lut_24_select];
    
    assign out_data[24] = lut_24_out;
    
    
    
    // LUT : 25
    wire [15:0] lut_25_table = 16'b0101011101110111;
    wire [3:0] lut_25_select = {
                             in_data[103],
                             in_data[102],
                             in_data[101],
                             in_data[100]};
    
    wire lut_25_out = lut_25_table[lut_25_select];
    
    assign out_data[25] = lut_25_out;
    
    
    
    // LUT : 26
    wire [15:0] lut_26_table = 16'b0000111100000100;
    wire [3:0] lut_26_select = {
                             in_data[107],
                             in_data[106],
                             in_data[105],
                             in_data[104]};
    
    wire lut_26_out = lut_26_table[lut_26_select];
    
    assign out_data[26] = lut_26_out;
    
    
    
    // LUT : 27
    wire [15:0] lut_27_table = 16'b0100000001000000;
    wire [3:0] lut_27_select = {
                             in_data[111],
                             in_data[110],
                             in_data[109],
                             in_data[108]};
    
    wire lut_27_out = lut_27_table[lut_27_select];
    
    assign out_data[27] = lut_27_out;
    
    
    
    // LUT : 28
    wire [15:0] lut_28_table = 16'b1111110000000000;
    wire [3:0] lut_28_select = {
                             in_data[115],
                             in_data[114],
                             in_data[113],
                             in_data[112]};
    
    wire lut_28_out = lut_28_table[lut_28_select];
    
    assign out_data[28] = lut_28_out;
    
    
    
    // LUT : 29
    wire [15:0] lut_29_table = 16'b0111000100010000;
    wire [3:0] lut_29_select = {
                             in_data[119],
                             in_data[118],
                             in_data[117],
                             in_data[116]};
    
    wire lut_29_out = lut_29_table[lut_29_select];
    
    assign out_data[29] = lut_29_out;
    
    
    
    // LUT : 30
    wire [15:0] lut_30_table = 16'b1110111111101111;
    wire [3:0] lut_30_select = {
                             in_data[123],
                             in_data[122],
                             in_data[121],
                             in_data[120]};
    
    wire lut_30_out = lut_30_table[lut_30_select];
    
    assign out_data[30] = lut_30_out;
    
    
    
    // LUT : 31
    wire [15:0] lut_31_table = 16'b1100110011011111;
    wire [3:0] lut_31_select = {
                             in_data[127],
                             in_data[126],
                             in_data[125],
                             in_data[124]};
    
    wire lut_31_out = lut_31_table[lut_31_select];
    
    assign out_data[31] = lut_31_out;
    
    
    
    // LUT : 32
    wire [15:0] lut_32_table = 16'b0100010001000000;
    wire [3:0] lut_32_select = {
                             in_data[131],
                             in_data[130],
                             in_data[129],
                             in_data[128]};
    
    wire lut_32_out = lut_32_table[lut_32_select];
    
    assign out_data[32] = lut_32_out;
    
    
    
    // LUT : 33
    wire [15:0] lut_33_table = 16'b0000000010001010;
    wire [3:0] lut_33_select = {
                             in_data[135],
                             in_data[134],
                             in_data[133],
                             in_data[132]};
    
    wire lut_33_out = lut_33_table[lut_33_select];
    
    assign out_data[33] = lut_33_out;
    
    
    
    // LUT : 34
    wire [15:0] lut_34_table = 16'b0100111111011111;
    wire [3:0] lut_34_select = {
                             in_data[139],
                             in_data[138],
                             in_data[137],
                             in_data[136]};
    
    wire lut_34_out = lut_34_table[lut_34_select];
    
    assign out_data[34] = lut_34_out;
    
    
    
    // LUT : 35
    wire [15:0] lut_35_table = 16'b0101110101001111;
    wire [3:0] lut_35_select = {
                             in_data[143],
                             in_data[142],
                             in_data[141],
                             in_data[140]};
    
    wire lut_35_out = lut_35_table[lut_35_select];
    
    assign out_data[35] = lut_35_out;
    
    
    
    // LUT : 36
    wire [15:0] lut_36_table = 16'b0011001000000000;
    wire [3:0] lut_36_select = {
                             in_data[147],
                             in_data[146],
                             in_data[145],
                             in_data[144]};
    
    wire lut_36_out = lut_36_table[lut_36_select];
    
    assign out_data[36] = lut_36_out;
    
    
    
    // LUT : 37
    wire [15:0] lut_37_table = 16'b0000001000100000;
    wire [3:0] lut_37_select = {
                             in_data[151],
                             in_data[150],
                             in_data[149],
                             in_data[148]};
    
    wire lut_37_out = lut_37_table[lut_37_select];
    
    assign out_data[37] = lut_37_out;
    
    
    
    // LUT : 38
    wire [15:0] lut_38_table = 16'b0001011101111111;
    wire [3:0] lut_38_select = {
                             in_data[155],
                             in_data[154],
                             in_data[153],
                             in_data[152]};
    
    wire lut_38_out = lut_38_table[lut_38_select];
    
    assign out_data[38] = lut_38_out;
    
    
    
    // LUT : 39
    wire [15:0] lut_39_table = 16'b1100100011101000;
    wire [3:0] lut_39_select = {
                             in_data[159],
                             in_data[158],
                             in_data[157],
                             in_data[156]};
    
    wire lut_39_out = lut_39_table[lut_39_select];
    
    assign out_data[39] = lut_39_out;
    
    
    
    // LUT : 40
    wire [15:0] lut_40_table = 16'b1010111011111111;
    wire [3:0] lut_40_select = {
                             in_data[163],
                             in_data[162],
                             in_data[161],
                             in_data[160]};
    
    wire lut_40_out = lut_40_table[lut_40_select];
    
    assign out_data[40] = lut_40_out;
    
    
    
    // LUT : 41
    wire [15:0] lut_41_table = 16'b0011011101110111;
    wire [3:0] lut_41_select = {
                             in_data[167],
                             in_data[166],
                             in_data[165],
                             in_data[164]};
    
    wire lut_41_out = lut_41_table[lut_41_select];
    
    assign out_data[41] = lut_41_out;
    
    
    
    // LUT : 42
    wire [15:0] lut_42_table = 16'b1111110011111100;
    wire [3:0] lut_42_select = {
                             in_data[171],
                             in_data[170],
                             in_data[169],
                             in_data[168]};
    
    wire lut_42_out = lut_42_table[lut_42_select];
    
    assign out_data[42] = lut_42_out;
    
    
    
    // LUT : 43
    wire [15:0] lut_43_table = 16'b1111111111111011;
    wire [3:0] lut_43_select = {
                             in_data[175],
                             in_data[174],
                             in_data[173],
                             in_data[172]};
    
    wire lut_43_out = lut_43_table[lut_43_select];
    
    assign out_data[43] = lut_43_out;
    
    
    
    // LUT : 44
    wire [15:0] lut_44_table = 16'b1100000000000001;
    wire [3:0] lut_44_select = {
                             in_data[179],
                             in_data[178],
                             in_data[177],
                             in_data[176]};
    
    wire lut_44_out = lut_44_table[lut_44_select];
    
    assign out_data[44] = lut_44_out;
    
    
    
    // LUT : 45
    wire [15:0] lut_45_table = 16'b1101111101010101;
    wire [3:0] lut_45_select = {
                             in_data[183],
                             in_data[182],
                             in_data[181],
                             in_data[180]};
    
    wire lut_45_out = lut_45_table[lut_45_select];
    
    assign out_data[45] = lut_45_out;
    
    
    
    // LUT : 46
    wire [15:0] lut_46_table = 16'b0000000000001000;
    wire [3:0] lut_46_select = {
                             in_data[187],
                             in_data[186],
                             in_data[185],
                             in_data[184]};
    
    wire lut_46_out = lut_46_table[lut_46_select];
    
    assign out_data[46] = lut_46_out;
    
    
    
    // LUT : 47
    wire [15:0] lut_47_table = 16'b1111111100000101;
    wire [3:0] lut_47_select = {
                             in_data[191],
                             in_data[190],
                             in_data[189],
                             in_data[188]};
    
    wire lut_47_out = lut_47_table[lut_47_select];
    
    assign out_data[47] = lut_47_out;
    
    
    
    // LUT : 48
    wire [15:0] lut_48_table = 16'b0101011101110111;
    wire [3:0] lut_48_select = {
                             in_data[195],
                             in_data[194],
                             in_data[193],
                             in_data[192]};
    
    wire lut_48_out = lut_48_table[lut_48_select];
    
    assign out_data[48] = lut_48_out;
    
    
    
    // LUT : 49
    wire [15:0] lut_49_table = 16'b0000000011111001;
    wire [3:0] lut_49_select = {
                             in_data[199],
                             in_data[198],
                             in_data[197],
                             in_data[196]};
    
    wire lut_49_out = lut_49_table[lut_49_select];
    
    assign out_data[49] = lut_49_out;
    
    
    
    // LUT : 50
    wire [15:0] lut_50_table = 16'b0000000000100011;
    wire [3:0] lut_50_select = {
                             in_data[203],
                             in_data[202],
                             in_data[201],
                             in_data[200]};
    
    wire lut_50_out = lut_50_table[lut_50_select];
    
    assign out_data[50] = lut_50_out;
    
    
    
    // LUT : 51
    wire [15:0] lut_51_table = 16'b0000111100000010;
    wire [3:0] lut_51_select = {
                             in_data[207],
                             in_data[206],
                             in_data[205],
                             in_data[204]};
    
    wire lut_51_out = lut_51_table[lut_51_select];
    
    assign out_data[51] = lut_51_out;
    
    
    
    // LUT : 52
    wire [15:0] lut_52_table = 16'b1111111111111010;
    wire [3:0] lut_52_select = {
                             in_data[211],
                             in_data[210],
                             in_data[209],
                             in_data[208]};
    
    wire lut_52_out = lut_52_table[lut_52_select];
    
    assign out_data[52] = lut_52_out;
    
    
    
    // LUT : 53
    wire [15:0] lut_53_table = 16'b1111111111111110;
    wire [3:0] lut_53_select = {
                             in_data[215],
                             in_data[214],
                             in_data[213],
                             in_data[212]};
    
    wire lut_53_out = lut_53_table[lut_53_select];
    
    assign out_data[53] = lut_53_out;
    
    
    
    // LUT : 54
    wire [15:0] lut_54_table = 16'b0000000100000000;
    wire [3:0] lut_54_select = {
                             in_data[219],
                             in_data[218],
                             in_data[217],
                             in_data[216]};
    
    wire lut_54_out = lut_54_table[lut_54_select];
    
    assign out_data[54] = lut_54_out;
    
    
    
    // LUT : 55
    wire [15:0] lut_55_table = 16'b1101010011000100;
    wire [3:0] lut_55_select = {
                             in_data[223],
                             in_data[222],
                             in_data[221],
                             in_data[220]};
    
    wire lut_55_out = lut_55_table[lut_55_select];
    
    assign out_data[55] = lut_55_out;
    
    
    
    // LUT : 56
    wire [15:0] lut_56_table = 16'b1111111111101111;
    wire [3:0] lut_56_select = {
                             in_data[227],
                             in_data[226],
                             in_data[225],
                             in_data[224]};
    
    wire lut_56_out = lut_56_table[lut_56_select];
    
    assign out_data[56] = lut_56_out;
    
    
    
    // LUT : 57
    wire [15:0] lut_57_table = 16'b0000000010000000;
    wire [3:0] lut_57_select = {
                             in_data[231],
                             in_data[230],
                             in_data[229],
                             in_data[228]};
    
    wire lut_57_out = lut_57_table[lut_57_select];
    
    assign out_data[57] = lut_57_out;
    
    
    
    // LUT : 58
    wire [15:0] lut_58_table = 16'b0010011000100000;
    wire [3:0] lut_58_select = {
                             in_data[235],
                             in_data[234],
                             in_data[233],
                             in_data[232]};
    
    wire lut_58_out = lut_58_table[lut_58_select];
    
    assign out_data[58] = lut_58_out;
    
    
    
    // LUT : 59
    wire [15:0] lut_59_table = 16'b1101110111111111;
    wire [3:0] lut_59_select = {
                             in_data[239],
                             in_data[238],
                             in_data[237],
                             in_data[236]};
    
    wire lut_59_out = lut_59_table[lut_59_select];
    
    assign out_data[59] = lut_59_out;
    
    
    
    // LUT : 60
    wire [15:0] lut_60_table = 16'b0001001100101011;
    wire [3:0] lut_60_select = {
                             in_data[243],
                             in_data[242],
                             in_data[241],
                             in_data[240]};
    
    wire lut_60_out = lut_60_table[lut_60_select];
    
    assign out_data[60] = lut_60_out;
    
    
    
    // LUT : 61
    wire [15:0] lut_61_table = 16'b1111111011110000;
    wire [3:0] lut_61_select = {
                             in_data[247],
                             in_data[246],
                             in_data[245],
                             in_data[244]};
    
    wire lut_61_out = lut_61_table[lut_61_select];
    
    assign out_data[61] = lut_61_out;
    
    
    
    // LUT : 62
    wire [15:0] lut_62_table = 16'b1111111101001111;
    wire [3:0] lut_62_select = {
                             in_data[251],
                             in_data[250],
                             in_data[249],
                             in_data[248]};
    
    wire lut_62_out = lut_62_table[lut_62_select];
    
    assign out_data[62] = lut_62_out;
    
    
    
    // LUT : 63
    wire [15:0] lut_63_table = 16'b0000000011110101;
    wire [3:0] lut_63_select = {
                             in_data[255],
                             in_data[254],
                             in_data[253],
                             in_data[252]};
    
    wire lut_63_out = lut_63_table[lut_63_select];
    
    assign out_data[63] = lut_63_out;
    
    
endmodule



module MnistLut4Simple_sub2
        #(
            parameter INIT_REG = 1'bx,
            parameter DEVICE   = "RTL"
        )
        (
            input  wire         reset,
            input  wire         clk,
            input  wire         cke,
            
            input  wire [63:0]  in_data,
            output wire [255:0]  out_data
        );
    
    
    // LUT : 0
    wire [15:0] lut_0_table = 16'b0100000001110010;
    wire [3:0] lut_0_select = {
                             in_data[32],
                             in_data[27],
                             in_data[17],
                             in_data[8]};
    
    wire lut_0_out = lut_0_table[lut_0_select];
    
    assign out_data[0] = lut_0_out;
    
    
    
    // LUT : 1
    wire [15:0] lut_1_table = 16'b0000000011111111;
    wire [3:0] lut_1_select = {
                             in_data[25],
                             in_data[51],
                             in_data[33],
                             in_data[52]};
    
    wire lut_1_out = lut_1_table[lut_1_select];
    
    assign out_data[1] = lut_1_out;
    
    
    
    // LUT : 2
    wire [15:0] lut_2_table = 16'b0000111100000000;
    wire [3:0] lut_2_select = {
                             in_data[20],
                             in_data[53],
                             in_data[14],
                             in_data[26]};
    
    wire lut_2_out = lut_2_table[lut_2_select];
    
    assign out_data[2] = lut_2_out;
    
    
    
    // LUT : 3
    wire [15:0] lut_3_table = 16'b1111101010101000;
    wire [3:0] lut_3_select = {
                             in_data[47],
                             in_data[10],
                             in_data[3],
                             in_data[24]};
    
    wire lut_3_out = lut_3_table[lut_3_select];
    
    assign out_data[3] = lut_3_out;
    
    
    
    // LUT : 4
    wire [15:0] lut_4_table = 16'b1111000010100000;
    wire [3:0] lut_4_select = {
                             in_data[44],
                             in_data[19],
                             in_data[57],
                             in_data[63]};
    
    wire lut_4_out = lut_4_table[lut_4_select];
    
    assign out_data[4] = lut_4_out;
    
    
    
    // LUT : 5
    wire [15:0] lut_5_table = 16'b1111000000110000;
    wire [3:0] lut_5_select = {
                             in_data[62],
                             in_data[21],
                             in_data[58],
                             in_data[22]};
    
    wire lut_5_out = lut_5_table[lut_5_select];
    
    assign out_data[5] = lut_5_out;
    
    
    
    // LUT : 6
    wire [15:0] lut_6_table = 16'b0011101100101011;
    wire [3:0] lut_6_select = {
                             in_data[48],
                             in_data[9],
                             in_data[7],
                             in_data[15]};
    
    wire lut_6_out = lut_6_table[lut_6_select];
    
    assign out_data[6] = lut_6_out;
    
    
    
    // LUT : 7
    wire [15:0] lut_7_table = 16'b1111000111110001;
    wire [3:0] lut_7_select = {
                             in_data[2],
                             in_data[41],
                             in_data[45],
                             in_data[31]};
    
    wire lut_7_out = lut_7_table[lut_7_select];
    
    assign out_data[7] = lut_7_out;
    
    
    
    // LUT : 8
    wire [15:0] lut_8_table = 16'b0000010100000100;
    wire [3:0] lut_8_select = {
                             in_data[0],
                             in_data[28],
                             in_data[30],
                             in_data[34]};
    
    wire lut_8_out = lut_8_table[lut_8_select];
    
    assign out_data[8] = lut_8_out;
    
    
    
    // LUT : 9
    wire [15:0] lut_9_table = 16'b1010000000001111;
    wire [3:0] lut_9_select = {
                             in_data[35],
                             in_data[40],
                             in_data[1],
                             in_data[60]};
    
    wire lut_9_out = lut_9_table[lut_9_select];
    
    assign out_data[9] = lut_9_out;
    
    
    
    // LUT : 10
    wire [15:0] lut_10_table = 16'b0000000000001000;
    wire [3:0] lut_10_select = {
                             in_data[6],
                             in_data[4],
                             in_data[18],
                             in_data[54]};
    
    wire lut_10_out = lut_10_table[lut_10_select];
    
    assign out_data[10] = lut_10_out;
    
    
    
    // LUT : 11
    wire [15:0] lut_11_table = 16'b0100111000000000;
    wire [3:0] lut_11_select = {
                             in_data[46],
                             in_data[38],
                             in_data[61],
                             in_data[42]};
    
    wire lut_11_out = lut_11_table[lut_11_select];
    
    assign out_data[11] = lut_11_out;
    
    
    
    // LUT : 12
    wire [15:0] lut_12_table = 16'b1111011100110001;
    wire [3:0] lut_12_select = {
                             in_data[39],
                             in_data[59],
                             in_data[11],
                             in_data[23]};
    
    wire lut_12_out = lut_12_table[lut_12_select];
    
    assign out_data[12] = lut_12_out;
    
    
    
    // LUT : 13
    wire [15:0] lut_13_table = 16'b0001000011101100;
    wire [3:0] lut_13_select = {
                             in_data[56],
                             in_data[5],
                             in_data[13],
                             in_data[29]};
    
    wire lut_13_out = lut_13_table[lut_13_select];
    
    assign out_data[13] = lut_13_out;
    
    
    
    // LUT : 14
    wire [15:0] lut_14_table = 16'b0111111101011111;
    wire [3:0] lut_14_select = {
                             in_data[43],
                             in_data[12],
                             in_data[49],
                             in_data[55]};
    
    wire lut_14_out = lut_14_table[lut_14_select];
    
    assign out_data[14] = lut_14_out;
    
    
    
    // LUT : 15
    wire [15:0] lut_15_table = 16'b0000000011111111;
    wire [3:0] lut_15_select = {
                             in_data[16],
                             in_data[37],
                             in_data[36],
                             in_data[50]};
    
    wire lut_15_out = lut_15_table[lut_15_select];
    
    assign out_data[15] = lut_15_out;
    
    
    
    // LUT : 16
    wire [15:0] lut_16_table = 16'b1111001111110111;
    wire [3:0] lut_16_select = {
                             in_data[11],
                             in_data[6],
                             in_data[58],
                             in_data[9]};
    
    wire lut_16_out = lut_16_table[lut_16_select];
    
    assign out_data[16] = lut_16_out;
    
    
    
    // LUT : 17
    wire [15:0] lut_17_table = 16'b1010101110101010;
    wire [3:0] lut_17_select = {
                             in_data[28],
                             in_data[27],
                             in_data[51],
                             in_data[16]};
    
    wire lut_17_out = lut_17_table[lut_17_select];
    
    assign out_data[17] = lut_17_out;
    
    
    
    // LUT : 18
    wire [15:0] lut_18_table = 16'b0100011111000000;
    wire [3:0] lut_18_select = {
                             in_data[25],
                             in_data[55],
                             in_data[10],
                             in_data[61]};
    
    wire lut_18_out = lut_18_table[lut_18_select];
    
    assign out_data[18] = lut_18_out;
    
    
    
    // LUT : 19
    wire [15:0] lut_19_table = 16'b0000101000001000;
    wire [3:0] lut_19_select = {
                             in_data[60],
                             in_data[24],
                             in_data[5],
                             in_data[45]};
    
    wire lut_19_out = lut_19_table[lut_19_select];
    
    assign out_data[19] = lut_19_out;
    
    
    
    // LUT : 20
    wire [15:0] lut_20_table = 16'b1101000011011000;
    wire [3:0] lut_20_select = {
                             in_data[2],
                             in_data[22],
                             in_data[59],
                             in_data[43]};
    
    wire lut_20_out = lut_20_table[lut_20_select];
    
    assign out_data[20] = lut_20_out;
    
    
    
    // LUT : 21
    wire [15:0] lut_21_table = 16'b0001111100001111;
    wire [3:0] lut_21_select = {
                             in_data[3],
                             in_data[32],
                             in_data[1],
                             in_data[20]};
    
    wire lut_21_out = lut_21_table[lut_21_select];
    
    assign out_data[21] = lut_21_out;
    
    
    
    // LUT : 22
    wire [15:0] lut_22_table = 16'b1100110011001000;
    wire [3:0] lut_22_select = {
                             in_data[18],
                             in_data[38],
                             in_data[21],
                             in_data[35]};
    
    wire lut_22_out = lut_22_table[lut_22_select];
    
    assign out_data[22] = lut_22_out;
    
    
    
    // LUT : 23
    wire [15:0] lut_23_table = 16'b1010001011110010;
    wire [3:0] lut_23_select = {
                             in_data[40],
                             in_data[39],
                             in_data[14],
                             in_data[30]};
    
    wire lut_23_out = lut_23_table[lut_23_select];
    
    assign out_data[23] = lut_23_out;
    
    
    
    // LUT : 24
    wire [15:0] lut_24_table = 16'b1111111111110101;
    wire [3:0] lut_24_select = {
                             in_data[52],
                             in_data[47],
                             in_data[50],
                             in_data[33]};
    
    wire lut_24_out = lut_24_table[lut_24_select];
    
    assign out_data[24] = lut_24_out;
    
    
    
    // LUT : 25
    wire [15:0] lut_25_table = 16'b0000001100000011;
    wire [3:0] lut_25_select = {
                             in_data[23],
                             in_data[13],
                             in_data[56],
                             in_data[12]};
    
    wire lut_25_out = lut_25_table[lut_25_select];
    
    assign out_data[25] = lut_25_out;
    
    
    
    // LUT : 26
    wire [15:0] lut_26_table = 16'b1111001111111111;
    wire [3:0] lut_26_select = {
                             in_data[8],
                             in_data[17],
                             in_data[41],
                             in_data[49]};
    
    wire lut_26_out = lut_26_table[lut_26_select];
    
    assign out_data[26] = lut_26_out;
    
    
    
    // LUT : 27
    wire [15:0] lut_27_table = 16'b0100010001000100;
    wire [3:0] lut_27_select = {
                             in_data[54],
                             in_data[44],
                             in_data[29],
                             in_data[4]};
    
    wire lut_27_out = lut_27_table[lut_27_select];
    
    assign out_data[27] = lut_27_out;
    
    
    
    // LUT : 28
    wire [15:0] lut_28_table = 16'b1011101100000000;
    wire [3:0] lut_28_select = {
                             in_data[57],
                             in_data[0],
                             in_data[42],
                             in_data[34]};
    
    wire lut_28_out = lut_28_table[lut_28_select];
    
    assign out_data[28] = lut_28_out;
    
    
    
    // LUT : 29
    wire [15:0] lut_29_table = 16'b0000011000001111;
    wire [3:0] lut_29_select = {
                             in_data[19],
                             in_data[48],
                             in_data[63],
                             in_data[31]};
    
    wire lut_29_out = lut_29_table[lut_29_select];
    
    assign out_data[29] = lut_29_out;
    
    
    
    // LUT : 30
    wire [15:0] lut_30_table = 16'b1010101011101110;
    wire [3:0] lut_30_select = {
                             in_data[62],
                             in_data[37],
                             in_data[7],
                             in_data[53]};
    
    wire lut_30_out = lut_30_table[lut_30_select];
    
    assign out_data[30] = lut_30_out;
    
    
    
    // LUT : 31
    wire [15:0] lut_31_table = 16'b0111011101110111;
    wire [3:0] lut_31_select = {
                             in_data[26],
                             in_data[36],
                             in_data[15],
                             in_data[46]};
    
    wire lut_31_out = lut_31_table[lut_31_select];
    
    assign out_data[31] = lut_31_out;
    
    
    
    // LUT : 32
    wire [15:0] lut_32_table = 16'b1110010001110101;
    wire [3:0] lut_32_select = {
                             in_data[58],
                             in_data[20],
                             in_data[62],
                             in_data[17]};
    
    wire lut_32_out = lut_32_table[lut_32_select];
    
    assign out_data[32] = lut_32_out;
    
    
    
    // LUT : 33
    wire [15:0] lut_33_table = 16'b1111111111101010;
    wire [3:0] lut_33_select = {
                             in_data[9],
                             in_data[47],
                             in_data[53],
                             in_data[59]};
    
    wire lut_33_out = lut_33_table[lut_33_select];
    
    assign out_data[33] = lut_33_out;
    
    
    
    // LUT : 34
    wire [15:0] lut_34_table = 16'b1111101100111011;
    wire [3:0] lut_34_select = {
                             in_data[43],
                             in_data[28],
                             in_data[15],
                             in_data[1]};
    
    wire lut_34_out = lut_34_table[lut_34_select];
    
    assign out_data[34] = lut_34_out;
    
    
    
    // LUT : 35
    wire [15:0] lut_35_table = 16'b1111101011110001;
    wire [3:0] lut_35_select = {
                             in_data[22],
                             in_data[18],
                             in_data[21],
                             in_data[27]};
    
    wire lut_35_out = lut_35_table[lut_35_select];
    
    assign out_data[35] = lut_35_out;
    
    
    
    // LUT : 36
    wire [15:0] lut_36_table = 16'b0101010001010100;
    wire [3:0] lut_36_select = {
                             in_data[49],
                             in_data[35],
                             in_data[63],
                             in_data[26]};
    
    wire lut_36_out = lut_36_table[lut_36_select];
    
    assign out_data[36] = lut_36_out;
    
    
    
    // LUT : 37
    wire [15:0] lut_37_table = 16'b1010110011111101;
    wire [3:0] lut_37_select = {
                             in_data[7],
                             in_data[32],
                             in_data[44],
                             in_data[10]};
    
    wire lut_37_out = lut_37_table[lut_37_select];
    
    assign out_data[37] = lut_37_out;
    
    
    
    // LUT : 38
    wire [15:0] lut_38_table = 16'b1010101000101010;
    wire [3:0] lut_38_select = {
                             in_data[2],
                             in_data[41],
                             in_data[12],
                             in_data[14]};
    
    wire lut_38_out = lut_38_table[lut_38_select];
    
    assign out_data[38] = lut_38_out;
    
    
    
    // LUT : 39
    wire [15:0] lut_39_table = 16'b0100000101000111;
    wire [3:0] lut_39_select = {
                             in_data[48],
                             in_data[30],
                             in_data[55],
                             in_data[61]};
    
    wire lut_39_out = lut_39_table[lut_39_select];
    
    assign out_data[39] = lut_39_out;
    
    
    
    // LUT : 40
    wire [15:0] lut_40_table = 16'b0000010001000100;
    wire [3:0] lut_40_select = {
                             in_data[11],
                             in_data[52],
                             in_data[29],
                             in_data[5]};
    
    wire lut_40_out = lut_40_table[lut_40_select];
    
    assign out_data[40] = lut_40_out;
    
    
    
    // LUT : 41
    wire [15:0] lut_41_table = 16'b1011001111111011;
    wire [3:0] lut_41_select = {
                             in_data[54],
                             in_data[56],
                             in_data[19],
                             in_data[45]};
    
    wire lut_41_out = lut_41_table[lut_41_select];
    
    assign out_data[41] = lut_41_out;
    
    
    
    // LUT : 42
    wire [15:0] lut_42_table = 16'b1101110111111101;
    wire [3:0] lut_42_select = {
                             in_data[42],
                             in_data[38],
                             in_data[34],
                             in_data[36]};
    
    wire lut_42_out = lut_42_table[lut_42_select];
    
    assign out_data[42] = lut_42_out;
    
    
    
    // LUT : 43
    wire [15:0] lut_43_table = 16'b1111101000001010;
    wire [3:0] lut_43_select = {
                             in_data[16],
                             in_data[46],
                             in_data[50],
                             in_data[23]};
    
    wire lut_43_out = lut_43_table[lut_43_select];
    
    assign out_data[43] = lut_43_out;
    
    
    
    // LUT : 44
    wire [15:0] lut_44_table = 16'b0000110000001100;
    wire [3:0] lut_44_select = {
                             in_data[3],
                             in_data[6],
                             in_data[31],
                             in_data[13]};
    
    wire lut_44_out = lut_44_table[lut_44_select];
    
    assign out_data[44] = lut_44_out;
    
    
    
    // LUT : 45
    wire [15:0] lut_45_table = 16'b1111110011111100;
    wire [3:0] lut_45_select = {
                             in_data[8],
                             in_data[4],
                             in_data[39],
                             in_data[57]};
    
    wire lut_45_out = lut_45_table[lut_45_select];
    
    assign out_data[45] = lut_45_out;
    
    
    
    // LUT : 46
    wire [15:0] lut_46_table = 16'b1010101010111011;
    wire [3:0] lut_46_select = {
                             in_data[40],
                             in_data[0],
                             in_data[51],
                             in_data[37]};
    
    wire lut_46_out = lut_46_table[lut_46_select];
    
    assign out_data[46] = lut_46_out;
    
    
    
    // LUT : 47
    wire [15:0] lut_47_table = 16'b1101111100001010;
    wire [3:0] lut_47_select = {
                             in_data[24],
                             in_data[60],
                             in_data[25],
                             in_data[33]};
    
    wire lut_47_out = lut_47_table[lut_47_select];
    
    assign out_data[47] = lut_47_out;
    
    
    
    // LUT : 48
    wire [15:0] lut_48_table = 16'b0101010111001100;
    wire [3:0] lut_48_select = {
                             in_data[18],
                             in_data[31],
                             in_data[6],
                             in_data[24]};
    
    wire lut_48_out = lut_48_table[lut_48_select];
    
    assign out_data[48] = lut_48_out;
    
    
    
    // LUT : 49
    wire [15:0] lut_49_table = 16'b1111111110110000;
    wire [3:0] lut_49_select = {
                             in_data[42],
                             in_data[40],
                             in_data[38],
                             in_data[55]};
    
    wire lut_49_out = lut_49_table[lut_49_select];
    
    assign out_data[49] = lut_49_out;
    
    
    
    // LUT : 50
    wire [15:0] lut_50_table = 16'b1010101011111111;
    wire [3:0] lut_50_select = {
                             in_data[60],
                             in_data[51],
                             in_data[5],
                             in_data[41]};
    
    wire lut_50_out = lut_50_table[lut_50_select];
    
    assign out_data[50] = lut_50_out;
    
    
    
    // LUT : 51
    wire [15:0] lut_51_table = 16'b1100010001010100;
    wire [3:0] lut_51_select = {
                             in_data[33],
                             in_data[15],
                             in_data[36],
                             in_data[14]};
    
    wire lut_51_out = lut_51_table[lut_51_select];
    
    assign out_data[51] = lut_51_out;
    
    
    
    // LUT : 52
    wire [15:0] lut_52_table = 16'b0000001100001111;
    wire [3:0] lut_52_select = {
                             in_data[17],
                             in_data[4],
                             in_data[20],
                             in_data[52]};
    
    wire lut_52_out = lut_52_table[lut_52_select];
    
    assign out_data[52] = lut_52_out;
    
    
    
    // LUT : 53
    wire [15:0] lut_53_table = 16'b1111111100110000;
    wire [3:0] lut_53_select = {
                             in_data[28],
                             in_data[58],
                             in_data[32],
                             in_data[63]};
    
    wire lut_53_out = lut_53_table[lut_53_select];
    
    assign out_data[53] = lut_53_out;
    
    
    
    // LUT : 54
    wire [15:0] lut_54_table = 16'b0010000010110000;
    wire [3:0] lut_54_select = {
                             in_data[29],
                             in_data[21],
                             in_data[25],
                             in_data[46]};
    
    wire lut_54_out = lut_54_table[lut_54_select];
    
    assign out_data[54] = lut_54_out;
    
    
    
    // LUT : 55
    wire [15:0] lut_55_table = 16'b1100111110001111;
    wire [3:0] lut_55_select = {
                             in_data[47],
                             in_data[23],
                             in_data[10],
                             in_data[59]};
    
    wire lut_55_out = lut_55_table[lut_55_select];
    
    assign out_data[55] = lut_55_out;
    
    
    
    // LUT : 56
    wire [15:0] lut_56_table = 16'b1010111100000010;
    wire [3:0] lut_56_select = {
                             in_data[37],
                             in_data[34],
                             in_data[1],
                             in_data[43]};
    
    wire lut_56_out = lut_56_table[lut_56_select];
    
    assign out_data[56] = lut_56_out;
    
    
    
    // LUT : 57
    wire [15:0] lut_57_table = 16'b0000110000011101;
    wire [3:0] lut_57_select = {
                             in_data[45],
                             in_data[26],
                             in_data[19],
                             in_data[57]};
    
    wire lut_57_out = lut_57_table[lut_57_select];
    
    assign out_data[57] = lut_57_out;
    
    
    
    // LUT : 58
    wire [15:0] lut_58_table = 16'b0011000000110000;
    wire [3:0] lut_58_select = {
                             in_data[3],
                             in_data[39],
                             in_data[48],
                             in_data[62]};
    
    wire lut_58_out = lut_58_table[lut_58_select];
    
    assign out_data[58] = lut_58_out;
    
    
    
    // LUT : 59
    wire [15:0] lut_59_table = 16'b1111010111110101;
    wire [3:0] lut_59_select = {
                             in_data[49],
                             in_data[12],
                             in_data[13],
                             in_data[54]};
    
    wire lut_59_out = lut_59_table[lut_59_select];
    
    assign out_data[59] = lut_59_out;
    
    
    
    // LUT : 60
    wire [15:0] lut_60_table = 16'b1000111100000101;
    wire [3:0] lut_60_select = {
                             in_data[35],
                             in_data[16],
                             in_data[0],
                             in_data[7]};
    
    wire lut_60_out = lut_60_table[lut_60_select];
    
    assign out_data[60] = lut_60_out;
    
    
    
    // LUT : 61
    wire [15:0] lut_61_table = 16'b0001000100010001;
    wire [3:0] lut_61_select = {
                             in_data[9],
                             in_data[50],
                             in_data[44],
                             in_data[53]};
    
    wire lut_61_out = lut_61_table[lut_61_select];
    
    assign out_data[61] = lut_61_out;
    
    
    
    // LUT : 62
    wire [15:0] lut_62_table = 16'b0001000100010001;
    wire [3:0] lut_62_select = {
                             in_data[8],
                             in_data[2],
                             in_data[56],
                             in_data[22]};
    
    wire lut_62_out = lut_62_table[lut_62_select];
    
    assign out_data[62] = lut_62_out;
    
    
    
    // LUT : 63
    wire [15:0] lut_63_table = 16'b1110000011100100;
    wire [3:0] lut_63_select = {
                             in_data[11],
                             in_data[30],
                             in_data[27],
                             in_data[61]};
    
    wire lut_63_out = lut_63_table[lut_63_select];
    
    assign out_data[63] = lut_63_out;
    
    
    
    // LUT : 64
    wire [15:0] lut_64_table = 16'b0000001100100011;
    wire [3:0] lut_64_select = {
                             in_data[50],
                             in_data[47],
                             in_data[13],
                             in_data[61]};
    
    wire lut_64_out = lut_64_table[lut_64_select];
    
    assign out_data[64] = lut_64_out;
    
    
    
    // LUT : 65
    wire [15:0] lut_65_table = 16'b0011111100000000;
    wire [3:0] lut_65_select = {
                             in_data[25],
                             in_data[63],
                             in_data[52],
                             in_data[9]};
    
    wire lut_65_out = lut_65_table[lut_65_select];
    
    assign out_data[65] = lut_65_out;
    
    
    
    // LUT : 66
    wire [15:0] lut_66_table = 16'b1111111100111111;
    wire [3:0] lut_66_select = {
                             in_data[31],
                             in_data[24],
                             in_data[29],
                             in_data[62]};
    
    wire lut_66_out = lut_66_table[lut_66_select];
    
    assign out_data[66] = lut_66_out;
    
    
    
    // LUT : 67
    wire [15:0] lut_67_table = 16'b1100110011111111;
    wire [3:0] lut_67_select = {
                             in_data[40],
                             in_data[0],
                             in_data[37],
                             in_data[5]};
    
    wire lut_67_out = lut_67_table[lut_67_select];
    
    assign out_data[67] = lut_67_out;
    
    
    
    // LUT : 68
    wire [15:0] lut_68_table = 16'b1111011111111111;
    wire [3:0] lut_68_select = {
                             in_data[55],
                             in_data[59],
                             in_data[7],
                             in_data[19]};
    
    wire lut_68_out = lut_68_table[lut_68_select];
    
    assign out_data[68] = lut_68_out;
    
    
    
    // LUT : 69
    wire [15:0] lut_69_table = 16'b1111111110001111;
    wire [3:0] lut_69_select = {
                             in_data[4],
                             in_data[22],
                             in_data[10],
                             in_data[56]};
    
    wire lut_69_out = lut_69_table[lut_69_select];
    
    assign out_data[69] = lut_69_out;
    
    
    
    // LUT : 70
    wire [15:0] lut_70_table = 16'b0001000011111111;
    wire [3:0] lut_70_select = {
                             in_data[27],
                             in_data[57],
                             in_data[3],
                             in_data[8]};
    
    wire lut_70_out = lut_70_table[lut_70_select];
    
    assign out_data[70] = lut_70_out;
    
    
    
    // LUT : 71
    wire [15:0] lut_71_table = 16'b1010001000111111;
    wire [3:0] lut_71_select = {
                             in_data[42],
                             in_data[41],
                             in_data[21],
                             in_data[33]};
    
    wire lut_71_out = lut_71_table[lut_71_select];
    
    assign out_data[71] = lut_71_out;
    
    
    
    // LUT : 72
    wire [15:0] lut_72_table = 16'b1100110001000000;
    wire [3:0] lut_72_select = {
                             in_data[45],
                             in_data[51],
                             in_data[20],
                             in_data[43]};
    
    wire lut_72_out = lut_72_table[lut_72_select];
    
    assign out_data[72] = lut_72_out;
    
    
    
    // LUT : 73
    wire [15:0] lut_73_table = 16'b1111010011110000;
    wire [3:0] lut_73_select = {
                             in_data[30],
                             in_data[18],
                             in_data[32],
                             in_data[34]};
    
    wire lut_73_out = lut_73_table[lut_73_select];
    
    assign out_data[73] = lut_73_out;
    
    
    
    // LUT : 74
    wire [15:0] lut_74_table = 16'b0011001110001000;
    wire [3:0] lut_74_select = {
                             in_data[26],
                             in_data[35],
                             in_data[44],
                             in_data[15]};
    
    wire lut_74_out = lut_74_table[lut_74_select];
    
    assign out_data[74] = lut_74_out;
    
    
    
    // LUT : 75
    wire [15:0] lut_75_table = 16'b1111010111110101;
    wire [3:0] lut_75_select = {
                             in_data[1],
                             in_data[53],
                             in_data[58],
                             in_data[17]};
    
    wire lut_75_out = lut_75_table[lut_75_select];
    
    assign out_data[75] = lut_75_out;
    
    
    
    // LUT : 76
    wire [15:0] lut_76_table = 16'b0000101000001111;
    wire [3:0] lut_76_select = {
                             in_data[38],
                             in_data[16],
                             in_data[49],
                             in_data[11]};
    
    wire lut_76_out = lut_76_table[lut_76_select];
    
    assign out_data[76] = lut_76_out;
    
    
    
    // LUT : 77
    wire [15:0] lut_77_table = 16'b0000000000000010;
    wire [3:0] lut_77_select = {
                             in_data[39],
                             in_data[28],
                             in_data[6],
                             in_data[46]};
    
    wire lut_77_out = lut_77_table[lut_77_select];
    
    assign out_data[77] = lut_77_out;
    
    
    
    // LUT : 78
    wire [15:0] lut_78_table = 16'b0001000110100000;
    wire [3:0] lut_78_select = {
                             in_data[14],
                             in_data[60],
                             in_data[23],
                             in_data[36]};
    
    wire lut_78_out = lut_78_table[lut_78_select];
    
    assign out_data[78] = lut_78_out;
    
    
    
    // LUT : 79
    wire [15:0] lut_79_table = 16'b1111111110111011;
    wire [3:0] lut_79_select = {
                             in_data[48],
                             in_data[2],
                             in_data[54],
                             in_data[12]};
    
    wire lut_79_out = lut_79_table[lut_79_select];
    
    assign out_data[79] = lut_79_out;
    
    
    
    // LUT : 80
    wire [15:0] lut_80_table = 16'b0111010111111111;
    wire [3:0] lut_80_select = {
                             in_data[13],
                             in_data[59],
                             in_data[40],
                             in_data[8]};
    
    wire lut_80_out = lut_80_table[lut_80_select];
    
    assign out_data[80] = lut_80_out;
    
    
    
    // LUT : 81
    wire [15:0] lut_81_table = 16'b0011000110110101;
    wire [3:0] lut_81_select = {
                             in_data[61],
                             in_data[38],
                             in_data[39],
                             in_data[33]};
    
    wire lut_81_out = lut_81_table[lut_81_select];
    
    assign out_data[81] = lut_81_out;
    
    
    
    // LUT : 82
    wire [15:0] lut_82_table = 16'b0000000011001100;
    wire [3:0] lut_82_select = {
                             in_data[58],
                             in_data[27],
                             in_data[60],
                             in_data[43]};
    
    wire lut_82_out = lut_82_table[lut_82_select];
    
    assign out_data[82] = lut_82_out;
    
    
    
    // LUT : 83
    wire [15:0] lut_83_table = 16'b0000111100001110;
    wire [3:0] lut_83_select = {
                             in_data[45],
                             in_data[25],
                             in_data[57],
                             in_data[36]};
    
    wire lut_83_out = lut_83_table[lut_83_select];
    
    assign out_data[83] = lut_83_out;
    
    
    
    // LUT : 84
    wire [15:0] lut_84_table = 16'b1010010011100000;
    wire [3:0] lut_84_select = {
                             in_data[41],
                             in_data[44],
                             in_data[14],
                             in_data[28]};
    
    wire lut_84_out = lut_84_table[lut_84_select];
    
    assign out_data[84] = lut_84_out;
    
    
    
    // LUT : 85
    wire [15:0] lut_85_table = 16'b1111111100001111;
    wire [3:0] lut_85_select = {
                             in_data[4],
                             in_data[26],
                             in_data[6],
                             in_data[32]};
    
    wire lut_85_out = lut_85_table[lut_85_select];
    
    assign out_data[85] = lut_85_out;
    
    
    
    // LUT : 86
    wire [15:0] lut_86_table = 16'b0000111100001111;
    wire [3:0] lut_86_select = {
                             in_data[51],
                             in_data[35],
                             in_data[50],
                             in_data[1]};
    
    wire lut_86_out = lut_86_table[lut_86_select];
    
    assign out_data[86] = lut_86_out;
    
    
    
    // LUT : 87
    wire [15:0] lut_87_table = 16'b0001010100000000;
    wire [3:0] lut_87_select = {
                             in_data[23],
                             in_data[16],
                             in_data[48],
                             in_data[30]};
    
    wire lut_87_out = lut_87_table[lut_87_select];
    
    assign out_data[87] = lut_87_out;
    
    
    
    // LUT : 88
    wire [15:0] lut_88_table = 16'b1111001011111111;
    wire [3:0] lut_88_select = {
                             in_data[7],
                             in_data[47],
                             in_data[5],
                             in_data[18]};
    
    wire lut_88_out = lut_88_table[lut_88_select];
    
    assign out_data[88] = lut_88_out;
    
    
    
    // LUT : 89
    wire [15:0] lut_89_table = 16'b1110111011001100;
    wire [3:0] lut_89_select = {
                             in_data[56],
                             in_data[49],
                             in_data[22],
                             in_data[24]};
    
    wire lut_89_out = lut_89_table[lut_89_select];
    
    assign out_data[89] = lut_89_out;
    
    
    
    // LUT : 90
    wire [15:0] lut_90_table = 16'b1110101010101010;
    wire [3:0] lut_90_select = {
                             in_data[29],
                             in_data[10],
                             in_data[37],
                             in_data[12]};
    
    wire lut_90_out = lut_90_table[lut_90_select];
    
    assign out_data[90] = lut_90_out;
    
    
    
    // LUT : 91
    wire [15:0] lut_91_table = 16'b1110111011001100;
    wire [3:0] lut_91_select = {
                             in_data[54],
                             in_data[52],
                             in_data[19],
                             in_data[53]};
    
    wire lut_91_out = lut_91_table[lut_91_select];
    
    assign out_data[91] = lut_91_out;
    
    
    
    // LUT : 92
    wire [15:0] lut_92_table = 16'b0010001000100010;
    wire [3:0] lut_92_select = {
                             in_data[62],
                             in_data[46],
                             in_data[9],
                             in_data[15]};
    
    wire lut_92_out = lut_92_table[lut_92_select];
    
    assign out_data[92] = lut_92_out;
    
    
    
    // LUT : 93
    wire [15:0] lut_93_table = 16'b0000111100101111;
    wire [3:0] lut_93_select = {
                             in_data[20],
                             in_data[21],
                             in_data[55],
                             in_data[17]};
    
    wire lut_93_out = lut_93_table[lut_93_select];
    
    assign out_data[93] = lut_93_out;
    
    
    
    // LUT : 94
    wire [15:0] lut_94_table = 16'b0000000100000111;
    wire [3:0] lut_94_select = {
                             in_data[0],
                             in_data[31],
                             in_data[34],
                             in_data[11]};
    
    wire lut_94_out = lut_94_table[lut_94_select];
    
    assign out_data[94] = lut_94_out;
    
    
    
    // LUT : 95
    wire [15:0] lut_95_table = 16'b0101010101010101;
    wire [3:0] lut_95_select = {
                             in_data[3],
                             in_data[2],
                             in_data[42],
                             in_data[63]};
    
    wire lut_95_out = lut_95_table[lut_95_select];
    
    assign out_data[95] = lut_95_out;
    
    
    
    // LUT : 96
    wire [15:0] lut_96_table = 16'b0000000110000011;
    wire [3:0] lut_96_select = {
                             in_data[29],
                             in_data[53],
                             in_data[27],
                             in_data[24]};
    
    wire lut_96_out = lut_96_table[lut_96_select];
    
    assign out_data[96] = lut_96_out;
    
    
    
    // LUT : 97
    wire [15:0] lut_97_table = 16'b0101010100000101;
    wire [3:0] lut_97_select = {
                             in_data[54],
                             in_data[5],
                             in_data[49],
                             in_data[12]};
    
    wire lut_97_out = lut_97_table[lut_97_select];
    
    assign out_data[97] = lut_97_out;
    
    
    
    // LUT : 98
    wire [15:0] lut_98_table = 16'b1110101110001010;
    wire [3:0] lut_98_select = {
                             in_data[30],
                             in_data[61],
                             in_data[56],
                             in_data[14]};
    
    wire lut_98_out = lut_98_table[lut_98_select];
    
    assign out_data[98] = lut_98_out;
    
    
    
    // LUT : 99
    wire [15:0] lut_99_table = 16'b1111110011110000;
    wire [3:0] lut_99_select = {
                             in_data[18],
                             in_data[31],
                             in_data[33],
                             in_data[2]};
    
    wire lut_99_out = lut_99_table[lut_99_select];
    
    assign out_data[99] = lut_99_out;
    
    
    
    // LUT : 100
    wire [15:0] lut_100_table = 16'b1000100011000000;
    wire [3:0] lut_100_select = {
                             in_data[20],
                             in_data[63],
                             in_data[9],
                             in_data[60]};
    
    wire lut_100_out = lut_100_table[lut_100_select];
    
    assign out_data[100] = lut_100_out;
    
    
    
    // LUT : 101
    wire [15:0] lut_101_table = 16'b1111110011111100;
    wire [3:0] lut_101_select = {
                             in_data[0],
                             in_data[48],
                             in_data[25],
                             in_data[58]};
    
    wire lut_101_out = lut_101_table[lut_101_select];
    
    assign out_data[101] = lut_101_out;
    
    
    
    // LUT : 102
    wire [15:0] lut_102_table = 16'b1111011111110111;
    wire [3:0] lut_102_select = {
                             in_data[57],
                             in_data[35],
                             in_data[7],
                             in_data[39]};
    
    wire lut_102_out = lut_102_table[lut_102_select];
    
    assign out_data[102] = lut_102_out;
    
    
    
    // LUT : 103
    wire [15:0] lut_103_table = 16'b0000000011111101;
    wire [3:0] lut_103_select = {
                             in_data[16],
                             in_data[41],
                             in_data[32],
                             in_data[1]};
    
    wire lut_103_out = lut_103_table[lut_103_select];
    
    assign out_data[103] = lut_103_out;
    
    
    
    // LUT : 104
    wire [15:0] lut_104_table = 16'b0011111100110011;
    wire [3:0] lut_104_select = {
                             in_data[42],
                             in_data[50],
                             in_data[11],
                             in_data[43]};
    
    wire lut_104_out = lut_104_table[lut_104_select];
    
    assign out_data[104] = lut_104_out;
    
    
    
    // LUT : 105
    wire [15:0] lut_105_table = 16'b1111111100000001;
    wire [3:0] lut_105_select = {
                             in_data[44],
                             in_data[13],
                             in_data[26],
                             in_data[28]};
    
    wire lut_105_out = lut_105_table[lut_105_select];
    
    assign out_data[105] = lut_105_out;
    
    
    
    // LUT : 106
    wire [15:0] lut_106_table = 16'b1110101001010000;
    wire [3:0] lut_106_select = {
                             in_data[23],
                             in_data[21],
                             in_data[36],
                             in_data[19]};
    
    wire lut_106_out = lut_106_table[lut_106_select];
    
    assign out_data[106] = lut_106_out;
    
    
    
    // LUT : 107
    wire [15:0] lut_107_table = 16'b1111010000010000;
    wire [3:0] lut_107_select = {
                             in_data[10],
                             in_data[40],
                             in_data[8],
                             in_data[45]};
    
    wire lut_107_out = lut_107_table[lut_107_select];
    
    assign out_data[107] = lut_107_out;
    
    
    
    // LUT : 108
    wire [15:0] lut_108_table = 16'b1110111111101111;
    wire [3:0] lut_108_select = {
                             in_data[52],
                             in_data[15],
                             in_data[34],
                             in_data[51]};
    
    wire lut_108_out = lut_108_table[lut_108_select];
    
    assign out_data[108] = lut_108_out;
    
    
    
    // LUT : 109
    wire [15:0] lut_109_table = 16'b0000000011011000;
    wire [3:0] lut_109_select = {
                             in_data[3],
                             in_data[59],
                             in_data[37],
                             in_data[55]};
    
    wire lut_109_out = lut_109_table[lut_109_select];
    
    assign out_data[109] = lut_109_out;
    
    
    
    // LUT : 110
    wire [15:0] lut_110_table = 16'b0000000010100101;
    wire [3:0] lut_110_select = {
                             in_data[4],
                             in_data[17],
                             in_data[47],
                             in_data[6]};
    
    wire lut_110_out = lut_110_table[lut_110_select];
    
    assign out_data[110] = lut_110_out;
    
    
    
    // LUT : 111
    wire [15:0] lut_111_table = 16'b1111000111110101;
    wire [3:0] lut_111_select = {
                             in_data[38],
                             in_data[22],
                             in_data[62],
                             in_data[46]};
    
    wire lut_111_out = lut_111_table[lut_111_select];
    
    assign out_data[111] = lut_111_out;
    
    
    
    // LUT : 112
    wire [15:0] lut_112_table = 16'b0100110111001100;
    wire [3:0] lut_112_select = {
                             in_data[15],
                             in_data[39],
                             in_data[26],
                             in_data[34]};
    
    wire lut_112_out = lut_112_table[lut_112_select];
    
    assign out_data[112] = lut_112_out;
    
    
    
    // LUT : 113
    wire [15:0] lut_113_table = 16'b0011001100110010;
    wire [3:0] lut_113_select = {
                             in_data[2],
                             in_data[49],
                             in_data[56],
                             in_data[59]};
    
    wire lut_113_out = lut_113_table[lut_113_select];
    
    assign out_data[113] = lut_113_out;
    
    
    
    // LUT : 114
    wire [15:0] lut_114_table = 16'b1111111111111010;
    wire [3:0] lut_114_select = {
                             in_data[42],
                             in_data[38],
                             in_data[24],
                             in_data[31]};
    
    wire lut_114_out = lut_114_table[lut_114_select];
    
    assign out_data[114] = lut_114_out;
    
    
    
    // LUT : 115
    wire [15:0] lut_115_table = 16'b1010000011110000;
    wire [3:0] lut_115_select = {
                             in_data[40],
                             in_data[19],
                             in_data[63],
                             in_data[17]};
    
    wire lut_115_out = lut_115_table[lut_115_select];
    
    assign out_data[115] = lut_115_out;
    
    
    
    // LUT : 116
    wire [15:0] lut_116_table = 16'b1111110000000000;
    wire [3:0] lut_116_select = {
                             in_data[18],
                             in_data[22],
                             in_data[6],
                             in_data[50]};
    
    wire lut_116_out = lut_116_table[lut_116_select];
    
    assign out_data[116] = lut_116_out;
    
    
    
    // LUT : 117
    wire [15:0] lut_117_table = 16'b1111001111111111;
    wire [3:0] lut_117_select = {
                             in_data[32],
                             in_data[53],
                             in_data[54],
                             in_data[1]};
    
    wire lut_117_out = lut_117_table[lut_117_select];
    
    assign out_data[117] = lut_117_out;
    
    
    
    // LUT : 118
    wire [15:0] lut_118_table = 16'b0010101010101010;
    wire [3:0] lut_118_select = {
                             in_data[8],
                             in_data[55],
                             in_data[62],
                             in_data[30]};
    
    wire lut_118_out = lut_118_table[lut_118_select];
    
    assign out_data[118] = lut_118_out;
    
    
    
    // LUT : 119
    wire [15:0] lut_119_table = 16'b0000001111110010;
    wire [3:0] lut_119_select = {
                             in_data[25],
                             in_data[33],
                             in_data[61],
                             in_data[58]};
    
    wire lut_119_out = lut_119_table[lut_119_select];
    
    assign out_data[119] = lut_119_out;
    
    
    
    // LUT : 120
    wire [15:0] lut_120_table = 16'b0000110011001100;
    wire [3:0] lut_120_select = {
                             in_data[37],
                             in_data[52],
                             in_data[28],
                             in_data[36]};
    
    wire lut_120_out = lut_120_table[lut_120_select];
    
    assign out_data[120] = lut_120_out;
    
    
    
    // LUT : 121
    wire [15:0] lut_121_table = 16'b1100000011000000;
    wire [3:0] lut_121_select = {
                             in_data[48],
                             in_data[46],
                             in_data[27],
                             in_data[10]};
    
    wire lut_121_out = lut_121_table[lut_121_select];
    
    assign out_data[121] = lut_121_out;
    
    
    
    // LUT : 122
    wire [15:0] lut_122_table = 16'b0100000001000101;
    wire [3:0] lut_122_select = {
                             in_data[45],
                             in_data[9],
                             in_data[57],
                             in_data[4]};
    
    wire lut_122_out = lut_122_table[lut_122_select];
    
    assign out_data[122] = lut_122_out;
    
    
    
    // LUT : 123
    wire [15:0] lut_123_table = 16'b0011000000110000;
    wire [3:0] lut_123_select = {
                             in_data[0],
                             in_data[16],
                             in_data[44],
                             in_data[5]};
    
    wire lut_123_out = lut_123_table[lut_123_select];
    
    assign out_data[123] = lut_123_out;
    
    
    
    // LUT : 124
    wire [15:0] lut_124_table = 16'b0101110100001111;
    wire [3:0] lut_124_select = {
                             in_data[35],
                             in_data[43],
                             in_data[3],
                             in_data[7]};
    
    wire lut_124_out = lut_124_table[lut_124_select];
    
    assign out_data[124] = lut_124_out;
    
    
    
    // LUT : 125
    wire [15:0] lut_125_table = 16'b1111000000000000;
    wire [3:0] lut_125_select = {
                             in_data[20],
                             in_data[21],
                             in_data[12],
                             in_data[14]};
    
    wire lut_125_out = lut_125_table[lut_125_select];
    
    assign out_data[125] = lut_125_out;
    
    
    
    // LUT : 126
    wire [15:0] lut_126_table = 16'b0011001101111111;
    wire [3:0] lut_126_select = {
                             in_data[41],
                             in_data[13],
                             in_data[23],
                             in_data[60]};
    
    wire lut_126_out = lut_126_table[lut_126_select];
    
    assign out_data[126] = lut_126_out;
    
    
    
    // LUT : 127
    wire [15:0] lut_127_table = 16'b0000000011110111;
    wire [3:0] lut_127_select = {
                             in_data[29],
                             in_data[47],
                             in_data[51],
                             in_data[11]};
    
    wire lut_127_out = lut_127_table[lut_127_select];
    
    assign out_data[127] = lut_127_out;
    
    
    
    // LUT : 128
    wire [15:0] lut_128_table = 16'b0010101000111010;
    wire [3:0] lut_128_select = {
                             in_data[47],
                             in_data[12],
                             in_data[52],
                             in_data[26]};
    
    wire lut_128_out = lut_128_table[lut_128_select];
    
    assign out_data[128] = lut_128_out;
    
    
    
    // LUT : 129
    wire [15:0] lut_129_table = 16'b0111001111110011;
    wire [3:0] lut_129_select = {
                             in_data[54],
                             in_data[2],
                             in_data[7],
                             in_data[15]};
    
    wire lut_129_out = lut_129_table[lut_129_select];
    
    assign out_data[129] = lut_129_out;
    
    
    
    // LUT : 130
    wire [15:0] lut_130_table = 16'b0000101000001111;
    wire [3:0] lut_130_select = {
                             in_data[24],
                             in_data[27],
                             in_data[0],
                             in_data[40]};
    
    wire lut_130_out = lut_130_table[lut_130_select];
    
    assign out_data[130] = lut_130_out;
    
    
    
    // LUT : 131
    wire [15:0] lut_131_table = 16'b1111000000110000;
    wire [3:0] lut_131_select = {
                             in_data[25],
                             in_data[44],
                             in_data[56],
                             in_data[53]};
    
    wire lut_131_out = lut_131_table[lut_131_select];
    
    assign out_data[131] = lut_131_out;
    
    
    
    // LUT : 132
    wire [15:0] lut_132_table = 16'b1011111100110111;
    wire [3:0] lut_132_select = {
                             in_data[6],
                             in_data[57],
                             in_data[10],
                             in_data[8]};
    
    wire lut_132_out = lut_132_table[lut_132_select];
    
    assign out_data[132] = lut_132_out;
    
    
    
    // LUT : 133
    wire [15:0] lut_133_table = 16'b0000110011111100;
    wire [3:0] lut_133_select = {
                             in_data[13],
                             in_data[36],
                             in_data[43],
                             in_data[33]};
    
    wire lut_133_out = lut_133_table[lut_133_select];
    
    assign out_data[133] = lut_133_out;
    
    
    
    // LUT : 134
    wire [15:0] lut_134_table = 16'b1000000010000000;
    wire [3:0] lut_134_select = {
                             in_data[63],
                             in_data[55],
                             in_data[46],
                             in_data[9]};
    
    wire lut_134_out = lut_134_table[lut_134_select];
    
    assign out_data[134] = lut_134_out;
    
    
    
    // LUT : 135
    wire [15:0] lut_135_table = 16'b1100100011000000;
    wire [3:0] lut_135_select = {
                             in_data[4],
                             in_data[14],
                             in_data[21],
                             in_data[39]};
    
    wire lut_135_out = lut_135_table[lut_135_select];
    
    assign out_data[135] = lut_135_out;
    
    
    
    // LUT : 136
    wire [15:0] lut_136_table = 16'b1111101011111110;
    wire [3:0] lut_136_select = {
                             in_data[18],
                             in_data[5],
                             in_data[11],
                             in_data[59]};
    
    wire lut_136_out = lut_136_table[lut_136_select];
    
    assign out_data[136] = lut_136_out;
    
    
    
    // LUT : 137
    wire [15:0] lut_137_table = 16'b0001111100011111;
    wire [3:0] lut_137_select = {
                             in_data[60],
                             in_data[45],
                             in_data[34],
                             in_data[32]};
    
    wire lut_137_out = lut_137_table[lut_137_select];
    
    assign out_data[137] = lut_137_out;
    
    
    
    // LUT : 138
    wire [15:0] lut_138_table = 16'b1101110111011111;
    wire [3:0] lut_138_select = {
                             in_data[17],
                             in_data[41],
                             in_data[31],
                             in_data[22]};
    
    wire lut_138_out = lut_138_table[lut_138_select];
    
    assign out_data[138] = lut_138_out;
    
    
    
    // LUT : 139
    wire [15:0] lut_139_table = 16'b0010111100101111;
    wire [3:0] lut_139_select = {
                             in_data[3],
                             in_data[58],
                             in_data[16],
                             in_data[51]};
    
    wire lut_139_out = lut_139_table[lut_139_select];
    
    assign out_data[139] = lut_139_out;
    
    
    
    // LUT : 140
    wire [15:0] lut_140_table = 16'b1111010011111100;
    wire [3:0] lut_140_select = {
                             in_data[1],
                             in_data[35],
                             in_data[23],
                             in_data[28]};
    
    wire lut_140_out = lut_140_table[lut_140_select];
    
    assign out_data[140] = lut_140_out;
    
    
    
    // LUT : 141
    wire [15:0] lut_141_table = 16'b1100000011000000;
    wire [3:0] lut_141_select = {
                             in_data[38],
                             in_data[37],
                             in_data[19],
                             in_data[30]};
    
    wire lut_141_out = lut_141_table[lut_141_select];
    
    assign out_data[141] = lut_141_out;
    
    
    
    // LUT : 142
    wire [15:0] lut_142_table = 16'b1111111100000000;
    wire [3:0] lut_142_select = {
                             in_data[29],
                             in_data[48],
                             in_data[62],
                             in_data[49]};
    
    wire lut_142_out = lut_142_table[lut_142_select];
    
    assign out_data[142] = lut_142_out;
    
    
    
    // LUT : 143
    wire [15:0] lut_143_table = 16'b0000111100000011;
    wire [3:0] lut_143_select = {
                             in_data[61],
                             in_data[42],
                             in_data[20],
                             in_data[50]};
    
    wire lut_143_out = lut_143_table[lut_143_select];
    
    assign out_data[143] = lut_143_out;
    
    
    
    // LUT : 144
    wire [15:0] lut_144_table = 16'b0011000100000000;
    wire [3:0] lut_144_select = {
                             in_data[55],
                             in_data[59],
                             in_data[61],
                             in_data[51]};
    
    wire lut_144_out = lut_144_table[lut_144_select];
    
    assign out_data[144] = lut_144_out;
    
    
    
    // LUT : 145
    wire [15:0] lut_145_table = 16'b0011001100010000;
    wire [3:0] lut_145_select = {
                             in_data[27],
                             in_data[43],
                             in_data[4],
                             in_data[0]};
    
    wire lut_145_out = lut_145_table[lut_145_select];
    
    assign out_data[145] = lut_145_out;
    
    
    
    // LUT : 146
    wire [15:0] lut_146_table = 16'b1100100000001010;
    wire [3:0] lut_146_select = {
                             in_data[30],
                             in_data[58],
                             in_data[41],
                             in_data[24]};
    
    wire lut_146_out = lut_146_table[lut_146_select];
    
    assign out_data[146] = lut_146_out;
    
    
    
    // LUT : 147
    wire [15:0] lut_147_table = 16'b1010101011111010;
    wire [3:0] lut_147_select = {
                             in_data[48],
                             in_data[39],
                             in_data[12],
                             in_data[6]};
    
    wire lut_147_out = lut_147_table[lut_147_select];
    
    assign out_data[147] = lut_147_out;
    
    
    
    // LUT : 148
    wire [15:0] lut_148_table = 16'b0011011100111111;
    wire [3:0] lut_148_select = {
                             in_data[13],
                             in_data[15],
                             in_data[21],
                             in_data[19]};
    
    wire lut_148_out = lut_148_table[lut_148_select];
    
    assign out_data[148] = lut_148_out;
    
    
    
    // LUT : 149
    wire [15:0] lut_149_table = 16'b1110111011001100;
    wire [3:0] lut_149_select = {
                             in_data[38],
                             in_data[52],
                             in_data[26],
                             in_data[54]};
    
    wire lut_149_out = lut_149_table[lut_149_select];
    
    assign out_data[149] = lut_149_out;
    
    
    
    // LUT : 150
    wire [15:0] lut_150_table = 16'b0111001111110011;
    wire [3:0] lut_150_select = {
                             in_data[36],
                             in_data[5],
                             in_data[46],
                             in_data[31]};
    
    wire lut_150_out = lut_150_table[lut_150_select];
    
    assign out_data[150] = lut_150_out;
    
    
    
    // LUT : 151
    wire [15:0] lut_151_table = 16'b0000000010101010;
    wire [3:0] lut_151_select = {
                             in_data[42],
                             in_data[47],
                             in_data[3],
                             in_data[8]};
    
    wire lut_151_out = lut_151_table[lut_151_select];
    
    assign out_data[151] = lut_151_out;
    
    
    
    // LUT : 152
    wire [15:0] lut_152_table = 16'b0100010011111101;
    wire [3:0] lut_152_select = {
                             in_data[44],
                             in_data[9],
                             in_data[17],
                             in_data[37]};
    
    wire lut_152_out = lut_152_table[lut_152_select];
    
    assign out_data[152] = lut_152_out;
    
    
    
    // LUT : 153
    wire [15:0] lut_153_table = 16'b0101111100000000;
    wire [3:0] lut_153_select = {
                             in_data[33],
                             in_data[7],
                             in_data[1],
                             in_data[25]};
    
    wire lut_153_out = lut_153_table[lut_153_select];
    
    assign out_data[153] = lut_153_out;
    
    
    
    // LUT : 154
    wire [15:0] lut_154_table = 16'b1100111111001111;
    wire [3:0] lut_154_select = {
                             in_data[50],
                             in_data[63],
                             in_data[28],
                             in_data[45]};
    
    wire lut_154_out = lut_154_table[lut_154_select];
    
    assign out_data[154] = lut_154_out;
    
    
    
    // LUT : 155
    wire [15:0] lut_155_table = 16'b0000111110101111;
    wire [3:0] lut_155_select = {
                             in_data[40],
                             in_data[23],
                             in_data[14],
                             in_data[53]};
    
    wire lut_155_out = lut_155_table[lut_155_select];
    
    assign out_data[155] = lut_155_out;
    
    
    
    // LUT : 156
    wire [15:0] lut_156_table = 16'b1011111110111111;
    wire [3:0] lut_156_select = {
                             in_data[49],
                             in_data[20],
                             in_data[29],
                             in_data[56]};
    
    wire lut_156_out = lut_156_table[lut_156_select];
    
    assign out_data[156] = lut_156_out;
    
    
    
    // LUT : 157
    wire [15:0] lut_157_table = 16'b0101111100000101;
    wire [3:0] lut_157_select = {
                             in_data[60],
                             in_data[34],
                             in_data[2],
                             in_data[57]};
    
    wire lut_157_out = lut_157_table[lut_157_select];
    
    assign out_data[157] = lut_157_out;
    
    
    
    // LUT : 158
    wire [15:0] lut_158_table = 16'b1111100011110000;
    wire [3:0] lut_158_select = {
                             in_data[10],
                             in_data[18],
                             in_data[62],
                             in_data[22]};
    
    wire lut_158_out = lut_158_table[lut_158_select];
    
    assign out_data[158] = lut_158_out;
    
    
    
    // LUT : 159
    wire [15:0] lut_159_table = 16'b0011001100110011;
    wire [3:0] lut_159_select = {
                             in_data[11],
                             in_data[32],
                             in_data[16],
                             in_data[35]};
    
    wire lut_159_out = lut_159_table[lut_159_select];
    
    assign out_data[159] = lut_159_out;
    
    
    
    // LUT : 160
    wire [15:0] lut_160_table = 16'b1111111111110111;
    wire [3:0] lut_160_select = {
                             in_data[22],
                             in_data[4],
                             in_data[57],
                             in_data[55]};
    
    wire lut_160_out = lut_160_table[lut_160_select];
    
    assign out_data[160] = lut_160_out;
    
    
    
    // LUT : 161
    wire [15:0] lut_161_table = 16'b0010001011111111;
    wire [3:0] lut_161_select = {
                             in_data[27],
                             in_data[2],
                             in_data[17],
                             in_data[52]};
    
    wire lut_161_out = lut_161_table[lut_161_select];
    
    assign out_data[161] = lut_161_out;
    
    
    
    // LUT : 162
    wire [15:0] lut_162_table = 16'b0100000011010101;
    wire [3:0] lut_162_select = {
                             in_data[29],
                             in_data[42],
                             in_data[7],
                             in_data[40]};
    
    wire lut_162_out = lut_162_table[lut_162_select];
    
    assign out_data[162] = lut_162_out;
    
    
    
    // LUT : 163
    wire [15:0] lut_163_table = 16'b0011001100110011;
    wire [3:0] lut_163_select = {
                             in_data[0],
                             in_data[14],
                             in_data[37],
                             in_data[15]};
    
    wire lut_163_out = lut_163_table[lut_163_select];
    
    assign out_data[163] = lut_163_out;
    
    
    
    // LUT : 164
    wire [15:0] lut_164_table = 16'b0000101000001010;
    wire [3:0] lut_164_select = {
                             in_data[36],
                             in_data[48],
                             in_data[51],
                             in_data[24]};
    
    wire lut_164_out = lut_164_table[lut_164_select];
    
    assign out_data[164] = lut_164_out;
    
    
    
    // LUT : 165
    wire [15:0] lut_165_table = 16'b0101111110101110;
    wire [3:0] lut_165_select = {
                             in_data[21],
                             in_data[45],
                             in_data[34],
                             in_data[61]};
    
    wire lut_165_out = lut_165_table[lut_165_select];
    
    assign out_data[165] = lut_165_out;
    
    
    
    // LUT : 166
    wire [15:0] lut_166_table = 16'b1111000111110000;
    wire [3:0] lut_166_select = {
                             in_data[26],
                             in_data[23],
                             in_data[43],
                             in_data[10]};
    
    wire lut_166_out = lut_166_table[lut_166_select];
    
    assign out_data[166] = lut_166_out;
    
    
    
    // LUT : 167
    wire [15:0] lut_167_table = 16'b0101000001010100;
    wire [3:0] lut_167_select = {
                             in_data[38],
                             in_data[28],
                             in_data[62],
                             in_data[53]};
    
    wire lut_167_out = lut_167_table[lut_167_select];
    
    assign out_data[167] = lut_167_out;
    
    
    
    // LUT : 168
    wire [15:0] lut_168_table = 16'b1111000001010000;
    wire [3:0] lut_168_select = {
                             in_data[19],
                             in_data[30],
                             in_data[13],
                             in_data[39]};
    
    wire lut_168_out = lut_168_table[lut_168_select];
    
    assign out_data[168] = lut_168_out;
    
    
    
    // LUT : 169
    wire [15:0] lut_169_table = 16'b0011001100000011;
    wire [3:0] lut_169_select = {
                             in_data[32],
                             in_data[63],
                             in_data[6],
                             in_data[60]};
    
    wire lut_169_out = lut_169_table[lut_169_select];
    
    assign out_data[169] = lut_169_out;
    
    
    
    // LUT : 170
    wire [15:0] lut_170_table = 16'b0000010100000000;
    wire [3:0] lut_170_select = {
                             in_data[41],
                             in_data[5],
                             in_data[1],
                             in_data[47]};
    
    wire lut_170_out = lut_170_table[lut_170_select];
    
    assign out_data[170] = lut_170_out;
    
    
    
    // LUT : 171
    wire [15:0] lut_171_table = 16'b1101100011011111;
    wire [3:0] lut_171_select = {
                             in_data[59],
                             in_data[16],
                             in_data[56],
                             in_data[9]};
    
    wire lut_171_out = lut_171_table[lut_171_select];
    
    assign out_data[171] = lut_171_out;
    
    
    
    // LUT : 172
    wire [15:0] lut_172_table = 16'b0010000011110100;
    wire [3:0] lut_172_select = {
                             in_data[18],
                             in_data[54],
                             in_data[25],
                             in_data[58]};
    
    wire lut_172_out = lut_172_table[lut_172_select];
    
    assign out_data[172] = lut_172_out;
    
    
    
    // LUT : 173
    wire [15:0] lut_173_table = 16'b1011101100100010;
    wire [3:0] lut_173_select = {
                             in_data[31],
                             in_data[3],
                             in_data[11],
                             in_data[44]};
    
    wire lut_173_out = lut_173_table[lut_173_select];
    
    assign out_data[173] = lut_173_out;
    
    
    
    // LUT : 174
    wire [15:0] lut_174_table = 16'b0111010001110100;
    wire [3:0] lut_174_select = {
                             in_data[50],
                             in_data[20],
                             in_data[12],
                             in_data[35]};
    
    wire lut_174_out = lut_174_table[lut_174_select];
    
    assign out_data[174] = lut_174_out;
    
    
    
    // LUT : 175
    wire [15:0] lut_175_table = 16'b1010000010100001;
    wire [3:0] lut_175_select = {
                             in_data[49],
                             in_data[33],
                             in_data[8],
                             in_data[46]};
    
    wire lut_175_out = lut_175_table[lut_175_select];
    
    assign out_data[175] = lut_175_out;
    
    
    
    // LUT : 176
    wire [15:0] lut_176_table = 16'b1000101111111011;
    wire [3:0] lut_176_select = {
                             in_data[10],
                             in_data[55],
                             in_data[63],
                             in_data[19]};
    
    wire lut_176_out = lut_176_table[lut_176_select];
    
    assign out_data[176] = lut_176_out;
    
    
    
    // LUT : 177
    wire [15:0] lut_177_table = 16'b1111101100010001;
    wire [3:0] lut_177_select = {
                             in_data[13],
                             in_data[36],
                             in_data[30],
                             in_data[61]};
    
    wire lut_177_out = lut_177_table[lut_177_select];
    
    assign out_data[177] = lut_177_out;
    
    
    
    // LUT : 178
    wire [15:0] lut_178_table = 16'b1111001100110011;
    wire [3:0] lut_178_select = {
                             in_data[6],
                             in_data[8],
                             in_data[40],
                             in_data[50]};
    
    wire lut_178_out = lut_178_table[lut_178_select];
    
    assign out_data[178] = lut_178_out;
    
    
    
    // LUT : 179
    wire [15:0] lut_179_table = 16'b0000111100001111;
    wire [3:0] lut_179_select = {
                             in_data[47],
                             in_data[44],
                             in_data[15],
                             in_data[1]};
    
    wire lut_179_out = lut_179_table[lut_179_select];
    
    assign out_data[179] = lut_179_out;
    
    
    
    // LUT : 180
    wire [15:0] lut_180_table = 16'b1111101110111010;
    wire [3:0] lut_180_select = {
                             in_data[27],
                             in_data[14],
                             in_data[16],
                             in_data[53]};
    
    wire lut_180_out = lut_180_table[lut_180_select];
    
    assign out_data[180] = lut_180_out;
    
    
    
    // LUT : 181
    wire [15:0] lut_181_table = 16'b0100111100001111;
    wire [3:0] lut_181_select = {
                             in_data[59],
                             in_data[17],
                             in_data[4],
                             in_data[11]};
    
    wire lut_181_out = lut_181_table[lut_181_select];
    
    assign out_data[181] = lut_181_out;
    
    
    
    // LUT : 182
    wire [15:0] lut_182_table = 16'b0001000000110011;
    wire [3:0] lut_182_select = {
                             in_data[62],
                             in_data[49],
                             in_data[43],
                             in_data[51]};
    
    wire lut_182_out = lut_182_table[lut_182_select];
    
    assign out_data[182] = lut_182_out;
    
    
    
    // LUT : 183
    wire [15:0] lut_183_table = 16'b1000101010101010;
    wire [3:0] lut_183_select = {
                             in_data[57],
                             in_data[3],
                             in_data[34],
                             in_data[28]};
    
    wire lut_183_out = lut_183_table[lut_183_select];
    
    assign out_data[183] = lut_183_out;
    
    
    
    // LUT : 184
    wire [15:0] lut_184_table = 16'b1000111111111111;
    wire [3:0] lut_184_select = {
                             in_data[54],
                             in_data[46],
                             in_data[42],
                             in_data[52]};
    
    wire lut_184_out = lut_184_table[lut_184_select];
    
    assign out_data[184] = lut_184_out;
    
    
    
    // LUT : 185
    wire [15:0] lut_185_table = 16'b0011111100110011;
    wire [3:0] lut_185_select = {
                             in_data[22],
                             in_data[38],
                             in_data[24],
                             in_data[2]};
    
    wire lut_185_out = lut_185_table[lut_185_select];
    
    assign out_data[185] = lut_185_out;
    
    
    
    // LUT : 186
    wire [15:0] lut_186_table = 16'b1010101010101010;
    wire [3:0] lut_186_select = {
                             in_data[9],
                             in_data[0],
                             in_data[7],
                             in_data[18]};
    
    wire lut_186_out = lut_186_table[lut_186_select];
    
    assign out_data[186] = lut_186_out;
    
    
    
    // LUT : 187
    wire [15:0] lut_187_table = 16'b1111000011111111;
    wire [3:0] lut_187_select = {
                             in_data[21],
                             in_data[48],
                             in_data[20],
                             in_data[37]};
    
    wire lut_187_out = lut_187_table[lut_187_select];
    
    assign out_data[187] = lut_187_out;
    
    
    
    // LUT : 188
    wire [15:0] lut_188_table = 16'b0000010000000001;
    wire [3:0] lut_188_select = {
                             in_data[60],
                             in_data[31],
                             in_data[29],
                             in_data[56]};
    
    wire lut_188_out = lut_188_table[lut_188_select];
    
    assign out_data[188] = lut_188_out;
    
    
    
    // LUT : 189
    wire [15:0] lut_189_table = 16'b0100110000110000;
    wire [3:0] lut_189_select = {
                             in_data[12],
                             in_data[23],
                             in_data[5],
                             in_data[35]};
    
    wire lut_189_out = lut_189_table[lut_189_select];
    
    assign out_data[189] = lut_189_out;
    
    
    
    // LUT : 190
    wire [15:0] lut_190_table = 16'b0000101011011011;
    wire [3:0] lut_190_select = {
                             in_data[25],
                             in_data[33],
                             in_data[39],
                             in_data[32]};
    
    wire lut_190_out = lut_190_table[lut_190_select];
    
    assign out_data[190] = lut_190_out;
    
    
    
    // LUT : 191
    wire [15:0] lut_191_table = 16'b0101111100010011;
    wire [3:0] lut_191_select = {
                             in_data[41],
                             in_data[58],
                             in_data[45],
                             in_data[26]};
    
    wire lut_191_out = lut_191_table[lut_191_select];
    
    assign out_data[191] = lut_191_out;
    
    
    
    // LUT : 192
    wire [15:0] lut_192_table = 16'b1010000011000000;
    wire [3:0] lut_192_select = {
                             in_data[11],
                             in_data[55],
                             in_data[7],
                             in_data[37]};
    
    wire lut_192_out = lut_192_table[lut_192_select];
    
    assign out_data[192] = lut_192_out;
    
    
    
    // LUT : 193
    wire [15:0] lut_193_table = 16'b0101110101000100;
    wire [3:0] lut_193_select = {
                             in_data[57],
                             in_data[63],
                             in_data[22],
                             in_data[35]};
    
    wire lut_193_out = lut_193_table[lut_193_select];
    
    assign out_data[193] = lut_193_out;
    
    
    
    // LUT : 194
    wire [15:0] lut_194_table = 16'b0010001000100010;
    wire [3:0] lut_194_select = {
                             in_data[51],
                             in_data[38],
                             in_data[30],
                             in_data[24]};
    
    wire lut_194_out = lut_194_table[lut_194_select];
    
    assign out_data[194] = lut_194_out;
    
    
    
    // LUT : 195
    wire [15:0] lut_195_table = 16'b1111100001010010;
    wire [3:0] lut_195_select = {
                             in_data[41],
                             in_data[31],
                             in_data[56],
                             in_data[9]};
    
    wire lut_195_out = lut_195_table[lut_195_select];
    
    assign out_data[195] = lut_195_out;
    
    
    
    // LUT : 196
    wire [15:0] lut_196_table = 16'b1011101101000000;
    wire [3:0] lut_196_select = {
                             in_data[23],
                             in_data[8],
                             in_data[20],
                             in_data[61]};
    
    wire lut_196_out = lut_196_table[lut_196_select];
    
    assign out_data[196] = lut_196_out;
    
    
    
    // LUT : 197
    wire [15:0] lut_197_table = 16'b1101110100001101;
    wire [3:0] lut_197_select = {
                             in_data[53],
                             in_data[19],
                             in_data[16],
                             in_data[17]};
    
    wire lut_197_out = lut_197_table[lut_197_select];
    
    assign out_data[197] = lut_197_out;
    
    
    
    // LUT : 198
    wire [15:0] lut_198_table = 16'b0101010111111111;
    wire [3:0] lut_198_select = {
                             in_data[43],
                             in_data[3],
                             in_data[52],
                             in_data[46]};
    
    wire lut_198_out = lut_198_table[lut_198_select];
    
    assign out_data[198] = lut_198_out;
    
    
    
    // LUT : 199
    wire [15:0] lut_199_table = 16'b0000111100000101;
    wire [3:0] lut_199_select = {
                             in_data[28],
                             in_data[5],
                             in_data[0],
                             in_data[60]};
    
    wire lut_199_out = lut_199_table[lut_199_select];
    
    assign out_data[199] = lut_199_out;
    
    
    
    // LUT : 200
    wire [15:0] lut_200_table = 16'b0100000011000001;
    wire [3:0] lut_200_select = {
                             in_data[40],
                             in_data[15],
                             in_data[59],
                             in_data[62]};
    
    wire lut_200_out = lut_200_table[lut_200_select];
    
    assign out_data[200] = lut_200_out;
    
    
    
    // LUT : 201
    wire [15:0] lut_201_table = 16'b1010101010101010;
    wire [3:0] lut_201_select = {
                             in_data[50],
                             in_data[13],
                             in_data[10],
                             in_data[21]};
    
    wire lut_201_out = lut_201_table[lut_201_select];
    
    assign out_data[201] = lut_201_out;
    
    
    
    // LUT : 202
    wire [15:0] lut_202_table = 16'b0100110001010001;
    wire [3:0] lut_202_select = {
                             in_data[29],
                             in_data[26],
                             in_data[36],
                             in_data[39]};
    
    wire lut_202_out = lut_202_table[lut_202_select];
    
    assign out_data[202] = lut_202_out;
    
    
    
    // LUT : 203
    wire [15:0] lut_203_table = 16'b1100110010001010;
    wire [3:0] lut_203_select = {
                             in_data[27],
                             in_data[1],
                             in_data[42],
                             in_data[54]};
    
    wire lut_203_out = lut_203_table[lut_203_select];
    
    assign out_data[203] = lut_203_out;
    
    
    
    // LUT : 204
    wire [15:0] lut_204_table = 16'b1111111110100010;
    wire [3:0] lut_204_select = {
                             in_data[18],
                             in_data[58],
                             in_data[6],
                             in_data[48]};
    
    wire lut_204_out = lut_204_table[lut_204_select];
    
    assign out_data[204] = lut_204_out;
    
    
    
    // LUT : 205
    wire [15:0] lut_205_table = 16'b0011001000111011;
    wire [3:0] lut_205_select = {
                             in_data[4],
                             in_data[14],
                             in_data[45],
                             in_data[25]};
    
    wire lut_205_out = lut_205_table[lut_205_select];
    
    assign out_data[205] = lut_205_out;
    
    
    
    // LUT : 206
    wire [15:0] lut_206_table = 16'b1111001100110011;
    wire [3:0] lut_206_select = {
                             in_data[2],
                             in_data[33],
                             in_data[44],
                             in_data[12]};
    
    wire lut_206_out = lut_206_table[lut_206_select];
    
    assign out_data[206] = lut_206_out;
    
    
    
    // LUT : 207
    wire [15:0] lut_207_table = 16'b0111000101110001;
    wire [3:0] lut_207_select = {
                             in_data[49],
                             in_data[47],
                             in_data[34],
                             in_data[32]};
    
    wire lut_207_out = lut_207_table[lut_207_select];
    
    assign out_data[207] = lut_207_out;
    
    
    
    // LUT : 208
    wire [15:0] lut_208_table = 16'b0000011100001111;
    wire [3:0] lut_208_select = {
                             in_data[58],
                             in_data[28],
                             in_data[16],
                             in_data[60]};
    
    wire lut_208_out = lut_208_table[lut_208_select];
    
    assign out_data[208] = lut_208_out;
    
    
    
    // LUT : 209
    wire [15:0] lut_209_table = 16'b1111100011111010;
    wire [3:0] lut_209_select = {
                             in_data[13],
                             in_data[26],
                             in_data[37],
                             in_data[56]};
    
    wire lut_209_out = lut_209_table[lut_209_select];
    
    assign out_data[209] = lut_209_out;
    
    
    
    // LUT : 210
    wire [15:0] lut_210_table = 16'b0011000000110000;
    wire [3:0] lut_210_select = {
                             in_data[20],
                             in_data[23],
                             in_data[33],
                             in_data[3]};
    
    wire lut_210_out = lut_210_table[lut_210_select];
    
    assign out_data[210] = lut_210_out;
    
    
    
    // LUT : 211
    wire [15:0] lut_211_table = 16'b1111111100000001;
    wire [3:0] lut_211_select = {
                             in_data[35],
                             in_data[34],
                             in_data[63],
                             in_data[19]};
    
    wire lut_211_out = lut_211_table[lut_211_select];
    
    assign out_data[211] = lut_211_out;
    
    
    
    // LUT : 212
    wire [15:0] lut_212_table = 16'b1101010001010000;
    wire [3:0] lut_212_select = {
                             in_data[4],
                             in_data[21],
                             in_data[12],
                             in_data[47]};
    
    wire lut_212_out = lut_212_table[lut_212_select];
    
    assign out_data[212] = lut_212_out;
    
    
    
    // LUT : 213
    wire [15:0] lut_213_table = 16'b0000110000101100;
    wire [3:0] lut_213_select = {
                             in_data[27],
                             in_data[18],
                             in_data[8],
                             in_data[11]};
    
    wire lut_213_out = lut_213_table[lut_213_select];
    
    assign out_data[213] = lut_213_out;
    
    
    
    // LUT : 214
    wire [15:0] lut_214_table = 16'b0101111101010101;
    wire [3:0] lut_214_select = {
                             in_data[24],
                             in_data[59],
                             in_data[2],
                             in_data[30]};
    
    wire lut_214_out = lut_214_table[lut_214_select];
    
    assign out_data[214] = lut_214_out;
    
    
    
    // LUT : 215
    wire [15:0] lut_215_table = 16'b1011000000110000;
    wire [3:0] lut_215_select = {
                             in_data[41],
                             in_data[46],
                             in_data[15],
                             in_data[54]};
    
    wire lut_215_out = lut_215_table[lut_215_select];
    
    assign out_data[215] = lut_215_out;
    
    
    
    // LUT : 216
    wire [15:0] lut_216_table = 16'b0000000000110001;
    wire [3:0] lut_216_select = {
                             in_data[38],
                             in_data[39],
                             in_data[5],
                             in_data[50]};
    
    wire lut_216_out = lut_216_table[lut_216_select];
    
    assign out_data[216] = lut_216_out;
    
    
    
    // LUT : 217
    wire [15:0] lut_217_table = 16'b1111111100000000;
    wire [3:0] lut_217_select = {
                             in_data[25],
                             in_data[42],
                             in_data[0],
                             in_data[29]};
    
    wire lut_217_out = lut_217_table[lut_217_select];
    
    assign out_data[217] = lut_217_out;
    
    
    
    // LUT : 218
    wire [15:0] lut_218_table = 16'b0000000011111111;
    wire [3:0] lut_218_select = {
                             in_data[62],
                             in_data[53],
                             in_data[52],
                             in_data[49]};
    
    wire lut_218_out = lut_218_table[lut_218_select];
    
    assign out_data[218] = lut_218_out;
    
    
    
    // LUT : 219
    wire [15:0] lut_219_table = 16'b1111111100101111;
    wire [3:0] lut_219_select = {
                             in_data[48],
                             in_data[44],
                             in_data[57],
                             in_data[43]};
    
    wire lut_219_out = lut_219_table[lut_219_select];
    
    assign out_data[219] = lut_219_out;
    
    
    
    // LUT : 220
    wire [15:0] lut_220_table = 16'b1000000011100010;
    wire [3:0] lut_220_select = {
                             in_data[22],
                             in_data[17],
                             in_data[6],
                             in_data[7]};
    
    wire lut_220_out = lut_220_table[lut_220_select];
    
    assign out_data[220] = lut_220_out;
    
    
    
    // LUT : 221
    wire [15:0] lut_221_table = 16'b0100110000001100;
    wire [3:0] lut_221_select = {
                             in_data[51],
                             in_data[31],
                             in_data[9],
                             in_data[10]};
    
    wire lut_221_out = lut_221_table[lut_221_select];
    
    assign out_data[221] = lut_221_out;
    
    
    
    // LUT : 222
    wire [15:0] lut_222_table = 16'b0000000010001000;
    wire [3:0] lut_222_select = {
                             in_data[61],
                             in_data[1],
                             in_data[55],
                             in_data[40]};
    
    wire lut_222_out = lut_222_table[lut_222_select];
    
    assign out_data[222] = lut_222_out;
    
    
    
    // LUT : 223
    wire [15:0] lut_223_table = 16'b0000010111111111;
    wire [3:0] lut_223_select = {
                             in_data[45],
                             in_data[36],
                             in_data[14],
                             in_data[32]};
    
    wire lut_223_out = lut_223_table[lut_223_select];
    
    assign out_data[223] = lut_223_out;
    
    
    
    // LUT : 224
    wire [15:0] lut_224_table = 16'b1111111111001110;
    wire [3:0] lut_224_select = {
                             in_data[47],
                             in_data[49],
                             in_data[52],
                             in_data[2]};
    
    wire lut_224_out = lut_224_table[lut_224_select];
    
    assign out_data[224] = lut_224_out;
    
    
    
    // LUT : 225
    wire [15:0] lut_225_table = 16'b0001000100110011;
    wire [3:0] lut_225_select = {
                             in_data[19],
                             in_data[0],
                             in_data[17],
                             in_data[50]};
    
    wire lut_225_out = lut_225_table[lut_225_select];
    
    assign out_data[225] = lut_225_out;
    
    
    
    // LUT : 226
    wire [15:0] lut_226_table = 16'b0000000011001100;
    wire [3:0] lut_226_select = {
                             in_data[39],
                             in_data[8],
                             in_data[45],
                             in_data[42]};
    
    wire lut_226_out = lut_226_table[lut_226_select];
    
    assign out_data[226] = lut_226_out;
    
    
    
    // LUT : 227
    wire [15:0] lut_227_table = 16'b1110000111010101;
    wire [3:0] lut_227_select = {
                             in_data[32],
                             in_data[33],
                             in_data[36],
                             in_data[55]};
    
    wire lut_227_out = lut_227_table[lut_227_select];
    
    assign out_data[227] = lut_227_out;
    
    
    
    // LUT : 228
    wire [15:0] lut_228_table = 16'b0000010100000101;
    wire [3:0] lut_228_select = {
                             in_data[51],
                             in_data[5],
                             in_data[31],
                             in_data[20]};
    
    wire lut_228_out = lut_228_table[lut_228_select];
    
    assign out_data[228] = lut_228_out;
    
    
    
    // LUT : 229
    wire [15:0] lut_229_table = 16'b1101110101011101;
    wire [3:0] lut_229_select = {
                             in_data[37],
                             in_data[35],
                             in_data[28],
                             in_data[27]};
    
    wire lut_229_out = lut_229_table[lut_229_select];
    
    assign out_data[229] = lut_229_out;
    
    
    
    // LUT : 230
    wire [15:0] lut_230_table = 16'b0000000001111111;
    wire [3:0] lut_230_select = {
                             in_data[44],
                             in_data[59],
                             in_data[9],
                             in_data[11]};
    
    wire lut_230_out = lut_230_table[lut_230_select];
    
    assign out_data[230] = lut_230_out;
    
    
    
    // LUT : 231
    wire [15:0] lut_231_table = 16'b0001111101011111;
    wire [3:0] lut_231_select = {
                             in_data[13],
                             in_data[46],
                             in_data[12],
                             in_data[21]};
    
    wire lut_231_out = lut_231_table[lut_231_select];
    
    assign out_data[231] = lut_231_out;
    
    
    
    // LUT : 232
    wire [15:0] lut_232_table = 16'b1111001101110001;
    wire [3:0] lut_232_select = {
                             in_data[60],
                             in_data[18],
                             in_data[40],
                             in_data[54]};
    
    wire lut_232_out = lut_232_table[lut_232_select];
    
    assign out_data[232] = lut_232_out;
    
    
    
    // LUT : 233
    wire [15:0] lut_233_table = 16'b0010101011111000;
    wire [3:0] lut_233_select = {
                             in_data[6],
                             in_data[34],
                             in_data[57],
                             in_data[38]};
    
    wire lut_233_out = lut_233_table[lut_233_select];
    
    assign out_data[233] = lut_233_out;
    
    
    
    // LUT : 234
    wire [15:0] lut_234_table = 16'b0011110100111001;
    wire [3:0] lut_234_select = {
                             in_data[3],
                             in_data[43],
                             in_data[29],
                             in_data[26]};
    
    wire lut_234_out = lut_234_table[lut_234_select];
    
    assign out_data[234] = lut_234_out;
    
    
    
    // LUT : 235
    wire [15:0] lut_235_table = 16'b1110001001001100;
    wire [3:0] lut_235_select = {
                             in_data[14],
                             in_data[56],
                             in_data[25],
                             in_data[63]};
    
    wire lut_235_out = lut_235_table[lut_235_select];
    
    assign out_data[235] = lut_235_out;
    
    
    
    // LUT : 236
    wire [15:0] lut_236_table = 16'b1010111100000011;
    wire [3:0] lut_236_select = {
                             in_data[30],
                             in_data[22],
                             in_data[24],
                             in_data[16]};
    
    wire lut_236_out = lut_236_table[lut_236_select];
    
    assign out_data[236] = lut_236_out;
    
    
    
    // LUT : 237
    wire [15:0] lut_237_table = 16'b0010000000110000;
    wire [3:0] lut_237_select = {
                             in_data[61],
                             in_data[23],
                             in_data[4],
                             in_data[7]};
    
    wire lut_237_out = lut_237_table[lut_237_select];
    
    assign out_data[237] = lut_237_out;
    
    
    
    // LUT : 238
    wire [15:0] lut_238_table = 16'b1111111100001111;
    wire [3:0] lut_238_select = {
                             in_data[58],
                             in_data[15],
                             in_data[1],
                             in_data[10]};
    
    wire lut_238_out = lut_238_table[lut_238_select];
    
    assign out_data[238] = lut_238_out;
    
    
    
    // LUT : 239
    wire [15:0] lut_239_table = 16'b1111110011111111;
    wire [3:0] lut_239_select = {
                             in_data[41],
                             in_data[48],
                             in_data[62],
                             in_data[53]};
    
    wire lut_239_out = lut_239_table[lut_239_select];
    
    assign out_data[239] = lut_239_out;
    
    
    
    // LUT : 240
    wire [15:0] lut_240_table = 16'b0001000001010000;
    wire [3:0] lut_240_select = {
                             in_data[58],
                             in_data[46],
                             in_data[50],
                             in_data[5]};
    
    wire lut_240_out = lut_240_table[lut_240_select];
    
    assign out_data[240] = lut_240_out;
    
    
    
    // LUT : 241
    wire [15:0] lut_241_table = 16'b1101111111011111;
    wire [3:0] lut_241_select = {
                             in_data[1],
                             in_data[14],
                             in_data[38],
                             in_data[20]};
    
    wire lut_241_out = lut_241_table[lut_241_select];
    
    assign out_data[241] = lut_241_out;
    
    
    
    // LUT : 242
    wire [15:0] lut_242_table = 16'b1010101110111111;
    wire [3:0] lut_242_select = {
                             in_data[27],
                             in_data[36],
                             in_data[52],
                             in_data[31]};
    
    wire lut_242_out = lut_242_table[lut_242_select];
    
    assign out_data[242] = lut_242_out;
    
    
    
    // LUT : 243
    wire [15:0] lut_243_table = 16'b1100100011011010;
    wire [3:0] lut_243_select = {
                             in_data[59],
                             in_data[6],
                             in_data[9],
                             in_data[60]};
    
    wire lut_243_out = lut_243_table[lut_243_select];
    
    assign out_data[243] = lut_243_out;
    
    
    
    // LUT : 244
    wire [15:0] lut_244_table = 16'b0000000010101010;
    wire [3:0] lut_244_select = {
                             in_data[53],
                             in_data[13],
                             in_data[2],
                             in_data[40]};
    
    wire lut_244_out = lut_244_table[lut_244_select];
    
    assign out_data[244] = lut_244_out;
    
    
    
    // LUT : 245
    wire [15:0] lut_245_table = 16'b1010101011101010;
    wire [3:0] lut_245_select = {
                             in_data[10],
                             in_data[43],
                             in_data[16],
                             in_data[33]};
    
    wire lut_245_out = lut_245_table[lut_245_select];
    
    assign out_data[245] = lut_245_out;
    
    
    
    // LUT : 246
    wire [15:0] lut_246_table = 16'b0011001111110011;
    wire [3:0] lut_246_select = {
                             in_data[41],
                             in_data[54],
                             in_data[30],
                             in_data[0]};
    
    wire lut_246_out = lut_246_table[lut_246_select];
    
    assign out_data[246] = lut_246_out;
    
    
    
    // LUT : 247
    wire [15:0] lut_247_table = 16'b0100010011111101;
    wire [3:0] lut_247_select = {
                             in_data[24],
                             in_data[4],
                             in_data[25],
                             in_data[8]};
    
    wire lut_247_out = lut_247_table[lut_247_select];
    
    assign out_data[247] = lut_247_out;
    
    
    
    // LUT : 248
    wire [15:0] lut_248_table = 16'b1011111000111111;
    wire [3:0] lut_248_select = {
                             in_data[57],
                             in_data[62],
                             in_data[63],
                             in_data[51]};
    
    wire lut_248_out = lut_248_table[lut_248_select];
    
    assign out_data[248] = lut_248_out;
    
    
    
    // LUT : 249
    wire [15:0] lut_249_table = 16'b0000101010100011;
    wire [3:0] lut_249_select = {
                             in_data[37],
                             in_data[7],
                             in_data[23],
                             in_data[35]};
    
    wire lut_249_out = lut_249_table[lut_249_select];
    
    assign out_data[249] = lut_249_out;
    
    
    
    // LUT : 250
    wire [15:0] lut_250_table = 16'b0000101000000010;
    wire [3:0] lut_250_select = {
                             in_data[47],
                             in_data[3],
                             in_data[56],
                             in_data[55]};
    
    wire lut_250_out = lut_250_table[lut_250_select];
    
    assign out_data[250] = lut_250_out;
    
    
    
    // LUT : 251
    wire [15:0] lut_251_table = 16'b1010111110000000;
    wire [3:0] lut_251_select = {
                             in_data[42],
                             in_data[21],
                             in_data[34],
                             in_data[22]};
    
    wire lut_251_out = lut_251_table[lut_251_select];
    
    assign out_data[251] = lut_251_out;
    
    
    
    // LUT : 252
    wire [15:0] lut_252_table = 16'b1100111000001100;
    wire [3:0] lut_252_select = {
                             in_data[15],
                             in_data[28],
                             in_data[12],
                             in_data[49]};
    
    wire lut_252_out = lut_252_table[lut_252_select];
    
    assign out_data[252] = lut_252_out;
    
    
    
    // LUT : 253
    wire [15:0] lut_253_table = 16'b1001100011001100;
    wire [3:0] lut_253_select = {
                             in_data[26],
                             in_data[29],
                             in_data[19],
                             in_data[32]};
    
    wire lut_253_out = lut_253_table[lut_253_select];
    
    assign out_data[253] = lut_253_out;
    
    
    
    // LUT : 254
    wire [15:0] lut_254_table = 16'b1110110000000000;
    wire [3:0] lut_254_select = {
                             in_data[45],
                             in_data[48],
                             in_data[17],
                             in_data[39]};
    
    wire lut_254_out = lut_254_table[lut_254_select];
    
    assign out_data[254] = lut_254_out;
    
    
    
    // LUT : 255
    wire [15:0] lut_255_table = 16'b1000100010001000;
    wire [3:0] lut_255_select = {
                             in_data[61],
                             in_data[11],
                             in_data[18],
                             in_data[44]};
    
    wire lut_255_out = lut_255_table[lut_255_select];
    
    assign out_data[255] = lut_255_out;
    
    
endmodule



module MnistLut4Simple_sub3
        #(
            parameter INIT_REG = 1'bx,
            parameter DEVICE   = "RTL"
        )
        (
            input  wire         reset,
            input  wire         clk,
            input  wire         cke,
            
            input  wire [255:0]  in_data,
            output wire [63:0]  out_data
        );
    
    
    // LUT : 0
    wire [15:0] lut_0_table = 16'b0101000011010001;
    wire [3:0] lut_0_select = {
                             in_data[3],
                             in_data[2],
                             in_data[1],
                             in_data[0]};
    
    wire lut_0_out = lut_0_table[lut_0_select];
    
    assign out_data[0] = lut_0_out;
    
    
    
    // LUT : 1
    wire [15:0] lut_1_table = 16'b1100110010001100;
    wire [3:0] lut_1_select = {
                             in_data[7],
                             in_data[6],
                             in_data[5],
                             in_data[4]};
    
    wire lut_1_out = lut_1_table[lut_1_select];
    
    assign out_data[1] = lut_1_out;
    
    
    
    // LUT : 2
    wire [15:0] lut_2_table = 16'b0001011100110011;
    wire [3:0] lut_2_select = {
                             in_data[11],
                             in_data[10],
                             in_data[9],
                             in_data[8]};
    
    wire lut_2_out = lut_2_table[lut_2_select];
    
    assign out_data[2] = lut_2_out;
    
    
    
    // LUT : 3
    wire [15:0] lut_3_table = 16'b1101110111000000;
    wire [3:0] lut_3_select = {
                             in_data[15],
                             in_data[14],
                             in_data[13],
                             in_data[12]};
    
    wire lut_3_out = lut_3_table[lut_3_select];
    
    assign out_data[3] = lut_3_out;
    
    
    
    // LUT : 4
    wire [15:0] lut_4_table = 16'b1011111110101011;
    wire [3:0] lut_4_select = {
                             in_data[19],
                             in_data[18],
                             in_data[17],
                             in_data[16]};
    
    wire lut_4_out = lut_4_table[lut_4_select];
    
    assign out_data[4] = lut_4_out;
    
    
    
    // LUT : 5
    wire [15:0] lut_5_table = 16'b1110001011110011;
    wire [3:0] lut_5_select = {
                             in_data[23],
                             in_data[22],
                             in_data[21],
                             in_data[20]};
    
    wire lut_5_out = lut_5_table[lut_5_select];
    
    assign out_data[5] = lut_5_out;
    
    
    
    // LUT : 6
    wire [15:0] lut_6_table = 16'b1010101010100000;
    wire [3:0] lut_6_select = {
                             in_data[27],
                             in_data[26],
                             in_data[25],
                             in_data[24]};
    
    wire lut_6_out = lut_6_table[lut_6_select];
    
    assign out_data[6] = lut_6_out;
    
    
    
    // LUT : 7
    wire [15:0] lut_7_table = 16'b1111111101110011;
    wire [3:0] lut_7_select = {
                             in_data[31],
                             in_data[30],
                             in_data[29],
                             in_data[28]};
    
    wire lut_7_out = lut_7_table[lut_7_select];
    
    assign out_data[7] = lut_7_out;
    
    
    
    // LUT : 8
    wire [15:0] lut_8_table = 16'b1011100011111110;
    wire [3:0] lut_8_select = {
                             in_data[35],
                             in_data[34],
                             in_data[33],
                             in_data[32]};
    
    wire lut_8_out = lut_8_table[lut_8_select];
    
    assign out_data[8] = lut_8_out;
    
    
    
    // LUT : 9
    wire [15:0] lut_9_table = 16'b1011101010111010;
    wire [3:0] lut_9_select = {
                             in_data[39],
                             in_data[38],
                             in_data[37],
                             in_data[36]};
    
    wire lut_9_out = lut_9_table[lut_9_select];
    
    assign out_data[9] = lut_9_out;
    
    
    
    // LUT : 10
    wire [15:0] lut_10_table = 16'b0000101100001001;
    wire [3:0] lut_10_select = {
                             in_data[43],
                             in_data[42],
                             in_data[41],
                             in_data[40]};
    
    wire lut_10_out = lut_10_table[lut_10_select];
    
    assign out_data[10] = lut_10_out;
    
    
    
    // LUT : 11
    wire [15:0] lut_11_table = 16'b1011111100101011;
    wire [3:0] lut_11_select = {
                             in_data[47],
                             in_data[46],
                             in_data[45],
                             in_data[44]};
    
    wire lut_11_out = lut_11_table[lut_11_select];
    
    assign out_data[11] = lut_11_out;
    
    
    
    // LUT : 12
    wire [15:0] lut_12_table = 16'b0000000111000100;
    wire [3:0] lut_12_select = {
                             in_data[51],
                             in_data[50],
                             in_data[49],
                             in_data[48]};
    
    wire lut_12_out = lut_12_table[lut_12_select];
    
    assign out_data[12] = lut_12_out;
    
    
    
    // LUT : 13
    wire [15:0] lut_13_table = 16'b1010111100000000;
    wire [3:0] lut_13_select = {
                             in_data[55],
                             in_data[54],
                             in_data[53],
                             in_data[52]};
    
    wire lut_13_out = lut_13_table[lut_13_select];
    
    assign out_data[13] = lut_13_out;
    
    
    
    // LUT : 14
    wire [15:0] lut_14_table = 16'b0001001100010001;
    wire [3:0] lut_14_select = {
                             in_data[59],
                             in_data[58],
                             in_data[57],
                             in_data[56]};
    
    wire lut_14_out = lut_14_table[lut_14_select];
    
    assign out_data[14] = lut_14_out;
    
    
    
    // LUT : 15
    wire [15:0] lut_15_table = 16'b0000110001001101;
    wire [3:0] lut_15_select = {
                             in_data[63],
                             in_data[62],
                             in_data[61],
                             in_data[60]};
    
    wire lut_15_out = lut_15_table[lut_15_select];
    
    assign out_data[15] = lut_15_out;
    
    
    
    // LUT : 16
    wire [15:0] lut_16_table = 16'b1011001010110010;
    wire [3:0] lut_16_select = {
                             in_data[67],
                             in_data[66],
                             in_data[65],
                             in_data[64]};
    
    wire lut_16_out = lut_16_table[lut_16_select];
    
    assign out_data[16] = lut_16_out;
    
    
    
    // LUT : 17
    wire [15:0] lut_17_table = 16'b1110111010001000;
    wire [3:0] lut_17_select = {
                             in_data[71],
                             in_data[70],
                             in_data[69],
                             in_data[68]};
    
    wire lut_17_out = lut_17_table[lut_17_select];
    
    assign out_data[17] = lut_17_out;
    
    
    
    // LUT : 18
    wire [15:0] lut_18_table = 16'b1111110011110101;
    wire [3:0] lut_18_select = {
                             in_data[75],
                             in_data[74],
                             in_data[73],
                             in_data[72]};
    
    wire lut_18_out = lut_18_table[lut_18_select];
    
    assign out_data[18] = lut_18_out;
    
    
    
    // LUT : 19
    wire [15:0] lut_19_table = 16'b0010001011111110;
    wire [3:0] lut_19_select = {
                             in_data[79],
                             in_data[78],
                             in_data[77],
                             in_data[76]};
    
    wire lut_19_out = lut_19_table[lut_19_select];
    
    assign out_data[19] = lut_19_out;
    
    
    
    // LUT : 20
    wire [15:0] lut_20_table = 16'b1011101011111010;
    wire [3:0] lut_20_select = {
                             in_data[83],
                             in_data[82],
                             in_data[81],
                             in_data[80]};
    
    wire lut_20_out = lut_20_table[lut_20_select];
    
    assign out_data[20] = lut_20_out;
    
    
    
    // LUT : 21
    wire [15:0] lut_21_table = 16'b0001001101110011;
    wire [3:0] lut_21_select = {
                             in_data[87],
                             in_data[86],
                             in_data[85],
                             in_data[84]};
    
    wire lut_21_out = lut_21_table[lut_21_select];
    
    assign out_data[21] = lut_21_out;
    
    
    
    // LUT : 22
    wire [15:0] lut_22_table = 16'b0000100011111110;
    wire [3:0] lut_22_select = {
                             in_data[91],
                             in_data[90],
                             in_data[89],
                             in_data[88]};
    
    wire lut_22_out = lut_22_table[lut_22_select];
    
    assign out_data[22] = lut_22_out;
    
    
    
    // LUT : 23
    wire [15:0] lut_23_table = 16'b0011111110101111;
    wire [3:0] lut_23_select = {
                             in_data[95],
                             in_data[94],
                             in_data[93],
                             in_data[92]};
    
    wire lut_23_out = lut_23_table[lut_23_select];
    
    assign out_data[23] = lut_23_out;
    
    
    
    // LUT : 24
    wire [15:0] lut_24_table = 16'b0000000001010100;
    wire [3:0] lut_24_select = {
                             in_data[99],
                             in_data[98],
                             in_data[97],
                             in_data[96]};
    
    wire lut_24_out = lut_24_table[lut_24_select];
    
    assign out_data[24] = lut_24_out;
    
    
    
    // LUT : 25
    wire [15:0] lut_25_table = 16'b1111111100100011;
    wire [3:0] lut_25_select = {
                             in_data[103],
                             in_data[102],
                             in_data[101],
                             in_data[100]};
    
    wire lut_25_out = lut_25_table[lut_25_select];
    
    assign out_data[25] = lut_25_out;
    
    
    
    // LUT : 26
    wire [15:0] lut_26_table = 16'b1100000011111000;
    wire [3:0] lut_26_select = {
                             in_data[107],
                             in_data[106],
                             in_data[105],
                             in_data[104]};
    
    wire lut_26_out = lut_26_table[lut_26_select];
    
    assign out_data[26] = lut_26_out;
    
    
    
    // LUT : 27
    wire [15:0] lut_27_table = 16'b1101110101000000;
    wire [3:0] lut_27_select = {
                             in_data[111],
                             in_data[110],
                             in_data[109],
                             in_data[108]};
    
    wire lut_27_out = lut_27_table[lut_27_select];
    
    assign out_data[27] = lut_27_out;
    
    
    
    // LUT : 28
    wire [15:0] lut_28_table = 16'b1101111100001111;
    wire [3:0] lut_28_select = {
                             in_data[115],
                             in_data[114],
                             in_data[113],
                             in_data[112]};
    
    wire lut_28_out = lut_28_table[lut_28_select];
    
    assign out_data[28] = lut_28_out;
    
    
    
    // LUT : 29
    wire [15:0] lut_29_table = 16'b0011011100000011;
    wire [3:0] lut_29_select = {
                             in_data[119],
                             in_data[118],
                             in_data[117],
                             in_data[116]};
    
    wire lut_29_out = lut_29_table[lut_29_select];
    
    assign out_data[29] = lut_29_out;
    
    
    
    // LUT : 30
    wire [15:0] lut_30_table = 16'b0011101100100010;
    wire [3:0] lut_30_select = {
                             in_data[123],
                             in_data[122],
                             in_data[121],
                             in_data[120]};
    
    wire lut_30_out = lut_30_table[lut_30_select];
    
    assign out_data[30] = lut_30_out;
    
    
    
    // LUT : 31
    wire [15:0] lut_31_table = 16'b1100111111001101;
    wire [3:0] lut_31_select = {
                             in_data[127],
                             in_data[126],
                             in_data[125],
                             in_data[124]};
    
    wire lut_31_out = lut_31_table[lut_31_select];
    
    assign out_data[31] = lut_31_out;
    
    
    
    // LUT : 32
    wire [15:0] lut_32_table = 16'b0101111100000100;
    wire [3:0] lut_32_select = {
                             in_data[131],
                             in_data[130],
                             in_data[129],
                             in_data[128]};
    
    wire lut_32_out = lut_32_table[lut_32_select];
    
    assign out_data[32] = lut_32_out;
    
    
    
    // LUT : 33
    wire [15:0] lut_33_table = 16'b1111111111101000;
    wire [3:0] lut_33_select = {
                             in_data[135],
                             in_data[134],
                             in_data[133],
                             in_data[132]};
    
    wire lut_33_out = lut_33_table[lut_33_select];
    
    assign out_data[33] = lut_33_out;
    
    
    
    // LUT : 34
    wire [15:0] lut_34_table = 16'b1111000000110000;
    wire [3:0] lut_34_select = {
                             in_data[139],
                             in_data[138],
                             in_data[137],
                             in_data[136]};
    
    wire lut_34_out = lut_34_table[lut_34_select];
    
    assign out_data[34] = lut_34_out;
    
    
    
    // LUT : 35
    wire [15:0] lut_35_table = 16'b1011001000000000;
    wire [3:0] lut_35_select = {
                             in_data[143],
                             in_data[142],
                             in_data[141],
                             in_data[140]};
    
    wire lut_35_out = lut_35_table[lut_35_select];
    
    assign out_data[35] = lut_35_out;
    
    
    
    // LUT : 36
    wire [15:0] lut_36_table = 16'b1010100011001100;
    wire [3:0] lut_36_select = {
                             in_data[147],
                             in_data[146],
                             in_data[145],
                             in_data[144]};
    
    wire lut_36_out = lut_36_table[lut_36_select];
    
    assign out_data[36] = lut_36_out;
    
    
    
    // LUT : 37
    wire [15:0] lut_37_table = 16'b0001010100000001;
    wire [3:0] lut_37_select = {
                             in_data[151],
                             in_data[150],
                             in_data[149],
                             in_data[148]};
    
    wire lut_37_out = lut_37_table[lut_37_select];
    
    assign out_data[37] = lut_37_out;
    
    
    
    // LUT : 38
    wire [15:0] lut_38_table = 16'b0101110111111111;
    wire [3:0] lut_38_select = {
                             in_data[155],
                             in_data[154],
                             in_data[153],
                             in_data[152]};
    
    wire lut_38_out = lut_38_table[lut_38_select];
    
    assign out_data[38] = lut_38_out;
    
    
    
    // LUT : 39
    wire [15:0] lut_39_table = 16'b1111000010111010;
    wire [3:0] lut_39_select = {
                             in_data[159],
                             in_data[158],
                             in_data[157],
                             in_data[156]};
    
    wire lut_39_out = lut_39_table[lut_39_select];
    
    assign out_data[39] = lut_39_out;
    
    
    
    // LUT : 40
    wire [15:0] lut_40_table = 16'b0101111100010101;
    wire [3:0] lut_40_select = {
                             in_data[163],
                             in_data[162],
                             in_data[161],
                             in_data[160]};
    
    wire lut_40_out = lut_40_table[lut_40_select];
    
    assign out_data[40] = lut_40_out;
    
    
    
    // LUT : 41
    wire [15:0] lut_41_table = 16'b1011000010110000;
    wire [3:0] lut_41_select = {
                             in_data[167],
                             in_data[166],
                             in_data[165],
                             in_data[164]};
    
    wire lut_41_out = lut_41_table[lut_41_select];
    
    assign out_data[41] = lut_41_out;
    
    
    
    // LUT : 42
    wire [15:0] lut_42_table = 16'b1011000000100000;
    wire [3:0] lut_42_select = {
                             in_data[171],
                             in_data[170],
                             in_data[169],
                             in_data[168]};
    
    wire lut_42_out = lut_42_table[lut_42_select];
    
    assign out_data[42] = lut_42_out;
    
    
    
    // LUT : 43
    wire [15:0] lut_43_table = 16'b1110110011001000;
    wire [3:0] lut_43_select = {
                             in_data[175],
                             in_data[174],
                             in_data[173],
                             in_data[172]};
    
    wire lut_43_out = lut_43_table[lut_43_select];
    
    assign out_data[43] = lut_43_out;
    
    
    
    // LUT : 44
    wire [15:0] lut_44_table = 16'b0010001010110011;
    wire [3:0] lut_44_select = {
                             in_data[179],
                             in_data[178],
                             in_data[177],
                             in_data[176]};
    
    wire lut_44_out = lut_44_table[lut_44_select];
    
    assign out_data[44] = lut_44_out;
    
    
    
    // LUT : 45
    wire [15:0] lut_45_table = 16'b1111011101010001;
    wire [3:0] lut_45_select = {
                             in_data[183],
                             in_data[182],
                             in_data[181],
                             in_data[180]};
    
    wire lut_45_out = lut_45_table[lut_45_select];
    
    assign out_data[45] = lut_45_out;
    
    
    
    // LUT : 46
    wire [15:0] lut_46_table = 16'b0000000001000000;
    wire [3:0] lut_46_select = {
                             in_data[187],
                             in_data[186],
                             in_data[185],
                             in_data[184]};
    
    wire lut_46_out = lut_46_table[lut_46_select];
    
    assign out_data[46] = lut_46_out;
    
    
    
    // LUT : 47
    wire [15:0] lut_47_table = 16'b1111111011101000;
    wire [3:0] lut_47_select = {
                             in_data[191],
                             in_data[190],
                             in_data[189],
                             in_data[188]};
    
    wire lut_47_out = lut_47_table[lut_47_select];
    
    assign out_data[47] = lut_47_out;
    
    
    
    // LUT : 48
    wire [15:0] lut_48_table = 16'b0000001100100111;
    wire [3:0] lut_48_select = {
                             in_data[195],
                             in_data[194],
                             in_data[193],
                             in_data[192]};
    
    wire lut_48_out = lut_48_table[lut_48_select];
    
    assign out_data[48] = lut_48_out;
    
    
    
    // LUT : 49
    wire [15:0] lut_49_table = 16'b0010111100101011;
    wire [3:0] lut_49_select = {
                             in_data[199],
                             in_data[198],
                             in_data[197],
                             in_data[196]};
    
    wire lut_49_out = lut_49_table[lut_49_select];
    
    assign out_data[49] = lut_49_out;
    
    
    
    // LUT : 50
    wire [15:0] lut_50_table = 16'b0011101110111111;
    wire [3:0] lut_50_select = {
                             in_data[203],
                             in_data[202],
                             in_data[201],
                             in_data[200]};
    
    wire lut_50_out = lut_50_table[lut_50_select];
    
    assign out_data[50] = lut_50_out;
    
    
    
    // LUT : 51
    wire [15:0] lut_51_table = 16'b0000001100011111;
    wire [3:0] lut_51_select = {
                             in_data[207],
                             in_data[206],
                             in_data[205],
                             in_data[204]};
    
    wire lut_51_out = lut_51_table[lut_51_select];
    
    assign out_data[51] = lut_51_out;
    
    
    
    // LUT : 52
    wire [15:0] lut_52_table = 16'b1111111010101100;
    wire [3:0] lut_52_select = {
                             in_data[211],
                             in_data[210],
                             in_data[209],
                             in_data[208]};
    
    wire lut_52_out = lut_52_table[lut_52_select];
    
    assign out_data[52] = lut_52_out;
    
    
    
    // LUT : 53
    wire [15:0] lut_53_table = 16'b0010001000000010;
    wire [3:0] lut_53_select = {
                             in_data[215],
                             in_data[214],
                             in_data[213],
                             in_data[212]};
    
    wire lut_53_out = lut_53_table[lut_53_select];
    
    assign out_data[53] = lut_53_out;
    
    
    
    // LUT : 54
    wire [15:0] lut_54_table = 16'b0101011111111111;
    wire [3:0] lut_54_select = {
                             in_data[219],
                             in_data[218],
                             in_data[217],
                             in_data[216]};
    
    wire lut_54_out = lut_54_table[lut_54_select];
    
    assign out_data[54] = lut_54_out;
    
    
    
    // LUT : 55
    wire [15:0] lut_55_table = 16'b0101011100000101;
    wire [3:0] lut_55_select = {
                             in_data[223],
                             in_data[222],
                             in_data[221],
                             in_data[220]};
    
    wire lut_55_out = lut_55_table[lut_55_select];
    
    assign out_data[55] = lut_55_out;
    
    
    
    // LUT : 56
    wire [15:0] lut_56_table = 16'b1110111100001110;
    wire [3:0] lut_56_select = {
                             in_data[227],
                             in_data[226],
                             in_data[225],
                             in_data[224]};
    
    wire lut_56_out = lut_56_table[lut_56_select];
    
    assign out_data[56] = lut_56_out;
    
    
    
    // LUT : 57
    wire [15:0] lut_57_table = 16'b0000000001001101;
    wire [3:0] lut_57_select = {
                             in_data[231],
                             in_data[230],
                             in_data[229],
                             in_data[228]};
    
    wire lut_57_out = lut_57_table[lut_57_select];
    
    assign out_data[57] = lut_57_out;
    
    
    
    // LUT : 58
    wire [15:0] lut_58_table = 16'b1011001000100000;
    wire [3:0] lut_58_select = {
                             in_data[235],
                             in_data[234],
                             in_data[233],
                             in_data[232]};
    
    wire lut_58_out = lut_58_table[lut_58_select];
    
    assign out_data[58] = lut_58_out;
    
    
    
    // LUT : 59
    wire [15:0] lut_59_table = 16'b0100110011011101;
    wire [3:0] lut_59_select = {
                             in_data[239],
                             in_data[238],
                             in_data[237],
                             in_data[236]};
    
    wire lut_59_out = lut_59_table[lut_59_select];
    
    assign out_data[59] = lut_59_out;
    
    
    
    // LUT : 60
    wire [15:0] lut_60_table = 16'b0111111100101011;
    wire [3:0] lut_60_select = {
                             in_data[243],
                             in_data[242],
                             in_data[241],
                             in_data[240]};
    
    wire lut_60_out = lut_60_table[lut_60_select];
    
    assign out_data[60] = lut_60_out;
    
    
    
    // LUT : 61
    wire [15:0] lut_61_table = 16'b0000001100010111;
    wire [3:0] lut_61_select = {
                             in_data[247],
                             in_data[246],
                             in_data[245],
                             in_data[244]};
    
    wire lut_61_out = lut_61_table[lut_61_select];
    
    assign out_data[61] = lut_61_out;
    
    
    
    // LUT : 62
    wire [15:0] lut_62_table = 16'b0000111011001111;
    wire [3:0] lut_62_select = {
                             in_data[251],
                             in_data[250],
                             in_data[249],
                             in_data[248]};
    
    wire lut_62_out = lut_62_table[lut_62_select];
    
    assign out_data[62] = lut_62_out;
    
    
    
    // LUT : 63
    wire [15:0] lut_63_table = 16'b1111111100100010;
    wire [3:0] lut_63_select = {
                             in_data[255],
                             in_data[254],
                             in_data[253],
                             in_data[252]};
    
    wire lut_63_out = lut_63_table[lut_63_select];
    
    assign out_data[63] = lut_63_out;
    
    
endmodule



module MnistLut4Simple_sub4
        #(
            parameter INIT_REG = 1'bx,
            parameter DEVICE   = "RTL"
        )
        (
            input  wire         reset,
            input  wire         clk,
            input  wire         cke,
            
            input  wire [63:0]  in_data,
            output wire [255:0]  out_data
        );
    
    
    // LUT : 0
    wire [15:0] lut_0_table = 16'b0000010111110111;
    wire [3:0] lut_0_select = {
                             in_data[32],
                             in_data[27],
                             in_data[17],
                             in_data[8]};
    
    wire lut_0_out = lut_0_table[lut_0_select];
    
    assign out_data[0] = lut_0_out;
    
    
    
    // LUT : 1
    wire [15:0] lut_1_table = 16'b0000110000001010;
    wire [3:0] lut_1_select = {
                             in_data[25],
                             in_data[51],
                             in_data[33],
                             in_data[52]};
    
    wire lut_1_out = lut_1_table[lut_1_select];
    
    assign out_data[1] = lut_1_out;
    
    
    
    // LUT : 2
    wire [15:0] lut_2_table = 16'b1011001111111011;
    wire [3:0] lut_2_select = {
                             in_data[20],
                             in_data[53],
                             in_data[14],
                             in_data[26]};
    
    wire lut_2_out = lut_2_table[lut_2_select];
    
    assign out_data[2] = lut_2_out;
    
    
    
    // LUT : 3
    wire [15:0] lut_3_table = 16'b0000000100010111;
    wire [3:0] lut_3_select = {
                             in_data[47],
                             in_data[10],
                             in_data[3],
                             in_data[24]};
    
    wire lut_3_out = lut_3_table[lut_3_select];
    
    assign out_data[3] = lut_3_out;
    
    
    
    // LUT : 4
    wire [15:0] lut_4_table = 16'b0100000011010000;
    wire [3:0] lut_4_select = {
                             in_data[44],
                             in_data[19],
                             in_data[57],
                             in_data[63]};
    
    wire lut_4_out = lut_4_table[lut_4_select];
    
    assign out_data[4] = lut_4_out;
    
    
    
    // LUT : 5
    wire [15:0] lut_5_table = 16'b0101110101010001;
    wire [3:0] lut_5_select = {
                             in_data[62],
                             in_data[21],
                             in_data[58],
                             in_data[22]};
    
    wire lut_5_out = lut_5_table[lut_5_select];
    
    assign out_data[5] = lut_5_out;
    
    
    
    // LUT : 6
    wire [15:0] lut_6_table = 16'b1101010100000000;
    wire [3:0] lut_6_select = {
                             in_data[48],
                             in_data[9],
                             in_data[7],
                             in_data[15]};
    
    wire lut_6_out = lut_6_table[lut_6_select];
    
    assign out_data[6] = lut_6_out;
    
    
    
    // LUT : 7
    wire [15:0] lut_7_table = 16'b0010101000100000;
    wire [3:0] lut_7_select = {
                             in_data[2],
                             in_data[41],
                             in_data[45],
                             in_data[31]};
    
    wire lut_7_out = lut_7_table[lut_7_select];
    
    assign out_data[7] = lut_7_out;
    
    
    
    // LUT : 8
    wire [15:0] lut_8_table = 16'b0011001110111011;
    wire [3:0] lut_8_select = {
                             in_data[0],
                             in_data[28],
                             in_data[30],
                             in_data[34]};
    
    wire lut_8_out = lut_8_table[lut_8_select];
    
    assign out_data[8] = lut_8_out;
    
    
    
    // LUT : 9
    wire [15:0] lut_9_table = 16'b1011111110101100;
    wire [3:0] lut_9_select = {
                             in_data[35],
                             in_data[40],
                             in_data[1],
                             in_data[60]};
    
    wire lut_9_out = lut_9_table[lut_9_select];
    
    assign out_data[9] = lut_9_out;
    
    
    
    // LUT : 10
    wire [15:0] lut_10_table = 16'b1011001010110000;
    wire [3:0] lut_10_select = {
                             in_data[6],
                             in_data[4],
                             in_data[18],
                             in_data[54]};
    
    wire lut_10_out = lut_10_table[lut_10_select];
    
    assign out_data[10] = lut_10_out;
    
    
    
    // LUT : 11
    wire [15:0] lut_11_table = 16'b0000111100111111;
    wire [3:0] lut_11_select = {
                             in_data[46],
                             in_data[38],
                             in_data[61],
                             in_data[42]};
    
    wire lut_11_out = lut_11_table[lut_11_select];
    
    assign out_data[11] = lut_11_out;
    
    
    
    // LUT : 12
    wire [15:0] lut_12_table = 16'b0001111101111111;
    wire [3:0] lut_12_select = {
                             in_data[39],
                             in_data[59],
                             in_data[11],
                             in_data[23]};
    
    wire lut_12_out = lut_12_table[lut_12_select];
    
    assign out_data[12] = lut_12_out;
    
    
    
    // LUT : 13
    wire [15:0] lut_13_table = 16'b1010101011111010;
    wire [3:0] lut_13_select = {
                             in_data[56],
                             in_data[5],
                             in_data[13],
                             in_data[29]};
    
    wire lut_13_out = lut_13_table[lut_13_select];
    
    assign out_data[13] = lut_13_out;
    
    
    
    // LUT : 14
    wire [15:0] lut_14_table = 16'b0000001100000010;
    wire [3:0] lut_14_select = {
                             in_data[43],
                             in_data[12],
                             in_data[49],
                             in_data[55]};
    
    wire lut_14_out = lut_14_table[lut_14_select];
    
    assign out_data[14] = lut_14_out;
    
    
    
    // LUT : 15
    wire [15:0] lut_15_table = 16'b1010001010101010;
    wire [3:0] lut_15_select = {
                             in_data[16],
                             in_data[37],
                             in_data[36],
                             in_data[50]};
    
    wire lut_15_out = lut_15_table[lut_15_select];
    
    assign out_data[15] = lut_15_out;
    
    
    
    // LUT : 16
    wire [15:0] lut_16_table = 16'b0000110011001111;
    wire [3:0] lut_16_select = {
                             in_data[11],
                             in_data[6],
                             in_data[58],
                             in_data[9]};
    
    wire lut_16_out = lut_16_table[lut_16_select];
    
    assign out_data[16] = lut_16_out;
    
    
    
    // LUT : 17
    wire [15:0] lut_17_table = 16'b1011000000110001;
    wire [3:0] lut_17_select = {
                             in_data[28],
                             in_data[27],
                             in_data[51],
                             in_data[16]};
    
    wire lut_17_out = lut_17_table[lut_17_select];
    
    assign out_data[17] = lut_17_out;
    
    
    
    // LUT : 18
    wire [15:0] lut_18_table = 16'b0010101100100011;
    wire [3:0] lut_18_select = {
                             in_data[25],
                             in_data[55],
                             in_data[10],
                             in_data[61]};
    
    wire lut_18_out = lut_18_table[lut_18_select];
    
    assign out_data[18] = lut_18_out;
    
    
    
    // LUT : 19
    wire [15:0] lut_19_table = 16'b0011011100010011;
    wire [3:0] lut_19_select = {
                             in_data[60],
                             in_data[24],
                             in_data[5],
                             in_data[45]};
    
    wire lut_19_out = lut_19_table[lut_19_select];
    
    assign out_data[19] = lut_19_out;
    
    
    
    // LUT : 20
    wire [15:0] lut_20_table = 16'b0011011100010001;
    wire [3:0] lut_20_select = {
                             in_data[2],
                             in_data[22],
                             in_data[59],
                             in_data[43]};
    
    wire lut_20_out = lut_20_table[lut_20_select];
    
    assign out_data[20] = lut_20_out;
    
    
    
    // LUT : 21
    wire [15:0] lut_21_table = 16'b0101111101010111;
    wire [3:0] lut_21_select = {
                             in_data[3],
                             in_data[32],
                             in_data[1],
                             in_data[20]};
    
    wire lut_21_out = lut_21_table[lut_21_select];
    
    assign out_data[21] = lut_21_out;
    
    
    
    // LUT : 22
    wire [15:0] lut_22_table = 16'b0000111100000100;
    wire [3:0] lut_22_select = {
                             in_data[18],
                             in_data[38],
                             in_data[21],
                             in_data[35]};
    
    wire lut_22_out = lut_22_table[lut_22_select];
    
    assign out_data[22] = lut_22_out;
    
    
    
    // LUT : 23
    wire [15:0] lut_23_table = 16'b1010101010101010;
    wire [3:0] lut_23_select = {
                             in_data[40],
                             in_data[39],
                             in_data[14],
                             in_data[30]};
    
    wire lut_23_out = lut_23_table[lut_23_select];
    
    assign out_data[23] = lut_23_out;
    
    
    
    // LUT : 24
    wire [15:0] lut_24_table = 16'b1100110011001111;
    wire [3:0] lut_24_select = {
                             in_data[52],
                             in_data[47],
                             in_data[50],
                             in_data[33]};
    
    wire lut_24_out = lut_24_table[lut_24_select];
    
    assign out_data[24] = lut_24_out;
    
    
    
    // LUT : 25
    wire [15:0] lut_25_table = 16'b1111101100100010;
    wire [3:0] lut_25_select = {
                             in_data[23],
                             in_data[13],
                             in_data[56],
                             in_data[12]};
    
    wire lut_25_out = lut_25_table[lut_25_select];
    
    assign out_data[25] = lut_25_out;
    
    
    
    // LUT : 26
    wire [15:0] lut_26_table = 16'b1111010011000100;
    wire [3:0] lut_26_select = {
                             in_data[8],
                             in_data[17],
                             in_data[41],
                             in_data[49]};
    
    wire lut_26_out = lut_26_table[lut_26_select];
    
    assign out_data[26] = lut_26_out;
    
    
    
    // LUT : 27
    wire [15:0] lut_27_table = 16'b1011000010100000;
    wire [3:0] lut_27_select = {
                             in_data[54],
                             in_data[44],
                             in_data[29],
                             in_data[4]};
    
    wire lut_27_out = lut_27_table[lut_27_select];
    
    assign out_data[27] = lut_27_out;
    
    
    
    // LUT : 28
    wire [15:0] lut_28_table = 16'b1101110011101100;
    wire [3:0] lut_28_select = {
                             in_data[57],
                             in_data[0],
                             in_data[42],
                             in_data[34]};
    
    wire lut_28_out = lut_28_table[lut_28_select];
    
    assign out_data[28] = lut_28_out;
    
    
    
    // LUT : 29
    wire [15:0] lut_29_table = 16'b0011001001010011;
    wire [3:0] lut_29_select = {
                             in_data[19],
                             in_data[48],
                             in_data[63],
                             in_data[31]};
    
    wire lut_29_out = lut_29_table[lut_29_select];
    
    assign out_data[29] = lut_29_out;
    
    
    
    // LUT : 30
    wire [15:0] lut_30_table = 16'b0011001110111011;
    wire [3:0] lut_30_select = {
                             in_data[62],
                             in_data[37],
                             in_data[7],
                             in_data[53]};
    
    wire lut_30_out = lut_30_table[lut_30_select];
    
    assign out_data[30] = lut_30_out;
    
    
    
    // LUT : 31
    wire [15:0] lut_31_table = 16'b1111111011110010;
    wire [3:0] lut_31_select = {
                             in_data[26],
                             in_data[36],
                             in_data[15],
                             in_data[46]};
    
    wire lut_31_out = lut_31_table[lut_31_select];
    
    assign out_data[31] = lut_31_out;
    
    
    
    // LUT : 32
    wire [15:0] lut_32_table = 16'b1111000000110010;
    wire [3:0] lut_32_select = {
                             in_data[58],
                             in_data[20],
                             in_data[62],
                             in_data[17]};
    
    wire lut_32_out = lut_32_table[lut_32_select];
    
    assign out_data[32] = lut_32_out;
    
    
    
    // LUT : 33
    wire [15:0] lut_33_table = 16'b1111110011000000;
    wire [3:0] lut_33_select = {
                             in_data[9],
                             in_data[47],
                             in_data[53],
                             in_data[59]};
    
    wire lut_33_out = lut_33_table[lut_33_select];
    
    assign out_data[33] = lut_33_out;
    
    
    
    // LUT : 34
    wire [15:0] lut_34_table = 16'b0010001010100010;
    wire [3:0] lut_34_select = {
                             in_data[43],
                             in_data[28],
                             in_data[15],
                             in_data[1]};
    
    wire lut_34_out = lut_34_table[lut_34_select];
    
    assign out_data[34] = lut_34_out;
    
    
    
    // LUT : 35
    wire [15:0] lut_35_table = 16'b1111111100000100;
    wire [3:0] lut_35_select = {
                             in_data[22],
                             in_data[18],
                             in_data[21],
                             in_data[27]};
    
    wire lut_35_out = lut_35_table[lut_35_select];
    
    assign out_data[35] = lut_35_out;
    
    
    
    // LUT : 36
    wire [15:0] lut_36_table = 16'b0010001100100011;
    wire [3:0] lut_36_select = {
                             in_data[49],
                             in_data[35],
                             in_data[63],
                             in_data[26]};
    
    wire lut_36_out = lut_36_table[lut_36_select];
    
    assign out_data[36] = lut_36_out;
    
    
    
    // LUT : 37
    wire [15:0] lut_37_table = 16'b0001000011110101;
    wire [3:0] lut_37_select = {
                             in_data[7],
                             in_data[32],
                             in_data[44],
                             in_data[10]};
    
    wire lut_37_out = lut_37_table[lut_37_select];
    
    assign out_data[37] = lut_37_out;
    
    
    
    // LUT : 38
    wire [15:0] lut_38_table = 16'b0001000100010111;
    wire [3:0] lut_38_select = {
                             in_data[2],
                             in_data[41],
                             in_data[12],
                             in_data[14]};
    
    wire lut_38_out = lut_38_table[lut_38_select];
    
    assign out_data[38] = lut_38_out;
    
    
    
    // LUT : 39
    wire [15:0] lut_39_table = 16'b1111001100110011;
    wire [3:0] lut_39_select = {
                             in_data[48],
                             in_data[30],
                             in_data[55],
                             in_data[61]};
    
    wire lut_39_out = lut_39_table[lut_39_select];
    
    assign out_data[39] = lut_39_out;
    
    
    
    // LUT : 40
    wire [15:0] lut_40_table = 16'b1000111100001111;
    wire [3:0] lut_40_select = {
                             in_data[11],
                             in_data[52],
                             in_data[29],
                             in_data[5]};
    
    wire lut_40_out = lut_40_table[lut_40_select];
    
    assign out_data[40] = lut_40_out;
    
    
    
    // LUT : 41
    wire [15:0] lut_41_table = 16'b0100010111110111;
    wire [3:0] lut_41_select = {
                             in_data[54],
                             in_data[56],
                             in_data[19],
                             in_data[45]};
    
    wire lut_41_out = lut_41_table[lut_41_select];
    
    assign out_data[41] = lut_41_out;
    
    
    
    // LUT : 42
    wire [15:0] lut_42_table = 16'b0101110001010100;
    wire [3:0] lut_42_select = {
                             in_data[42],
                             in_data[38],
                             in_data[34],
                             in_data[36]};
    
    wire lut_42_out = lut_42_table[lut_42_select];
    
    assign out_data[42] = lut_42_out;
    
    
    
    // LUT : 43
    wire [15:0] lut_43_table = 16'b0010010111111101;
    wire [3:0] lut_43_select = {
                             in_data[16],
                             in_data[46],
                             in_data[50],
                             in_data[23]};
    
    wire lut_43_out = lut_43_table[lut_43_select];
    
    assign out_data[43] = lut_43_out;
    
    
    
    // LUT : 44
    wire [15:0] lut_44_table = 16'b0100010100000101;
    wire [3:0] lut_44_select = {
                             in_data[3],
                             in_data[6],
                             in_data[31],
                             in_data[13]};
    
    wire lut_44_out = lut_44_table[lut_44_select];
    
    assign out_data[44] = lut_44_out;
    
    
    
    // LUT : 45
    wire [15:0] lut_45_table = 16'b0101010101111111;
    wire [3:0] lut_45_select = {
                             in_data[8],
                             in_data[4],
                             in_data[39],
                             in_data[57]};
    
    wire lut_45_out = lut_45_table[lut_45_select];
    
    assign out_data[45] = lut_45_out;
    
    
    
    // LUT : 46
    wire [15:0] lut_46_table = 16'b0000010100110111;
    wire [3:0] lut_46_select = {
                             in_data[40],
                             in_data[0],
                             in_data[51],
                             in_data[37]};
    
    wire lut_46_out = lut_46_table[lut_46_select];
    
    assign out_data[46] = lut_46_out;
    
    
    
    // LUT : 47
    wire [15:0] lut_47_table = 16'b0000100010101011;
    wire [3:0] lut_47_select = {
                             in_data[24],
                             in_data[60],
                             in_data[25],
                             in_data[33]};
    
    wire lut_47_out = lut_47_table[lut_47_select];
    
    assign out_data[47] = lut_47_out;
    
    
    
    // LUT : 48
    wire [15:0] lut_48_table = 16'b0100111100001100;
    wire [3:0] lut_48_select = {
                             in_data[18],
                             in_data[31],
                             in_data[6],
                             in_data[24]};
    
    wire lut_48_out = lut_48_table[lut_48_select];
    
    assign out_data[48] = lut_48_out;
    
    
    
    // LUT : 49
    wire [15:0] lut_49_table = 16'b1111010011010100;
    wire [3:0] lut_49_select = {
                             in_data[42],
                             in_data[40],
                             in_data[38],
                             in_data[55]};
    
    wire lut_49_out = lut_49_table[lut_49_select];
    
    assign out_data[49] = lut_49_out;
    
    
    
    // LUT : 50
    wire [15:0] lut_50_table = 16'b0101010101110111;
    wire [3:0] lut_50_select = {
                             in_data[60],
                             in_data[51],
                             in_data[5],
                             in_data[41]};
    
    wire lut_50_out = lut_50_table[lut_50_select];
    
    assign out_data[50] = lut_50_out;
    
    
    
    // LUT : 51
    wire [15:0] lut_51_table = 16'b0000001110111011;
    wire [3:0] lut_51_select = {
                             in_data[33],
                             in_data[15],
                             in_data[36],
                             in_data[14]};
    
    wire lut_51_out = lut_51_table[lut_51_select];
    
    assign out_data[51] = lut_51_out;
    
    
    
    // LUT : 52
    wire [15:0] lut_52_table = 16'b1111000011010000;
    wire [3:0] lut_52_select = {
                             in_data[17],
                             in_data[4],
                             in_data[20],
                             in_data[52]};
    
    wire lut_52_out = lut_52_table[lut_52_select];
    
    assign out_data[52] = lut_52_out;
    
    
    
    // LUT : 53
    wire [15:0] lut_53_table = 16'b1111110001000000;
    wire [3:0] lut_53_select = {
                             in_data[28],
                             in_data[58],
                             in_data[32],
                             in_data[63]};
    
    wire lut_53_out = lut_53_table[lut_53_select];
    
    assign out_data[53] = lut_53_out;
    
    
    
    // LUT : 54
    wire [15:0] lut_54_table = 16'b0111010100000000;
    wire [3:0] lut_54_select = {
                             in_data[29],
                             in_data[21],
                             in_data[25],
                             in_data[46]};
    
    wire lut_54_out = lut_54_table[lut_54_select];
    
    assign out_data[54] = lut_54_out;
    
    
    
    // LUT : 55
    wire [15:0] lut_55_table = 16'b1101111101011101;
    wire [3:0] lut_55_select = {
                             in_data[47],
                             in_data[23],
                             in_data[10],
                             in_data[59]};
    
    wire lut_55_out = lut_55_table[lut_55_select];
    
    assign out_data[55] = lut_55_out;
    
    
    
    // LUT : 56
    wire [15:0] lut_56_table = 16'b0001001100100111;
    wire [3:0] lut_56_select = {
                             in_data[37],
                             in_data[34],
                             in_data[1],
                             in_data[43]};
    
    wire lut_56_out = lut_56_table[lut_56_select];
    
    assign out_data[56] = lut_56_out;
    
    
    
    // LUT : 57
    wire [15:0] lut_57_table = 16'b0100010100000101;
    wire [3:0] lut_57_select = {
                             in_data[45],
                             in_data[26],
                             in_data[19],
                             in_data[57]};
    
    wire lut_57_out = lut_57_table[lut_57_select];
    
    assign out_data[57] = lut_57_out;
    
    
    
    // LUT : 58
    wire [15:0] lut_58_table = 16'b1110100011101010;
    wire [3:0] lut_58_select = {
                             in_data[3],
                             in_data[39],
                             in_data[48],
                             in_data[62]};
    
    wire lut_58_out = lut_58_table[lut_58_select];
    
    assign out_data[58] = lut_58_out;
    
    
    
    // LUT : 59
    wire [15:0] lut_59_table = 16'b0101010101010111;
    wire [3:0] lut_59_select = {
                             in_data[49],
                             in_data[12],
                             in_data[13],
                             in_data[54]};
    
    wire lut_59_out = lut_59_table[lut_59_select];
    
    assign out_data[59] = lut_59_out;
    
    
    
    // LUT : 60
    wire [15:0] lut_60_table = 16'b1000000011010100;
    wire [3:0] lut_60_select = {
                             in_data[35],
                             in_data[16],
                             in_data[0],
                             in_data[7]};
    
    wire lut_60_out = lut_60_table[lut_60_select];
    
    assign out_data[60] = lut_60_out;
    
    
    
    // LUT : 61
    wire [15:0] lut_61_table = 16'b0101000011110101;
    wire [3:0] lut_61_select = {
                             in_data[9],
                             in_data[50],
                             in_data[44],
                             in_data[53]};
    
    wire lut_61_out = lut_61_table[lut_61_select];
    
    assign out_data[61] = lut_61_out;
    
    
    
    // LUT : 62
    wire [15:0] lut_62_table = 16'b0101010100000100;
    wire [3:0] lut_62_select = {
                             in_data[8],
                             in_data[2],
                             in_data[56],
                             in_data[22]};
    
    wire lut_62_out = lut_62_table[lut_62_select];
    
    assign out_data[62] = lut_62_out;
    
    
    
    // LUT : 63
    wire [15:0] lut_63_table = 16'b0000000111111111;
    wire [3:0] lut_63_select = {
                             in_data[11],
                             in_data[30],
                             in_data[27],
                             in_data[61]};
    
    wire lut_63_out = lut_63_table[lut_63_select];
    
    assign out_data[63] = lut_63_out;
    
    
    
    // LUT : 64
    wire [15:0] lut_64_table = 16'b0101010101011101;
    wire [3:0] lut_64_select = {
                             in_data[50],
                             in_data[47],
                             in_data[13],
                             in_data[61]};
    
    wire lut_64_out = lut_64_table[lut_64_select];
    
    assign out_data[64] = lut_64_out;
    
    
    
    // LUT : 65
    wire [15:0] lut_65_table = 16'b1100110011001100;
    wire [3:0] lut_65_select = {
                             in_data[25],
                             in_data[63],
                             in_data[52],
                             in_data[9]};
    
    wire lut_65_out = lut_65_table[lut_65_select];
    
    assign out_data[65] = lut_65_out;
    
    
    
    // LUT : 66
    wire [15:0] lut_66_table = 16'b0011001000110011;
    wire [3:0] lut_66_select = {
                             in_data[31],
                             in_data[24],
                             in_data[29],
                             in_data[62]};
    
    wire lut_66_out = lut_66_table[lut_66_select];
    
    assign out_data[66] = lut_66_out;
    
    
    
    // LUT : 67
    wire [15:0] lut_67_table = 16'b1110000011101000;
    wire [3:0] lut_67_select = {
                             in_data[40],
                             in_data[0],
                             in_data[37],
                             in_data[5]};
    
    wire lut_67_out = lut_67_table[lut_67_select];
    
    assign out_data[67] = lut_67_out;
    
    
    
    // LUT : 68
    wire [15:0] lut_68_table = 16'b1111010111110101;
    wire [3:0] lut_68_select = {
                             in_data[55],
                             in_data[59],
                             in_data[7],
                             in_data[19]};
    
    wire lut_68_out = lut_68_table[lut_68_select];
    
    assign out_data[68] = lut_68_out;
    
    
    
    // LUT : 69
    wire [15:0] lut_69_table = 16'b1011100010110010;
    wire [3:0] lut_69_select = {
                             in_data[4],
                             in_data[22],
                             in_data[10],
                             in_data[56]};
    
    wire lut_69_out = lut_69_table[lut_69_select];
    
    assign out_data[69] = lut_69_out;
    
    
    
    // LUT : 70
    wire [15:0] lut_70_table = 16'b0111011100010101;
    wire [3:0] lut_70_select = {
                             in_data[27],
                             in_data[57],
                             in_data[3],
                             in_data[8]};
    
    wire lut_70_out = lut_70_table[lut_70_select];
    
    assign out_data[70] = lut_70_out;
    
    
    
    // LUT : 71
    wire [15:0] lut_71_table = 16'b1111110001011101;
    wire [3:0] lut_71_select = {
                             in_data[42],
                             in_data[41],
                             in_data[21],
                             in_data[33]};
    
    wire lut_71_out = lut_71_table[lut_71_select];
    
    assign out_data[71] = lut_71_out;
    
    
    
    // LUT : 72
    wire [15:0] lut_72_table = 16'b0000011100010111;
    wire [3:0] lut_72_select = {
                             in_data[45],
                             in_data[51],
                             in_data[20],
                             in_data[43]};
    
    wire lut_72_out = lut_72_table[lut_72_select];
    
    assign out_data[72] = lut_72_out;
    
    
    
    // LUT : 73
    wire [15:0] lut_73_table = 16'b0001010101010001;
    wire [3:0] lut_73_select = {
                             in_data[30],
                             in_data[18],
                             in_data[32],
                             in_data[34]};
    
    wire lut_73_out = lut_73_table[lut_73_select];
    
    assign out_data[73] = lut_73_out;
    
    
    
    // LUT : 74
    wire [15:0] lut_74_table = 16'b0010001010101011;
    wire [3:0] lut_74_select = {
                             in_data[26],
                             in_data[35],
                             in_data[44],
                             in_data[15]};
    
    wire lut_74_out = lut_74_table[lut_74_select];
    
    assign out_data[74] = lut_74_out;
    
    
    
    // LUT : 75
    wire [15:0] lut_75_table = 16'b0000000100010111;
    wire [3:0] lut_75_select = {
                             in_data[1],
                             in_data[53],
                             in_data[58],
                             in_data[17]};
    
    wire lut_75_out = lut_75_table[lut_75_select];
    
    assign out_data[75] = lut_75_out;
    
    
    
    // LUT : 76
    wire [15:0] lut_76_table = 16'b1010100010111111;
    wire [3:0] lut_76_select = {
                             in_data[38],
                             in_data[16],
                             in_data[49],
                             in_data[11]};
    
    wire lut_76_out = lut_76_table[lut_76_select];
    
    assign out_data[76] = lut_76_out;
    
    
    
    // LUT : 77
    wire [15:0] lut_77_table = 16'b1101110110001100;
    wire [3:0] lut_77_select = {
                             in_data[39],
                             in_data[28],
                             in_data[6],
                             in_data[46]};
    
    wire lut_77_out = lut_77_table[lut_77_select];
    
    assign out_data[77] = lut_77_out;
    
    
    
    // LUT : 78
    wire [15:0] lut_78_table = 16'b0011000111111111;
    wire [3:0] lut_78_select = {
                             in_data[14],
                             in_data[60],
                             in_data[23],
                             in_data[36]};
    
    wire lut_78_out = lut_78_table[lut_78_select];
    
    assign out_data[78] = lut_78_out;
    
    
    
    // LUT : 79
    wire [15:0] lut_79_table = 16'b0001000100110111;
    wire [3:0] lut_79_select = {
                             in_data[48],
                             in_data[2],
                             in_data[54],
                             in_data[12]};
    
    wire lut_79_out = lut_79_table[lut_79_select];
    
    assign out_data[79] = lut_79_out;
    
    
    
    // LUT : 80
    wire [15:0] lut_80_table = 16'b1000000011111000;
    wire [3:0] lut_80_select = {
                             in_data[13],
                             in_data[59],
                             in_data[40],
                             in_data[8]};
    
    wire lut_80_out = lut_80_table[lut_80_select];
    
    assign out_data[80] = lut_80_out;
    
    
    
    // LUT : 81
    wire [15:0] lut_81_table = 16'b0111111100001111;
    wire [3:0] lut_81_select = {
                             in_data[61],
                             in_data[38],
                             in_data[39],
                             in_data[33]};
    
    wire lut_81_out = lut_81_table[lut_81_select];
    
    assign out_data[81] = lut_81_out;
    
    
    
    // LUT : 82
    wire [15:0] lut_82_table = 16'b1000100010101000;
    wire [3:0] lut_82_select = {
                             in_data[58],
                             in_data[27],
                             in_data[60],
                             in_data[43]};
    
    wire lut_82_out = lut_82_table[lut_82_select];
    
    assign out_data[82] = lut_82_out;
    
    
    
    // LUT : 83
    wire [15:0] lut_83_table = 16'b1010100011111110;
    wire [3:0] lut_83_select = {
                             in_data[45],
                             in_data[25],
                             in_data[57],
                             in_data[36]};
    
    wire lut_83_out = lut_83_table[lut_83_select];
    
    assign out_data[83] = lut_83_out;
    
    
    
    // LUT : 84
    wire [15:0] lut_84_table = 16'b1011000010110000;
    wire [3:0] lut_84_select = {
                             in_data[41],
                             in_data[44],
                             in_data[14],
                             in_data[28]};
    
    wire lut_84_out = lut_84_table[lut_84_select];
    
    assign out_data[84] = lut_84_out;
    
    
    
    // LUT : 85
    wire [15:0] lut_85_table = 16'b0000010111111111;
    wire [3:0] lut_85_select = {
                             in_data[4],
                             in_data[26],
                             in_data[6],
                             in_data[32]};
    
    wire lut_85_out = lut_85_table[lut_85_select];
    
    assign out_data[85] = lut_85_out;
    
    
    
    // LUT : 86
    wire [15:0] lut_86_table = 16'b0101010101010111;
    wire [3:0] lut_86_select = {
                             in_data[51],
                             in_data[35],
                             in_data[50],
                             in_data[1]};
    
    wire lut_86_out = lut_86_table[lut_86_select];
    
    assign out_data[86] = lut_86_out;
    
    
    
    // LUT : 87
    wire [15:0] lut_87_table = 16'b0101010111110101;
    wire [3:0] lut_87_select = {
                             in_data[23],
                             in_data[16],
                             in_data[48],
                             in_data[30]};
    
    wire lut_87_out = lut_87_table[lut_87_select];
    
    assign out_data[87] = lut_87_out;
    
    
    
    // LUT : 88
    wire [15:0] lut_88_table = 16'b0111101100110011;
    wire [3:0] lut_88_select = {
                             in_data[7],
                             in_data[47],
                             in_data[5],
                             in_data[18]};
    
    wire lut_88_out = lut_88_table[lut_88_select];
    
    assign out_data[88] = lut_88_out;
    
    
    
    // LUT : 89
    wire [15:0] lut_89_table = 16'b1010111110001010;
    wire [3:0] lut_89_select = {
                             in_data[56],
                             in_data[49],
                             in_data[22],
                             in_data[24]};
    
    wire lut_89_out = lut_89_table[lut_89_select];
    
    assign out_data[89] = lut_89_out;
    
    
    
    // LUT : 90
    wire [15:0] lut_90_table = 16'b1110111111001000;
    wire [3:0] lut_90_select = {
                             in_data[29],
                             in_data[10],
                             in_data[37],
                             in_data[12]};
    
    wire lut_90_out = lut_90_table[lut_90_select];
    
    assign out_data[90] = lut_90_out;
    
    
    
    // LUT : 91
    wire [15:0] lut_91_table = 16'b0101000001010001;
    wire [3:0] lut_91_select = {
                             in_data[54],
                             in_data[52],
                             in_data[19],
                             in_data[53]};
    
    wire lut_91_out = lut_91_table[lut_91_select];
    
    assign out_data[91] = lut_91_out;
    
    
    
    // LUT : 92
    wire [15:0] lut_92_table = 16'b1111000011110000;
    wire [3:0] lut_92_select = {
                             in_data[62],
                             in_data[46],
                             in_data[9],
                             in_data[15]};
    
    wire lut_92_out = lut_92_table[lut_92_select];
    
    assign out_data[92] = lut_92_out;
    
    
    
    // LUT : 93
    wire [15:0] lut_93_table = 16'b1010101010101011;
    wire [3:0] lut_93_select = {
                             in_data[20],
                             in_data[21],
                             in_data[55],
                             in_data[17]};
    
    wire lut_93_out = lut_93_table[lut_93_select];
    
    assign out_data[93] = lut_93_out;
    
    
    
    // LUT : 94
    wire [15:0] lut_94_table = 16'b0001000111111011;
    wire [3:0] lut_94_select = {
                             in_data[0],
                             in_data[31],
                             in_data[34],
                             in_data[11]};
    
    wire lut_94_out = lut_94_table[lut_94_select];
    
    assign out_data[94] = lut_94_out;
    
    
    
    // LUT : 95
    wire [15:0] lut_95_table = 16'b0111000000110000;
    wire [3:0] lut_95_select = {
                             in_data[3],
                             in_data[2],
                             in_data[42],
                             in_data[63]};
    
    wire lut_95_out = lut_95_table[lut_95_select];
    
    assign out_data[95] = lut_95_out;
    
    
    
    // LUT : 96
    wire [15:0] lut_96_table = 16'b0000000000001110;
    wire [3:0] lut_96_select = {
                             in_data[29],
                             in_data[53],
                             in_data[27],
                             in_data[24]};
    
    wire lut_96_out = lut_96_table[lut_96_select];
    
    assign out_data[96] = lut_96_out;
    
    
    
    // LUT : 97
    wire [15:0] lut_97_table = 16'b1111110011100000;
    wire [3:0] lut_97_select = {
                             in_data[54],
                             in_data[5],
                             in_data[49],
                             in_data[12]};
    
    wire lut_97_out = lut_97_table[lut_97_select];
    
    assign out_data[97] = lut_97_out;
    
    
    
    // LUT : 98
    wire [15:0] lut_98_table = 16'b0100010011001101;
    wire [3:0] lut_98_select = {
                             in_data[30],
                             in_data[61],
                             in_data[56],
                             in_data[14]};
    
    wire lut_98_out = lut_98_table[lut_98_select];
    
    assign out_data[98] = lut_98_out;
    
    
    
    // LUT : 99
    wire [15:0] lut_99_table = 16'b1111000011111010;
    wire [3:0] lut_99_select = {
                             in_data[18],
                             in_data[31],
                             in_data[33],
                             in_data[2]};
    
    wire lut_99_out = lut_99_table[lut_99_select];
    
    assign out_data[99] = lut_99_out;
    
    
    
    // LUT : 100
    wire [15:0] lut_100_table = 16'b0000111000001110;
    wire [3:0] lut_100_select = {
                             in_data[20],
                             in_data[63],
                             in_data[9],
                             in_data[60]};
    
    wire lut_100_out = lut_100_table[lut_100_select];
    
    assign out_data[100] = lut_100_out;
    
    
    
    // LUT : 101
    wire [15:0] lut_101_table = 16'b0111000111110000;
    wire [3:0] lut_101_select = {
                             in_data[0],
                             in_data[48],
                             in_data[25],
                             in_data[58]};
    
    wire lut_101_out = lut_101_table[lut_101_select];
    
    assign out_data[101] = lut_101_out;
    
    
    
    // LUT : 102
    wire [15:0] lut_102_table = 16'b1101010101001101;
    wire [3:0] lut_102_select = {
                             in_data[57],
                             in_data[35],
                             in_data[7],
                             in_data[39]};
    
    wire lut_102_out = lut_102_table[lut_102_select];
    
    assign out_data[102] = lut_102_out;
    
    
    
    // LUT : 103
    wire [15:0] lut_103_table = 16'b0001000111110011;
    wire [3:0] lut_103_select = {
                             in_data[16],
                             in_data[41],
                             in_data[32],
                             in_data[1]};
    
    wire lut_103_out = lut_103_table[lut_103_select];
    
    assign out_data[103] = lut_103_out;
    
    
    
    // LUT : 104
    wire [15:0] lut_104_table = 16'b1101010101000101;
    wire [3:0] lut_104_select = {
                             in_data[42],
                             in_data[50],
                             in_data[11],
                             in_data[43]};
    
    wire lut_104_out = lut_104_table[lut_104_select];
    
    assign out_data[104] = lut_104_out;
    
    
    
    // LUT : 105
    wire [15:0] lut_105_table = 16'b1101111101000100;
    wire [3:0] lut_105_select = {
                             in_data[44],
                             in_data[13],
                             in_data[26],
                             in_data[28]};
    
    wire lut_105_out = lut_105_table[lut_105_select];
    
    assign out_data[105] = lut_105_out;
    
    
    
    // LUT : 106
    wire [15:0] lut_106_table = 16'b0001111100000000;
    wire [3:0] lut_106_select = {
                             in_data[23],
                             in_data[21],
                             in_data[36],
                             in_data[19]};
    
    wire lut_106_out = lut_106_table[lut_106_select];
    
    assign out_data[106] = lut_106_out;
    
    
    
    // LUT : 107
    wire [15:0] lut_107_table = 16'b0011001100110011;
    wire [3:0] lut_107_select = {
                             in_data[10],
                             in_data[40],
                             in_data[8],
                             in_data[45]};
    
    wire lut_107_out = lut_107_table[lut_107_select];
    
    assign out_data[107] = lut_107_out;
    
    
    
    // LUT : 108
    wire [15:0] lut_108_table = 16'b1000101010111111;
    wire [3:0] lut_108_select = {
                             in_data[52],
                             in_data[15],
                             in_data[34],
                             in_data[51]};
    
    wire lut_108_out = lut_108_table[lut_108_select];
    
    assign out_data[108] = lut_108_out;
    
    
    
    // LUT : 109
    wire [15:0] lut_109_table = 16'b0111000011111100;
    wire [3:0] lut_109_select = {
                             in_data[3],
                             in_data[59],
                             in_data[37],
                             in_data[55]};
    
    wire lut_109_out = lut_109_table[lut_109_select];
    
    assign out_data[109] = lut_109_out;
    
    
    
    // LUT : 110
    wire [15:0] lut_110_table = 16'b0101010101010001;
    wire [3:0] lut_110_select = {
                             in_data[4],
                             in_data[17],
                             in_data[47],
                             in_data[6]};
    
    wire lut_110_out = lut_110_table[lut_110_select];
    
    assign out_data[110] = lut_110_out;
    
    
    
    // LUT : 111
    wire [15:0] lut_111_table = 16'b1011001000110000;
    wire [3:0] lut_111_select = {
                             in_data[38],
                             in_data[22],
                             in_data[62],
                             in_data[46]};
    
    wire lut_111_out = lut_111_table[lut_111_select];
    
    assign out_data[111] = lut_111_out;
    
    
    
    // LUT : 112
    wire [15:0] lut_112_table = 16'b0000111000001111;
    wire [3:0] lut_112_select = {
                             in_data[15],
                             in_data[39],
                             in_data[26],
                             in_data[34]};
    
    wire lut_112_out = lut_112_table[lut_112_select];
    
    assign out_data[112] = lut_112_out;
    
    
    
    // LUT : 113
    wire [15:0] lut_113_table = 16'b0000001011110111;
    wire [3:0] lut_113_select = {
                             in_data[2],
                             in_data[49],
                             in_data[56],
                             in_data[59]};
    
    wire lut_113_out = lut_113_table[lut_113_select];
    
    assign out_data[113] = lut_113_out;
    
    
    
    // LUT : 114
    wire [15:0] lut_114_table = 16'b1111010100010001;
    wire [3:0] lut_114_select = {
                             in_data[42],
                             in_data[38],
                             in_data[24],
                             in_data[31]};
    
    wire lut_114_out = lut_114_table[lut_114_select];
    
    assign out_data[114] = lut_114_out;
    
    
    
    // LUT : 115
    wire [15:0] lut_115_table = 16'b0100111111011111;
    wire [3:0] lut_115_select = {
                             in_data[40],
                             in_data[19],
                             in_data[63],
                             in_data[17]};
    
    wire lut_115_out = lut_115_table[lut_115_select];
    
    assign out_data[115] = lut_115_out;
    
    
    
    // LUT : 116
    wire [15:0] lut_116_table = 16'b0101011100000000;
    wire [3:0] lut_116_select = {
                             in_data[18],
                             in_data[22],
                             in_data[6],
                             in_data[50]};
    
    wire lut_116_out = lut_116_table[lut_116_select];
    
    assign out_data[116] = lut_116_out;
    
    
    
    // LUT : 117
    wire [15:0] lut_117_table = 16'b0101011101001100;
    wire [3:0] lut_117_select = {
                             in_data[32],
                             in_data[53],
                             in_data[54],
                             in_data[1]};
    
    wire lut_117_out = lut_117_table[lut_117_select];
    
    assign out_data[117] = lut_117_out;
    
    
    
    // LUT : 118
    wire [15:0] lut_118_table = 16'b0011001000101010;
    wire [3:0] lut_118_select = {
                             in_data[8],
                             in_data[55],
                             in_data[62],
                             in_data[30]};
    
    wire lut_118_out = lut_118_table[lut_118_select];
    
    assign out_data[118] = lut_118_out;
    
    
    
    // LUT : 119
    wire [15:0] lut_119_table = 16'b1000111111111111;
    wire [3:0] lut_119_select = {
                             in_data[25],
                             in_data[33],
                             in_data[61],
                             in_data[58]};
    
    wire lut_119_out = lut_119_table[lut_119_select];
    
    assign out_data[119] = lut_119_out;
    
    
    
    // LUT : 120
    wire [15:0] lut_120_table = 16'b0101110001000000;
    wire [3:0] lut_120_select = {
                             in_data[37],
                             in_data[52],
                             in_data[28],
                             in_data[36]};
    
    wire lut_120_out = lut_120_table[lut_120_select];
    
    assign out_data[120] = lut_120_out;
    
    
    
    // LUT : 121
    wire [15:0] lut_121_table = 16'b1111011111110000;
    wire [3:0] lut_121_select = {
                             in_data[48],
                             in_data[46],
                             in_data[27],
                             in_data[10]};
    
    wire lut_121_out = lut_121_table[lut_121_select];
    
    assign out_data[121] = lut_121_out;
    
    
    
    // LUT : 122
    wire [15:0] lut_122_table = 16'b0011111100000111;
    wire [3:0] lut_122_select = {
                             in_data[45],
                             in_data[9],
                             in_data[57],
                             in_data[4]};
    
    wire lut_122_out = lut_122_table[lut_122_select];
    
    assign out_data[122] = lut_122_out;
    
    
    
    // LUT : 123
    wire [15:0] lut_123_table = 16'b0010111100011111;
    wire [3:0] lut_123_select = {
                             in_data[0],
                             in_data[16],
                             in_data[44],
                             in_data[5]};
    
    wire lut_123_out = lut_123_table[lut_123_select];
    
    assign out_data[123] = lut_123_out;
    
    
    
    // LUT : 124
    wire [15:0] lut_124_table = 16'b1010000010110010;
    wire [3:0] lut_124_select = {
                             in_data[35],
                             in_data[43],
                             in_data[3],
                             in_data[7]};
    
    wire lut_124_out = lut_124_table[lut_124_select];
    
    assign out_data[124] = lut_124_out;
    
    
    
    // LUT : 125
    wire [15:0] lut_125_table = 16'b1000111011101111;
    wire [3:0] lut_125_select = {
                             in_data[20],
                             in_data[21],
                             in_data[12],
                             in_data[14]};
    
    wire lut_125_out = lut_125_table[lut_125_select];
    
    assign out_data[125] = lut_125_out;
    
    
    
    // LUT : 126
    wire [15:0] lut_126_table = 16'b1100010011001100;
    wire [3:0] lut_126_select = {
                             in_data[41],
                             in_data[13],
                             in_data[23],
                             in_data[60]};
    
    wire lut_126_out = lut_126_table[lut_126_select];
    
    assign out_data[126] = lut_126_out;
    
    
    
    // LUT : 127
    wire [15:0] lut_127_table = 16'b0101010101110111;
    wire [3:0] lut_127_select = {
                             in_data[29],
                             in_data[47],
                             in_data[51],
                             in_data[11]};
    
    wire lut_127_out = lut_127_table[lut_127_select];
    
    assign out_data[127] = lut_127_out;
    
    
    
    // LUT : 128
    wire [15:0] lut_128_table = 16'b1010111100000000;
    wire [3:0] lut_128_select = {
                             in_data[47],
                             in_data[12],
                             in_data[52],
                             in_data[26]};
    
    wire lut_128_out = lut_128_table[lut_128_select];
    
    assign out_data[128] = lut_128_out;
    
    
    
    // LUT : 129
    wire [15:0] lut_129_table = 16'b1011001110111010;
    wire [3:0] lut_129_select = {
                             in_data[54],
                             in_data[2],
                             in_data[7],
                             in_data[15]};
    
    wire lut_129_out = lut_129_table[lut_129_select];
    
    assign out_data[129] = lut_129_out;
    
    
    
    // LUT : 130
    wire [15:0] lut_130_table = 16'b1111111100010101;
    wire [3:0] lut_130_select = {
                             in_data[24],
                             in_data[27],
                             in_data[0],
                             in_data[40]};
    
    wire lut_130_out = lut_130_table[lut_130_select];
    
    assign out_data[130] = lut_130_out;
    
    
    
    // LUT : 131
    wire [15:0] lut_131_table = 16'b1011101010100000;
    wire [3:0] lut_131_select = {
                             in_data[25],
                             in_data[44],
                             in_data[56],
                             in_data[53]};
    
    wire lut_131_out = lut_131_table[lut_131_select];
    
    assign out_data[131] = lut_131_out;
    
    
    
    // LUT : 132
    wire [15:0] lut_132_table = 16'b1111101011101100;
    wire [3:0] lut_132_select = {
                             in_data[6],
                             in_data[57],
                             in_data[10],
                             in_data[8]};
    
    wire lut_132_out = lut_132_table[lut_132_select];
    
    assign out_data[132] = lut_132_out;
    
    
    
    // LUT : 133
    wire [15:0] lut_133_table = 16'b1010101100001010;
    wire [3:0] lut_133_select = {
                             in_data[13],
                             in_data[36],
                             in_data[43],
                             in_data[33]};
    
    wire lut_133_out = lut_133_table[lut_133_select];
    
    assign out_data[133] = lut_133_out;
    
    
    
    // LUT : 134
    wire [15:0] lut_134_table = 16'b1000100011101110;
    wire [3:0] lut_134_select = {
                             in_data[63],
                             in_data[55],
                             in_data[46],
                             in_data[9]};
    
    wire lut_134_out = lut_134_table[lut_134_select];
    
    assign out_data[134] = lut_134_out;
    
    
    
    // LUT : 135
    wire [15:0] lut_135_table = 16'b0111111100000111;
    wire [3:0] lut_135_select = {
                             in_data[4],
                             in_data[14],
                             in_data[21],
                             in_data[39]};
    
    wire lut_135_out = lut_135_table[lut_135_select];
    
    assign out_data[135] = lut_135_out;
    
    
    
    // LUT : 136
    wire [15:0] lut_136_table = 16'b0111011000000000;
    wire [3:0] lut_136_select = {
                             in_data[18],
                             in_data[5],
                             in_data[11],
                             in_data[59]};
    
    wire lut_136_out = lut_136_table[lut_136_select];
    
    assign out_data[136] = lut_136_out;
    
    
    
    // LUT : 137
    wire [15:0] lut_137_table = 16'b1010000010101000;
    wire [3:0] lut_137_select = {
                             in_data[60],
                             in_data[45],
                             in_data[34],
                             in_data[32]};
    
    wire lut_137_out = lut_137_table[lut_137_select];
    
    assign out_data[137] = lut_137_out;
    
    
    
    // LUT : 138
    wire [15:0] lut_138_table = 16'b0010001100111111;
    wire [3:0] lut_138_select = {
                             in_data[17],
                             in_data[41],
                             in_data[31],
                             in_data[22]};
    
    wire lut_138_out = lut_138_table[lut_138_select];
    
    assign out_data[138] = lut_138_out;
    
    
    
    // LUT : 139
    wire [15:0] lut_139_table = 16'b0100000011011101;
    wire [3:0] lut_139_select = {
                             in_data[3],
                             in_data[58],
                             in_data[16],
                             in_data[51]};
    
    wire lut_139_out = lut_139_table[lut_139_select];
    
    assign out_data[139] = lut_139_out;
    
    
    
    // LUT : 140
    wire [15:0] lut_140_table = 16'b1011101100000000;
    wire [3:0] lut_140_select = {
                             in_data[1],
                             in_data[35],
                             in_data[23],
                             in_data[28]};
    
    wire lut_140_out = lut_140_table[lut_140_select];
    
    assign out_data[140] = lut_140_out;
    
    
    
    // LUT : 141
    wire [15:0] lut_141_table = 16'b0011111100011111;
    wire [3:0] lut_141_select = {
                             in_data[38],
                             in_data[37],
                             in_data[19],
                             in_data[30]};
    
    wire lut_141_out = lut_141_table[lut_141_select];
    
    assign out_data[141] = lut_141_out;
    
    
    
    // LUT : 142
    wire [15:0] lut_142_table = 16'b0100010101000101;
    wire [3:0] lut_142_select = {
                             in_data[29],
                             in_data[48],
                             in_data[62],
                             in_data[49]};
    
    wire lut_142_out = lut_142_table[lut_142_select];
    
    assign out_data[142] = lut_142_out;
    
    
    
    // LUT : 143
    wire [15:0] lut_143_table = 16'b0010101001111111;
    wire [3:0] lut_143_select = {
                             in_data[61],
                             in_data[42],
                             in_data[20],
                             in_data[50]};
    
    wire lut_143_out = lut_143_table[lut_143_select];
    
    assign out_data[143] = lut_143_out;
    
    
    
    // LUT : 144
    wire [15:0] lut_144_table = 16'b0011011101110111;
    wire [3:0] lut_144_select = {
                             in_data[55],
                             in_data[59],
                             in_data[61],
                             in_data[51]};
    
    wire lut_144_out = lut_144_table[lut_144_select];
    
    assign out_data[144] = lut_144_out;
    
    
    
    // LUT : 145
    wire [15:0] lut_145_table = 16'b1011101100110000;
    wire [3:0] lut_145_select = {
                             in_data[27],
                             in_data[43],
                             in_data[4],
                             in_data[0]};
    
    wire lut_145_out = lut_145_table[lut_145_select];
    
    assign out_data[145] = lut_145_out;
    
    
    
    // LUT : 146
    wire [15:0] lut_146_table = 16'b1110111100000101;
    wire [3:0] lut_146_select = {
                             in_data[30],
                             in_data[58],
                             in_data[41],
                             in_data[24]};
    
    wire lut_146_out = lut_146_table[lut_146_select];
    
    assign out_data[146] = lut_146_out;
    
    
    
    // LUT : 147
    wire [15:0] lut_147_table = 16'b0101010011111111;
    wire [3:0] lut_147_select = {
                             in_data[48],
                             in_data[39],
                             in_data[12],
                             in_data[6]};
    
    wire lut_147_out = lut_147_table[lut_147_select];
    
    assign out_data[147] = lut_147_out;
    
    
    
    // LUT : 148
    wire [15:0] lut_148_table = 16'b1011001111110011;
    wire [3:0] lut_148_select = {
                             in_data[13],
                             in_data[15],
                             in_data[21],
                             in_data[19]};
    
    wire lut_148_out = lut_148_table[lut_148_select];
    
    assign out_data[148] = lut_148_out;
    
    
    
    // LUT : 149
    wire [15:0] lut_149_table = 16'b1111000001110001;
    wire [3:0] lut_149_select = {
                             in_data[38],
                             in_data[52],
                             in_data[26],
                             in_data[54]};
    
    wire lut_149_out = lut_149_table[lut_149_select];
    
    assign out_data[149] = lut_149_out;
    
    
    
    // LUT : 150
    wire [15:0] lut_150_table = 16'b0010001100010011;
    wire [3:0] lut_150_select = {
                             in_data[36],
                             in_data[5],
                             in_data[46],
                             in_data[31]};
    
    wire lut_150_out = lut_150_table[lut_150_select];
    
    assign out_data[150] = lut_150_out;
    
    
    
    // LUT : 151
    wire [15:0] lut_151_table = 16'b0000000010101010;
    wire [3:0] lut_151_select = {
                             in_data[42],
                             in_data[47],
                             in_data[3],
                             in_data[8]};
    
    wire lut_151_out = lut_151_table[lut_151_select];
    
    assign out_data[151] = lut_151_out;
    
    
    
    // LUT : 152
    wire [15:0] lut_152_table = 16'b0000110011001101;
    wire [3:0] lut_152_select = {
                             in_data[44],
                             in_data[9],
                             in_data[17],
                             in_data[37]};
    
    wire lut_152_out = lut_152_table[lut_152_select];
    
    assign out_data[152] = lut_152_out;
    
    
    
    // LUT : 153
    wire [15:0] lut_153_table = 16'b1010101000000000;
    wire [3:0] lut_153_select = {
                             in_data[33],
                             in_data[7],
                             in_data[1],
                             in_data[25]};
    
    wire lut_153_out = lut_153_table[lut_153_select];
    
    assign out_data[153] = lut_153_out;
    
    
    
    // LUT : 154
    wire [15:0] lut_154_table = 16'b1011001010101010;
    wire [3:0] lut_154_select = {
                             in_data[50],
                             in_data[63],
                             in_data[28],
                             in_data[45]};
    
    wire lut_154_out = lut_154_table[lut_154_select];
    
    assign out_data[154] = lut_154_out;
    
    
    
    // LUT : 155
    wire [15:0] lut_155_table = 16'b1101010101000000;
    wire [3:0] lut_155_select = {
                             in_data[40],
                             in_data[23],
                             in_data[14],
                             in_data[53]};
    
    wire lut_155_out = lut_155_table[lut_155_select];
    
    assign out_data[155] = lut_155_out;
    
    
    
    // LUT : 156
    wire [15:0] lut_156_table = 16'b1011001000100000;
    wire [3:0] lut_156_select = {
                             in_data[49],
                             in_data[20],
                             in_data[29],
                             in_data[56]};
    
    wire lut_156_out = lut_156_table[lut_156_select];
    
    assign out_data[156] = lut_156_out;
    
    
    
    // LUT : 157
    wire [15:0] lut_157_table = 16'b0111011100010001;
    wire [3:0] lut_157_select = {
                             in_data[60],
                             in_data[34],
                             in_data[2],
                             in_data[57]};
    
    wire lut_157_out = lut_157_table[lut_157_select];
    
    assign out_data[157] = lut_157_out;
    
    
    
    // LUT : 158
    wire [15:0] lut_158_table = 16'b0011000000110000;
    wire [3:0] lut_158_select = {
                             in_data[10],
                             in_data[18],
                             in_data[62],
                             in_data[22]};
    
    wire lut_158_out = lut_158_table[lut_158_select];
    
    assign out_data[158] = lut_158_out;
    
    
    
    // LUT : 159
    wire [15:0] lut_159_table = 16'b1011111110111010;
    wire [3:0] lut_159_select = {
                             in_data[11],
                             in_data[32],
                             in_data[16],
                             in_data[35]};
    
    wire lut_159_out = lut_159_table[lut_159_select];
    
    assign out_data[159] = lut_159_out;
    
    
    
    // LUT : 160
    wire [15:0] lut_160_table = 16'b0100110001000100;
    wire [3:0] lut_160_select = {
                             in_data[22],
                             in_data[4],
                             in_data[57],
                             in_data[55]};
    
    wire lut_160_out = lut_160_table[lut_160_select];
    
    assign out_data[160] = lut_160_out;
    
    
    
    // LUT : 161
    wire [15:0] lut_161_table = 16'b1111010101110101;
    wire [3:0] lut_161_select = {
                             in_data[27],
                             in_data[2],
                             in_data[17],
                             in_data[52]};
    
    wire lut_161_out = lut_161_table[lut_161_select];
    
    assign out_data[161] = lut_161_out;
    
    
    
    // LUT : 162
    wire [15:0] lut_162_table = 16'b0000000011101101;
    wire [3:0] lut_162_select = {
                             in_data[29],
                             in_data[42],
                             in_data[7],
                             in_data[40]};
    
    wire lut_162_out = lut_162_table[lut_162_select];
    
    assign out_data[162] = lut_162_out;
    
    
    
    // LUT : 163
    wire [15:0] lut_163_table = 16'b1111111110101010;
    wire [3:0] lut_163_select = {
                             in_data[0],
                             in_data[14],
                             in_data[37],
                             in_data[15]};
    
    wire lut_163_out = lut_163_table[lut_163_select];
    
    assign out_data[163] = lut_163_out;
    
    
    
    // LUT : 164
    wire [15:0] lut_164_table = 16'b0100010111111100;
    wire [3:0] lut_164_select = {
                             in_data[36],
                             in_data[48],
                             in_data[51],
                             in_data[24]};
    
    wire lut_164_out = lut_164_table[lut_164_select];
    
    assign out_data[164] = lut_164_out;
    
    
    
    // LUT : 165
    wire [15:0] lut_165_table = 16'b1100000011111111;
    wire [3:0] lut_165_select = {
                             in_data[21],
                             in_data[45],
                             in_data[34],
                             in_data[61]};
    
    wire lut_165_out = lut_165_table[lut_165_select];
    
    assign out_data[165] = lut_165_out;
    
    
    
    // LUT : 166
    wire [15:0] lut_166_table = 16'b1011101110101111;
    wire [3:0] lut_166_select = {
                             in_data[26],
                             in_data[23],
                             in_data[43],
                             in_data[10]};
    
    wire lut_166_out = lut_166_table[lut_166_select];
    
    assign out_data[166] = lut_166_out;
    
    
    
    // LUT : 167
    wire [15:0] lut_167_table = 16'b0011000000010001;
    wire [3:0] lut_167_select = {
                             in_data[38],
                             in_data[28],
                             in_data[62],
                             in_data[53]};
    
    wire lut_167_out = lut_167_table[lut_167_select];
    
    assign out_data[167] = lut_167_out;
    
    
    
    // LUT : 168
    wire [15:0] lut_168_table = 16'b1110100011111111;
    wire [3:0] lut_168_select = {
                             in_data[19],
                             in_data[30],
                             in_data[13],
                             in_data[39]};
    
    wire lut_168_out = lut_168_table[lut_168_select];
    
    assign out_data[168] = lut_168_out;
    
    
    
    // LUT : 169
    wire [15:0] lut_169_table = 16'b1010101100001110;
    wire [3:0] lut_169_select = {
                             in_data[32],
                             in_data[63],
                             in_data[6],
                             in_data[60]};
    
    wire lut_169_out = lut_169_table[lut_169_select];
    
    assign out_data[169] = lut_169_out;
    
    
    
    // LUT : 170
    wire [15:0] lut_170_table = 16'b1110101000000000;
    wire [3:0] lut_170_select = {
                             in_data[41],
                             in_data[5],
                             in_data[1],
                             in_data[47]};
    
    wire lut_170_out = lut_170_table[lut_170_select];
    
    assign out_data[170] = lut_170_out;
    
    
    
    // LUT : 171
    wire [15:0] lut_171_table = 16'b1011001010111000;
    wire [3:0] lut_171_select = {
                             in_data[59],
                             in_data[16],
                             in_data[56],
                             in_data[9]};
    
    wire lut_171_out = lut_171_table[lut_171_select];
    
    assign out_data[171] = lut_171_out;
    
    
    
    // LUT : 172
    wire [15:0] lut_172_table = 16'b0100110011111111;
    wire [3:0] lut_172_select = {
                             in_data[18],
                             in_data[54],
                             in_data[25],
                             in_data[58]};
    
    wire lut_172_out = lut_172_table[lut_172_select];
    
    assign out_data[172] = lut_172_out;
    
    
    
    // LUT : 173
    wire [15:0] lut_173_table = 16'b0010001011101111;
    wire [3:0] lut_173_select = {
                             in_data[31],
                             in_data[3],
                             in_data[11],
                             in_data[44]};
    
    wire lut_173_out = lut_173_table[lut_173_select];
    
    assign out_data[173] = lut_173_out;
    
    
    
    // LUT : 174
    wire [15:0] lut_174_table = 16'b0111000000010000;
    wire [3:0] lut_174_select = {
                             in_data[50],
                             in_data[20],
                             in_data[12],
                             in_data[35]};
    
    wire lut_174_out = lut_174_table[lut_174_select];
    
    assign out_data[174] = lut_174_out;
    
    
    
    // LUT : 175
    wire [15:0] lut_175_table = 16'b0000000011111111;
    wire [3:0] lut_175_select = {
                             in_data[49],
                             in_data[33],
                             in_data[8],
                             in_data[46]};
    
    wire lut_175_out = lut_175_table[lut_175_select];
    
    assign out_data[175] = lut_175_out;
    
    
    
    // LUT : 176
    wire [15:0] lut_176_table = 16'b1011101100011111;
    wire [3:0] lut_176_select = {
                             in_data[10],
                             in_data[55],
                             in_data[63],
                             in_data[19]};
    
    wire lut_176_out = lut_176_table[lut_176_select];
    
    assign out_data[176] = lut_176_out;
    
    
    
    // LUT : 177
    wire [15:0] lut_177_table = 16'b1101100001011101;
    wire [3:0] lut_177_select = {
                             in_data[13],
                             in_data[36],
                             in_data[30],
                             in_data[61]};
    
    wire lut_177_out = lut_177_table[lut_177_select];
    
    assign out_data[177] = lut_177_out;
    
    
    
    // LUT : 178
    wire [15:0] lut_178_table = 16'b1111111100000000;
    wire [3:0] lut_178_select = {
                             in_data[6],
                             in_data[8],
                             in_data[40],
                             in_data[50]};
    
    wire lut_178_out = lut_178_table[lut_178_select];
    
    assign out_data[178] = lut_178_out;
    
    
    
    // LUT : 179
    wire [15:0] lut_179_table = 16'b1101110111001110;
    wire [3:0] lut_179_select = {
                             in_data[47],
                             in_data[44],
                             in_data[15],
                             in_data[1]};
    
    wire lut_179_out = lut_179_table[lut_179_select];
    
    assign out_data[179] = lut_179_out;
    
    
    
    // LUT : 180
    wire [15:0] lut_180_table = 16'b0100000011111100;
    wire [3:0] lut_180_select = {
                             in_data[27],
                             in_data[14],
                             in_data[16],
                             in_data[53]};
    
    wire lut_180_out = lut_180_table[lut_180_select];
    
    assign out_data[180] = lut_180_out;
    
    
    
    // LUT : 181
    wire [15:0] lut_181_table = 16'b1100111100000101;
    wire [3:0] lut_181_select = {
                             in_data[59],
                             in_data[17],
                             in_data[4],
                             in_data[11]};
    
    wire lut_181_out = lut_181_table[lut_181_select];
    
    assign out_data[181] = lut_181_out;
    
    
    
    // LUT : 182
    wire [15:0] lut_182_table = 16'b1110111110001010;
    wire [3:0] lut_182_select = {
                             in_data[62],
                             in_data[49],
                             in_data[43],
                             in_data[51]};
    
    wire lut_182_out = lut_182_table[lut_182_select];
    
    assign out_data[182] = lut_182_out;
    
    
    
    // LUT : 183
    wire [15:0] lut_183_table = 16'b0010000000110011;
    wire [3:0] lut_183_select = {
                             in_data[57],
                             in_data[3],
                             in_data[34],
                             in_data[28]};
    
    wire lut_183_out = lut_183_table[lut_183_select];
    
    assign out_data[183] = lut_183_out;
    
    
    
    // LUT : 184
    wire [15:0] lut_184_table = 16'b1111110011111110;
    wire [3:0] lut_184_select = {
                             in_data[54],
                             in_data[46],
                             in_data[42],
                             in_data[52]};
    
    wire lut_184_out = lut_184_table[lut_184_select];
    
    assign out_data[184] = lut_184_out;
    
    
    
    // LUT : 185
    wire [15:0] lut_185_table = 16'b0101010001010001;
    wire [3:0] lut_185_select = {
                             in_data[22],
                             in_data[38],
                             in_data[24],
                             in_data[2]};
    
    wire lut_185_out = lut_185_table[lut_185_select];
    
    assign out_data[185] = lut_185_out;
    
    
    
    // LUT : 186
    wire [15:0] lut_186_table = 16'b0010001000000010;
    wire [3:0] lut_186_select = {
                             in_data[9],
                             in_data[0],
                             in_data[7],
                             in_data[18]};
    
    wire lut_186_out = lut_186_table[lut_186_select];
    
    assign out_data[186] = lut_186_out;
    
    
    
    // LUT : 187
    wire [15:0] lut_187_table = 16'b1111100011111010;
    wire [3:0] lut_187_select = {
                             in_data[21],
                             in_data[48],
                             in_data[20],
                             in_data[37]};
    
    wire lut_187_out = lut_187_table[lut_187_select];
    
    assign out_data[187] = lut_187_out;
    
    
    
    // LUT : 188
    wire [15:0] lut_188_table = 16'b0101010101010100;
    wire [3:0] lut_188_select = {
                             in_data[60],
                             in_data[31],
                             in_data[29],
                             in_data[56]};
    
    wire lut_188_out = lut_188_table[lut_188_select];
    
    assign out_data[188] = lut_188_out;
    
    
    
    // LUT : 189
    wire [15:0] lut_189_table = 16'b0001000101010101;
    wire [3:0] lut_189_select = {
                             in_data[12],
                             in_data[23],
                             in_data[5],
                             in_data[35]};
    
    wire lut_189_out = lut_189_table[lut_189_select];
    
    assign out_data[189] = lut_189_out;
    
    
    
    // LUT : 190
    wire [15:0] lut_190_table = 16'b1101010101000100;
    wire [3:0] lut_190_select = {
                             in_data[25],
                             in_data[33],
                             in_data[39],
                             in_data[32]};
    
    wire lut_190_out = lut_190_table[lut_190_select];
    
    assign out_data[190] = lut_190_out;
    
    
    
    // LUT : 191
    wire [15:0] lut_191_table = 16'b1010010011110011;
    wire [3:0] lut_191_select = {
                             in_data[41],
                             in_data[58],
                             in_data[45],
                             in_data[26]};
    
    wire lut_191_out = lut_191_table[lut_191_select];
    
    assign out_data[191] = lut_191_out;
    
    
    
    // LUT : 192
    wire [15:0] lut_192_table = 16'b0000000011101110;
    wire [3:0] lut_192_select = {
                             in_data[11],
                             in_data[55],
                             in_data[7],
                             in_data[37]};
    
    wire lut_192_out = lut_192_table[lut_192_select];
    
    assign out_data[192] = lut_192_out;
    
    
    
    // LUT : 193
    wire [15:0] lut_193_table = 16'b1100110011111111;
    wire [3:0] lut_193_select = {
                             in_data[57],
                             in_data[63],
                             in_data[22],
                             in_data[35]};
    
    wire lut_193_out = lut_193_table[lut_193_select];
    
    assign out_data[193] = lut_193_out;
    
    
    
    // LUT : 194
    wire [15:0] lut_194_table = 16'b0101110111001101;
    wire [3:0] lut_194_select = {
                             in_data[51],
                             in_data[38],
                             in_data[30],
                             in_data[24]};
    
    wire lut_194_out = lut_194_table[lut_194_select];
    
    assign out_data[194] = lut_194_out;
    
    
    
    // LUT : 195
    wire [15:0] lut_195_table = 16'b1000111010001111;
    wire [3:0] lut_195_select = {
                             in_data[41],
                             in_data[31],
                             in_data[56],
                             in_data[9]};
    
    wire lut_195_out = lut_195_table[lut_195_select];
    
    assign out_data[195] = lut_195_out;
    
    
    
    // LUT : 196
    wire [15:0] lut_196_table = 16'b0101000011010100;
    wire [3:0] lut_196_select = {
                             in_data[23],
                             in_data[8],
                             in_data[20],
                             in_data[61]};
    
    wire lut_196_out = lut_196_table[lut_196_select];
    
    assign out_data[196] = lut_196_out;
    
    
    
    // LUT : 197
    wire [15:0] lut_197_table = 16'b1110110000100000;
    wire [3:0] lut_197_select = {
                             in_data[53],
                             in_data[19],
                             in_data[16],
                             in_data[17]};
    
    wire lut_197_out = lut_197_table[lut_197_select];
    
    assign out_data[197] = lut_197_out;
    
    
    
    // LUT : 198
    wire [15:0] lut_198_table = 16'b1000000011111101;
    wire [3:0] lut_198_select = {
                             in_data[43],
                             in_data[3],
                             in_data[52],
                             in_data[46]};
    
    wire lut_198_out = lut_198_table[lut_198_select];
    
    assign out_data[198] = lut_198_out;
    
    
    
    // LUT : 199
    wire [15:0] lut_199_table = 16'b1111000011110001;
    wire [3:0] lut_199_select = {
                             in_data[28],
                             in_data[5],
                             in_data[0],
                             in_data[60]};
    
    wire lut_199_out = lut_199_table[lut_199_select];
    
    assign out_data[199] = lut_199_out;
    
    
    
    // LUT : 200
    wire [15:0] lut_200_table = 16'b1100110100000100;
    wire [3:0] lut_200_select = {
                             in_data[40],
                             in_data[15],
                             in_data[59],
                             in_data[62]};
    
    wire lut_200_out = lut_200_table[lut_200_select];
    
    assign out_data[200] = lut_200_out;
    
    
    
    // LUT : 201
    wire [15:0] lut_201_table = 16'b1111001100110000;
    wire [3:0] lut_201_select = {
                             in_data[50],
                             in_data[13],
                             in_data[10],
                             in_data[21]};
    
    wire lut_201_out = lut_201_table[lut_201_select];
    
    assign out_data[201] = lut_201_out;
    
    
    
    // LUT : 202
    wire [15:0] lut_202_table = 16'b0000001000110011;
    wire [3:0] lut_202_select = {
                             in_data[29],
                             in_data[26],
                             in_data[36],
                             in_data[39]};
    
    wire lut_202_out = lut_202_table[lut_202_select];
    
    assign out_data[202] = lut_202_out;
    
    
    
    // LUT : 203
    wire [15:0] lut_203_table = 16'b0010101100100010;
    wire [3:0] lut_203_select = {
                             in_data[27],
                             in_data[1],
                             in_data[42],
                             in_data[54]};
    
    wire lut_203_out = lut_203_table[lut_203_select];
    
    assign out_data[203] = lut_203_out;
    
    
    
    // LUT : 204
    wire [15:0] lut_204_table = 16'b0111011101011111;
    wire [3:0] lut_204_select = {
                             in_data[18],
                             in_data[58],
                             in_data[6],
                             in_data[48]};
    
    wire lut_204_out = lut_204_table[lut_204_select];
    
    assign out_data[204] = lut_204_out;
    
    
    
    // LUT : 205
    wire [15:0] lut_205_table = 16'b1000000011101111;
    wire [3:0] lut_205_select = {
                             in_data[4],
                             in_data[14],
                             in_data[45],
                             in_data[25]};
    
    wire lut_205_out = lut_205_table[lut_205_select];
    
    assign out_data[205] = lut_205_out;
    
    
    
    // LUT : 206
    wire [15:0] lut_206_table = 16'b1011000100010001;
    wire [3:0] lut_206_select = {
                             in_data[2],
                             in_data[33],
                             in_data[44],
                             in_data[12]};
    
    wire lut_206_out = lut_206_table[lut_206_select];
    
    assign out_data[206] = lut_206_out;
    
    
    
    // LUT : 207
    wire [15:0] lut_207_table = 16'b0111011100010001;
    wire [3:0] lut_207_select = {
                             in_data[49],
                             in_data[47],
                             in_data[34],
                             in_data[32]};
    
    wire lut_207_out = lut_207_table[lut_207_select];
    
    assign out_data[207] = lut_207_out;
    
    
    
    // LUT : 208
    wire [15:0] lut_208_table = 16'b1111101000000000;
    wire [3:0] lut_208_select = {
                             in_data[58],
                             in_data[28],
                             in_data[16],
                             in_data[60]};
    
    wire lut_208_out = lut_208_table[lut_208_select];
    
    assign out_data[208] = lut_208_out;
    
    
    
    // LUT : 209
    wire [15:0] lut_209_table = 16'b0101111101010100;
    wire [3:0] lut_209_select = {
                             in_data[13],
                             in_data[26],
                             in_data[37],
                             in_data[56]};
    
    wire lut_209_out = lut_209_table[lut_209_select];
    
    assign out_data[209] = lut_209_out;
    
    
    
    // LUT : 210
    wire [15:0] lut_210_table = 16'b1110111100000110;
    wire [3:0] lut_210_select = {
                             in_data[20],
                             in_data[23],
                             in_data[33],
                             in_data[3]};
    
    wire lut_210_out = lut_210_table[lut_210_select];
    
    assign out_data[210] = lut_210_out;
    
    
    
    // LUT : 211
    wire [15:0] lut_211_table = 16'b0010000010110000;
    wire [3:0] lut_211_select = {
                             in_data[35],
                             in_data[34],
                             in_data[63],
                             in_data[19]};
    
    wire lut_211_out = lut_211_table[lut_211_select];
    
    assign out_data[211] = lut_211_out;
    
    
    
    // LUT : 212
    wire [15:0] lut_212_table = 16'b1000111011110111;
    wire [3:0] lut_212_select = {
                             in_data[4],
                             in_data[21],
                             in_data[12],
                             in_data[47]};
    
    wire lut_212_out = lut_212_table[lut_212_select];
    
    assign out_data[212] = lut_212_out;
    
    
    
    // LUT : 213
    wire [15:0] lut_213_table = 16'b0000111111001111;
    wire [3:0] lut_213_select = {
                             in_data[27],
                             in_data[18],
                             in_data[8],
                             in_data[11]};
    
    wire lut_213_out = lut_213_table[lut_213_select];
    
    assign out_data[213] = lut_213_out;
    
    
    
    // LUT : 214
    wire [15:0] lut_214_table = 16'b0000001000101011;
    wire [3:0] lut_214_select = {
                             in_data[24],
                             in_data[59],
                             in_data[2],
                             in_data[30]};
    
    wire lut_214_out = lut_214_table[lut_214_select];
    
    assign out_data[214] = lut_214_out;
    
    
    
    // LUT : 215
    wire [15:0] lut_215_table = 16'b0101010011111101;
    wire [3:0] lut_215_select = {
                             in_data[41],
                             in_data[46],
                             in_data[15],
                             in_data[54]};
    
    wire lut_215_out = lut_215_table[lut_215_select];
    
    assign out_data[215] = lut_215_out;
    
    
    
    // LUT : 216
    wire [15:0] lut_216_table = 16'b1101010001001101;
    wire [3:0] lut_216_select = {
                             in_data[38],
                             in_data[39],
                             in_data[5],
                             in_data[50]};
    
    wire lut_216_out = lut_216_table[lut_216_select];
    
    assign out_data[216] = lut_216_out;
    
    
    
    // LUT : 217
    wire [15:0] lut_217_table = 16'b1000101011101110;
    wire [3:0] lut_217_select = {
                             in_data[25],
                             in_data[42],
                             in_data[0],
                             in_data[29]};
    
    wire lut_217_out = lut_217_table[lut_217_select];
    
    assign out_data[217] = lut_217_out;
    
    
    
    // LUT : 218
    wire [15:0] lut_218_table = 16'b1100110011001000;
    wire [3:0] lut_218_select = {
                             in_data[62],
                             in_data[53],
                             in_data[52],
                             in_data[49]};
    
    wire lut_218_out = lut_218_table[lut_218_select];
    
    assign out_data[218] = lut_218_out;
    
    
    
    // LUT : 219
    wire [15:0] lut_219_table = 16'b0000000011101110;
    wire [3:0] lut_219_select = {
                             in_data[48],
                             in_data[44],
                             in_data[57],
                             in_data[43]};
    
    wire lut_219_out = lut_219_table[lut_219_select];
    
    assign out_data[219] = lut_219_out;
    
    
    
    // LUT : 220
    wire [15:0] lut_220_table = 16'b0011100101111100;
    wire [3:0] lut_220_select = {
                             in_data[22],
                             in_data[17],
                             in_data[6],
                             in_data[7]};
    
    wire lut_220_out = lut_220_table[lut_220_select];
    
    assign out_data[220] = lut_220_out;
    
    
    
    // LUT : 221
    wire [15:0] lut_221_table = 16'b0000010111001101;
    wire [3:0] lut_221_select = {
                             in_data[51],
                             in_data[31],
                             in_data[9],
                             in_data[10]};
    
    wire lut_221_out = lut_221_table[lut_221_select];
    
    assign out_data[221] = lut_221_out;
    
    
    
    // LUT : 222
    wire [15:0] lut_222_table = 16'b0100110001000101;
    wire [3:0] lut_222_select = {
                             in_data[61],
                             in_data[1],
                             in_data[55],
                             in_data[40]};
    
    wire lut_222_out = lut_222_table[lut_222_select];
    
    assign out_data[222] = lut_222_out;
    
    
    
    // LUT : 223
    wire [15:0] lut_223_table = 16'b0001111100011111;
    wire [3:0] lut_223_select = {
                             in_data[45],
                             in_data[36],
                             in_data[14],
                             in_data[32]};
    
    wire lut_223_out = lut_223_table[lut_223_select];
    
    assign out_data[223] = lut_223_out;
    
    
    
    // LUT : 224
    wire [15:0] lut_224_table = 16'b0101000101010000;
    wire [3:0] lut_224_select = {
                             in_data[47],
                             in_data[49],
                             in_data[52],
                             in_data[2]};
    
    wire lut_224_out = lut_224_table[lut_224_select];
    
    assign out_data[224] = lut_224_out;
    
    
    
    // LUT : 225
    wire [15:0] lut_225_table = 16'b1100110001001000;
    wire [3:0] lut_225_select = {
                             in_data[19],
                             in_data[0],
                             in_data[17],
                             in_data[50]};
    
    wire lut_225_out = lut_225_table[lut_225_select];
    
    assign out_data[225] = lut_225_out;
    
    
    
    // LUT : 226
    wire [15:0] lut_226_table = 16'b0000000011110000;
    wire [3:0] lut_226_select = {
                             in_data[39],
                             in_data[8],
                             in_data[45],
                             in_data[42]};
    
    wire lut_226_out = lut_226_table[lut_226_select];
    
    assign out_data[226] = lut_226_out;
    
    
    
    // LUT : 227
    wire [15:0] lut_227_table = 16'b1000110110101111;
    wire [3:0] lut_227_select = {
                             in_data[32],
                             in_data[33],
                             in_data[36],
                             in_data[55]};
    
    wire lut_227_out = lut_227_table[lut_227_select];
    
    assign out_data[227] = lut_227_out;
    
    
    
    // LUT : 228
    wire [15:0] lut_228_table = 16'b0111001101110111;
    wire [3:0] lut_228_select = {
                             in_data[51],
                             in_data[5],
                             in_data[31],
                             in_data[20]};
    
    wire lut_228_out = lut_228_table[lut_228_select];
    
    assign out_data[228] = lut_228_out;
    
    
    
    // LUT : 229
    wire [15:0] lut_229_table = 16'b0011000111111111;
    wire [3:0] lut_229_select = {
                             in_data[37],
                             in_data[35],
                             in_data[28],
                             in_data[27]};
    
    wire lut_229_out = lut_229_table[lut_229_select];
    
    assign out_data[229] = lut_229_out;
    
    
    
    // LUT : 230
    wire [15:0] lut_230_table = 16'b0100110001001100;
    wire [3:0] lut_230_select = {
                             in_data[44],
                             in_data[59],
                             in_data[9],
                             in_data[11]};
    
    wire lut_230_out = lut_230_table[lut_230_select];
    
    assign out_data[230] = lut_230_out;
    
    
    
    // LUT : 231
    wire [15:0] lut_231_table = 16'b1010111000001110;
    wire [3:0] lut_231_select = {
                             in_data[13],
                             in_data[46],
                             in_data[12],
                             in_data[21]};
    
    wire lut_231_out = lut_231_table[lut_231_select];
    
    assign out_data[231] = lut_231_out;
    
    
    
    // LUT : 232
    wire [15:0] lut_232_table = 16'b1010111000101110;
    wire [3:0] lut_232_select = {
                             in_data[60],
                             in_data[18],
                             in_data[40],
                             in_data[54]};
    
    wire lut_232_out = lut_232_table[lut_232_select];
    
    assign out_data[232] = lut_232_out;
    
    
    
    // LUT : 233
    wire [15:0] lut_233_table = 16'b0000101010101000;
    wire [3:0] lut_233_select = {
                             in_data[6],
                             in_data[34],
                             in_data[57],
                             in_data[38]};
    
    wire lut_233_out = lut_233_table[lut_233_select];
    
    assign out_data[233] = lut_233_out;
    
    
    
    // LUT : 234
    wire [15:0] lut_234_table = 16'b1111000011100010;
    wire [3:0] lut_234_select = {
                             in_data[3],
                             in_data[43],
                             in_data[29],
                             in_data[26]};
    
    wire lut_234_out = lut_234_table[lut_234_select];
    
    assign out_data[234] = lut_234_out;
    
    
    
    // LUT : 235
    wire [15:0] lut_235_table = 16'b1101010110001100;
    wire [3:0] lut_235_select = {
                             in_data[14],
                             in_data[56],
                             in_data[25],
                             in_data[63]};
    
    wire lut_235_out = lut_235_table[lut_235_select];
    
    assign out_data[235] = lut_235_out;
    
    
    
    // LUT : 236
    wire [15:0] lut_236_table = 16'b1000100010001111;
    wire [3:0] lut_236_select = {
                             in_data[30],
                             in_data[22],
                             in_data[24],
                             in_data[16]};
    
    wire lut_236_out = lut_236_table[lut_236_select];
    
    assign out_data[236] = lut_236_out;
    
    
    
    // LUT : 237
    wire [15:0] lut_237_table = 16'b1111100000000000;
    wire [3:0] lut_237_select = {
                             in_data[61],
                             in_data[23],
                             in_data[4],
                             in_data[7]};
    
    wire lut_237_out = lut_237_table[lut_237_select];
    
    assign out_data[237] = lut_237_out;
    
    
    
    // LUT : 238
    wire [15:0] lut_238_table = 16'b0101110110001111;
    wire [3:0] lut_238_select = {
                             in_data[58],
                             in_data[15],
                             in_data[1],
                             in_data[10]};
    
    wire lut_238_out = lut_238_table[lut_238_select];
    
    assign out_data[238] = lut_238_out;
    
    
    
    // LUT : 239
    wire [15:0] lut_239_table = 16'b0001011100000001;
    wire [3:0] lut_239_select = {
                             in_data[41],
                             in_data[48],
                             in_data[62],
                             in_data[53]};
    
    wire lut_239_out = lut_239_table[lut_239_select];
    
    assign out_data[239] = lut_239_out;
    
    
    
    // LUT : 240
    wire [15:0] lut_240_table = 16'b0000000100001011;
    wire [3:0] lut_240_select = {
                             in_data[58],
                             in_data[46],
                             in_data[50],
                             in_data[5]};
    
    wire lut_240_out = lut_240_table[lut_240_select];
    
    assign out_data[240] = lut_240_out;
    
    
    
    // LUT : 241
    wire [15:0] lut_241_table = 16'b1011111100010011;
    wire [3:0] lut_241_select = {
                             in_data[1],
                             in_data[14],
                             in_data[38],
                             in_data[20]};
    
    wire lut_241_out = lut_241_table[lut_241_select];
    
    assign out_data[241] = lut_241_out;
    
    
    
    // LUT : 242
    wire [15:0] lut_242_table = 16'b1011101010100000;
    wire [3:0] lut_242_select = {
                             in_data[27],
                             in_data[36],
                             in_data[52],
                             in_data[31]};
    
    wire lut_242_out = lut_242_table[lut_242_select];
    
    assign out_data[242] = lut_242_out;
    
    
    
    // LUT : 243
    wire [15:0] lut_243_table = 16'b1100000011110101;
    wire [3:0] lut_243_select = {
                             in_data[59],
                             in_data[6],
                             in_data[9],
                             in_data[60]};
    
    wire lut_243_out = lut_243_table[lut_243_select];
    
    assign out_data[243] = lut_243_out;
    
    
    
    // LUT : 244
    wire [15:0] lut_244_table = 16'b1000001000001110;
    wire [3:0] lut_244_select = {
                             in_data[53],
                             in_data[13],
                             in_data[2],
                             in_data[40]};
    
    wire lut_244_out = lut_244_table[lut_244_select];
    
    assign out_data[244] = lut_244_out;
    
    
    
    // LUT : 245
    wire [15:0] lut_245_table = 16'b1111111110101000;
    wire [3:0] lut_245_select = {
                             in_data[10],
                             in_data[43],
                             in_data[16],
                             in_data[33]};
    
    wire lut_245_out = lut_245_table[lut_245_select];
    
    assign out_data[245] = lut_245_out;
    
    
    
    // LUT : 246
    wire [15:0] lut_246_table = 16'b1010110000101110;
    wire [3:0] lut_246_select = {
                             in_data[41],
                             in_data[54],
                             in_data[30],
                             in_data[0]};
    
    wire lut_246_out = lut_246_table[lut_246_select];
    
    assign out_data[246] = lut_246_out;
    
    
    
    // LUT : 247
    wire [15:0] lut_247_table = 16'b1000100010001000;
    wire [3:0] lut_247_select = {
                             in_data[24],
                             in_data[4],
                             in_data[25],
                             in_data[8]};
    
    wire lut_247_out = lut_247_table[lut_247_select];
    
    assign out_data[247] = lut_247_out;
    
    
    
    // LUT : 248
    wire [15:0] lut_248_table = 16'b0000000100010111;
    wire [3:0] lut_248_select = {
                             in_data[57],
                             in_data[62],
                             in_data[63],
                             in_data[51]};
    
    wire lut_248_out = lut_248_table[lut_248_select];
    
    assign out_data[248] = lut_248_out;
    
    
    
    // LUT : 249
    wire [15:0] lut_249_table = 16'b0111000001110001;
    wire [3:0] lut_249_select = {
                             in_data[37],
                             in_data[7],
                             in_data[23],
                             in_data[35]};
    
    wire lut_249_out = lut_249_table[lut_249_select];
    
    assign out_data[249] = lut_249_out;
    
    
    
    // LUT : 250
    wire [15:0] lut_250_table = 16'b1111000000000000;
    wire [3:0] lut_250_select = {
                             in_data[47],
                             in_data[3],
                             in_data[56],
                             in_data[55]};
    
    wire lut_250_out = lut_250_table[lut_250_select];
    
    assign out_data[250] = lut_250_out;
    
    
    
    // LUT : 251
    wire [15:0] lut_251_table = 16'b0101000000110000;
    wire [3:0] lut_251_select = {
                             in_data[42],
                             in_data[21],
                             in_data[34],
                             in_data[22]};
    
    wire lut_251_out = lut_251_table[lut_251_select];
    
    assign out_data[251] = lut_251_out;
    
    
    
    // LUT : 252
    wire [15:0] lut_252_table = 16'b1111111111001100;
    wire [3:0] lut_252_select = {
                             in_data[15],
                             in_data[28],
                             in_data[12],
                             in_data[49]};
    
    wire lut_252_out = lut_252_table[lut_252_select];
    
    assign out_data[252] = lut_252_out;
    
    
    
    // LUT : 253
    wire [15:0] lut_253_table = 16'b1111010011110101;
    wire [3:0] lut_253_select = {
                             in_data[26],
                             in_data[29],
                             in_data[19],
                             in_data[32]};
    
    wire lut_253_out = lut_253_table[lut_253_select];
    
    assign out_data[253] = lut_253_out;
    
    
    
    // LUT : 254
    wire [15:0] lut_254_table = 16'b1101000011111110;
    wire [3:0] lut_254_select = {
                             in_data[45],
                             in_data[48],
                             in_data[17],
                             in_data[39]};
    
    wire lut_254_out = lut_254_table[lut_254_select];
    
    assign out_data[254] = lut_254_out;
    
    
    
    // LUT : 255
    wire [15:0] lut_255_table = 16'b1011101100001000;
    wire [3:0] lut_255_select = {
                             in_data[61],
                             in_data[11],
                             in_data[18],
                             in_data[44]};
    
    wire lut_255_out = lut_255_table[lut_255_select];
    
    assign out_data[255] = lut_255_out;
    
    
endmodule



module MnistLut4Simple_sub5
        #(
            parameter INIT_REG = 1'bx,
            parameter DEVICE   = "RTL"
        )
        (
            input  wire         reset,
            input  wire         clk,
            input  wire         cke,
            
            input  wire [255:0]  in_data,
            output wire [63:0]  out_data
        );
    
    
    // LUT : 0
    wire [15:0] lut_0_table = 16'b1111111100001010;
    wire [3:0] lut_0_select = {
                             in_data[3],
                             in_data[2],
                             in_data[1],
                             in_data[0]};
    
    wire lut_0_out = lut_0_table[lut_0_select];
    
    assign out_data[0] = lut_0_out;
    
    
    
    // LUT : 1
    wire [15:0] lut_1_table = 16'b1111100011101000;
    wire [3:0] lut_1_select = {
                             in_data[7],
                             in_data[6],
                             in_data[5],
                             in_data[4]};
    
    wire lut_1_out = lut_1_table[lut_1_select];
    
    assign out_data[1] = lut_1_out;
    
    
    
    // LUT : 2
    wire [15:0] lut_2_table = 16'b0111011101010101;
    wire [3:0] lut_2_select = {
                             in_data[11],
                             in_data[10],
                             in_data[9],
                             in_data[8]};
    
    wire lut_2_out = lut_2_table[lut_2_select];
    
    assign out_data[2] = lut_2_out;
    
    
    
    // LUT : 3
    wire [15:0] lut_3_table = 16'b0000110011001101;
    wire [3:0] lut_3_select = {
                             in_data[15],
                             in_data[14],
                             in_data[13],
                             in_data[12]};
    
    wire lut_3_out = lut_3_table[lut_3_select];
    
    assign out_data[3] = lut_3_out;
    
    
    
    // LUT : 4
    wire [15:0] lut_4_table = 16'b1000111010001000;
    wire [3:0] lut_4_select = {
                             in_data[19],
                             in_data[18],
                             in_data[17],
                             in_data[16]};
    
    wire lut_4_out = lut_4_table[lut_4_select];
    
    assign out_data[4] = lut_4_out;
    
    
    
    // LUT : 5
    wire [15:0] lut_5_table = 16'b0000000100010111;
    wire [3:0] lut_5_select = {
                             in_data[23],
                             in_data[22],
                             in_data[21],
                             in_data[20]};
    
    wire lut_5_out = lut_5_table[lut_5_select];
    
    assign out_data[5] = lut_5_out;
    
    
    
    // LUT : 6
    wire [15:0] lut_6_table = 16'b1111101110110010;
    wire [3:0] lut_6_select = {
                             in_data[27],
                             in_data[26],
                             in_data[25],
                             in_data[24]};
    
    wire lut_6_out = lut_6_table[lut_6_select];
    
    assign out_data[6] = lut_6_out;
    
    
    
    // LUT : 7
    wire [15:0] lut_7_table = 16'b1111001000100000;
    wire [3:0] lut_7_select = {
                             in_data[31],
                             in_data[30],
                             in_data[29],
                             in_data[28]};
    
    wire lut_7_out = lut_7_table[lut_7_select];
    
    assign out_data[7] = lut_7_out;
    
    
    
    // LUT : 8
    wire [15:0] lut_8_table = 16'b1100000011111100;
    wire [3:0] lut_8_select = {
                             in_data[35],
                             in_data[34],
                             in_data[33],
                             in_data[32]};
    
    wire lut_8_out = lut_8_table[lut_8_select];
    
    assign out_data[8] = lut_8_out;
    
    
    
    // LUT : 9
    wire [15:0] lut_9_table = 16'b1010001011110010;
    wire [3:0] lut_9_select = {
                             in_data[39],
                             in_data[38],
                             in_data[37],
                             in_data[36]};
    
    wire lut_9_out = lut_9_table[lut_9_select];
    
    assign out_data[9] = lut_9_out;
    
    
    
    // LUT : 10
    wire [15:0] lut_10_table = 16'b0000110100000100;
    wire [3:0] lut_10_select = {
                             in_data[43],
                             in_data[42],
                             in_data[41],
                             in_data[40]};
    
    wire lut_10_out = lut_10_table[lut_10_select];
    
    assign out_data[10] = lut_10_out;
    
    
    
    // LUT : 11
    wire [15:0] lut_11_table = 16'b0100000011110000;
    wire [3:0] lut_11_select = {
                             in_data[47],
                             in_data[46],
                             in_data[45],
                             in_data[44]};
    
    wire lut_11_out = lut_11_table[lut_11_select];
    
    assign out_data[11] = lut_11_out;
    
    
    
    // LUT : 12
    wire [15:0] lut_12_table = 16'b1011001010110010;
    wire [3:0] lut_12_select = {
                             in_data[51],
                             in_data[50],
                             in_data[49],
                             in_data[48]};
    
    wire lut_12_out = lut_12_table[lut_12_select];
    
    assign out_data[12] = lut_12_out;
    
    
    
    // LUT : 13
    wire [15:0] lut_13_table = 16'b1000111000001000;
    wire [3:0] lut_13_select = {
                             in_data[55],
                             in_data[54],
                             in_data[53],
                             in_data[52]};
    
    wire lut_13_out = lut_13_table[lut_13_select];
    
    assign out_data[13] = lut_13_out;
    
    
    
    // LUT : 14
    wire [15:0] lut_14_table = 16'b0101000111110111;
    wire [3:0] lut_14_select = {
                             in_data[59],
                             in_data[58],
                             in_data[57],
                             in_data[56]};
    
    wire lut_14_out = lut_14_table[lut_14_select];
    
    assign out_data[14] = lut_14_out;
    
    
    
    // LUT : 15
    wire [15:0] lut_15_table = 16'b0000110001001100;
    wire [3:0] lut_15_select = {
                             in_data[63],
                             in_data[62],
                             in_data[61],
                             in_data[60]};
    
    wire lut_15_out = lut_15_table[lut_15_select];
    
    assign out_data[15] = lut_15_out;
    
    
    
    // LUT : 16
    wire [15:0] lut_16_table = 16'b1100000011111100;
    wire [3:0] lut_16_select = {
                             in_data[67],
                             in_data[66],
                             in_data[65],
                             in_data[64]};
    
    wire lut_16_out = lut_16_table[lut_16_select];
    
    assign out_data[16] = lut_16_out;
    
    
    
    // LUT : 17
    wire [15:0] lut_17_table = 16'b1110100010000000;
    wire [3:0] lut_17_select = {
                             in_data[71],
                             in_data[70],
                             in_data[69],
                             in_data[68]};
    
    wire lut_17_out = lut_17_table[lut_17_select];
    
    assign out_data[17] = lut_17_out;
    
    
    
    // LUT : 18
    wire [15:0] lut_18_table = 16'b0000000000000101;
    wire [3:0] lut_18_select = {
                             in_data[75],
                             in_data[74],
                             in_data[73],
                             in_data[72]};
    
    wire lut_18_out = lut_18_table[lut_18_select];
    
    assign out_data[18] = lut_18_out;
    
    
    
    // LUT : 19
    wire [15:0] lut_19_table = 16'b1111011101010001;
    wire [3:0] lut_19_select = {
                             in_data[79],
                             in_data[78],
                             in_data[77],
                             in_data[76]};
    
    wire lut_19_out = lut_19_table[lut_19_select];
    
    assign out_data[19] = lut_19_out;
    
    
    
    // LUT : 20
    wire [15:0] lut_20_table = 16'b0000010001001101;
    wire [3:0] lut_20_select = {
                             in_data[83],
                             in_data[82],
                             in_data[81],
                             in_data[80]};
    
    wire lut_20_out = lut_20_table[lut_20_select];
    
    assign out_data[20] = lut_20_out;
    
    
    
    // LUT : 21
    wire [15:0] lut_21_table = 16'b1011101100101010;
    wire [3:0] lut_21_select = {
                             in_data[87],
                             in_data[86],
                             in_data[85],
                             in_data[84]};
    
    wire lut_21_out = lut_21_table[lut_21_select];
    
    assign out_data[21] = lut_21_out;
    
    
    
    // LUT : 22
    wire [15:0] lut_22_table = 16'b1000111000001000;
    wire [3:0] lut_22_select = {
                             in_data[91],
                             in_data[90],
                             in_data[89],
                             in_data[88]};
    
    wire lut_22_out = lut_22_table[lut_22_select];
    
    assign out_data[22] = lut_22_out;
    
    
    
    // LUT : 23
    wire [15:0] lut_23_table = 16'b0011001010111011;
    wire [3:0] lut_23_select = {
                             in_data[95],
                             in_data[94],
                             in_data[93],
                             in_data[92]};
    
    wire lut_23_out = lut_23_table[lut_23_select];
    
    assign out_data[23] = lut_23_out;
    
    
    
    // LUT : 24
    wire [15:0] lut_24_table = 16'b0100110101000100;
    wire [3:0] lut_24_select = {
                             in_data[99],
                             in_data[98],
                             in_data[97],
                             in_data[96]};
    
    wire lut_24_out = lut_24_table[lut_24_select];
    
    assign out_data[24] = lut_24_out;
    
    
    
    // LUT : 25
    wire [15:0] lut_25_table = 16'b1111101010100000;
    wire [3:0] lut_25_select = {
                             in_data[103],
                             in_data[102],
                             in_data[101],
                             in_data[100]};
    
    wire lut_25_out = lut_25_table[lut_25_select];
    
    assign out_data[25] = lut_25_out;
    
    
    
    // LUT : 26
    wire [15:0] lut_26_table = 16'b1111101110111010;
    wire [3:0] lut_26_select = {
                             in_data[107],
                             in_data[106],
                             in_data[105],
                             in_data[104]};
    
    wire lut_26_out = lut_26_table[lut_26_select];
    
    assign out_data[26] = lut_26_out;
    
    
    
    // LUT : 27
    wire [15:0] lut_27_table = 16'b1111110111010100;
    wire [3:0] lut_27_select = {
                             in_data[111],
                             in_data[110],
                             in_data[109],
                             in_data[108]};
    
    wire lut_27_out = lut_27_table[lut_27_select];
    
    assign out_data[27] = lut_27_out;
    
    
    
    // LUT : 28
    wire [15:0] lut_28_table = 16'b0010101110111111;
    wire [3:0] lut_28_select = {
                             in_data[115],
                             in_data[114],
                             in_data[113],
                             in_data[112]};
    
    wire lut_28_out = lut_28_table[lut_28_select];
    
    assign out_data[28] = lut_28_out;
    
    
    
    // LUT : 29
    wire [15:0] lut_29_table = 16'b0100110100000100;
    wire [3:0] lut_29_select = {
                             in_data[119],
                             in_data[118],
                             in_data[117],
                             in_data[116]};
    
    wire lut_29_out = lut_29_table[lut_29_select];
    
    assign out_data[29] = lut_29_out;
    
    
    
    // LUT : 30
    wire [15:0] lut_30_table = 16'b1000111011001110;
    wire [3:0] lut_30_select = {
                             in_data[123],
                             in_data[122],
                             in_data[121],
                             in_data[120]};
    
    wire lut_30_out = lut_30_table[lut_30_select];
    
    assign out_data[30] = lut_30_out;
    
    
    
    // LUT : 31
    wire [15:0] lut_31_table = 16'b0101010011110101;
    wire [3:0] lut_31_select = {
                             in_data[127],
                             in_data[126],
                             in_data[125],
                             in_data[124]};
    
    wire lut_31_out = lut_31_table[lut_31_select];
    
    assign out_data[31] = lut_31_out;
    
    
    
    // LUT : 32
    wire [15:0] lut_32_table = 16'b1111111110110010;
    wire [3:0] lut_32_select = {
                             in_data[131],
                             in_data[130],
                             in_data[129],
                             in_data[128]};
    
    wire lut_32_out = lut_32_table[lut_32_select];
    
    assign out_data[32] = lut_32_out;
    
    
    
    // LUT : 33
    wire [15:0] lut_33_table = 16'b1110100010000000;
    wire [3:0] lut_33_select = {
                             in_data[135],
                             in_data[134],
                             in_data[133],
                             in_data[132]};
    
    wire lut_33_out = lut_33_table[lut_33_select];
    
    assign out_data[33] = lut_33_out;
    
    
    
    // LUT : 34
    wire [15:0] lut_34_table = 16'b1111101011101010;
    wire [3:0] lut_34_select = {
                             in_data[139],
                             in_data[138],
                             in_data[137],
                             in_data[136]};
    
    wire lut_34_out = lut_34_table[lut_34_select];
    
    assign out_data[34] = lut_34_out;
    
    
    
    // LUT : 35
    wire [15:0] lut_35_table = 16'b0100010001000000;
    wire [3:0] lut_35_select = {
                             in_data[143],
                             in_data[142],
                             in_data[141],
                             in_data[140]};
    
    wire lut_35_out = lut_35_table[lut_35_select];
    
    assign out_data[35] = lut_35_out;
    
    
    
    // LUT : 36
    wire [15:0] lut_36_table = 16'b1010100010001000;
    wire [3:0] lut_36_select = {
                             in_data[147],
                             in_data[146],
                             in_data[145],
                             in_data[144]};
    
    wire lut_36_out = lut_36_table[lut_36_select];
    
    assign out_data[36] = lut_36_out;
    
    
    
    // LUT : 37
    wire [15:0] lut_37_table = 16'b0010101110111111;
    wire [3:0] lut_37_select = {
                             in_data[151],
                             in_data[150],
                             in_data[149],
                             in_data[148]};
    
    wire lut_37_out = lut_37_table[lut_37_select];
    
    assign out_data[37] = lut_37_out;
    
    
    
    // LUT : 38
    wire [15:0] lut_38_table = 16'b0000000001001100;
    wire [3:0] lut_38_select = {
                             in_data[155],
                             in_data[154],
                             in_data[153],
                             in_data[152]};
    
    wire lut_38_out = lut_38_table[lut_38_select];
    
    assign out_data[38] = lut_38_out;
    
    
    
    // LUT : 39
    wire [15:0] lut_39_table = 16'b1110110011111110;
    wire [3:0] lut_39_select = {
                             in_data[159],
                             in_data[158],
                             in_data[157],
                             in_data[156]};
    
    wire lut_39_out = lut_39_table[lut_39_select];
    
    assign out_data[39] = lut_39_out;
    
    
    
    // LUT : 40
    wire [15:0] lut_40_table = 16'b1000111010001100;
    wire [3:0] lut_40_select = {
                             in_data[163],
                             in_data[162],
                             in_data[161],
                             in_data[160]};
    
    wire lut_40_out = lut_40_table[lut_40_select];
    
    assign out_data[40] = lut_40_out;
    
    
    
    // LUT : 41
    wire [15:0] lut_41_table = 16'b1111010101110101;
    wire [3:0] lut_41_select = {
                             in_data[167],
                             in_data[166],
                             in_data[165],
                             in_data[164]};
    
    wire lut_41_out = lut_41_table[lut_41_select];
    
    assign out_data[41] = lut_41_out;
    
    
    
    // LUT : 42
    wire [15:0] lut_42_table = 16'b1101010011010100;
    wire [3:0] lut_42_select = {
                             in_data[171],
                             in_data[170],
                             in_data[169],
                             in_data[168]};
    
    wire lut_42_out = lut_42_table[lut_42_select];
    
    assign out_data[42] = lut_42_out;
    
    
    
    // LUT : 43
    wire [15:0] lut_43_table = 16'b1111110111010100;
    wire [3:0] lut_43_select = {
                             in_data[175],
                             in_data[174],
                             in_data[173],
                             in_data[172]};
    
    wire lut_43_out = lut_43_table[lut_43_select];
    
    assign out_data[43] = lut_43_out;
    
    
    
    // LUT : 44
    wire [15:0] lut_44_table = 16'b1100111100001100;
    wire [3:0] lut_44_select = {
                             in_data[179],
                             in_data[178],
                             in_data[177],
                             in_data[176]};
    
    wire lut_44_out = lut_44_table[lut_44_select];
    
    assign out_data[44] = lut_44_out;
    
    
    
    // LUT : 45
    wire [15:0] lut_45_table = 16'b0100111100000101;
    wire [3:0] lut_45_select = {
                             in_data[183],
                             in_data[182],
                             in_data[181],
                             in_data[180]};
    
    wire lut_45_out = lut_45_table[lut_45_select];
    
    assign out_data[45] = lut_45_out;
    
    
    
    // LUT : 46
    wire [15:0] lut_46_table = 16'b1110100010101000;
    wire [3:0] lut_46_select = {
                             in_data[187],
                             in_data[186],
                             in_data[185],
                             in_data[184]};
    
    wire lut_46_out = lut_46_table[lut_46_select];
    
    assign out_data[46] = lut_46_out;
    
    
    
    // LUT : 47
    wire [15:0] lut_47_table = 16'b0010101110111011;
    wire [3:0] lut_47_select = {
                             in_data[191],
                             in_data[190],
                             in_data[189],
                             in_data[188]};
    
    wire lut_47_out = lut_47_table[lut_47_select];
    
    assign out_data[47] = lut_47_out;
    
    
    
    // LUT : 48
    wire [15:0] lut_48_table = 16'b0100010011011101;
    wire [3:0] lut_48_select = {
                             in_data[195],
                             in_data[194],
                             in_data[193],
                             in_data[192]};
    
    wire lut_48_out = lut_48_table[lut_48_select];
    
    assign out_data[48] = lut_48_out;
    
    
    
    // LUT : 49
    wire [15:0] lut_49_table = 16'b0101000000010000;
    wire [3:0] lut_49_select = {
                             in_data[199],
                             in_data[198],
                             in_data[197],
                             in_data[196]};
    
    wire lut_49_out = lut_49_table[lut_49_select];
    
    assign out_data[49] = lut_49_out;
    
    
    
    // LUT : 50
    wire [15:0] lut_50_table = 16'b0000101100101011;
    wire [3:0] lut_50_select = {
                             in_data[203],
                             in_data[202],
                             in_data[201],
                             in_data[200]};
    
    wire lut_50_out = lut_50_table[lut_50_select];
    
    assign out_data[50] = lut_50_out;
    
    
    
    // LUT : 51
    wire [15:0] lut_51_table = 16'b0001000101110111;
    wire [3:0] lut_51_select = {
                             in_data[207],
                             in_data[206],
                             in_data[205],
                             in_data[204]};
    
    wire lut_51_out = lut_51_table[lut_51_select];
    
    assign out_data[51] = lut_51_out;
    
    
    
    // LUT : 52
    wire [15:0] lut_52_table = 16'b1111001110110010;
    wire [3:0] lut_52_select = {
                             in_data[211],
                             in_data[210],
                             in_data[209],
                             in_data[208]};
    
    wire lut_52_out = lut_52_table[lut_52_select];
    
    assign out_data[52] = lut_52_out;
    
    
    
    // LUT : 53
    wire [15:0] lut_53_table = 16'b1111001100110000;
    wire [3:0] lut_53_select = {
                             in_data[215],
                             in_data[214],
                             in_data[213],
                             in_data[212]};
    
    wire lut_53_out = lut_53_table[lut_53_select];
    
    assign out_data[53] = lut_53_out;
    
    
    
    // LUT : 54
    wire [15:0] lut_54_table = 16'b0001000000110001;
    wire [3:0] lut_54_select = {
                             in_data[219],
                             in_data[218],
                             in_data[217],
                             in_data[216]};
    
    wire lut_54_out = lut_54_table[lut_54_select];
    
    assign out_data[54] = lut_54_out;
    
    
    
    // LUT : 55
    wire [15:0] lut_55_table = 16'b1101000001000000;
    wire [3:0] lut_55_select = {
                             in_data[223],
                             in_data[222],
                             in_data[221],
                             in_data[220]};
    
    wire lut_55_out = lut_55_table[lut_55_select];
    
    assign out_data[55] = lut_55_out;
    
    
    
    // LUT : 56
    wire [15:0] lut_56_table = 16'b0010101100000011;
    wire [3:0] lut_56_select = {
                             in_data[227],
                             in_data[226],
                             in_data[225],
                             in_data[224]};
    
    wire lut_56_out = lut_56_table[lut_56_select];
    
    assign out_data[56] = lut_56_out;
    
    
    
    // LUT : 57
    wire [15:0] lut_57_table = 16'b1000111000001000;
    wire [3:0] lut_57_select = {
                             in_data[231],
                             in_data[230],
                             in_data[229],
                             in_data[228]};
    
    wire lut_57_out = lut_57_table[lut_57_select];
    
    assign out_data[57] = lut_57_out;
    
    
    
    // LUT : 58
    wire [15:0] lut_58_table = 16'b1111111011101100;
    wire [3:0] lut_58_select = {
                             in_data[235],
                             in_data[234],
                             in_data[233],
                             in_data[232]};
    
    wire lut_58_out = lut_58_table[lut_58_select];
    
    assign out_data[58] = lut_58_out;
    
    
    
    // LUT : 59
    wire [15:0] lut_59_table = 16'b0011011100010011;
    wire [3:0] lut_59_select = {
                             in_data[239],
                             in_data[238],
                             in_data[237],
                             in_data[236]};
    
    wire lut_59_out = lut_59_table[lut_59_select];
    
    assign out_data[59] = lut_59_out;
    
    
    
    // LUT : 60
    wire [15:0] lut_60_table = 16'b1000111100000000;
    wire [3:0] lut_60_select = {
                             in_data[243],
                             in_data[242],
                             in_data[241],
                             in_data[240]};
    
    wire lut_60_out = lut_60_table[lut_60_select];
    
    assign out_data[60] = lut_60_out;
    
    
    
    // LUT : 61
    wire [15:0] lut_61_table = 16'b1100110001000000;
    wire [3:0] lut_61_select = {
                             in_data[247],
                             in_data[246],
                             in_data[245],
                             in_data[244]};
    
    wire lut_61_out = lut_61_table[lut_61_select];
    
    assign out_data[61] = lut_61_out;
    
    
    
    // LUT : 62
    wire [15:0] lut_62_table = 16'b1111111011101100;
    wire [3:0] lut_62_select = {
                             in_data[251],
                             in_data[250],
                             in_data[249],
                             in_data[248]};
    
    wire lut_62_out = lut_62_table[lut_62_select];
    
    assign out_data[62] = lut_62_out;
    
    
    
    // LUT : 63
    wire [15:0] lut_63_table = 16'b1111111101110011;
    wire [3:0] lut_63_select = {
                             in_data[255],
                             in_data[254],
                             in_data[253],
                             in_data[252]};
    
    wire lut_63_out = lut_63_table[lut_63_select];
    
    assign out_data[63] = lut_63_out;
    
    
endmodule



module MnistLut4Simple_sub6
        #(
            parameter INIT_REG = 1'bx,
            parameter DEVICE   = "RTL"
        )
        (
            input  wire         reset,
            input  wire         clk,
            input  wire         cke,
            
            input  wire [63:0]  in_data,
            output wire [159:0]  out_data
        );
    
    
    // LUT : 0
    wire [15:0] lut_0_table = 16'b1110000011000100;
    wire [3:0] lut_0_select = {
                             in_data[32],
                             in_data[27],
                             in_data[17],
                             in_data[8]};
    
    wire lut_0_out = lut_0_table[lut_0_select];
    
    assign out_data[0] = lut_0_out;
    
    
    
    // LUT : 1
    wire [15:0] lut_1_table = 16'b0111010011111110;
    wire [3:0] lut_1_select = {
                             in_data[25],
                             in_data[51],
                             in_data[33],
                             in_data[52]};
    
    wire lut_1_out = lut_1_table[lut_1_select];
    
    assign out_data[1] = lut_1_out;
    
    
    
    // LUT : 2
    wire [15:0] lut_2_table = 16'b1111101010000000;
    wire [3:0] lut_2_select = {
                             in_data[20],
                             in_data[53],
                             in_data[14],
                             in_data[26]};
    
    wire lut_2_out = lut_2_table[lut_2_select];
    
    assign out_data[2] = lut_2_out;
    
    
    
    // LUT : 3
    wire [15:0] lut_3_table = 16'b0100111000000000;
    wire [3:0] lut_3_select = {
                             in_data[47],
                             in_data[10],
                             in_data[3],
                             in_data[24]};
    
    wire lut_3_out = lut_3_table[lut_3_select];
    
    assign out_data[3] = lut_3_out;
    
    
    
    // LUT : 4
    wire [15:0] lut_4_table = 16'b0000001101111111;
    wire [3:0] lut_4_select = {
                             in_data[44],
                             in_data[19],
                             in_data[57],
                             in_data[63]};
    
    wire lut_4_out = lut_4_table[lut_4_select];
    
    assign out_data[4] = lut_4_out;
    
    
    
    // LUT : 5
    wire [15:0] lut_5_table = 16'b0001000001110101;
    wire [3:0] lut_5_select = {
                             in_data[62],
                             in_data[21],
                             in_data[58],
                             in_data[22]};
    
    wire lut_5_out = lut_5_table[lut_5_select];
    
    assign out_data[5] = lut_5_out;
    
    
    
    // LUT : 6
    wire [15:0] lut_6_table = 16'b0000000010101111;
    wire [3:0] lut_6_select = {
                             in_data[48],
                             in_data[9],
                             in_data[7],
                             in_data[15]};
    
    wire lut_6_out = lut_6_table[lut_6_select];
    
    assign out_data[6] = lut_6_out;
    
    
    
    // LUT : 7
    wire [15:0] lut_7_table = 16'b0011111100001000;
    wire [3:0] lut_7_select = {
                             in_data[2],
                             in_data[41],
                             in_data[45],
                             in_data[31]};
    
    wire lut_7_out = lut_7_table[lut_7_select];
    
    assign out_data[7] = lut_7_out;
    
    
    
    // LUT : 8
    wire [15:0] lut_8_table = 16'b0111011101010101;
    wire [3:0] lut_8_select = {
                             in_data[0],
                             in_data[28],
                             in_data[30],
                             in_data[34]};
    
    wire lut_8_out = lut_8_table[lut_8_select];
    
    assign out_data[8] = lut_8_out;
    
    
    
    // LUT : 9
    wire [15:0] lut_9_table = 16'b0001011100010101;
    wire [3:0] lut_9_select = {
                             in_data[35],
                             in_data[40],
                             in_data[1],
                             in_data[60]};
    
    wire lut_9_out = lut_9_table[lut_9_select];
    
    assign out_data[9] = lut_9_out;
    
    
    
    // LUT : 10
    wire [15:0] lut_10_table = 16'b0000010101001111;
    wire [3:0] lut_10_select = {
                             in_data[6],
                             in_data[4],
                             in_data[18],
                             in_data[54]};
    
    wire lut_10_out = lut_10_table[lut_10_select];
    
    assign out_data[10] = lut_10_out;
    
    
    
    // LUT : 11
    wire [15:0] lut_11_table = 16'b0001011100010100;
    wire [3:0] lut_11_select = {
                             in_data[46],
                             in_data[38],
                             in_data[61],
                             in_data[42]};
    
    wire lut_11_out = lut_11_table[lut_11_select];
    
    assign out_data[11] = lut_11_out;
    
    
    
    // LUT : 12
    wire [15:0] lut_12_table = 16'b1100110011000000;
    wire [3:0] lut_12_select = {
                             in_data[39],
                             in_data[59],
                             in_data[11],
                             in_data[23]};
    
    wire lut_12_out = lut_12_table[lut_12_select];
    
    assign out_data[12] = lut_12_out;
    
    
    
    // LUT : 13
    wire [15:0] lut_13_table = 16'b0000110100000101;
    wire [3:0] lut_13_select = {
                             in_data[56],
                             in_data[5],
                             in_data[13],
                             in_data[29]};
    
    wire lut_13_out = lut_13_table[lut_13_select];
    
    assign out_data[13] = lut_13_out;
    
    
    
    // LUT : 14
    wire [15:0] lut_14_table = 16'b1010111100101111;
    wire [3:0] lut_14_select = {
                             in_data[43],
                             in_data[12],
                             in_data[49],
                             in_data[55]};
    
    wire lut_14_out = lut_14_table[lut_14_select];
    
    assign out_data[14] = lut_14_out;
    
    
    
    // LUT : 15
    wire [15:0] lut_15_table = 16'b1100111111001111;
    wire [3:0] lut_15_select = {
                             in_data[16],
                             in_data[37],
                             in_data[36],
                             in_data[50]};
    
    wire lut_15_out = lut_15_table[lut_15_select];
    
    assign out_data[15] = lut_15_out;
    
    
    
    // LUT : 16
    wire [15:0] lut_16_table = 16'b1111110001000000;
    wire [3:0] lut_16_select = {
                             in_data[11],
                             in_data[6],
                             in_data[58],
                             in_data[9]};
    
    wire lut_16_out = lut_16_table[lut_16_select];
    
    assign out_data[16] = lut_16_out;
    
    
    
    // LUT : 17
    wire [15:0] lut_17_table = 16'b1110101000000000;
    wire [3:0] lut_17_select = {
                             in_data[28],
                             in_data[27],
                             in_data[51],
                             in_data[16]};
    
    wire lut_17_out = lut_17_table[lut_17_select];
    
    assign out_data[17] = lut_17_out;
    
    
    
    // LUT : 18
    wire [15:0] lut_18_table = 16'b0011000011110011;
    wire [3:0] lut_18_select = {
                             in_data[25],
                             in_data[55],
                             in_data[10],
                             in_data[61]};
    
    wire lut_18_out = lut_18_table[lut_18_select];
    
    assign out_data[18] = lut_18_out;
    
    
    
    // LUT : 19
    wire [15:0] lut_19_table = 16'b1111011111110010;
    wire [3:0] lut_19_select = {
                             in_data[60],
                             in_data[24],
                             in_data[5],
                             in_data[45]};
    
    wire lut_19_out = lut_19_table[lut_19_select];
    
    assign out_data[19] = lut_19_out;
    
    
    
    // LUT : 20
    wire [15:0] lut_20_table = 16'b0000111100001111;
    wire [3:0] lut_20_select = {
                             in_data[2],
                             in_data[22],
                             in_data[59],
                             in_data[43]};
    
    wire lut_20_out = lut_20_table[lut_20_select];
    
    assign out_data[20] = lut_20_out;
    
    
    
    // LUT : 21
    wire [15:0] lut_21_table = 16'b1110111110101010;
    wire [3:0] lut_21_select = {
                             in_data[3],
                             in_data[32],
                             in_data[1],
                             in_data[20]};
    
    wire lut_21_out = lut_21_table[lut_21_select];
    
    assign out_data[21] = lut_21_out;
    
    
    
    // LUT : 22
    wire [15:0] lut_22_table = 16'b0000110000001100;
    wire [3:0] lut_22_select = {
                             in_data[18],
                             in_data[38],
                             in_data[21],
                             in_data[35]};
    
    wire lut_22_out = lut_22_table[lut_22_select];
    
    assign out_data[22] = lut_22_out;
    
    
    
    // LUT : 23
    wire [15:0] lut_23_table = 16'b1110111010001000;
    wire [3:0] lut_23_select = {
                             in_data[40],
                             in_data[39],
                             in_data[14],
                             in_data[30]};
    
    wire lut_23_out = lut_23_table[lut_23_select];
    
    assign out_data[23] = lut_23_out;
    
    
    
    // LUT : 24
    wire [15:0] lut_24_table = 16'b1101010001000000;
    wire [3:0] lut_24_select = {
                             in_data[52],
                             in_data[47],
                             in_data[50],
                             in_data[33]};
    
    wire lut_24_out = lut_24_table[lut_24_select];
    
    assign out_data[24] = lut_24_out;
    
    
    
    // LUT : 25
    wire [15:0] lut_25_table = 16'b0111000101010001;
    wire [3:0] lut_25_select = {
                             in_data[23],
                             in_data[13],
                             in_data[56],
                             in_data[12]};
    
    wire lut_25_out = lut_25_table[lut_25_select];
    
    assign out_data[25] = lut_25_out;
    
    
    
    // LUT : 26
    wire [15:0] lut_26_table = 16'b0000000001010100;
    wire [3:0] lut_26_select = {
                             in_data[8],
                             in_data[17],
                             in_data[41],
                             in_data[49]};
    
    wire lut_26_out = lut_26_table[lut_26_select];
    
    assign out_data[26] = lut_26_out;
    
    
    
    // LUT : 27
    wire [15:0] lut_27_table = 16'b1111111111001110;
    wire [3:0] lut_27_select = {
                             in_data[54],
                             in_data[44],
                             in_data[29],
                             in_data[4]};
    
    wire lut_27_out = lut_27_table[lut_27_select];
    
    assign out_data[27] = lut_27_out;
    
    
    
    // LUT : 28
    wire [15:0] lut_28_table = 16'b1100111100001100;
    wire [3:0] lut_28_select = {
                             in_data[57],
                             in_data[0],
                             in_data[42],
                             in_data[34]};
    
    wire lut_28_out = lut_28_table[lut_28_select];
    
    assign out_data[28] = lut_28_out;
    
    
    
    // LUT : 29
    wire [15:0] lut_29_table = 16'b1101000001000000;
    wire [3:0] lut_29_select = {
                             in_data[19],
                             in_data[48],
                             in_data[63],
                             in_data[31]};
    
    wire lut_29_out = lut_29_table[lut_29_select];
    
    assign out_data[29] = lut_29_out;
    
    
    
    // LUT : 30
    wire [15:0] lut_30_table = 16'b1010101010110010;
    wire [3:0] lut_30_select = {
                             in_data[62],
                             in_data[37],
                             in_data[7],
                             in_data[53]};
    
    wire lut_30_out = lut_30_table[lut_30_select];
    
    assign out_data[30] = lut_30_out;
    
    
    
    // LUT : 31
    wire [15:0] lut_31_table = 16'b1100110011111110;
    wire [3:0] lut_31_select = {
                             in_data[26],
                             in_data[36],
                             in_data[15],
                             in_data[46]};
    
    wire lut_31_out = lut_31_table[lut_31_select];
    
    assign out_data[31] = lut_31_out;
    
    
    
    // LUT : 32
    wire [15:0] lut_32_table = 16'b1011001100110011;
    wire [3:0] lut_32_select = {
                             in_data[58],
                             in_data[20],
                             in_data[62],
                             in_data[17]};
    
    wire lut_32_out = lut_32_table[lut_32_select];
    
    assign out_data[32] = lut_32_out;
    
    
    
    // LUT : 33
    wire [15:0] lut_33_table = 16'b1111111110101000;
    wire [3:0] lut_33_select = {
                             in_data[9],
                             in_data[47],
                             in_data[53],
                             in_data[59]};
    
    wire lut_33_out = lut_33_table[lut_33_select];
    
    assign out_data[33] = lut_33_out;
    
    
    
    // LUT : 34
    wire [15:0] lut_34_table = 16'b1101111111011101;
    wire [3:0] lut_34_select = {
                             in_data[43],
                             in_data[28],
                             in_data[15],
                             in_data[1]};
    
    wire lut_34_out = lut_34_table[lut_34_select];
    
    assign out_data[34] = lut_34_out;
    
    
    
    // LUT : 35
    wire [15:0] lut_35_table = 16'b0111111101010101;
    wire [3:0] lut_35_select = {
                             in_data[22],
                             in_data[18],
                             in_data[21],
                             in_data[27]};
    
    wire lut_35_out = lut_35_table[lut_35_select];
    
    assign out_data[35] = lut_35_out;
    
    
    
    // LUT : 36
    wire [15:0] lut_36_table = 16'b1111000011111000;
    wire [3:0] lut_36_select = {
                             in_data[49],
                             in_data[35],
                             in_data[63],
                             in_data[26]};
    
    wire lut_36_out = lut_36_table[lut_36_select];
    
    assign out_data[36] = lut_36_out;
    
    
    
    // LUT : 37
    wire [15:0] lut_37_table = 16'b0011001100110111;
    wire [3:0] lut_37_select = {
                             in_data[7],
                             in_data[32],
                             in_data[44],
                             in_data[10]};
    
    wire lut_37_out = lut_37_table[lut_37_select];
    
    assign out_data[37] = lut_37_out;
    
    
    
    // LUT : 38
    wire [15:0] lut_38_table = 16'b1010110011001100;
    wire [3:0] lut_38_select = {
                             in_data[2],
                             in_data[41],
                             in_data[12],
                             in_data[14]};
    
    wire lut_38_out = lut_38_table[lut_38_select];
    
    assign out_data[38] = lut_38_out;
    
    
    
    // LUT : 39
    wire [15:0] lut_39_table = 16'b0000000011111000;
    wire [3:0] lut_39_select = {
                             in_data[48],
                             in_data[30],
                             in_data[55],
                             in_data[61]};
    
    wire lut_39_out = lut_39_table[lut_39_select];
    
    assign out_data[39] = lut_39_out;
    
    
    
    // LUT : 40
    wire [15:0] lut_40_table = 16'b0011000100010001;
    wire [3:0] lut_40_select = {
                             in_data[11],
                             in_data[52],
                             in_data[29],
                             in_data[5]};
    
    wire lut_40_out = lut_40_table[lut_40_select];
    
    assign out_data[40] = lut_40_out;
    
    
    
    // LUT : 41
    wire [15:0] lut_41_table = 16'b0111001101010101;
    wire [3:0] lut_41_select = {
                             in_data[54],
                             in_data[56],
                             in_data[19],
                             in_data[45]};
    
    wire lut_41_out = lut_41_table[lut_41_select];
    
    assign out_data[41] = lut_41_out;
    
    
    
    // LUT : 42
    wire [15:0] lut_42_table = 16'b1111101111110010;
    wire [3:0] lut_42_select = {
                             in_data[42],
                             in_data[38],
                             in_data[34],
                             in_data[36]};
    
    wire lut_42_out = lut_42_table[lut_42_select];
    
    assign out_data[42] = lut_42_out;
    
    
    
    // LUT : 43
    wire [15:0] lut_43_table = 16'b0011111100000010;
    wire [3:0] lut_43_select = {
                             in_data[16],
                             in_data[46],
                             in_data[50],
                             in_data[23]};
    
    wire lut_43_out = lut_43_table[lut_43_select];
    
    assign out_data[43] = lut_43_out;
    
    
    
    // LUT : 44
    wire [15:0] lut_44_table = 16'b1011101000100010;
    wire [3:0] lut_44_select = {
                             in_data[3],
                             in_data[6],
                             in_data[31],
                             in_data[13]};
    
    wire lut_44_out = lut_44_table[lut_44_select];
    
    assign out_data[44] = lut_44_out;
    
    
    
    // LUT : 45
    wire [15:0] lut_45_table = 16'b1101111110000000;
    wire [3:0] lut_45_select = {
                             in_data[8],
                             in_data[4],
                             in_data[39],
                             in_data[57]};
    
    wire lut_45_out = lut_45_table[lut_45_select];
    
    assign out_data[45] = lut_45_out;
    
    
    
    // LUT : 46
    wire [15:0] lut_46_table = 16'b0100010011101100;
    wire [3:0] lut_46_select = {
                             in_data[40],
                             in_data[0],
                             in_data[51],
                             in_data[37]};
    
    wire lut_46_out = lut_46_table[lut_46_select];
    
    assign out_data[46] = lut_46_out;
    
    
    
    // LUT : 47
    wire [15:0] lut_47_table = 16'b0000110010001100;
    wire [3:0] lut_47_select = {
                             in_data[24],
                             in_data[60],
                             in_data[25],
                             in_data[33]};
    
    wire lut_47_out = lut_47_table[lut_47_select];
    
    assign out_data[47] = lut_47_out;
    
    
    
    // LUT : 48
    wire [15:0] lut_48_table = 16'b0111111101001101;
    wire [3:0] lut_48_select = {
                             in_data[18],
                             in_data[31],
                             in_data[6],
                             in_data[24]};
    
    wire lut_48_out = lut_48_table[lut_48_select];
    
    assign out_data[48] = lut_48_out;
    
    
    
    // LUT : 49
    wire [15:0] lut_49_table = 16'b0011000000110000;
    wire [3:0] lut_49_select = {
                             in_data[42],
                             in_data[40],
                             in_data[38],
                             in_data[55]};
    
    wire lut_49_out = lut_49_table[lut_49_select];
    
    assign out_data[49] = lut_49_out;
    
    
    
    // LUT : 50
    wire [15:0] lut_50_table = 16'b0000010001011101;
    wire [3:0] lut_50_select = {
                             in_data[60],
                             in_data[51],
                             in_data[5],
                             in_data[41]};
    
    wire lut_50_out = lut_50_table[lut_50_select];
    
    assign out_data[50] = lut_50_out;
    
    
    
    // LUT : 51
    wire [15:0] lut_51_table = 16'b0010111100000010;
    wire [3:0] lut_51_select = {
                             in_data[33],
                             in_data[15],
                             in_data[36],
                             in_data[14]};
    
    wire lut_51_out = lut_51_table[lut_51_select];
    
    assign out_data[51] = lut_51_out;
    
    
    
    // LUT : 52
    wire [15:0] lut_52_table = 16'b0001011100000001;
    wire [3:0] lut_52_select = {
                             in_data[17],
                             in_data[4],
                             in_data[20],
                             in_data[52]};
    
    wire lut_52_out = lut_52_table[lut_52_select];
    
    assign out_data[52] = lut_52_out;
    
    
    
    // LUT : 53
    wire [15:0] lut_53_table = 16'b1000101000001010;
    wire [3:0] lut_53_select = {
                             in_data[28],
                             in_data[58],
                             in_data[32],
                             in_data[63]};
    
    wire lut_53_out = lut_53_table[lut_53_select];
    
    assign out_data[53] = lut_53_out;
    
    
    
    // LUT : 54
    wire [15:0] lut_54_table = 16'b1110000011101000;
    wire [3:0] lut_54_select = {
                             in_data[29],
                             in_data[21],
                             in_data[25],
                             in_data[46]};
    
    wire lut_54_out = lut_54_table[lut_54_select];
    
    assign out_data[54] = lut_54_out;
    
    
    
    // LUT : 55
    wire [15:0] lut_55_table = 16'b1101010111111101;
    wire [3:0] lut_55_select = {
                             in_data[47],
                             in_data[23],
                             in_data[10],
                             in_data[59]};
    
    wire lut_55_out = lut_55_table[lut_55_select];
    
    assign out_data[55] = lut_55_out;
    
    
    
    // LUT : 56
    wire [15:0] lut_56_table = 16'b1100010011101100;
    wire [3:0] lut_56_select = {
                             in_data[37],
                             in_data[34],
                             in_data[1],
                             in_data[43]};
    
    wire lut_56_out = lut_56_table[lut_56_select];
    
    assign out_data[56] = lut_56_out;
    
    
    
    // LUT : 57
    wire [15:0] lut_57_table = 16'b0101110100010101;
    wire [3:0] lut_57_select = {
                             in_data[45],
                             in_data[26],
                             in_data[19],
                             in_data[57]};
    
    wire lut_57_out = lut_57_table[lut_57_select];
    
    assign out_data[57] = lut_57_out;
    
    
    
    // LUT : 58
    wire [15:0] lut_58_table = 16'b0011001010110010;
    wire [3:0] lut_58_select = {
                             in_data[3],
                             in_data[39],
                             in_data[48],
                             in_data[62]};
    
    wire lut_58_out = lut_58_table[lut_58_select];
    
    assign out_data[58] = lut_58_out;
    
    
    
    // LUT : 59
    wire [15:0] lut_59_table = 16'b0001000100010001;
    wire [3:0] lut_59_select = {
                             in_data[49],
                             in_data[12],
                             in_data[13],
                             in_data[54]};
    
    wire lut_59_out = lut_59_table[lut_59_select];
    
    assign out_data[59] = lut_59_out;
    
    
    
    // LUT : 60
    wire [15:0] lut_60_table = 16'b1000111100001100;
    wire [3:0] lut_60_select = {
                             in_data[35],
                             in_data[16],
                             in_data[0],
                             in_data[7]};
    
    wire lut_60_out = lut_60_table[lut_60_select];
    
    assign out_data[60] = lut_60_out;
    
    
    
    // LUT : 61
    wire [15:0] lut_61_table = 16'b1111101100110011;
    wire [3:0] lut_61_select = {
                             in_data[9],
                             in_data[50],
                             in_data[44],
                             in_data[53]};
    
    wire lut_61_out = lut_61_table[lut_61_select];
    
    assign out_data[61] = lut_61_out;
    
    
    
    // LUT : 62
    wire [15:0] lut_62_table = 16'b0000000001010101;
    wire [3:0] lut_62_select = {
                             in_data[8],
                             in_data[2],
                             in_data[56],
                             in_data[22]};
    
    wire lut_62_out = lut_62_table[lut_62_select];
    
    assign out_data[62] = lut_62_out;
    
    
    
    // LUT : 63
    wire [15:0] lut_63_table = 16'b1111101110110010;
    wire [3:0] lut_63_select = {
                             in_data[11],
                             in_data[30],
                             in_data[27],
                             in_data[61]};
    
    wire lut_63_out = lut_63_table[lut_63_select];
    
    assign out_data[63] = lut_63_out;
    
    
    
    // LUT : 64
    wire [15:0] lut_64_table = 16'b0111000001110001;
    wire [3:0] lut_64_select = {
                             in_data[50],
                             in_data[47],
                             in_data[13],
                             in_data[61]};
    
    wire lut_64_out = lut_64_table[lut_64_select];
    
    assign out_data[64] = lut_64_out;
    
    
    
    // LUT : 65
    wire [15:0] lut_65_table = 16'b1011111100010011;
    wire [3:0] lut_65_select = {
                             in_data[25],
                             in_data[63],
                             in_data[52],
                             in_data[9]};
    
    wire lut_65_out = lut_65_table[lut_65_select];
    
    assign out_data[65] = lut_65_out;
    
    
    
    // LUT : 66
    wire [15:0] lut_66_table = 16'b0000000000110011;
    wire [3:0] lut_66_select = {
                             in_data[31],
                             in_data[24],
                             in_data[29],
                             in_data[62]};
    
    wire lut_66_out = lut_66_table[lut_66_select];
    
    assign out_data[66] = lut_66_out;
    
    
    
    // LUT : 67
    wire [15:0] lut_67_table = 16'b0101010101110111;
    wire [3:0] lut_67_select = {
                             in_data[40],
                             in_data[0],
                             in_data[37],
                             in_data[5]};
    
    wire lut_67_out = lut_67_table[lut_67_select];
    
    assign out_data[67] = lut_67_out;
    
    
    
    // LUT : 68
    wire [15:0] lut_68_table = 16'b1000100010001000;
    wire [3:0] lut_68_select = {
                             in_data[55],
                             in_data[59],
                             in_data[7],
                             in_data[19]};
    
    wire lut_68_out = lut_68_table[lut_68_select];
    
    assign out_data[68] = lut_68_out;
    
    
    
    // LUT : 69
    wire [15:0] lut_69_table = 16'b0010111100000000;
    wire [3:0] lut_69_select = {
                             in_data[4],
                             in_data[22],
                             in_data[10],
                             in_data[56]};
    
    wire lut_69_out = lut_69_table[lut_69_select];
    
    assign out_data[69] = lut_69_out;
    
    
    
    // LUT : 70
    wire [15:0] lut_70_table = 16'b0000111100000000;
    wire [3:0] lut_70_select = {
                             in_data[27],
                             in_data[57],
                             in_data[3],
                             in_data[8]};
    
    wire lut_70_out = lut_70_table[lut_70_select];
    
    assign out_data[70] = lut_70_out;
    
    
    
    // LUT : 71
    wire [15:0] lut_71_table = 16'b1000111011001100;
    wire [3:0] lut_71_select = {
                             in_data[42],
                             in_data[41],
                             in_data[21],
                             in_data[33]};
    
    wire lut_71_out = lut_71_table[lut_71_select];
    
    assign out_data[71] = lut_71_out;
    
    
    
    // LUT : 72
    wire [15:0] lut_72_table = 16'b1011101100000010;
    wire [3:0] lut_72_select = {
                             in_data[45],
                             in_data[51],
                             in_data[20],
                             in_data[43]};
    
    wire lut_72_out = lut_72_table[lut_72_select];
    
    assign out_data[72] = lut_72_out;
    
    
    
    // LUT : 73
    wire [15:0] lut_73_table = 16'b0001011111111111;
    wire [3:0] lut_73_select = {
                             in_data[30],
                             in_data[18],
                             in_data[32],
                             in_data[34]};
    
    wire lut_73_out = lut_73_table[lut_73_select];
    
    assign out_data[73] = lut_73_out;
    
    
    
    // LUT : 74
    wire [15:0] lut_74_table = 16'b0000010000010101;
    wire [3:0] lut_74_select = {
                             in_data[26],
                             in_data[35],
                             in_data[44],
                             in_data[15]};
    
    wire lut_74_out = lut_74_table[lut_74_select];
    
    assign out_data[74] = lut_74_out;
    
    
    
    // LUT : 75
    wire [15:0] lut_75_table = 16'b0011111100000010;
    wire [3:0] lut_75_select = {
                             in_data[1],
                             in_data[53],
                             in_data[58],
                             in_data[17]};
    
    wire lut_75_out = lut_75_table[lut_75_select];
    
    assign out_data[75] = lut_75_out;
    
    
    
    // LUT : 76
    wire [15:0] lut_76_table = 16'b0111001100010001;
    wire [3:0] lut_76_select = {
                             in_data[38],
                             in_data[16],
                             in_data[49],
                             in_data[11]};
    
    wire lut_76_out = lut_76_table[lut_76_select];
    
    assign out_data[76] = lut_76_out;
    
    
    
    // LUT : 77
    wire [15:0] lut_77_table = 16'b0101000111110111;
    wire [3:0] lut_77_select = {
                             in_data[39],
                             in_data[28],
                             in_data[6],
                             in_data[46]};
    
    wire lut_77_out = lut_77_table[lut_77_select];
    
    assign out_data[77] = lut_77_out;
    
    
    
    // LUT : 78
    wire [15:0] lut_78_table = 16'b0001000100110011;
    wire [3:0] lut_78_select = {
                             in_data[14],
                             in_data[60],
                             in_data[23],
                             in_data[36]};
    
    wire lut_78_out = lut_78_table[lut_78_select];
    
    assign out_data[78] = lut_78_out;
    
    
    
    // LUT : 79
    wire [15:0] lut_79_table = 16'b1111110110110000;
    wire [3:0] lut_79_select = {
                             in_data[48],
                             in_data[2],
                             in_data[54],
                             in_data[12]};
    
    wire lut_79_out = lut_79_table[lut_79_select];
    
    assign out_data[79] = lut_79_out;
    
    
    
    // LUT : 80
    wire [15:0] lut_80_table = 16'b1100110011101111;
    wire [3:0] lut_80_select = {
                             in_data[13],
                             in_data[59],
                             in_data[40],
                             in_data[8]};
    
    wire lut_80_out = lut_80_table[lut_80_select];
    
    assign out_data[80] = lut_80_out;
    
    
    
    // LUT : 81
    wire [15:0] lut_81_table = 16'b1111111110111010;
    wire [3:0] lut_81_select = {
                             in_data[61],
                             in_data[38],
                             in_data[39],
                             in_data[33]};
    
    wire lut_81_out = lut_81_table[lut_81_select];
    
    assign out_data[81] = lut_81_out;
    
    
    
    // LUT : 82
    wire [15:0] lut_82_table = 16'b1010000011111110;
    wire [3:0] lut_82_select = {
                             in_data[58],
                             in_data[27],
                             in_data[60],
                             in_data[43]};
    
    wire lut_82_out = lut_82_table[lut_82_select];
    
    assign out_data[82] = lut_82_out;
    
    
    
    // LUT : 83
    wire [15:0] lut_83_table = 16'b1111000011101010;
    wire [3:0] lut_83_select = {
                             in_data[45],
                             in_data[25],
                             in_data[57],
                             in_data[36]};
    
    wire lut_83_out = lut_83_table[lut_83_select];
    
    assign out_data[83] = lut_83_out;
    
    
    
    // LUT : 84
    wire [15:0] lut_84_table = 16'b1000100010101000;
    wire [3:0] lut_84_select = {
                             in_data[41],
                             in_data[44],
                             in_data[14],
                             in_data[28]};
    
    wire lut_84_out = lut_84_table[lut_84_select];
    
    assign out_data[84] = lut_84_out;
    
    
    
    // LUT : 85
    wire [15:0] lut_85_table = 16'b1111010001110000;
    wire [3:0] lut_85_select = {
                             in_data[4],
                             in_data[26],
                             in_data[6],
                             in_data[32]};
    
    wire lut_85_out = lut_85_table[lut_85_select];
    
    assign out_data[85] = lut_85_out;
    
    
    
    // LUT : 86
    wire [15:0] lut_86_table = 16'b1111111100010000;
    wire [3:0] lut_86_select = {
                             in_data[51],
                             in_data[35],
                             in_data[50],
                             in_data[1]};
    
    wire lut_86_out = lut_86_table[lut_86_select];
    
    assign out_data[86] = lut_86_out;
    
    
    
    // LUT : 87
    wire [15:0] lut_87_table = 16'b0000100000011111;
    wire [3:0] lut_87_select = {
                             in_data[23],
                             in_data[16],
                             in_data[48],
                             in_data[30]};
    
    wire lut_87_out = lut_87_table[lut_87_select];
    
    assign out_data[87] = lut_87_out;
    
    
    
    // LUT : 88
    wire [15:0] lut_88_table = 16'b0011001000111011;
    wire [3:0] lut_88_select = {
                             in_data[7],
                             in_data[47],
                             in_data[5],
                             in_data[18]};
    
    wire lut_88_out = lut_88_table[lut_88_select];
    
    assign out_data[88] = lut_88_out;
    
    
    
    // LUT : 89
    wire [15:0] lut_89_table = 16'b0000000000101011;
    wire [3:0] lut_89_select = {
                             in_data[56],
                             in_data[49],
                             in_data[22],
                             in_data[24]};
    
    wire lut_89_out = lut_89_table[lut_89_select];
    
    assign out_data[89] = lut_89_out;
    
    
    
    // LUT : 90
    wire [15:0] lut_90_table = 16'b0010101010101010;
    wire [3:0] lut_90_select = {
                             in_data[29],
                             in_data[10],
                             in_data[37],
                             in_data[12]};
    
    wire lut_90_out = lut_90_table[lut_90_select];
    
    assign out_data[90] = lut_90_out;
    
    
    
    // LUT : 91
    wire [15:0] lut_91_table = 16'b0000000001010101;
    wire [3:0] lut_91_select = {
                             in_data[54],
                             in_data[52],
                             in_data[19],
                             in_data[53]};
    
    wire lut_91_out = lut_91_table[lut_91_select];
    
    assign out_data[91] = lut_91_out;
    
    
    
    // LUT : 92
    wire [15:0] lut_92_table = 16'b0000010100001101;
    wire [3:0] lut_92_select = {
                             in_data[62],
                             in_data[46],
                             in_data[9],
                             in_data[15]};
    
    wire lut_92_out = lut_92_table[lut_92_select];
    
    assign out_data[92] = lut_92_out;
    
    
    
    // LUT : 93
    wire [15:0] lut_93_table = 16'b0010000100010001;
    wire [3:0] lut_93_select = {
                             in_data[20],
                             in_data[21],
                             in_data[55],
                             in_data[17]};
    
    wire lut_93_out = lut_93_table[lut_93_select];
    
    assign out_data[93] = lut_93_out;
    
    
    
    // LUT : 94
    wire [15:0] lut_94_table = 16'b1110111011101010;
    wire [3:0] lut_94_select = {
                             in_data[0],
                             in_data[31],
                             in_data[34],
                             in_data[11]};
    
    wire lut_94_out = lut_94_table[lut_94_select];
    
    assign out_data[94] = lut_94_out;
    
    
    
    // LUT : 95
    wire [15:0] lut_95_table = 16'b0000000000001010;
    wire [3:0] lut_95_select = {
                             in_data[3],
                             in_data[2],
                             in_data[42],
                             in_data[63]};
    
    wire lut_95_out = lut_95_table[lut_95_select];
    
    assign out_data[95] = lut_95_out;
    
    
    
    // LUT : 96
    wire [15:0] lut_96_table = 16'b0100010011101100;
    wire [3:0] lut_96_select = {
                             in_data[29],
                             in_data[53],
                             in_data[27],
                             in_data[24]};
    
    wire lut_96_out = lut_96_table[lut_96_select];
    
    assign out_data[96] = lut_96_out;
    
    
    
    // LUT : 97
    wire [15:0] lut_97_table = 16'b1111111111100010;
    wire [3:0] lut_97_select = {
                             in_data[54],
                             in_data[5],
                             in_data[49],
                             in_data[12]};
    
    wire lut_97_out = lut_97_table[lut_97_select];
    
    assign out_data[97] = lut_97_out;
    
    
    
    // LUT : 98
    wire [15:0] lut_98_table = 16'b0011001100000000;
    wire [3:0] lut_98_select = {
                             in_data[30],
                             in_data[61],
                             in_data[56],
                             in_data[14]};
    
    wire lut_98_out = lut_98_table[lut_98_select];
    
    assign out_data[98] = lut_98_out;
    
    
    
    // LUT : 99
    wire [15:0] lut_99_table = 16'b1101111101000100;
    wire [3:0] lut_99_select = {
                             in_data[18],
                             in_data[31],
                             in_data[33],
                             in_data[2]};
    
    wire lut_99_out = lut_99_table[lut_99_select];
    
    assign out_data[99] = lut_99_out;
    
    
    
    // LUT : 100
    wire [15:0] lut_100_table = 16'b1110110011101010;
    wire [3:0] lut_100_select = {
                             in_data[20],
                             in_data[63],
                             in_data[9],
                             in_data[60]};
    
    wire lut_100_out = lut_100_table[lut_100_select];
    
    assign out_data[100] = lut_100_out;
    
    
    
    // LUT : 101
    wire [15:0] lut_101_table = 16'b1000111010001010;
    wire [3:0] lut_101_select = {
                             in_data[0],
                             in_data[48],
                             in_data[25],
                             in_data[58]};
    
    wire lut_101_out = lut_101_table[lut_101_select];
    
    assign out_data[101] = lut_101_out;
    
    
    
    // LUT : 102
    wire [15:0] lut_102_table = 16'b0000000101110111;
    wire [3:0] lut_102_select = {
                             in_data[57],
                             in_data[35],
                             in_data[7],
                             in_data[39]};
    
    wire lut_102_out = lut_102_table[lut_102_select];
    
    assign out_data[102] = lut_102_out;
    
    
    
    // LUT : 103
    wire [15:0] lut_103_table = 16'b1000111000001000;
    wire [3:0] lut_103_select = {
                             in_data[16],
                             in_data[41],
                             in_data[32],
                             in_data[1]};
    
    wire lut_103_out = lut_103_table[lut_103_select];
    
    assign out_data[103] = lut_103_out;
    
    
    
    // LUT : 104
    wire [15:0] lut_104_table = 16'b0010111100000011;
    wire [3:0] lut_104_select = {
                             in_data[42],
                             in_data[50],
                             in_data[11],
                             in_data[43]};
    
    wire lut_104_out = lut_104_table[lut_104_select];
    
    assign out_data[104] = lut_104_out;
    
    
    
    // LUT : 105
    wire [15:0] lut_105_table = 16'b0011000011111011;
    wire [3:0] lut_105_select = {
                             in_data[44],
                             in_data[13],
                             in_data[26],
                             in_data[28]};
    
    wire lut_105_out = lut_105_table[lut_105_select];
    
    assign out_data[105] = lut_105_out;
    
    
    
    // LUT : 106
    wire [15:0] lut_106_table = 16'b0000000000110010;
    wire [3:0] lut_106_select = {
                             in_data[23],
                             in_data[21],
                             in_data[36],
                             in_data[19]};
    
    wire lut_106_out = lut_106_table[lut_106_select];
    
    assign out_data[106] = lut_106_out;
    
    
    
    // LUT : 107
    wire [15:0] lut_107_table = 16'b1011101111110010;
    wire [3:0] lut_107_select = {
                             in_data[10],
                             in_data[40],
                             in_data[8],
                             in_data[45]};
    
    wire lut_107_out = lut_107_table[lut_107_select];
    
    assign out_data[107] = lut_107_out;
    
    
    
    // LUT : 108
    wire [15:0] lut_108_table = 16'b0101010111111101;
    wire [3:0] lut_108_select = {
                             in_data[52],
                             in_data[15],
                             in_data[34],
                             in_data[51]};
    
    wire lut_108_out = lut_108_table[lut_108_select];
    
    assign out_data[108] = lut_108_out;
    
    
    
    // LUT : 109
    wire [15:0] lut_109_table = 16'b0010111111101111;
    wire [3:0] lut_109_select = {
                             in_data[3],
                             in_data[59],
                             in_data[37],
                             in_data[55]};
    
    wire lut_109_out = lut_109_table[lut_109_select];
    
    assign out_data[109] = lut_109_out;
    
    
    
    // LUT : 110
    wire [15:0] lut_110_table = 16'b0000101010101010;
    wire [3:0] lut_110_select = {
                             in_data[4],
                             in_data[17],
                             in_data[47],
                             in_data[6]};
    
    wire lut_110_out = lut_110_table[lut_110_select];
    
    assign out_data[110] = lut_110_out;
    
    
    
    // LUT : 111
    wire [15:0] lut_111_table = 16'b1111010101000101;
    wire [3:0] lut_111_select = {
                             in_data[38],
                             in_data[22],
                             in_data[62],
                             in_data[46]};
    
    wire lut_111_out = lut_111_table[lut_111_select];
    
    assign out_data[111] = lut_111_out;
    
    
    
    // LUT : 112
    wire [15:0] lut_112_table = 16'b0000111101001111;
    wire [3:0] lut_112_select = {
                             in_data[15],
                             in_data[39],
                             in_data[26],
                             in_data[34]};
    
    wire lut_112_out = lut_112_table[lut_112_select];
    
    assign out_data[112] = lut_112_out;
    
    
    
    // LUT : 113
    wire [15:0] lut_113_table = 16'b1011101100000000;
    wire [3:0] lut_113_select = {
                             in_data[2],
                             in_data[49],
                             in_data[56],
                             in_data[59]};
    
    wire lut_113_out = lut_113_table[lut_113_select];
    
    assign out_data[113] = lut_113_out;
    
    
    
    // LUT : 114
    wire [15:0] lut_114_table = 16'b1110100010001000;
    wire [3:0] lut_114_select = {
                             in_data[42],
                             in_data[38],
                             in_data[24],
                             in_data[31]};
    
    wire lut_114_out = lut_114_table[lut_114_select];
    
    assign out_data[114] = lut_114_out;
    
    
    
    // LUT : 115
    wire [15:0] lut_115_table = 16'b0010001000111011;
    wire [3:0] lut_115_select = {
                             in_data[40],
                             in_data[19],
                             in_data[63],
                             in_data[17]};
    
    wire lut_115_out = lut_115_table[lut_115_select];
    
    assign out_data[115] = lut_115_out;
    
    
    
    // LUT : 116
    wire [15:0] lut_116_table = 16'b1110111110001010;
    wire [3:0] lut_116_select = {
                             in_data[18],
                             in_data[22],
                             in_data[6],
                             in_data[50]};
    
    wire lut_116_out = lut_116_table[lut_116_select];
    
    assign out_data[116] = lut_116_out;
    
    
    
    // LUT : 117
    wire [15:0] lut_117_table = 16'b0000111100001101;
    wire [3:0] lut_117_select = {
                             in_data[32],
                             in_data[53],
                             in_data[54],
                             in_data[1]};
    
    wire lut_117_out = lut_117_table[lut_117_select];
    
    assign out_data[117] = lut_117_out;
    
    
    
    // LUT : 118
    wire [15:0] lut_118_table = 16'b1011101100110011;
    wire [3:0] lut_118_select = {
                             in_data[8],
                             in_data[55],
                             in_data[62],
                             in_data[30]};
    
    wire lut_118_out = lut_118_table[lut_118_select];
    
    assign out_data[118] = lut_118_out;
    
    
    
    // LUT : 119
    wire [15:0] lut_119_table = 16'b1010001011111011;
    wire [3:0] lut_119_select = {
                             in_data[25],
                             in_data[33],
                             in_data[61],
                             in_data[58]};
    
    wire lut_119_out = lut_119_table[lut_119_select];
    
    assign out_data[119] = lut_119_out;
    
    
    
    // LUT : 120
    wire [15:0] lut_120_table = 16'b1010101010111111;
    wire [3:0] lut_120_select = {
                             in_data[37],
                             in_data[52],
                             in_data[28],
                             in_data[36]};
    
    wire lut_120_out = lut_120_table[lut_120_select];
    
    assign out_data[120] = lut_120_out;
    
    
    
    // LUT : 121
    wire [15:0] lut_121_table = 16'b1010101011111110;
    wire [3:0] lut_121_select = {
                             in_data[48],
                             in_data[46],
                             in_data[27],
                             in_data[10]};
    
    wire lut_121_out = lut_121_table[lut_121_select];
    
    assign out_data[121] = lut_121_out;
    
    
    
    // LUT : 122
    wire [15:0] lut_122_table = 16'b0000010101011111;
    wire [3:0] lut_122_select = {
                             in_data[45],
                             in_data[9],
                             in_data[57],
                             in_data[4]};
    
    wire lut_122_out = lut_122_table[lut_122_select];
    
    assign out_data[122] = lut_122_out;
    
    
    
    // LUT : 123
    wire [15:0] lut_123_table = 16'b1101010101010000;
    wire [3:0] lut_123_select = {
                             in_data[0],
                             in_data[16],
                             in_data[44],
                             in_data[5]};
    
    wire lut_123_out = lut_123_table[lut_123_select];
    
    assign out_data[123] = lut_123_out;
    
    
    
    // LUT : 124
    wire [15:0] lut_124_table = 16'b1000111010001110;
    wire [3:0] lut_124_select = {
                             in_data[35],
                             in_data[43],
                             in_data[3],
                             in_data[7]};
    
    wire lut_124_out = lut_124_table[lut_124_select];
    
    assign out_data[124] = lut_124_out;
    
    
    
    // LUT : 125
    wire [15:0] lut_125_table = 16'b1101110101000100;
    wire [3:0] lut_125_select = {
                             in_data[20],
                             in_data[21],
                             in_data[12],
                             in_data[14]};
    
    wire lut_125_out = lut_125_table[lut_125_select];
    
    assign out_data[125] = lut_125_out;
    
    
    
    // LUT : 126
    wire [15:0] lut_126_table = 16'b1111000011111011;
    wire [3:0] lut_126_select = {
                             in_data[41],
                             in_data[13],
                             in_data[23],
                             in_data[60]};
    
    wire lut_126_out = lut_126_table[lut_126_select];
    
    assign out_data[126] = lut_126_out;
    
    
    
    // LUT : 127
    wire [15:0] lut_127_table = 16'b0000001000101011;
    wire [3:0] lut_127_select = {
                             in_data[29],
                             in_data[47],
                             in_data[51],
                             in_data[11]};
    
    wire lut_127_out = lut_127_table[lut_127_select];
    
    assign out_data[127] = lut_127_out;
    
    
    
    // LUT : 128
    wire [15:0] lut_128_table = 16'b1000111100000011;
    wire [3:0] lut_128_select = {
                             in_data[47],
                             in_data[12],
                             in_data[52],
                             in_data[26]};
    
    wire lut_128_out = lut_128_table[lut_128_select];
    
    assign out_data[128] = lut_128_out;
    
    
    
    // LUT : 129
    wire [15:0] lut_129_table = 16'b0000000011110011;
    wire [3:0] lut_129_select = {
                             in_data[54],
                             in_data[2],
                             in_data[7],
                             in_data[15]};
    
    wire lut_129_out = lut_129_table[lut_129_select];
    
    assign out_data[129] = lut_129_out;
    
    
    
    // LUT : 130
    wire [15:0] lut_130_table = 16'b0111010100000000;
    wire [3:0] lut_130_select = {
                             in_data[24],
                             in_data[27],
                             in_data[0],
                             in_data[40]};
    
    wire lut_130_out = lut_130_table[lut_130_select];
    
    assign out_data[130] = lut_130_out;
    
    
    
    // LUT : 131
    wire [15:0] lut_131_table = 16'b1011000010110000;
    wire [3:0] lut_131_select = {
                             in_data[25],
                             in_data[44],
                             in_data[56],
                             in_data[53]};
    
    wire lut_131_out = lut_131_table[lut_131_select];
    
    assign out_data[131] = lut_131_out;
    
    
    
    // LUT : 132
    wire [15:0] lut_132_table = 16'b0101001100000001;
    wire [3:0] lut_132_select = {
                             in_data[6],
                             in_data[57],
                             in_data[10],
                             in_data[8]};
    
    wire lut_132_out = lut_132_table[lut_132_select];
    
    assign out_data[132] = lut_132_out;
    
    
    
    // LUT : 133
    wire [15:0] lut_133_table = 16'b0011001100010011;
    wire [3:0] lut_133_select = {
                             in_data[13],
                             in_data[36],
                             in_data[43],
                             in_data[33]};
    
    wire lut_133_out = lut_133_table[lut_133_select];
    
    assign out_data[133] = lut_133_out;
    
    
    
    // LUT : 134
    wire [15:0] lut_134_table = 16'b1111001011111111;
    wire [3:0] lut_134_select = {
                             in_data[63],
                             in_data[55],
                             in_data[46],
                             in_data[9]};
    
    wire lut_134_out = lut_134_table[lut_134_select];
    
    assign out_data[134] = lut_134_out;
    
    
    
    // LUT : 135
    wire [15:0] lut_135_table = 16'b1010000010101010;
    wire [3:0] lut_135_select = {
                             in_data[4],
                             in_data[14],
                             in_data[21],
                             in_data[39]};
    
    wire lut_135_out = lut_135_table[lut_135_select];
    
    assign out_data[135] = lut_135_out;
    
    
    
    // LUT : 136
    wire [15:0] lut_136_table = 16'b1111110111010101;
    wire [3:0] lut_136_select = {
                             in_data[18],
                             in_data[5],
                             in_data[11],
                             in_data[59]};
    
    wire lut_136_out = lut_136_table[lut_136_select];
    
    assign out_data[136] = lut_136_out;
    
    
    
    // LUT : 137
    wire [15:0] lut_137_table = 16'b0010000000101010;
    wire [3:0] lut_137_select = {
                             in_data[60],
                             in_data[45],
                             in_data[34],
                             in_data[32]};
    
    wire lut_137_out = lut_137_table[lut_137_select];
    
    assign out_data[137] = lut_137_out;
    
    
    
    // LUT : 138
    wire [15:0] lut_138_table = 16'b0011111100111111;
    wire [3:0] lut_138_select = {
                             in_data[17],
                             in_data[41],
                             in_data[31],
                             in_data[22]};
    
    wire lut_138_out = lut_138_table[lut_138_select];
    
    assign out_data[138] = lut_138_out;
    
    
    
    // LUT : 139
    wire [15:0] lut_139_table = 16'b1111110100000000;
    wire [3:0] lut_139_select = {
                             in_data[3],
                             in_data[58],
                             in_data[16],
                             in_data[51]};
    
    wire lut_139_out = lut_139_table[lut_139_select];
    
    assign out_data[139] = lut_139_out;
    
    
    
    // LUT : 140
    wire [15:0] lut_140_table = 16'b0011001011110010;
    wire [3:0] lut_140_select = {
                             in_data[1],
                             in_data[35],
                             in_data[23],
                             in_data[28]};
    
    wire lut_140_out = lut_140_table[lut_140_select];
    
    assign out_data[140] = lut_140_out;
    
    
    
    // LUT : 141
    wire [15:0] lut_141_table = 16'b1000000001000100;
    wire [3:0] lut_141_select = {
                             in_data[38],
                             in_data[37],
                             in_data[19],
                             in_data[30]};
    
    wire lut_141_out = lut_141_table[lut_141_select];
    
    assign out_data[141] = lut_141_out;
    
    
    
    // LUT : 142
    wire [15:0] lut_142_table = 16'b1110100011111000;
    wire [3:0] lut_142_select = {
                             in_data[29],
                             in_data[48],
                             in_data[62],
                             in_data[49]};
    
    wire lut_142_out = lut_142_table[lut_142_select];
    
    assign out_data[142] = lut_142_out;
    
    
    
    // LUT : 143
    wire [15:0] lut_143_table = 16'b0000001010100010;
    wire [3:0] lut_143_select = {
                             in_data[61],
                             in_data[42],
                             in_data[20],
                             in_data[50]};
    
    wire lut_143_out = lut_143_table[lut_143_select];
    
    assign out_data[143] = lut_143_out;
    
    
    
    // LUT : 144
    wire [15:0] lut_144_table = 16'b1111010101010100;
    wire [3:0] lut_144_select = {
                             in_data[55],
                             in_data[59],
                             in_data[61],
                             in_data[51]};
    
    wire lut_144_out = lut_144_table[lut_144_select];
    
    assign out_data[144] = lut_144_out;
    
    
    
    // LUT : 145
    wire [15:0] lut_145_table = 16'b0101110111001101;
    wire [3:0] lut_145_select = {
                             in_data[27],
                             in_data[43],
                             in_data[4],
                             in_data[0]};
    
    wire lut_145_out = lut_145_table[lut_145_select];
    
    assign out_data[145] = lut_145_out;
    
    
    
    // LUT : 146
    wire [15:0] lut_146_table = 16'b1111111100001000;
    wire [3:0] lut_146_select = {
                             in_data[30],
                             in_data[58],
                             in_data[41],
                             in_data[24]};
    
    wire lut_146_out = lut_146_table[lut_146_select];
    
    assign out_data[146] = lut_146_out;
    
    
    
    // LUT : 147
    wire [15:0] lut_147_table = 16'b0101000001010001;
    wire [3:0] lut_147_select = {
                             in_data[48],
                             in_data[39],
                             in_data[12],
                             in_data[6]};
    
    wire lut_147_out = lut_147_table[lut_147_select];
    
    assign out_data[147] = lut_147_out;
    
    
    
    // LUT : 148
    wire [15:0] lut_148_table = 16'b1100110011111101;
    wire [3:0] lut_148_select = {
                             in_data[13],
                             in_data[15],
                             in_data[21],
                             in_data[19]};
    
    wire lut_148_out = lut_148_table[lut_148_select];
    
    assign out_data[148] = lut_148_out;
    
    
    
    // LUT : 149
    wire [15:0] lut_149_table = 16'b1100111100000000;
    wire [3:0] lut_149_select = {
                             in_data[38],
                             in_data[52],
                             in_data[26],
                             in_data[54]};
    
    wire lut_149_out = lut_149_table[lut_149_select];
    
    assign out_data[149] = lut_149_out;
    
    
    
    // LUT : 150
    wire [15:0] lut_150_table = 16'b0000000011111011;
    wire [3:0] lut_150_select = {
                             in_data[36],
                             in_data[5],
                             in_data[46],
                             in_data[31]};
    
    wire lut_150_out = lut_150_table[lut_150_select];
    
    assign out_data[150] = lut_150_out;
    
    
    
    // LUT : 151
    wire [15:0] lut_151_table = 16'b0101000011010001;
    wire [3:0] lut_151_select = {
                             in_data[42],
                             in_data[47],
                             in_data[3],
                             in_data[8]};
    
    wire lut_151_out = lut_151_table[lut_151_select];
    
    assign out_data[151] = lut_151_out;
    
    
    
    // LUT : 152
    wire [15:0] lut_152_table = 16'b0100111111111111;
    wire [3:0] lut_152_select = {
                             in_data[44],
                             in_data[9],
                             in_data[17],
                             in_data[37]};
    
    wire lut_152_out = lut_152_table[lut_152_select];
    
    assign out_data[152] = lut_152_out;
    
    
    
    // LUT : 153
    wire [15:0] lut_153_table = 16'b1110111110100000;
    wire [3:0] lut_153_select = {
                             in_data[33],
                             in_data[7],
                             in_data[1],
                             in_data[25]};
    
    wire lut_153_out = lut_153_table[lut_153_select];
    
    assign out_data[153] = lut_153_out;
    
    
    
    // LUT : 154
    wire [15:0] lut_154_table = 16'b1100010001010100;
    wire [3:0] lut_154_select = {
                             in_data[50],
                             in_data[63],
                             in_data[28],
                             in_data[45]};
    
    wire lut_154_out = lut_154_table[lut_154_select];
    
    assign out_data[154] = lut_154_out;
    
    
    
    // LUT : 155
    wire [15:0] lut_155_table = 16'b1000110011001101;
    wire [3:0] lut_155_select = {
                             in_data[40],
                             in_data[23],
                             in_data[14],
                             in_data[53]};
    
    wire lut_155_out = lut_155_table[lut_155_select];
    
    assign out_data[155] = lut_155_out;
    
    
    
    // LUT : 156
    wire [15:0] lut_156_table = 16'b0010001100100010;
    wire [3:0] lut_156_select = {
                             in_data[49],
                             in_data[20],
                             in_data[29],
                             in_data[56]};
    
    wire lut_156_out = lut_156_table[lut_156_select];
    
    assign out_data[156] = lut_156_out;
    
    
    
    // LUT : 157
    wire [15:0] lut_157_table = 16'b0100010001010101;
    wire [3:0] lut_157_select = {
                             in_data[60],
                             in_data[34],
                             in_data[2],
                             in_data[57]};
    
    wire lut_157_out = lut_157_table[lut_157_select];
    
    assign out_data[157] = lut_157_out;
    
    
    
    // LUT : 158
    wire [15:0] lut_158_table = 16'b1111001111110011;
    wire [3:0] lut_158_select = {
                             in_data[10],
                             in_data[18],
                             in_data[62],
                             in_data[22]};
    
    wire lut_158_out = lut_158_table[lut_158_select];
    
    assign out_data[158] = lut_158_out;
    
    
    
    // LUT : 159
    wire [15:0] lut_159_table = 16'b0100110001011101;
    wire [3:0] lut_159_select = {
                             in_data[11],
                             in_data[32],
                             in_data[16],
                             in_data[35]};
    
    wire lut_159_out = lut_159_table[lut_159_select];
    
    assign out_data[159] = lut_159_out;
    
    
endmodule



module MnistLut4Simple_sub7
        #(
            parameter INIT_REG = 1'bx,
            parameter DEVICE   = "RTL"
        )
        (
            input  wire         reset,
            input  wire         clk,
            input  wire         cke,
            
            input  wire [159:0]  in_data,
            output wire [39:0]  out_data
        );
    
    
    // LUT : 0
    wire [15:0] lut_0_table = 16'b1111010001000000;
    wire [3:0] lut_0_select = {
                             in_data[3],
                             in_data[2],
                             in_data[1],
                             in_data[0]};
    
    wire lut_0_out = lut_0_table[lut_0_select];
    
    assign out_data[0] = lut_0_out;
    
    
    
    // LUT : 1
    wire [15:0] lut_1_table = 16'b1110101010001000;
    wire [3:0] lut_1_select = {
                             in_data[7],
                             in_data[6],
                             in_data[5],
                             in_data[4]};
    
    wire lut_1_out = lut_1_table[lut_1_select];
    
    assign out_data[1] = lut_1_out;
    
    
    
    // LUT : 2
    wire [15:0] lut_2_table = 16'b0111001100110000;
    wire [3:0] lut_2_select = {
                             in_data[11],
                             in_data[10],
                             in_data[9],
                             in_data[8]};
    
    wire lut_2_out = lut_2_table[lut_2_select];
    
    assign out_data[2] = lut_2_out;
    
    
    
    // LUT : 3
    wire [15:0] lut_3_table = 16'b0000010001001111;
    wire [3:0] lut_3_select = {
                             in_data[15],
                             in_data[14],
                             in_data[13],
                             in_data[12]};
    
    wire lut_3_out = lut_3_table[lut_3_select];
    
    assign out_data[3] = lut_3_out;
    
    
    
    // LUT : 4
    wire [15:0] lut_4_table = 16'b0000110010001111;
    wire [3:0] lut_4_select = {
                             in_data[19],
                             in_data[18],
                             in_data[17],
                             in_data[16]};
    
    wire lut_4_out = lut_4_table[lut_4_select];
    
    assign out_data[4] = lut_4_out;
    
    
    
    // LUT : 5
    wire [15:0] lut_5_table = 16'b0001000101110111;
    wire [3:0] lut_5_select = {
                             in_data[23],
                             in_data[22],
                             in_data[21],
                             in_data[20]};
    
    wire lut_5_out = lut_5_table[lut_5_select];
    
    assign out_data[5] = lut_5_out;
    
    
    
    // LUT : 6
    wire [15:0] lut_6_table = 16'b1111101011100000;
    wire [3:0] lut_6_select = {
                             in_data[27],
                             in_data[26],
                             in_data[25],
                             in_data[24]};
    
    wire lut_6_out = lut_6_table[lut_6_select];
    
    assign out_data[6] = lut_6_out;
    
    
    
    // LUT : 7
    wire [15:0] lut_7_table = 16'b1000111010001000;
    wire [3:0] lut_7_select = {
                             in_data[31],
                             in_data[30],
                             in_data[29],
                             in_data[28]};
    
    wire lut_7_out = lut_7_table[lut_7_select];
    
    assign out_data[7] = lut_7_out;
    
    
    
    // LUT : 8
    wire [15:0] lut_8_table = 16'b1011101000100000;
    wire [3:0] lut_8_select = {
                             in_data[35],
                             in_data[34],
                             in_data[33],
                             in_data[32]};
    
    wire lut_8_out = lut_8_table[lut_8_select];
    
    assign out_data[8] = lut_8_out;
    
    
    
    // LUT : 9
    wire [15:0] lut_9_table = 16'b1000000011101000;
    wire [3:0] lut_9_select = {
                             in_data[39],
                             in_data[38],
                             in_data[37],
                             in_data[36]};
    
    wire lut_9_out = lut_9_table[lut_9_select];
    
    assign out_data[9] = lut_9_out;
    
    
    
    // LUT : 10
    wire [15:0] lut_10_table = 16'b0100110100000101;
    wire [3:0] lut_10_select = {
                             in_data[43],
                             in_data[42],
                             in_data[41],
                             in_data[40]};
    
    wire lut_10_out = lut_10_table[lut_10_select];
    
    assign out_data[10] = lut_10_out;
    
    
    
    // LUT : 11
    wire [15:0] lut_11_table = 16'b0001000001110011;
    wire [3:0] lut_11_select = {
                             in_data[47],
                             in_data[46],
                             in_data[45],
                             in_data[44]};
    
    wire lut_11_out = lut_11_table[lut_11_select];
    
    assign out_data[11] = lut_11_out;
    
    
    
    // LUT : 12
    wire [15:0] lut_12_table = 16'b1100010011011101;
    wire [3:0] lut_12_select = {
                             in_data[51],
                             in_data[50],
                             in_data[49],
                             in_data[48]};
    
    wire lut_12_out = lut_12_table[lut_12_select];
    
    assign out_data[12] = lut_12_out;
    
    
    
    // LUT : 13
    wire [15:0] lut_13_table = 16'b0010001110101011;
    wire [3:0] lut_13_select = {
                             in_data[55],
                             in_data[54],
                             in_data[53],
                             in_data[52]};
    
    wire lut_13_out = lut_13_table[lut_13_select];
    
    assign out_data[13] = lut_13_out;
    
    
    
    // LUT : 14
    wire [15:0] lut_14_table = 16'b0111111100000001;
    wire [3:0] lut_14_select = {
                             in_data[59],
                             in_data[58],
                             in_data[57],
                             in_data[56]};
    
    wire lut_14_out = lut_14_table[lut_14_select];
    
    assign out_data[14] = lut_14_out;
    
    
    
    // LUT : 15
    wire [15:0] lut_15_table = 16'b0011001011111011;
    wire [3:0] lut_15_select = {
                             in_data[63],
                             in_data[62],
                             in_data[61],
                             in_data[60]};
    
    wire lut_15_out = lut_15_table[lut_15_select];
    
    assign out_data[15] = lut_15_out;
    
    
    
    // LUT : 16
    wire [15:0] lut_16_table = 16'b0011000011110111;
    wire [3:0] lut_16_select = {
                             in_data[67],
                             in_data[66],
                             in_data[65],
                             in_data[64]};
    
    wire lut_16_out = lut_16_table[lut_16_select];
    
    assign out_data[16] = lut_16_out;
    
    
    
    // LUT : 17
    wire [15:0] lut_17_table = 16'b1111111011101000;
    wire [3:0] lut_17_select = {
                             in_data[71],
                             in_data[70],
                             in_data[69],
                             in_data[68]};
    
    wire lut_17_out = lut_17_table[lut_17_select];
    
    assign out_data[17] = lut_17_out;
    
    
    
    // LUT : 18
    wire [15:0] lut_18_table = 16'b1010001011110011;
    wire [3:0] lut_18_select = {
                             in_data[75],
                             in_data[74],
                             in_data[73],
                             in_data[72]};
    
    wire lut_18_out = lut_18_table[lut_18_select];
    
    assign out_data[18] = lut_18_out;
    
    
    
    // LUT : 19
    wire [15:0] lut_19_table = 16'b0010101000101011;
    wire [3:0] lut_19_select = {
                             in_data[79],
                             in_data[78],
                             in_data[77],
                             in_data[76]};
    
    wire lut_19_out = lut_19_table[lut_19_select];
    
    assign out_data[19] = lut_19_out;
    
    
    
    // LUT : 20
    wire [15:0] lut_20_table = 16'b1000111000001000;
    wire [3:0] lut_20_select = {
                             in_data[83],
                             in_data[82],
                             in_data[81],
                             in_data[80]};
    
    wire lut_20_out = lut_20_table[lut_20_select];
    
    assign out_data[20] = lut_20_out;
    
    
    
    // LUT : 21
    wire [15:0] lut_21_table = 16'b1011101100001010;
    wire [3:0] lut_21_select = {
                             in_data[87],
                             in_data[86],
                             in_data[85],
                             in_data[84]};
    
    wire lut_21_out = lut_21_table[lut_21_select];
    
    assign out_data[21] = lut_21_out;
    
    
    
    // LUT : 22
    wire [15:0] lut_22_table = 16'b1100111101001100;
    wire [3:0] lut_22_select = {
                             in_data[91],
                             in_data[90],
                             in_data[89],
                             in_data[88]};
    
    wire lut_22_out = lut_22_table[lut_22_select];
    
    assign out_data[22] = lut_22_out;
    
    
    
    // LUT : 23
    wire [15:0] lut_23_table = 16'b1000110010001110;
    wire [3:0] lut_23_select = {
                             in_data[95],
                             in_data[94],
                             in_data[93],
                             in_data[92]};
    
    wire lut_23_out = lut_23_table[lut_23_select];
    
    assign out_data[23] = lut_23_out;
    
    
    
    // LUT : 24
    wire [15:0] lut_24_table = 16'b1101010101010000;
    wire [3:0] lut_24_select = {
                             in_data[99],
                             in_data[98],
                             in_data[97],
                             in_data[96]};
    
    wire lut_24_out = lut_24_table[lut_24_select];
    
    assign out_data[24] = lut_24_out;
    
    
    
    // LUT : 25
    wire [15:0] lut_25_table = 16'b1110100010100000;
    wire [3:0] lut_25_select = {
                             in_data[103],
                             in_data[102],
                             in_data[101],
                             in_data[100]};
    
    wire lut_25_out = lut_25_table[lut_25_select];
    
    assign out_data[25] = lut_25_out;
    
    
    
    // LUT : 26
    wire [15:0] lut_26_table = 16'b1010000011101000;
    wire [3:0] lut_26_select = {
                             in_data[107],
                             in_data[106],
                             in_data[105],
                             in_data[104]};
    
    wire lut_26_out = lut_26_table[lut_26_select];
    
    assign out_data[26] = lut_26_out;
    
    
    
    // LUT : 27
    wire [15:0] lut_27_table = 16'b1101010001000000;
    wire [3:0] lut_27_select = {
                             in_data[111],
                             in_data[110],
                             in_data[109],
                             in_data[108]};
    
    wire lut_27_out = lut_27_table[lut_27_select];
    
    assign out_data[27] = lut_27_out;
    
    
    
    // LUT : 28
    wire [15:0] lut_28_table = 16'b0100110101000100;
    wire [3:0] lut_28_select = {
                             in_data[115],
                             in_data[114],
                             in_data[113],
                             in_data[112]};
    
    wire lut_28_out = lut_28_table[lut_28_select];
    
    assign out_data[28] = lut_28_out;
    
    
    
    // LUT : 29
    wire [15:0] lut_29_table = 16'b0000011100010111;
    wire [3:0] lut_29_select = {
                             in_data[119],
                             in_data[118],
                             in_data[117],
                             in_data[116]};
    
    wire lut_29_out = lut_29_table[lut_29_select];
    
    assign out_data[29] = lut_29_out;
    
    
    
    // LUT : 30
    wire [15:0] lut_30_table = 16'b1000111100001000;
    wire [3:0] lut_30_select = {
                             in_data[123],
                             in_data[122],
                             in_data[121],
                             in_data[120]};
    
    wire lut_30_out = lut_30_table[lut_30_select];
    
    assign out_data[30] = lut_30_out;
    
    
    
    // LUT : 31
    wire [15:0] lut_31_table = 16'b1100111100001100;
    wire [3:0] lut_31_select = {
                             in_data[127],
                             in_data[126],
                             in_data[125],
                             in_data[124]};
    
    wire lut_31_out = lut_31_table[lut_31_select];
    
    assign out_data[31] = lut_31_out;
    
    
    
    // LUT : 32
    wire [15:0] lut_32_table = 16'b0011000010111010;
    wire [3:0] lut_32_select = {
                             in_data[131],
                             in_data[130],
                             in_data[129],
                             in_data[128]};
    
    wire lut_32_out = lut_32_table[lut_32_select];
    
    assign out_data[32] = lut_32_out;
    
    
    
    // LUT : 33
    wire [15:0] lut_33_table = 16'b0101110101000101;
    wire [3:0] lut_33_select = {
                             in_data[135],
                             in_data[134],
                             in_data[133],
                             in_data[132]};
    
    wire lut_33_out = lut_33_table[lut_33_select];
    
    assign out_data[33] = lut_33_out;
    
    
    
    // LUT : 34
    wire [15:0] lut_34_table = 16'b1110111000001000;
    wire [3:0] lut_34_select = {
                             in_data[139],
                             in_data[138],
                             in_data[137],
                             in_data[136]};
    
    wire lut_34_out = lut_34_table[lut_34_select];
    
    assign out_data[34] = lut_34_out;
    
    
    
    // LUT : 35
    wire [15:0] lut_35_table = 16'b1111001101010000;
    wire [3:0] lut_35_select = {
                             in_data[143],
                             in_data[142],
                             in_data[141],
                             in_data[140]};
    
    wire lut_35_out = lut_35_table[lut_35_select];
    
    assign out_data[35] = lut_35_out;
    
    
    
    // LUT : 36
    wire [15:0] lut_36_table = 16'b1110110010001000;
    wire [3:0] lut_36_select = {
                             in_data[147],
                             in_data[146],
                             in_data[145],
                             in_data[144]};
    
    wire lut_36_out = lut_36_table[lut_36_select];
    
    assign out_data[36] = lut_36_out;
    
    
    
    // LUT : 37
    wire [15:0] lut_37_table = 16'b0100110111011111;
    wire [3:0] lut_37_select = {
                             in_data[151],
                             in_data[150],
                             in_data[149],
                             in_data[148]};
    
    wire lut_37_out = lut_37_table[lut_37_select];
    
    assign out_data[37] = lut_37_out;
    
    
    
    // LUT : 38
    wire [15:0] lut_38_table = 16'b0000010101011101;
    wire [3:0] lut_38_select = {
                             in_data[155],
                             in_data[154],
                             in_data[153],
                             in_data[152]};
    
    wire lut_38_out = lut_38_table[lut_38_select];
    
    assign out_data[38] = lut_38_out;
    
    
    
    // LUT : 39
    wire [15:0] lut_39_table = 16'b0000111000001110;
    wire [3:0] lut_39_select = {
                             in_data[159],
                             in_data[158],
                             in_data[157],
                             in_data[156]};
    
    wire lut_39_out = lut_39_table[lut_39_select];
    
    assign out_data[39] = lut_39_out;
    
    
endmodule



module MnistLut4Simple_sub8
        #(
            parameter INIT_REG = 1'bx,
            parameter DEVICE   = "RTL"
        )
        (
            input  wire         reset,
            input  wire         clk,
            input  wire         cke,
            
            input  wire [39:0]  in_data,
            output wire [9:0]  out_data
        );
    
    
    // LUT : 0
    wire [15:0] lut_0_table = 16'b1110100010000000;
    wire [3:0] lut_0_select = {
                             in_data[3],
                             in_data[2],
                             in_data[1],
                             in_data[0]};
    
    wire lut_0_out = lut_0_table[lut_0_select];
    
    assign out_data[0] = lut_0_out;
    
    
    
    // LUT : 1
    wire [15:0] lut_1_table = 16'b1110100010000000;
    wire [3:0] lut_1_select = {
                             in_data[7],
                             in_data[6],
                             in_data[5],
                             in_data[4]};
    
    wire lut_1_out = lut_1_table[lut_1_select];
    
    assign out_data[1] = lut_1_out;
    
    
    
    // LUT : 2
    wire [15:0] lut_2_table = 16'b1110100010000000;
    wire [3:0] lut_2_select = {
                             in_data[11],
                             in_data[10],
                             in_data[9],
                             in_data[8]};
    
    wire lut_2_out = lut_2_table[lut_2_select];
    
    assign out_data[2] = lut_2_out;
    
    
    
    // LUT : 3
    wire [15:0] lut_3_table = 16'b1110100010000000;
    wire [3:0] lut_3_select = {
                             in_data[15],
                             in_data[14],
                             in_data[13],
                             in_data[12]};
    
    wire lut_3_out = lut_3_table[lut_3_select];
    
    assign out_data[3] = lut_3_out;
    
    
    
    // LUT : 4
    wire [15:0] lut_4_table = 16'b1110100010000000;
    wire [3:0] lut_4_select = {
                             in_data[19],
                             in_data[18],
                             in_data[17],
                             in_data[16]};
    
    wire lut_4_out = lut_4_table[lut_4_select];
    
    assign out_data[4] = lut_4_out;
    
    
    
    // LUT : 5
    wire [15:0] lut_5_table = 16'b1110100010000000;
    wire [3:0] lut_5_select = {
                             in_data[23],
                             in_data[22],
                             in_data[21],
                             in_data[20]};
    
    wire lut_5_out = lut_5_table[lut_5_select];
    
    assign out_data[5] = lut_5_out;
    
    
    
    // LUT : 6
    wire [15:0] lut_6_table = 16'b1110100010000000;
    wire [3:0] lut_6_select = {
                             in_data[27],
                             in_data[26],
                             in_data[25],
                             in_data[24]};
    
    wire lut_6_out = lut_6_table[lut_6_select];
    
    assign out_data[6] = lut_6_out;
    
    
    
    // LUT : 7
    wire [15:0] lut_7_table = 16'b1110100010000000;
    wire [3:0] lut_7_select = {
                             in_data[31],
                             in_data[30],
                             in_data[29],
                             in_data[28]};
    
    wire lut_7_out = lut_7_table[lut_7_select];
    
    assign out_data[7] = lut_7_out;
    
    
    
    // LUT : 8
    wire [15:0] lut_8_table = 16'b1110100010000000;
    wire [3:0] lut_8_select = {
                             in_data[35],
                             in_data[34],
                             in_data[33],
                             in_data[32]};
    
    wire lut_8_out = lut_8_table[lut_8_select];
    
    assign out_data[8] = lut_8_out;
    
    
    
    // LUT : 9
    wire [15:0] lut_9_table = 16'b1110100010000000;
    wire [3:0] lut_9_select = {
                             in_data[39],
                             in_data[38],
                             in_data[37],
                             in_data[36]};
    
    wire lut_9_out = lut_9_table[lut_9_select];
    
    assign out_data[9] = lut_9_out;
    
    
endmodule

