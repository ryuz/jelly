
#include <stdio.h>
#include <stdarg.h>
#include <winsock2.h>
#include "GdbServerTcp.h"
#include "RemoteUart.h"



void StatusPrint(const char *fmt, ...)
{
    va_list args;

    va_start(args, fmt);
	vprintf(fmt, args);
    va_end(args);
}


int main()
{
	WSADATA wsaData;
	
	StatusPrint(
			"======================================================\n"
			" Jelly GDB server ver. 0.01\n"
			"\n"
			"               Copy right (C) 2009 by Ryuji Fuchikami \n"
			"               http://homepage3.nifty.com/ryuz/\n"
			"======================================================\n\n"
		);
	
	// Initialize Socket
	if ( WSAStartup(MAKEWORD(2,0), &wsaData) != 0 )
	{
		return 1;
	}

	// Port Create
	CRemoteUart		UartPort(CBR_115200);

	// Port Open
	if ( !UartPort.Open("COM1") )
	{
		fprintf(stderr, "port open error\n");
		return 1;
	}
	
	StatusPrint("COM opened.\n");
	
	// connect
	if ( !UartPort.Connect() )
	{
		fprintf(stderr, "connection time out\n");
		return 1;
	}
	
	// create controler
	CJellyControl	JellCtl(&UartPort);
	
	// break;
	JellCtl.Break();
	
	
	StatusPrint("Jelly connected.\n");

	CGdbServerTcp	srv(&JellCtl, 2345);
	srv.RunServer();
	

	WSACleanup();
	
	return 0;
}


