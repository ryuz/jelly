

#include <stdio.h>
#include "gdb_svr.h"
#include "GdbServerTcp.h"


// コンストラクタ
CGdbServerTcp::CGdbServerTcp(CDebugControl* pDbgCtl, int port) : CGdbServer(pDbgCtl)
{
	m_blConected = false;
	
	m_sock0 = socket(AF_INET, SOCK_STREAM, 0);
	if ( m_sock0 == INVALID_SOCKET)
	{
		StatusPrint("socket : %d\n", WSAGetLastError());
		exit(1);
	}
	m_addr.sin_family = AF_INET;
	m_addr.sin_port   = htons(port);
	m_addr.sin_addr.S_un.S_addr = INADDR_ANY;
	
	if ( bind(m_sock0, (struct sockaddr *)&m_addr, sizeof(m_addr)) != 0 )
	{
		StatusPrint("bind : %d\n", WSAGetLastError());
		exit(1);
	}
	
	if ( listen(m_sock0, 5) != 0 )
	{
		StatusPrint("listen : %d\n", WSAGetLastError());
		exit(1);
	}
}


// デストラクタ
CGdbServerTcp::~CGdbServerTcp()
{
	if ( m_blConected )
	{
		closesocket(m_sock);
	}
}


int CGdbServerTcp::RemotePeekChar(void)
{
	// 接続
	if ( !m_blConected )
	{
		int len = sizeof(m_client);
		m_sock = accept(m_sock0, (struct sockaddr *)&m_client, &len);
		if (m_sock == INVALID_SOCKET)
		{
			printf("accept : %d\n", WSAGetLastError());
			return -1;
		}
		StatusPrint("TCP connected.\n");
		
		u_long val=1;
		ioctlsocket(m_sock, FIONBIO, &val);
		
		m_blConected = true;
	}
	
	// 受信
	int		n;
	char	c;
	if ( (n = recv(m_sock, &c, 1, 0)) == 1 )
	{
		// 受信ログ
		LogPrint("%c", c);
		
		return (int)(unsigned int)c;
	}	
	
	if ( n <= 0 )
	{
		if ( WSAGetLastError() != WSAEWOULDBLOCK )
		{
			closesocket(m_sock);
			m_blConected = false;
			StatusPrint("TCP disconnected.\n");
			return -2;
		}
	}

	return -1;
}


int CGdbServerTcp::RemoteGetChar(void)
{
	int c;
	while ( (c = RemotePeekChar()) < 0 )
	{
		if ( c < -1 )
		{
			return c;
		}
		Sleep(10);
	}
	
	return c;
}

/*
int CGdbServerTcp::RemoteGetChar(void)
{
	// 接続
	if ( !m_blConected )
	{
		int len = sizeof(m_client);
		m_sock = accept(m_sock0, (struct sockaddr *)&m_client, &len);
		if (m_sock == INVALID_SOCKET)
		{
			printf("accept : %d\n", WSAGetLastError());
			return -1;
		}
		
		u_long val=1;
		ioctlsocket(m_sock, FIONBIO, &val);
		
		m_blConected = true;
	}
	
	// 受信
	int		n;
	char	c;
	while ( (n = recv(m_sock, &c, 1, 0)) != 1 )
	{
		if ( n < 0 )
		{
			if ( WSAGetLastError() != WSAEWOULDBLOCK )
			{
				closesocket(m_sock);
				m_blConected = false;
				return -1;
			}
		}
		Sleep(10);
	}
	
	// 受信ログ
	LogPrint("%c", c);
	
	return (int)(unsigned int)c;
}
*/


int CGdbServerTcp::RemotePutChar(char c)
{
	if ( !m_blConected )
	{
		return 0;
	}

	// 送信ログ
	LogPrint("%c", c);
	
	// 送信
	return (send(m_sock, &c, 1, 0) == 1);
}

