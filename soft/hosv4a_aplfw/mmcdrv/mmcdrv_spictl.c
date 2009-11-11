/** 
 * Hyper Operating System  Application Framework
 *
 * @file  mmcfile_constructor.c
 * @brief %jp{memory file コンストラクタ}%en{Memory File  constructor}
 *
 * Copyright (C) 2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "hosaplfw.h"
#include "mmcfile_local.h"


#define GPIOA_DIR		((volatile unsigned long *)0xf3000000)
#define GPIOA_INPUT 	((volatile unsigned long *)0xf3000004)
#define GPIOA_OUPUT 	((volatile unsigned long *)0xf3000008)

#define MMC_CS			0x01
#define MMC_DI			0x02
#define MMC_CLK			0x04
#define MMC_DO			0x08


#define MMC_WAIT() do{ volatile int v; for(v=0;v<2;v++); } while (0)


static unsigned char MmcDrv_SendData(unsigned char ubData)
{
	unsigned char	ubRead = 0;
	unsigned long	c;
	int				i;
	
	c = (*GPIOA_OUPUT & ~(MMC_DI | MMC_CLK));
	
	for ( i = 0; i < 8; i++ )
	{
		ubRead <<= 1;
		if ( ubData & 0x80 )
		{
			*GPIOA_OUPUT = c | MMC_DI;
			MMC_WAIT();
			ubRead |= (*GPIOA_INPUT & MMC_DO) ? 1 : 0;
			*GPIOA_OUPUT = c | MMC_DI | MMC_CLK;
			MMC_WAIT();
		}
		else
		{
			*GPIOA_OUPUT = c;
			MMC_WAIT();
			ubRead |= (*GPIOA_INPUT & MMC_DO) ? 1 : 0;
			*GPIOA_OUPUT = c | MMC_CLK;
			MMC_WAIT();
		}
		ubData <<= 1;
	}

	return ubRead;
}


int MmcDrv_CardInitialize(C_MMCDRV *self)
{
	int i;
	unsigned char c;
	
	*GPIOA_DIR   = 0x07;
	*GPIOA_OUPUT = 0x07;
	
	/* 初期化 */
	for ( i = 0; i < 80; i++ )
	{
		*GPIOA_OUPUT &= ~MMC_CLK;
		*GPIOA_OUPUT |=  MMC_CLK;
	}
	*GPIOA_OUPUT &= ~MMC_CS;
	
	/* CMD0 */
	MmcDrv_SendData(0x40);
	MmcDrv_SendData(0x00);
	MmcDrv_SendData(0x00);
	MmcDrv_SendData(0x00);
	MmcDrv_SendData(0x00);
	MmcDrv_SendData(0x95);
	MmcDrv_SendData(0xff);
	MmcDrv_SendData(0xff);
	MmcDrv_SendData(0xff);
	
	/* CMD1 */
	for ( i = 0; ; i++ )
	{
		MmcDrv_SendData(0x41);
		MmcDrv_SendData(0x00);
		MmcDrv_SendData(0x00);
		MmcDrv_SendData(0x00);
		MmcDrv_SendData(0x00);
		MmcDrv_SendData(0xf9);
		MmcDrv_SendData(0xff);
		c = MmcDrv_SendData(0xff);
		MmcDrv_SendData(0xff);
		if ( c == 0 )
		{
			break;
		}
		
		if ( i >= 200 )
		{
			return FILE_ERR_NG;
		}
		Time_Wait(10);
	}
	
	return FILE_ERR_OK;
}


FILE_SIZE MmcDrv_BlockRead(C_MMCDRV *self, unsigned long uwAddr, void *pBuf)
{
	unsigned char	c;
	unsigned char	*pubBuf;
	int				i;
	
	MmcDrv_SendData(0x51);
	MmcDrv_SendData((uwAddr >> 24) & 0xff);
	MmcDrv_SendData((uwAddr >> 16) & 0xff);
	MmcDrv_SendData((uwAddr >>  8) & 0xff);
	MmcDrv_SendData((uwAddr >>  0) & 0xff);
	MmcDrv_SendData(0x01);
	MmcDrv_SendData(0xff);
	
	for ( i = 0; ; i++ )
	{
		c = MmcDrv_SendData(0xff);
		if ( c == 0xfe )
		{
			break;
		}

		if ( i >= 1024 )
		{
			return 0;
		}
	}
	
	pubBuf = (unsigned char *)pBuf;
	for ( i = 0; i < 512; i++ )
	{
		c = MmcDrv_SendData(0xff);
		*pubBuf++ = c;
	}
	MmcDrv_SendData(0xff);
	MmcDrv_SendData(0xff);
	
	return 512;
}



FILE_SIZE MmcDrv_BlockWrite(C_MMCDRV *self, unsigned long uwAddr, const void *pBuf)
{
	return 0;
}



/* end of file */
