/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"


void gpu_write(unsigned long addr, unsigned long data)
{
	*(volatile unsigned long *)(0x40000000 + addr) = data;
}

unsigned long gpu_read(unsigned long addr)
{
	return *(volatile unsigned long *)(0x40000000 + addr);
}


void TestGpu()
{
	printf("edge");
	gpu_write(0x1000, 0xfffff74f);
	gpu_write(0x1004, 0x0015b1fe);
	gpu_write(0x1008, 0x00090905);
	gpu_write(0x100c, 0xffffff1b);
	gpu_write(0x1010, 0x000243dd);
	gpu_write(0x1014, 0xfff8146a);
	gpu_write(0x1018, 0xfffff705);
	gpu_write(0x101c, 0x00166a2f);
	gpu_write(0x1020, 0x000e8a0e);
	gpu_write(0x1024, 0xffffff65);
	gpu_write(0x1028, 0x00018bac);
	gpu_write(0x102c, 0xfffbf927);
	gpu_write(0x1030, 0xfffffec5);
	gpu_write(0x1034, 0x00031bdb);
	gpu_write(0x1038, 0xfff45ade);
	gpu_write(0x103c, 0xfffff608);
	gpu_write(0x1040, 0x0018e275);
	gpu_write(0x1044, 0x00083a84);
	gpu_write(0x1048, 0xffffff27);
	gpu_write(0x104c, 0x000227f1);
	gpu_write(0x1050, 0xfff97d9b);
	gpu_write(0x1054, 0xfffff5a6);
	gpu_write(0x1058, 0x0019d65f);
	gpu_write(0x105c, 0x000fbccd);
	gpu_write(0x1060, 0xfffffd02);
	gpu_write(0x1064, 0x00077669);
	gpu_write(0x1068, 0x0005b10f);
	gpu_write(0x106c, 0xfffffd40);
	gpu_write(0x1070, 0x0006da24);
	gpu_write(0x1074, 0x00048a9f);
	gpu_write(0x1078, 0xfffffba3);
	gpu_write(0x107c, 0x000ae299);
	gpu_write(0x1080, 0x0008a117);
	gpu_write(0x1084, 0xfffffbf9);
	gpu_write(0x1088, 0x000a0a9b);
	gpu_write(0x108c, 0x00075be9);

	/*
	printf("polygon(tuv)");
	gpu_write(0x2000, 0x0000000d);
	gpu_write(0x2004, 0xffffdf7b);
	gpu_write(0x2008, 0x0000a897);
	gpu_write(0x200c, 0xffffffec);
	gpu_write(0x2010, 0x00003318);
	gpu_write(0x2014, 0xffff75c6);
	gpu_write(0x2018, 0x00000148);
	gpu_write(0x201c, 0xfffccd41);
	gpu_write(0x2020, 0xfffeaaba);
	gpu_write(0x2024, 0x00000010);
	gpu_write(0x2028, 0xffffd7fa);
	gpu_write(0x202c, 0x0000ce0e);
	gpu_write(0x2030, 0xfffffec3);
	gpu_write(0x2034, 0x0003173b);
	gpu_write(0x2038, 0x0001e1c4);
	gpu_write(0x203c, 0x0000002a);
	gpu_write(0x2040, 0xffff95e1);
	gpu_write(0x2044, 0x0001907c);
	gpu_write(0x2048, 0x00000000);
	gpu_write(0x204c, 0x000000b5);
	gpu_write(0x2050, 0x00004c70);
	gpu_write(0x2054, 0x00000130);
	gpu_write(0x2058, 0xfffd0a88);
	gpu_write(0x205c, 0xfffe0976);
	gpu_write(0x2060, 0xffffffb4);
	gpu_write(0x2064, 0x0000c203);
	gpu_write(0x2068, 0xfffe0529);
	gpu_write(0x206c, 0xfffffe6a);
	gpu_write(0x2070, 0x0003f548);
	gpu_write(0x2074, 0x0003506a);
	gpu_write(0x2078, 0x00000261);
	gpu_write(0x207c, 0xfffa1125);
	gpu_write(0x2080, 0xfffb7a0a);
	gpu_write(0x2084, 0xfffff6fb);
	gpu_write(0x2088, 0x00168326);
	gpu_write(0x208c, 0x000e9b06);
	gpu_write(0x2090, 0x00000000);
	gpu_write(0x2094, 0x0000006d);
	gpu_write(0x2098, 0x00002ddd);
	gpu_write(0x209c, 0xfffffed0);
	gpu_write(0x20a0, 0x0002f665);
	gpu_write(0x20a4, 0x000259ea);
	gpu_write(0x20a8, 0xffffffb4);
	gpu_write(0x20ac, 0x0000c072);
	gpu_write(0x20b0, 0xfffd5cfe);
	gpu_write(0x20b4, 0xffffff52);
	gpu_write(0x20b8, 0x0001b244);
	gpu_write(0x20bc, 0x00016b9b);
	gpu_write(0x20c0, 0xfffffe4d);
	gpu_write(0x20c4, 0x00043c98);
	gpu_write(0x20c8, 0x00031a5b);
	gpu_write(0x20cc, 0xfffffbf7);
	gpu_write(0x20d0, 0x000a128d);
	gpu_write(0x20d4, 0x00043094);
	*/

	printf("polygon(rgb)");
	gpu_write(0x2000, 0x00000000);
	gpu_write(0x2004, 0x00000000);
	gpu_write(0x2008, 0x00080000);
	gpu_write(0x200c, 0x00001f12);
	gpu_write(0x2010, 0xffb27169);
	gpu_write(0x2014, 0xffdfbf5b);
	gpu_write(0x2018, 0xfffffcce);
	gpu_write(0x201c, 0x00081753);
	gpu_write(0x2020, 0xfff3a761);
	gpu_write(0x2024, 0x00000000);
	gpu_write(0x2028, 0x00000000);
	gpu_write(0x202c, 0x00080000);
	gpu_write(0x2030, 0x0000034f);
	gpu_write(0x2034, 0xfff7a3fe);
	gpu_write(0x2038, 0x001f56fb);
	gpu_write(0x203c, 0xffffe525);
	gpu_write(0x2040, 0x004309ca);
	gpu_write(0x2044, 0x002628fa);
	gpu_write(0x2048, 0x00000000);
	gpu_write(0x204c, 0x00000000);
	gpu_write(0x2050, 0x00080000);
	gpu_write(0x2054, 0xfffffa50);
	gpu_write(0x2058, 0x000e84be);
	gpu_write(0x205c, 0xffda20c3);
	gpu_write(0x2060, 0x00001c23);
	gpu_write(0x2064, 0xffb9d39c);
	gpu_write(0x2068, 0xffda828d);
	gpu_write(0x206c, 0x00000000);
	gpu_write(0x2070, 0x00000000);
	gpu_write(0x2074, 0x00080000);
	gpu_write(0x2078, 0xffff465f);
	gpu_write(0x207c, 0x01cf51fe);
	gpu_write(0x2080, 0x012c8572);
	gpu_write(0x2084, 0x00005a34);
	gpu_write(0x2088, 0xff1ef80d);
	gpu_write(0x208c, 0xff5dba00);
	gpu_write(0x2090, 0x00000000);
	gpu_write(0x2094, 0x00000000);
	gpu_write(0x2098, 0x00080000);
	gpu_write(0x209c, 0xfffff99d);
	gpu_write(0x20a0, 0x00102c19);
	gpu_write(0x20a4, 0xffc75ca1);
	gpu_write(0x20a8, 0xffffe338);
	gpu_write(0x20ac, 0x0047c2be);
	gpu_write(0x20b0, 0x00448cd4);
	gpu_write(0x20b4, 0x00000000);
	gpu_write(0x20b8, 0x00000000);
	gpu_write(0x20bc, 0x00080000);
	gpu_write(0x20c0, 0xffffaf23);
	gpu_write(0x20c4, 0x00c9d95b);
	gpu_write(0x20c8, 0x0053ef20);
	gpu_write(0x20cc, 0xffffe669);
	gpu_write(0x20d0, 0x003fc301);
	gpu_write(0x20d4, 0x003a3af9);

	printf("region");
	gpu_write(0x3000, 0x0000000f);
	gpu_write(0x3004, 0x0000000c);
	gpu_write(0x3008, 0x000000f0);
	gpu_write(0x300c, 0x00000030);
	gpu_write(0x3010, 0x00000348);
	gpu_write(0x3014, 0x00000240);
	gpu_write(0x3018, 0x00000584);
	gpu_write(0x301c, 0x00000180);
	gpu_write(0x3020, 0x00000c12);
	gpu_write(0x3024, 0x00000402);
	gpu_write(0x3028, 0x00000a21);
	gpu_write(0x302c, 0x00000801);

	printf("start");
	gpu_write(0x0000, 0x00000001);
}


void rasterizer_test(void);

int main()
{
    init_platform();

    print("Hello World\n\r");

    printf("%08lx\r\n", gpu_read(0x00));
    printf("%08lx\r\n", gpu_read(0x04));
    printf("%08lx\r\n", gpu_read(0x08));
    printf("%08lx\r\n", gpu_read(0x0c));
    TestGpu();

    rasterizer_test();

    cleanup_platform();
    return 0;
}
