// ---------------------------------------------------------------------------
//  Jelly Debugger
//    Command line loader
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
// ---------------------------------------------------------------------------


#include <stdio.h>
#include <conio.h>
#include <windows.h>
#include "RemoteUart.h"
#include "JellyControl.h"


void PrintUsage(void);
void FileLoad(CJellyControl* pCtrl, const char *pszFileName, unsigned long ulAddr);
void PrintReg(CJellyControl* pCtrl);


// loader
int main(int argc, char *argv[])
{
	const char		*pszComPort  = "COM1";
	unsigned long	ulBitRate    = CBR_115200;
	unsigned long	ulStartAddr  = 0x00000000;
	const char		*pszFileName = NULL;
	bool			blAutoRun = false;
	int				i;
	
	
	printf("Jelly Loader Ver 0.01  Copyright (C) 2008 by Ryuji Fuchikami\n");
	
	// command line
	for ( i = 1; i < argc; i++ )
	{
		if ( argv[i][0] == '-' )
		{
			if ( strcmp(&argv[i][1], "h") == 0 )
			{
				PrintUsage();
				return 0;
			}
			else if ( strcmp(&argv[i][1], "r") == 0 )
			{
				blAutoRun = true;
			}
			else if ( strcmp(&argv[i][1], "p") == 0 && i+1 < argc )
			{
				i++;
				pszComPort = argv[i];
			}
			else if ( strcmp(&argv[i][1], "s") == 0 && i+1 < argc )
			{
				i++;
				ulBitRate = strtoul(argv[i], NULL, 0);
			}
			if ( strcmp(&argv[i][1], "a") == 0 && i+1 < argc )
			{
				i++;
				ulStartAddr = strtoul(argv[i], NULL, 0);
			}
		}
		else
		{
			pszFileName = argv[i];
		}
	}
		
	// Port Create
	CRemoteUart		remote(ulBitRate);

	// Port Open
	if ( !remote.Open(pszComPort) )
	{
		fprintf(stderr, "port open error : %s\n", pszComPort);
		return 1;
	}
	
	// connect
	if ( !remote.Connect() )
	{
		fprintf(stderr, "connection time out\n");
		return 1;
	}
	
	// create controler
	CJellyControl	ctrl(&remote);

	
	// break;
	ctrl.Break();

	// load
	if ( pszFileName != NULL )
	{
		FileLoad(&ctrl, pszFileName, ulStartAddr);
	}
	
	// auto run
	if ( blAutoRun )
	{
		// リセット
		remote.DbgRegWrite(2, 0x0000130);	// ADDR:STATUS
		remote.DbgRegWrite(4, 0x0000000);	// WRITE:0
		remote.DbgRegWrite(2, 0x0000160);	// ADDR:DEPC
		remote.DbgRegWrite(4, 0x0000000);	// WRITE:0
//		ctrl.SetPc(ulStartAddr);	// reset
		ctrl.Run();					// run
		return 0;
	}


	for ( ; ; )
	{
		// input command
		char	szCommand[512];
		printf("> ");
		gets(szCommand);
		int iLen  = strlen(szCommand);
		if ( szCommand[iLen-1] == '\n' )
		{
			szCommand[iLen-1] = '\0';
			iLen--;
		}
		
		// quit
		if ( stricmp(szCommand, "q") == 0 )
		{
			break;
		}
		
		// quit
		else if ( stricmp(szCommand, "h") == 0 )
		{
			printf("<help>\n");
			printf("q               quit\n");
			printf("reset           reset\n");
			printf("s               step execution\n");
			printf("r               run\n");
			printf("l <filename>    load\n");
			printf("p               print registers\n");
			printf("m <addr>        memory dump\n");
		}

		else if ( stricmp(szCommand, "reset") == 0 )
		{
			// リセット
			remote.DbgRegWrite(2, 0x0000130);	// ADDR:STATUS
			remote.DbgRegWrite(4, 0x0000000);	// WRITE:0

			remote.DbgRegWrite(2, 0x0000160);	// ADDR:DEPC
			remote.DbgRegWrite(4, 0x0000000);	// WRITE:0

			printf("reset\n");
		}
		
		// load
		else if ( strncmp(szCommand, "l ", 2) == 0 )
		{
			FileLoad(&ctrl, &szCommand[2], 0);
		}
		
		// print reg 
		else if ( stricmp(szCommand, "p") == 0 )
		{
			PrintReg(&ctrl);
		}
		
		// メモリリード
		else if ( strncmp(szCommand, "m ", 2) == 0 )
		{
			unsigned long ulAddr = strtoul(&szCommand[2], 0, 0);
			unsigned char ubBuf[256];
			remote.MemRead(ulAddr, ubBuf, 256);
			for ( i = 0; i < 256; i++ )
			{
				printf("%02x ", ubBuf[i]);
				if ( i % 16 == 15 )
				{
					printf("\n");
				}
			}
		}

		// step execution
		else if ( stricmp(szCommand, "s") == 0 )
		{
			ctrl.Step();
			printf("PC:0x%08x\n", ctrl.GetPc() );
		}

		// set break point
		if ( strncmp(szCommand, "bp ", 3) == 0 )
		{
			unsigned long ulAddr = strtoul(&szCommand[3], 0, 0);
			printf("set BP : 0x%08x\n", ulAddr);
			ctrl.SetBreakPoint(ulAddr);
		}

		// run
		else if ( stricmp(szCommand, "r") == 0 )
		{
			ctrl.Run();
			while ( !ctrl.GetStatus() )
			{
				if ( _kbhit() != 0 )
				{
					break;
				}
			}
			ctrl.Break();
		}
	}
	
	remote.Close();
	
	return 0;
}



void PrintUsage(void)
{
	printf("%s [options] [filename]\n");
	printf("  <options>\n");
	printf("    -bin             binary file\n");
	printf("    -a loadaddr      address (default: 0x00000000)\n");
	printf("    -p portname      port name (default: COM1)\n");
	printf("    -s speed         speed (default: 115200)\n");
	printf("    -r               run\n");
}



void FileLoad(CJellyControl* pCtrl, const char *pszFileName, unsigned long ulAddr)
{
	FILE	*fp;

	if ( (fp = fopen(pszFileName, "rb")) == NULL )
	{
		printf("file open error : %s\n", pszFileName);
		return;
	}

	int				iSize;
	unsigned char	ubBuf[256];
	while ( (iSize = fread(ubBuf, 1, 256, fp)) != 0 )
	{
		pCtrl->MemWrite(ulAddr, ubBuf, iSize);
		ulAddr += iSize;
		printf(".");
	}

	fclose(fp);
	printf("\n");
}



void PrintReg(CJellyControl* pCtrl)
{
	int iNum;
	int i;
	
	iNum = pCtrl->GetRegisterNum();
	for ( i = 0; i < iNum; i++ )
	{
		printf("%s:0x%08x ", pCtrl->GetRegisterName(i), pCtrl->GetRegisterValue(i));
		if ( i % 4 == 3 )
		{
			printf("\n");
		}
	}
	printf("\n");
}


// end of file
