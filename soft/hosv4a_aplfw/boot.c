/** 
 *  Sample program for Hyper Operating System V4 Advance
 *
 * @file  sample.c
 * @brief %jp{サンプルプログラム}%en{Sample program}
 *
 * Copyright (C) 1998-2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "kernel.h"
#include "kernel_id.h"
#include "system/system/system.h"
#include "system/sysapi/sysapi.h"
#include "system/file/console.h"
#include "system/process/process.h"
#include "system/command/command.h"
#include "driver/serial/jelly/jellyuartdrv.h"
#include "driver/console/vt100/vt100drv.h"
#include "driver/volume/fat/fatvol.h"
#include "application/syscmd/shell/shell.h"
#include "application/syscmd/commandlist/commandlist.h"
#include "application/syscmd/processlist/processlist.h"
#include "application/filecmd/filelist/filelist.h"
#include "application/filecmd/filecopy/filecopy.h"
#include "application/filecmd/filedump/filedump.h"
#include "application/filecmd/filecat/filecat.h"
#include "application/fatcmd/fatmount/fatmount.h"
#include "application/flashcmd/norflashcmd/norflashcmd.h"
#include "application/utility/timecmd/timecmd.h"
#include "application/utility/memdump/memdump.h"
#include "application/utility/memwrite/memwrite.h"
#include "application/utility/memtest/memtest.h"
#include "application/utility/keytest/keytest.h"
#include "application/example/hello/hello.h"
#include "boot.h"
#include "ostimer.h"
#include "mmcdrv/mmcdrv.h"


int dhrystone_main(int argc, char *argv[]);


#if 0

long	g_SystemHeap[128 * 1024 / sizeof(long)];
#define SYSTEM_HEAP_ADDR	((void *)g_SystemHeap)
#define SYSTEM_HEAP_SIZE	sizeof(g_SystemHeap)

#else

#define SYSTEM_HEAP_ADDR	((void *)0x01300000)
#define SYSTEM_HEAP_SIZE	0x00100000

#endif


extern SYSTIM_CPUTIME		SysTim_TimeCounter;		/* デフォルトのタイマカウンタ */



#define GPIOA_DIR		((volatile unsigned long *)0xfffff300)
#define GPIOA_INPUT 	((volatile unsigned long *)0xfffff304)
#define GPIOA_OUPUT 	((volatile unsigned long *)0xfffff308)

#define MMC_CS			0x01
#define MMC_DI			0x02
#define MMC_CLK			0x04
#define MMC_DO			0x08


unsigned char send_data(unsigned char ubData)
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
			ubRead |= (*GPIOA_INPUT & MMC_DO) ? 1 : 0;
			*GPIOA_OUPUT = c | MMC_DI | MMC_CLK;
		}
		else
		{
			*GPIOA_OUPUT = c;
			ubRead |= (*GPIOA_INPUT & MMC_DO) ? 1 : 0;
			*GPIOA_OUPUT = c | MMC_CLK;
		}
		ubData <<= 1;
	}
	
	return ubRead;
}


int test_main(int argc, char *argv[])
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
	
	send_data(0x40);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0x95);
	send_data(0xff);
	c = send_data(0xff);
	StdIo_PrintFormat("%02x\n", (int)c);
	send_data(0xff);
	
	
	send_data(0x41);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0xf9);
	send_data(0xff);
	c = send_data(0xff);
	StdIo_PrintFormat("%02x\n", (int)c);
	send_data(0xff);
	
	
	send_data(0x41);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0xf9);
	send_data(0xff);
	c = send_data(0xff);
	StdIo_PrintFormat("%02x\n", (int)c);
	send_data(0xff);
	
	Time_Wait(1000);
	send_data(0x41);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0xf9);
	send_data(0xff);
	c = send_data(0xff);
	StdIo_PrintFormat("%02x\n", (int)c);
	send_data(0xff);
	
	
	send_data(0x51);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0x01);
	send_data(0xff);
	for ( i = 0; i < 512 + 16; i++ )
	{
		c = send_data(0xff);
		StdIo_PrintFormat("%02x ", (int)c);
	}
	
	return 0;
}



int Boot_Process(VPARAM Param);


void Boot_Task(VP_INT exinf)
{
	T_SYSTEM_INITIALIZE_INF	SysInf;
	
	
	/*************************/
	/*       初期化          */
	/*************************/
	
	/* システム初期化 */
	memset(&SysInf, 0, sizeof(SysInf));
	SysInf.pSysMemBase     = SYSTEM_HEAP_ADDR;
	SysInf.SysMemSize      = SYSTEM_HEAP_SIZE;
	SysInf.SysMemAlign     = 8;
	SysInf.pIoMemBase      = NULL;
	SysInf.SystemStackSize = 2048;
	SysInf.pfncBoot        = Boot_Process;
	SysInf.BootParam       = (VPARAM)0;
	SysInf.BootStackSize   = 2048;
	System_Initialize(&SysInf);
}


/* ブートプロセス */
int Boot_Process(VPARAM Param)
{
	T_PROCESS_CREATE_INF	ProcInf;
	HANDLE					hProcess;
	HANDLE					hDriver;
	HANDLE					hTty;
	HANDLE					hCon;
	
	
	/*************************/
	/*   デバイスドライバ    */
	/*************************/
	
	/* タイマ初期化 */	
	OsTimer_Initialize();

	/* MMCドライバ生成 */
	hDriver = MmcDrv_Create();
	File_AddDevice("mmc0", hDriver);

	/* Jelly UART デバドラ生成 (/dev/com0 に登録) */
	hDriver = JellyUartDrv_Create((void *)0xfffff200, 1, 2, 256);
	File_AddDevice("com0", hDriver);

	/* シリアルを開く */
	hTty = File_Open("/dev/com0", FILE_OPEN_READ | FILE_OPEN_WRITE);
	
	/* シリアル上にコンソールを生成( /dev/con0 に登録) */
	hDriver = Vt100Drv_Create(hTty);
	File_AddDevice("con0", hDriver);
	
	/* コンソールを開く */
	hCon = File_Open("/dev/con0", FILE_OPEN_READ | FILE_OPEN_WRITE);
	

	
	/*************************/
	/*     標準入出力設定    */
	/*************************/
	
	Process_SetTerminal(HANDLE_NULL, hTty);
	Process_SetConIn(HANDLE_NULL, hCon);
	Process_SetConOut(HANDLE_NULL, hCon);
	Process_SetStdIn(HANDLE_NULL, hCon);
	Process_SetStdOut(HANDLE_NULL, hCon);
	Process_SetStdErr(HANDLE_NULL, hCon);
	
	
	/*************************/
	/*     コマンド登録      */
	/*************************/
	Command_AddCommand("sh",       Shell_Main);
	Command_AddCommand("ps",       ProcessList_Main);
	Command_AddCommand("help",     CommandList_Main);
	Command_AddCommand("time",     TimeCmd_Main);
	Command_AddCommand("memdump",  MemDump_Main);
	Command_AddCommand("memwrite", MemWrite_Main);
	Command_AddCommand("memtest",  MemTest_Main);
	Command_AddCommand("keytest",  KeyTest_Main);
	Command_AddCommand("hello",    Hello_Main);
	Command_AddCommand("ls",       FileList_Main);
	Command_AddCommand("cp",       FileCopy_Main);
	Command_AddCommand("cat",      FileCat_Main);
	Command_AddCommand("filedump", FileDump_Main);
	Command_AddCommand("fatmount", FatMount_Main);
	Command_AddCommand("norflash", NorFlashCmd_Main);
	
	Command_AddCommand("dhry",     dhrystone_main);
	Command_AddCommand("test",     test_main);
	
	
	/*************************/
	/*    起動メッセージ     */
	/*************************/

	StdIo_PutString(
			"\n\n"
			"================================================================\n"
			" Hyper Operating System  Application Framework\n"
			"\n"
			"                          Copyright (C) 1998-2008 by Project HOS\n"
			"                          http://sourceforge.jp/projects/hos/\n"
			"================================================================\n"
			"\n");
	
	
	/*************************/
	/*      シェル起動       */
	/*************************/
	
	/* プロセスの生成*/
	ProcInf.pszCommandLine = "sh -i";								/* 実行コマンド */
	ProcInf.pszCurrentDir  = "/";									/* 起動ディレクトリ */
	ProcInf.pfncEntry      = NULL;									/* 起動アドレス */
	ProcInf.Param          = 0;										/* ユーザーパラメータ */
	ProcInf.StackSize      = 2048;									/* スタックサイズ */
	ProcInf.Priority       = PROCESS_PRIORITY_NORMAL;				/* プロセス優先度 */
	ProcInf.hTerminal      = Process_GetTerminal(HANDLE_NULL);		/* ターミナル */
	ProcInf.hConIn         = Process_GetConIn(HANDLE_NULL);			/* コンソール入力 */
	ProcInf.hConOut        = Process_GetConOut(HANDLE_NULL);		/* コンソール出力 */
	ProcInf.hStdIn         = Process_GetStdIn(HANDLE_NULL);			/* 標準入力 */
	ProcInf.hStdOut        = Process_GetStdOut(HANDLE_NULL);		/* 標準出力 */
	ProcInf.hStdErr        = Process_GetStdErr(HANDLE_NULL);		/* 標準エラー出力 */
	for ( ; ; )
	{
		hProcess = Process_CreateEx(&ProcInf);
		Process_WaitExit(hProcess);
		Process_Delete(hProcess);
	}
}


/* end of file */
