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
#include "xil_cache.h"

#include "xparameters.h"
#include "sleep.h"
#include "xiicps.h"



#define IMG_MEM_ADDR						0x30000000

#define VIN_NORM_BASE_ADDR					0x40011000
#define	VIN_NORM_REG_CONTROL      			(VIN_NORM_BASE_ADDR + 0x00*4)
#define	VIN_NORM_REG_BUSY         			(VIN_NORM_BASE_ADDR + 0x01*4)
#define	VIN_NORM_REG_INDEX        			(VIN_NORM_BASE_ADDR + 0x02*4)
#define	VIN_NORM_REG_SKIP         			(VIN_NORM_BASE_ADDR + 0x03*4)
#define	VIN_NORM_REG_FRM_TIMER_EN 			(VIN_NORM_BASE_ADDR + 0x04*4)
#define	VIN_NORM_REG_FRM_TIMEOUT  			(VIN_NORM_BASE_ADDR + 0x05*4)
#define	VIN_NORM_REG_PARAM_WIDTH  			(VIN_NORM_BASE_ADDR + 0x08*4)
#define	VIN_NORM_REG_PARAM_HEIGHT 			(VIN_NORM_BASE_ADDR + 0x09*4)
#define	VIN_NORM_REG_PARAM_FILL   			(VIN_NORM_BASE_ADDR + 0x0a*4)
#define	VIN_NORM_REG_PARAM_TIMEOUT			(VIN_NORM_BASE_ADDR + 0x0b*4)

#define VDMAW_BASE_ADDR						0x40010000
#define VDMAW_REG_ID						(VDMAW_BASE_ADDR + 0x0000)
#define VDMAW_REG_VERSION					(VDMAW_BASE_ADDR + 0x0004)
#define VDMAW_REG_CTL_CONTROL				(VDMAW_BASE_ADDR + 0x0010)
#define VDMAW_REG_CTL_STATUS				(VDMAW_BASE_ADDR + 0x0014)
#define VDMAW_REG_CTL_INDEX 				(VDMAW_BASE_ADDR + 0x001c)
#define VDMAW_REG_PARAM_ADDR				(VDMAW_BASE_ADDR + 0x0020)
#define VDMAW_REG_PARAM_STRIDE				(VDMAW_BASE_ADDR + 0x0024)
#define VDMAW_REG_PARAM_WIDTH				(VDMAW_BASE_ADDR + 0x0028)
#define VDMAW_REG_PARAM_HEIGHT				(VDMAW_BASE_ADDR + 0x002c)
#define VDMAW_REG_PARAM_SIZE				(VDMAW_BASE_ADDR + 0x0030)
#define VDMAW_REG_PARAM_AWLEN				(VDMAW_BASE_ADDR + 0x003c)
#define VDMAW_REG_MONITOR_ADDR				(VDMAW_BASE_ADDR + 0x0040)
#define VDMAW_REG_MONITOR_STRIDE			(VDMAW_BASE_ADDR + 0x0044)
#define VDMAW_REG_MONITOR_WIDTH 			(VDMAW_BASE_ADDR + 0x0048)
#define VDMAW_REG_MONITOR_HEIGHT			(VDMAW_BASE_ADDR + 0x004c)
#define VDMAW_REG_MONITOR_SIZE				(VDMAW_BASE_ADDR + 0x0050)
#define VDMAW_REG_MONITOR_AWLEN 			(VDMAW_BASE_ADDR + 0x005c)

#define VDMAR_BASE_ADDR 					0x40020000
#define VDMAR_REG_ID						(VDMAR_BASE_ADDR + 0x0000)
#define VDMAR_REG_VERSION					(VDMAR_BASE_ADDR + 0x0004)
#define VDMAR_REG_CTL_CONTROL				(VDMAR_BASE_ADDR + 0x0010)
#define VDMAR_REG_CTL_STATUS				(VDMAR_BASE_ADDR + 0x0014)
#define VDMAR_REG_CTL_INDEX 				(VDMAR_BASE_ADDR + 0x001c)
#define VDMAR_REG_PARAM_ADDR				(VDMAR_BASE_ADDR + 0x0020)
#define VDMAR_REG_PARAM_STRIDE				(VDMAR_BASE_ADDR + 0x0024)
#define VDMAR_REG_PARAM_WIDTH				(VDMAR_BASE_ADDR + 0x0028)
#define VDMAR_REG_PARAM_HEIGHT				(VDMAR_BASE_ADDR + 0x002c)
#define VDMAR_REG_PARAM_SIZE				(VDMAR_BASE_ADDR + 0x0030)
#define VDMAR_REG_PARAM_ARLEN				(VDMAR_BASE_ADDR + 0x003c)
#define VDMAR_REG_MONITOR_ADDR				(VDMAR_BASE_ADDR + 0x0040)
#define VDMAR_REG_MONITOR_STRIDE			(VDMAR_BASE_ADDR + 0x0044)
#define VDMAR_REG_MONITOR_WIDTH 			(VDMAR_BASE_ADDR + 0x0048)
#define VDMAR_REG_MONITOR_HEIGHT			(VDMAR_BASE_ADDR + 0x004c)
#define VDMAR_REG_MONITOR_SIZE				(VDMAR_BASE_ADDR + 0x0050)
#define VDMAR_REG_MONITOR_ARLEN 			(VDMAR_BASE_ADDR + 0x005c)

#define	VOUT_VSGEN_BASE_ADDR				0x40021000
#define	VOUT_VSGEN_REG_ID                	(VOUT_VSGEN_BASE_ADDR + 0x0000)
#define	VOUT_VSGEN_REG_VERSION           	(VOUT_VSGEN_BASE_ADDR + 0x0004)
#define	VOUT_VSGEN_REG_CTL_CONTROL       	(VOUT_VSGEN_BASE_ADDR + 0x0010)
#define	VOUT_VSGEN_REG_CTL_STATUS        	(VOUT_VSGEN_BASE_ADDR + 0x0014)
#define	VOUT_VSGEN_REG_PARAM_HTOTAL      	(VOUT_VSGEN_BASE_ADDR + 0x0020)
#define	VOUT_VSGEN_REG_PARAM_HSYNC_POL   	(VOUT_VSGEN_BASE_ADDR + 0x002c)
#define	VOUT_VSGEN_REG_PARAM_HDISP_START 	(VOUT_VSGEN_BASE_ADDR + 0x0030)
#define	VOUT_VSGEN_REG_PARAM_HDISP_END   	(VOUT_VSGEN_BASE_ADDR + 0x0034)
#define	VOUT_VSGEN_REG_PARAM_HSYNC_START 	(VOUT_VSGEN_BASE_ADDR + 0x0038)
#define	VOUT_VSGEN_REG_PARAM_HSYNC_END   	(VOUT_VSGEN_BASE_ADDR + 0x003c)
#define	VOUT_VSGEN_REG_PARAM_VTOTAL      	(VOUT_VSGEN_BASE_ADDR + 0x0040)
#define	VOUT_VSGEN_REG_PARAM_VSYNC_POL   	(VOUT_VSGEN_BASE_ADDR + 0x004c)
#define	VOUT_VSGEN_REG_PARAM_VDISP_START 	(VOUT_VSGEN_BASE_ADDR + 0x0050)
#define	VOUT_VSGEN_REG_PARAM_VDISP_END   	(VOUT_VSGEN_BASE_ADDR + 0x0054)
#define	VOUT_VSGEN_REG_PARAM_VSYNC_START 	(VOUT_VSGEN_BASE_ADDR + 0x0058)
#define	VOUT_VSGEN_REG_PARAM_VSYNC_END   	(VOUT_VSGEN_BASE_ADDR + 0x005c)


void imx219_init(int width, int height);


int main()
{
//	int width  = 1640;
//	int height = 1232;
//	int stride = width*4;
	int width  = 640;
	int height = 132;
	int stride = 8192;

    init_platform();
    Xil_DCacheDisable();

    print("Start IMX219\n\r");

#if 0
    int data = *(volatile unsigned int *)0x40000000;
    printf("%08x\n\r", data);


    volatile unsigned char* p = (volatile unsigned char*)IMG_MEM_ADDR;
    for ( i = 0; i < 16; i++ ) {
        printf("%02x ", p[i]);
    }
    printf("\n\r");
    memset((void *)IMG_MEM_ADDR, 0, 256);
    for ( i = 0; i < 16; i++ ) {
        printf("%02x ", p[i]);
    }
    printf("\n\r");
#endif


    imx219_init(width, height);

    /*
	*(volatile unsigned int *)VDMAW_REG_CTL_CONTROL  = 0x0;
	*(volatile unsigned int *)VDMAR_REG_CTL_CONTROL  = 0x0;
	usleep(100000);
    *(volatile unsigned int *)VIN_NORM_REG_CONTROL   = 0;
	usleep(100000);
	*/

    *(volatile unsigned int *)VIN_NORM_REG_PARAM_WIDTH  = width;
	*(volatile unsigned int *)VIN_NORM_REG_PARAM_HEIGHT = height;
    *(volatile unsigned int *)VIN_NORM_REG_CONTROL      = 1;

	// start write
	*(volatile unsigned int *)VDMAW_REG_PARAM_ADDR   = IMG_MEM_ADDR;
	*(volatile unsigned int *)VDMAW_REG_PARAM_STRIDE = stride;			// stride
	*(volatile unsigned int *)VDMAW_REG_PARAM_WIDTH  = width;			// width
	*(volatile unsigned int *)VDMAW_REG_PARAM_HEIGHT = height;			// height
	*(volatile unsigned int *)VDMAW_REG_PARAM_SIZE   = width*height;    //16*1024*1024;	// size
	*(volatile unsigned int *)VDMAW_REG_PARAM_AWLEN  = 31;				// awlen
	*(volatile unsigned int *)VDMAW_REG_CTL_CONTROL  = 0x03;

	// start read
	*(volatile unsigned int *)VDMAR_REG_PARAM_ADDR   = IMG_MEM_ADDR;
	*(volatile unsigned int *)VDMAR_REG_PARAM_STRIDE = stride;
	*(volatile unsigned int *)VDMAR_REG_PARAM_WIDTH  = 1280;
	*(volatile unsigned int *)VDMAR_REG_PARAM_HEIGHT = 720;
	*(volatile unsigned int *)VDMAR_REG_PARAM_SIZE   = 1280*720;
	*(volatile unsigned int *)VDMAR_REG_PARAM_ARLEN  = 31;
	*(volatile unsigned int *)VDMAR_REG_CTL_CONTROL  = 0x3;

	*(volatile unsigned int *)VOUT_VSGEN_REG_CTL_CONTROL = 1;		// control

#if 0
	while ( 1 ) {
		*(volatile unsigned int *)VDMAW_REG_PARAM_ADDR   = IMG_MEM_ADDR;
		*(volatile unsigned int *)VDMAW_REG_PARAM_STRIDE = 1640*4;			// stride
		*(volatile unsigned int *)VDMAW_REG_PARAM_WIDTH  = 1640;			// width
		*(volatile unsigned int *)VDMAW_REG_PARAM_HEIGHT = 1232;			// height
		*(volatile unsigned int *)VDMAW_REG_PARAM_SIZE   = 16*1024*1024;	// size
		*(volatile unsigned int *)VDMAW_REG_PARAM_AWLEN  = 31;				// awlen
		*(volatile unsigned int *)VDMAW_REG_CTL_CONTROL  = 0x07;	// oneshot

		// Žæ‚èž‚ÝŠ®—¹‚ð‘Ò‚Â
		while ( (*(volatile unsigned int *)0x40010014) != 0 ) {
			usleep(1000);
		}

	    for ( i = 0; i < 16; i++ ) {
	        printf("%02x ", p[i]);
	    }
	    printf("\n\r");
    }
#endif

    cleanup_platform();

    return 0;
}
