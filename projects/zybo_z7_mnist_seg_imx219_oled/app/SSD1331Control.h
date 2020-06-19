


#ifndef	__JELLY__SSD1331_CONTROL_H__
#define __JELLY__SSD1331_CONTROL_H__


#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>
#include <sys/ioctl.h>

#include "jelly/MemAccess.h"


class SSD1331Control
{
protected:
	jelly::MemAccess	m_reg_acc;

	const int	REG_ADR_RES_N  = 0;		// RES_N 制御
	const int	REG_ADR_BS     = 1;		// BS 制御
	const int	REG_ADR_PWR_EN = 2;		// PWR_EN 制御
	const int	REG_ADR_VIN_EN = 3;		// VIN_EN 制御
	const int	REG_ADR_DBUD   = 4;		// データバス転送

	const int OLEDRGB_WIDTH          = 96;
	const int OLEDRGB_HEIGHT         = 64;

	const int OLEDRGB_CHARBYTES      = 8;    // Number of bytes in a glyph
	const int OLEDRGB_USERCHAR_MAX   = 0x20; // Number of character defs in user font table
	const int OLEDRGB_CHARBYTES_USER = (OLEDRGB_USERCHAR_MAX * OLEDRGB_CHARBYTES); // Number of bytes in user font table

	const int CMD_DRAWLINE                   = 0x21;
	const int CMD_DRAWRECTANGLE              = 0x22;
	const int CMD_COPYWINDOW                 = 0x23;
	const int CMD_DIMWINDOW                  = 0x24;
	const int CMD_CLEARWINDOW                = 0x25;
	const int CMD_FILLWINDOW                 = 0x26;
	const int DISABLE_FILL                   = 0x00;
	const int ENABLE_FILL                    = 0x01;
	const int CMD_CONTINUOUSSCROLLINGSETUP   = 0x27;
	const int CMD_DEACTIVESCROLLING          = 0x2E;
	const int CMD_ACTIVESCROLLING            = 0x2F;
	const int CMD_SETCOLUMNADDRESS           = 0x15;
	const int CMD_SETROWADDRESS              = 0x75;
	const int CMD_SETCONTRASTA               = 0x81;
	const int CMD_SETCONTRASTB               = 0x82;
	const int CMD_SETCONTRASTC               = 0x83;
	const int CMD_MASTERCURRENTCONTROL       = 0x87;
	const int CMD_SETPRECHARGESPEEDA         = 0x8A;
	const int CMD_SETPRECHARGESPEEDB         = 0x8B;
	const int CMD_SETPRECHARGESPEEDC         = 0x8C;
	const int CMD_SETREMAP                   = 0xA0;
	const int CMD_SETDISPLAYSTARTLINE        = 0xA1;
	const int CMD_SETDISPLAYOFFSET           = 0xA2;
	const int CMD_NORMALDISPLAY              = 0xA4;
	const int CMD_ENTIREDISPLAYON            = 0xA5;
	const int CMD_ENTIREDISPLAYOFF           = 0xA6;
	const int CMD_INVERSEDISPLAY             = 0xA7;
	const int CMD_SETMULTIPLEXRATIO          = 0xA8;
	const int CMD_DIMMODESETTING             = 0xAB;
	const int CMD_SETMASTERCONFIGURE         = 0xAD;
	const int CMD_DIMMODEDISPLAYON           = 0xAC;
	const int CMD_DISPLAYOFF                 = 0xAE;
	const int CMD_DISPLAYON                  = 0xAF;
	const int CMD_POWERSAVEMODE              = 0xB0;
	const int CMD_PHASEPERIODADJUSTMENT      = 0xB1;
	const int CMD_DISPLAYCLOCKDIV            = 0xB3;
	const int CMD_SETGRAySCALETABLE          = 0xB8;
	const int CMD_ENABLELINEARGRAYSCALETABLE = 0xB9;
	const int CMD_SETPRECHARGEVOLTAGE        = 0xBB;
	const int CMD_SETVVOLTAGE                = 0xBE;


public:
	SSD1331Control(jelly::MemAccess	reg_acc)
	{
		m_reg_acc = reg_acc;
	}

protected:
	void WriteReg(int addr, int data)
	{
		m_reg_acc.WriteReg(addr, data);
	}

	int ReadReg(int addr)
	{
		return m_reg_acc.ReadReg(addr);
	}

	void Wait(long time)
	{
		usleep(time);
	}


	void WriteCmd(std::uint8_t cmd)
	{
//		m_reg_acc.WriteWord32(0x00022010, (unsigned long)cmd | 0x100);
		WriteReg(REG_ADR_DBUD, (cmd & 0xff) | 0x100);
	}

	void WriteData(unsigned char cmd)
	{
		WriteReg(REG_ADR_DBUD, (cmd & 0xff));
	}

public:

	void Setup(void)
	{
		// BS (8080 mode)
		WriteReg(REG_ADR_BS, 0x03);

		// PWR_ON
		WriteReg(REG_ADR_PWR_EN, 0x01);
		Wait(10000);
		
		// reset
		WriteReg(REG_ADR_RES_N, 0x00);
		Wait(10000);
		WriteReg(REG_ADR_RES_N, 0x01);
		Wait(10000);

		if ( 0 ) {
			WriteReg(REG_ADR_DBUD, 0x00000055);
			WriteReg(REG_ADR_DBUD, 0x000000aa);
			WriteReg(REG_ADR_DBUD, 0x00000155);
			WriteReg(REG_ADR_DBUD, 0x000001aa);
		}

		// Command un-lock
		WriteCmd(0xFD);
		WriteCmd(0x12);

		// 5. Univision Initialization Steps
		// 5a) Set Display Off
		WriteCmd(CMD_DISPLAYOFF);

		// 5b) Set Remap and Data Format
		WriteCmd(CMD_SETREMAP);
	//	WriteCmd(0x72);			// color format?
		WriteCmd(0x32);			// color format?

		// 5c) Set Display Start Line
		WriteCmd(CMD_SETDISPLAYSTARTLINE);
		WriteCmd(0x00); // Start line is set at upper left corner
		// 5d) Set Display Offset
		WriteCmd(CMD_SETDISPLAYOFFSET);
		WriteCmd(0x00); //no offset
		// 5e)
		WriteCmd(CMD_NORMALDISPLAY);
		// 5f) Set Multiplex Ratio
		WriteCmd(CMD_SETMULTIPLEXRATIO);
		WriteCmd(0x3F); //64MUX
		// 5g)Set Master Configuration
		WriteCmd(CMD_SETMASTERCONFIGURE);
		WriteCmd(0x8E);
		// 5h)Set Power Saving Mode
		WriteCmd(CMD_POWERSAVEMODE);
		WriteCmd(0x0B);
		// 5i) Set Phase Length
		WriteCmd(CMD_PHASEPERIODADJUSTMENT);
		WriteCmd(0x31); // Phase 2 = 14 DCLKs, phase 1 = 15 DCLKS
		// 5j) Send Clock Divide Ratio and Oscillator Frequency
		WriteCmd(CMD_DISPLAYCLOCKDIV);
		WriteCmd(0xF0); // Mid high oscillator frequency, DCLK = FpbCllk/2

		// 5k) Set Second Pre-charge Speed of Color A
		WriteCmd(CMD_SETPRECHARGESPEEDA);
		WriteCmd(0x64);
		// 5l) Set Set Second Pre-charge Speed of Color B
		WriteCmd(CMD_SETPRECHARGESPEEDB);
		WriteCmd(0x78);
		// 5m) Set Second Pre-charge Speed of Color C
		WriteCmd(CMD_SETPRECHARGESPEEDC);
		WriteCmd(0x64);
		// 5n) Set Pre-Charge Voltage
		WriteCmd(CMD_SETPRECHARGEVOLTAGE);
		WriteCmd(0x3A); // Pre-charge voltage =...Vcc
		// 50) Set VCOMH Deselect Level
		WriteCmd(CMD_SETVVOLTAGE);
		WriteCmd(0x3E); // Vcomh = ...*Vcc
		// 5p) Set Master Current
		WriteCmd(CMD_MASTERCURRENTCONTROL);
		WriteCmd(0x06);
		// 5q) Set Contrast for Color A
		WriteCmd(CMD_SETCONTRASTA);
		WriteCmd(0x91);
		// 5r) Set Contrast for Color B
		WriteCmd(CMD_SETCONTRASTB);
		WriteCmd(0x50);
		// 5s) Set Contrast for Color C
		WriteCmd(CMD_SETCONTRASTC);
		WriteCmd(0x7D);
		// Disable scrolling
		WriteCmd(CMD_DEACTIVESCROLLING);

	#define	HIGH_SPEED	1

	#if HIGH_SPEED
		// GS
		WriteCmd(CMD_SETGRAySCALETABLE);
		for ( int i = 0; i < 32; i++ ) {
			if      ( i < 20 ) { WriteCmd(0); }
			if      ( i < 22 ) { WriteCmd(5); }
			if      ( i < 25 ) { WriteCmd(5); }
			if      ( i < 27 ) { WriteCmd(5); }
			else if ( i < 29 ) { WriteCmd(5); }
			else               { WriteCmd(5); }
		}
	#endif

		// 5u) Clear Screen
		WriteCmd(CMD_CLEARWINDOW);     // Enter the "clear mode"
		WriteCmd(0x00);                // Set the starting column coordinates
		WriteCmd(0x00);                // Set the starting row coordinates
		WriteCmd(OLEDRGB_WIDTH - 1);   // Set the finishing column coordinates;
		WriteCmd(OLEDRGB_HEIGHT - 1);  // Set the finishing row coordinates;
		Wait(100000);

		// Turn on VCC and wait for it to become stable
		WriteReg(REG_ADR_PWR_EN, 0x00000001);
		Wait(10000);

		// Send Display On command
		WriteCmd(CMD_DISPLAYON);
		Wait(100000);


		//set column start and end
		WriteCmd(CMD_SETCOLUMNADDRESS);
		WriteCmd(0);                    // Set the starting column coordinates
		WriteCmd(95);                   // Set the finishing column coordinates

		//set row start and end
		WriteCmd(CMD_SETROWADDRESS);
		WriteCmd(0);                   // Set the starting row coordinates
		WriteCmd(63);                   // Set the finishing row coordinates

		// VOUT enable
		WriteReg(REG_ADR_VIN_EN, 0x01);
	}

	void Stop(void)
	{
		WriteReg(REG_ADR_VIN_EN, 0x00);
		WriteReg(REG_ADR_PWR_EN, 0x00);
	}
	

#if 0
	void DrawBitmap8(u8 c1, u8 r1, u8 c2, u8 r2, u8 *bitmapR, u8 *bitmapG, u8 *bitmapB, int sx, int sy)
	{
		//set column start and end
		WriteCmd(CMD_SETCOLUMNADDRESS);
		WriteCmd(c1);                   // Set the starting column coordinates
		WriteCmd(c2);                   // Set the finishing column coordinates

		//set row start and end
		WriteCmd(CMD_SETROWADDRESS);
		WriteCmd(r1);                   // Set the starting row coordinates
		WriteCmd(r2);                   // Set the finishing row coordinates

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
		WriteCmd(CMD_SETCOLUMNADDRESS);
		WriteCmd(c1);                   // Set the starting column coordinates
		WriteCmd(c2);                   // Set the finishing column coordinates

		//set row start and end
		WriteCmd(CMD_SETROWADDRESS);
		WriteCmd(r1);                   // Set the starting row coordinates
		WriteCmd(r2);                   // Set the finishing row coordinates
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
				WriteData(dd);
			}
		}
	}
#endif

#if 0
	int oled_main()
	{

		oled_setup();

		//set column start and end
		WriteCmd(CMD_SETCOLUMNADDRESS);
		WriteCmd(0);                    // Set the starting column coordinates
		WriteCmd(95);                   // Set the finishing column coordinates

		//set row start and end
		WriteCmd(CMD_SETROWADDRESS);
		WriteCmd(0);                   // Set the starting row coordinates
		WriteCmd(63);                   // Set the finishing row coordinates

		// VOUT enable
		WriteReg(REG_ADR_VIN_EN, 0x01);
	
		return 0;
	}
#endif
};


#endif	// __JELLY__SSD1331_CONTROL_H__


// end of file
