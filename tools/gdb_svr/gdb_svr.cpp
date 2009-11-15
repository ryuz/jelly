
#include <stdio.h>
#include <winsock2.h>
#include "GdbServerTcp.h"
#include "RemoteUart.h"

int main()
{
	WSADATA wsaData;
	
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


	CGdbServerTcp	srv(&JellCtl, 12345);
	srv.RunServer();
	

	WSACleanup();
	
	return 0;
}


