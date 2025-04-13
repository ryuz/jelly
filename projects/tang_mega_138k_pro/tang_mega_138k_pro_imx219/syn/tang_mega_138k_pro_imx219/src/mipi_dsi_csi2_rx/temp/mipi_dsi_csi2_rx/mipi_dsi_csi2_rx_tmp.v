//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.11.01 (64-bit)
//Part Number: GW5AST-LV138FPG676AES
//Device: GW5AST-138
//Device Version: B
//Created Time: Sun Apr 13 18:58:13 2025

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	MIPI_DSI_CSI2_RX_Top your_instance_name(
		.I_RSTN(I_RSTN), //input I_RSTN
		.I_BYTE_CLK(I_BYTE_CLK), //input I_BYTE_CLK
		.I_REF_DT(I_REF_DT), //input [5:0] I_REF_DT
		.I_READY(I_READY), //input I_READY
		.I_DATA0(I_DATA0), //input [7:0] I_DATA0
		.I_DATA1(I_DATA1), //input [7:0] I_DATA1
		.O_SP_EN(O_SP_EN), //output O_SP_EN
		.O_LP_EN(O_LP_EN), //output O_LP_EN
		.O_LP_AV_EN(O_LP_AV_EN), //output O_LP_AV_EN
		.O_ECC_OK(O_ECC_OK), //output O_ECC_OK
		.O_ECC(O_ECC), //output [7:0] O_ECC
		.O_WC(O_WC), //output [15:0] O_WC
		.O_VC(O_VC), //output [1:0] O_VC
		.O_DT(O_DT), //output [5:0] O_DT
		.O_PAYLOAD(O_PAYLOAD), //output [15:0] O_PAYLOAD
		.O_PAYLOAD_DV(O_PAYLOAD_DV) //output [1:0] O_PAYLOAD_DV
	);

//--------Copy end-------------------
