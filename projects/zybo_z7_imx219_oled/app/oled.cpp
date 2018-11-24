

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>
#include <sys/ioctl.h>



/////////////////// OLED //////////////

#define OLEDRGB_WIDTH  96
#define OLEDRGB_HEIGHT 64

#define OLEDRGB_CHARBYTES    8    // Number of bytes in a glyph
#define	OLEDRGB_USERCHAR_MAX 0x20 // Number of character defs in user font
                                    // table
#define OLEDRGB_CHARBYTES_USER (OLEDRGB_USERCHAR_MAX*OLEDRGB_CHARBYTES)
                               // Number of bytes in user font table

#define CMD_DRAWLINE                   0x21
#define CMD_DRAWRECTANGLE              0x22
#define CMD_COPYWINDOW                 0x23
#define CMD_DIMWINDOW                  0x24
#define CMD_CLEARWINDOW                0x25
#define CMD_FILLWINDOW                 0x26
#define DISABLE_FILL                   0x00
#define ENABLE_FILL                    0x01
#define CMD_CONTINUOUSSCROLLINGSETUP   0x27
#define CMD_DEACTIVESCROLLING          0x2E
#define CMD_ACTIVESCROLLING            0x2F

#define CMD_SETCOLUMNADDRESS           0x15
#define CMD_SETROWADDRESS              0x75
#define CMD_SETCONTRASTA               0x81
#define CMD_SETCONTRASTB               0x82
#define CMD_SETCONTRASTC               0x83
#define CMD_MASTERCURRENTCONTROL       0x87
#define CMD_SETPRECHARGESPEEDA         0x8A
#define CMD_SETPRECHARGESPEEDB         0x8B
#define CMD_SETPRECHARGESPEEDC         0x8C
#define CMD_SETREMAP                   0xA0
#define CMD_SETDISPLAYSTARTLINE        0xA1
#define CMD_SETDISPLAYOFFSET           0xA2
#define CMD_NORMALDISPLAY              0xA4
#define CMD_ENTIREDISPLAYON            0xA5
#define CMD_ENTIREDISPLAYOFF           0xA6
#define CMD_INVERSEDISPLAY             0xA7
#define CMD_SETMULTIPLEXRATIO          0xA8
#define CMD_DIMMODESETTING             0xAB
#define CMD_SETMASTERCONFIGURE         0xAD
#define CMD_DIMMODEDISPLAYON           0xAC
#define CMD_DISPLAYOFF                 0xAE
#define CMD_DISPLAYON                  0xAF
#define CMD_POWERSAVEMODE              0xB0
#define CMD_PHASEPERIODADJUSTMENT      0xB1
#define CMD_DISPLAYCLOCKDIV            0xB3
#define CMD_SETGRAySCALETABLE          0xB8
#define CMD_ENABLELINEARGRAYSCALETABLE 0xB9
#define CMD_SETPRECHARGEVOLTAGE        0xBB
#define CMD_SETVVOLTAGE                0xBE


typedef unsigned char u8;

#include "UioMmap.h"


static UioMmap* um_pl_peri;

void oled_init(UioMmap* p)
{
	um_pl_peri = p;
}


void my_wait(long time)
{
	usleep(time);
}


void oled_write_cmd(unsigned char cmd)
{
	um_pl_peri->WriteWord32(0x00022010, (unsigned long)cmd | 0x100);
}

void oled_write_data(unsigned char cmd)
{
	um_pl_peri->WriteWord32(0x00022010, (unsigned long)cmd);
}


void oled_setup(void)
{
	// BS (8080 mode)
	um_pl_peri->WriteWord32(0x00022004, 0x00000003);

	// PWR_ON
	um_pl_peri->WriteWord32(0x00022008, 0x00000001);
	my_wait(10000);
	
	// reset
	um_pl_peri->WriteWord32(0x00022000, 0x00000000);
	my_wait(10000);
	um_pl_peri->WriteWord32(0x00022000, 0x00000001);
	my_wait(10000);

	while ( 0 ) {
		um_pl_peri->WriteWord32(0x00022010, 0x00000055);
		um_pl_peri->WriteWord32(0x00022010, 0x000000aa);
		um_pl_peri->WriteWord32(0x00022010, 0x00000155);
		um_pl_peri->WriteWord32(0x00022010, 0x000001aa);
	}


	// Command un-lock
	oled_write_cmd(0xFD);
	oled_write_cmd(0x12);

	// 5. Univision Initialization Steps
	// 5a) Set Display Off
	oled_write_cmd(CMD_DISPLAYOFF);

	// 5b) Set Remap and Data Format
	oled_write_cmd(CMD_SETREMAP);
//	oled_write_cmd(0x72);			// color format?
	oled_write_cmd(0x32);			// color format?

	// 5c) Set Display Start Line
	oled_write_cmd(CMD_SETDISPLAYSTARTLINE);
	oled_write_cmd(0x00); // Start line is set at upper left corner
	// 5d) Set Display Offset
	oled_write_cmd(CMD_SETDISPLAYOFFSET);
	oled_write_cmd(0x00); //no offset
	// 5e)
	oled_write_cmd(CMD_NORMALDISPLAY);
	// 5f) Set Multiplex Ratio
	oled_write_cmd(CMD_SETMULTIPLEXRATIO);
	oled_write_cmd(0x3F); //64MUX
	// 5g)Set Master Configuration
	oled_write_cmd(CMD_SETMASTERCONFIGURE);
	oled_write_cmd(0x8E);
	// 5h)Set Power Saving Mode
	oled_write_cmd(CMD_POWERSAVEMODE);
	oled_write_cmd(0x0B);
	// 5i) Set Phase Length
	oled_write_cmd(CMD_PHASEPERIODADJUSTMENT);
	oled_write_cmd(0x31); // Phase 2 = 14 DCLKs, phase 1 = 15 DCLKS
	// 5j) Send Clock Divide Ratio and Oscillator Frequency
	oled_write_cmd(CMD_DISPLAYCLOCKDIV);
	oled_write_cmd(0xF0); // Mid high oscillator frequency, DCLK = FpbCllk/2

	// 5k) Set Second Pre-charge Speed of Color A
	oled_write_cmd(CMD_SETPRECHARGESPEEDA);
	oled_write_cmd(0x64);
	// 5l) Set Set Second Pre-charge Speed of Color B
	oled_write_cmd(CMD_SETPRECHARGESPEEDB);
	oled_write_cmd(0x78);
	// 5m) Set Second Pre-charge Speed of Color C
	oled_write_cmd(CMD_SETPRECHARGESPEEDC);
	oled_write_cmd(0x64);
	// 5n) Set Pre-Charge Voltage
	oled_write_cmd(CMD_SETPRECHARGEVOLTAGE);
	oled_write_cmd(0x3A); // Pre-charge voltage =...Vcc
	// 50) Set VCOMH Deselect Level
	oled_write_cmd(CMD_SETVVOLTAGE);
	oled_write_cmd(0x3E); // Vcomh = ...*Vcc
	// 5p) Set Master Current
	oled_write_cmd(CMD_MASTERCURRENTCONTROL);
	oled_write_cmd(0x06);
	// 5q) Set Contrast for Color A
	oled_write_cmd(CMD_SETCONTRASTA);
	oled_write_cmd(0x91);
	// 5r) Set Contrast for Color B
	oled_write_cmd(CMD_SETCONTRASTB);
	oled_write_cmd(0x50);
	// 5s) Set Contrast for Color C
	oled_write_cmd(CMD_SETCONTRASTC);
	oled_write_cmd(0x7D);
	// Disable scrolling
	oled_write_cmd(CMD_DEACTIVESCROLLING);

#define	HIGH_SPEED	1

#if HIGH_SPEED
	// GS
	oled_write_cmd(CMD_SETGRAySCALETABLE);
	for ( int i = 0; i < 32; i++ ) {
		if      ( i < 20 ) { oled_write_cmd(0); }
		if      ( i < 22 ) { oled_write_cmd(5); }
		if      ( i < 25 ) { oled_write_cmd(5); }
		if      ( i < 27 ) { oled_write_cmd(5); }
		else if ( i < 29 ) { oled_write_cmd(5); }
		else               { oled_write_cmd(5); }
	}
#endif

	// 5u) Clear Screen
	oled_write_cmd(CMD_CLEARWINDOW);     // Enter the "clear mode"
	oled_write_cmd(0x00);                // Set the starting column coordinates
	oled_write_cmd(0x00);                // Set the starting row coordinates
	oled_write_cmd(OLEDRGB_WIDTH - 1);   // Set the finishing column coordinates;
	oled_write_cmd(OLEDRGB_HEIGHT - 1);  // Set the finishing row coordinates;
	my_wait(100000);

	// Turn on VCC and wait for it to become stable
	um_pl_peri->WriteWord32(0x0022008, 0x00000001);
	my_wait(10000);

	// Send Display On command
	oled_write_cmd(CMD_DISPLAYON);
	my_wait(100000);
}


void oled_draw_bitmap8(u8 c1, u8 r1, u8 c2, u8 r2, u8 *bitmapR, u8 *bitmapG, u8 *bitmapB, int sx, int sy)
{
   //set column start and end
   oled_write_cmd(CMD_SETCOLUMNADDRESS);
   oled_write_cmd(c1);                   // Set the starting column coordinates
   oled_write_cmd(c2);                   // Set the finishing column coordinates

   //set row start and end
   oled_write_cmd(CMD_SETROWADDRESS);
   oled_write_cmd(r1);                   // Set the starting row coordinates
   oled_write_cmd(r2);                   // Set the finishing row coordinates

   for ( int y = 0; y < 64; y++ ) {
	   int yy = (y+sy) % 64;
	   for ( int x = 0; x < 96; x++ ) {
		   int xx = (x+sx) % 96;
		   int idx = yy*96+xx;
		   int r = bitmapR[idx];
		   int g = bitmapG[idx];
		   int b = bitmapB[idx];
		   u8 dd = ((r & 0xe0) | ((g >> 3) & 0x1c) | ((b >> 6) & 0x03));
		   oled_write_data(dd);
	   }
   }
}


void oled_draw_bitmap8_x(u8 c1, u8 r1, u8 c2, u8 r2, u8 *bitmapR, u8 *bitmapG, u8 *bitmapB, int sx, int sy, int offset)
{
#if 0
   //set column start and end
   oled_write_cmd(CMD_SETCOLUMNADDRESS);
   oled_write_cmd(c1);                   // Set the starting column coordinates
   oled_write_cmd(c2);                   // Set the finishing column coordinates

   //set row start and end
   oled_write_cmd(CMD_SETROWADDRESS);
   oled_write_cmd(r1);                   // Set the starting row coordinates
   oled_write_cmd(r2);                   // Set the finishing row coordinates
#endif

   for ( int y = 0; y < 64; y++ ) {
	   int yy = (y+sy) % 64;
	   for ( int x = 0; x < 96; x++ ) {
		   int xx = (x+sx) % 96;
		   int idx = yy*96+xx;
		   int r = ((bitmapR[idx]/2+offset) & 0x80) ? 0xff : 0;
		   int g = ((bitmapG[idx]/2+offset) & 0x80) ? 0xff : 0;
		   int b = ((bitmapB[idx]/2+offset) & 0x80) ? 0xff : 0;
	//	   if ( r > 255 ) { r = 255; }
	//	   if ( g > 255 ) { g = 255; }
	//	   if ( b > 255 ) { b = 255; }
		   u8 dd = ((r & 0xe0) | ((g >> 3) & 0x1c) | ((b >> 6) & 0x03));
		   oled_write_data(dd);
	   }
   }
}

#include "bitmap.h"

u8 bitmap_r[64][96];
u8 bitmap_g[64][96];
u8 bitmap_b[64][96];


int oled_main()
{
    for ( int y = 0; y < 64; y++ ) {
 	   for ( int x = 0; x < 96; x++ ) {
		   int d = tommy[(y*96+x)*2+1] + (tommy[(y*96+x)*2+0] << 8);
		   bitmap_r[y][x] = ((d >> 8) & 0xf8);
		   bitmap_g[y][x] = ((d >> 3) & 0xfc);
		   bitmap_b[y][x] = ((d << 3) & 0xf8);
 	   }
    }


    float sx = 0;
    float sy = 0;
    float px = 0;
    float py = 0;

    oled_setup();

    //set column start and end
    oled_write_cmd(CMD_SETCOLUMNADDRESS);
    oled_write_cmd(0);                   // Set the starting column coordinates
    oled_write_cmd(95);                   // Set the finishing column coordinates

    //set row start and end
    oled_write_cmd(CMD_SETROWADDRESS);
    oled_write_cmd(0);                   // Set the starting row coordinates
    oled_write_cmd(63);                   // Set the finishing row coordinates

    // VOUT enable
    um_pl_peri->WriteWord32(0x002200c, 0x00000001);

#if 0
    int j = 0;
    int	sum_x = 0;
    int	sum_y = 0;
    int sum_n = 0;
	int ssx = 0;
	int ssy = 0;
    for ( int i = 0; i < 2000*2000; i++ )
    {
    	int dx = 0;// mpu.accel[0] - 184;
    	int dy = 0;// mpu.accel[1] - 81;
    	sum_x += dx;
    	sum_y += dy;
    	sum_n++;
//    	printf("%10d %10d\n", sum_x/sum_n, sum_y/sum_n);


    	sx +=  dx * (1.0f/40.0f);
    	sy += -dy * (1.0f/40.0f);
//    	printf("%10d %10d %10d  %10d %10d\n", mpu.accel[0], mpu.accel[1], mpu.accel[2], gx, gy);
    	sx = sx * 990 / 1000;
    	sy = sy * 990 / 1000;

    	px += sx / (1024*2);
    	py += sy / (1024*2);
    	px = px * 994 / 1000;
    	py = py * 994 / 1000;

#if HIGH_SPEED
	    ssx = (px + 96*4);
	    ssy = (py + 64*4);
#else
	    if ( i % 8 == 0 ) {
    	    ssx = (px + 96*4);
    	    ssy = (py + 64*4);
    	}
#endif

#if HIGH_SPEED
     	oled_draw_bitmap8_x(0, 0, 95, 63, (u8*)bitmap_r, (u8*)bitmap_g, (u8*)bitmap_b, ssx, 0, j<<4);
#else
//     	oled_draw_bitmap8(0, 0, 95, 63, (u8*)bitmap_r, (u8*)bitmap_g, (u8*)bitmap_b, i & ~0x7, 0);
     	oled_draw_bitmap8(0, 0, 95, 63, (u8*)bitmap_r, (u8*)bitmap_g, (u8*)bitmap_b, ssx, 0);
#endif

     	j++;
     	if ( j >= 8 ) { j = 0; }
//    	oled_draw_bitmap16(0, 0, 95, 63, (u8*)tommy, i);
    }
// 	oled_draw_bitmap8_x(0, 0, 95, 63, (u8*)bitmap_r, (u8*)bitmap_g, (u8*)bitmap_b, 0, 7<<4);

	// reset
//	um_pl_peri->WriteWord32(0x0022000, 0x00000000);
#endif
	
    return 0;
}

