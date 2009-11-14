

#include <stdio.h>
#include "GdbServer.h"


// コンストラクタ
CGdbServer::CGdbServer()
{
	m_blLogEnable = true;
	m_blBigEndian = true;
}


// デストラクタ
CGdbServer::~CGdbServer()
{
}


void CGdbServer::LogPrint(const char *fmt, ...)
{
    va_list args;
	
	if ( !m_blLogEnable )
	{
		return;
	}
	
    va_start(args, fmt);
	vprintf(fmt, args);
    va_end(args);
}


char CGdbServer::HexToChar(char c)
{
	c &= 0x0f;

	if ( c >= 0 && c <= 9 )
	{
		return '0' + c;
	}
	if ( c >= 10 && c <= 15 )
	{
		return 'a' + (c - 10);
	}
	
	return '0';
}


int CGdbServer::CharToHex(char c)
{
	if ( c >= '0' && c <= '9' )
	{
		return c - '0';
	}
	if ( c >= 'a' && c <= 'f' )
	{
		return c - 'a' + 10;
	}
	if ( c >= 'a' && c <= 'f' )
	{
		return c - 'A' + 10;
	}
	return 0;
}


int CGdbServer::RemoteSendPacket(char *buf, int len)
{
	unsigned char	sum = 0;
	int				i;

	RemotePutChar('$');
	for ( i = 0; i < len; i++ )
	{
		sum += buf[i];
		RemotePutChar(buf[i]);
	}
	RemotePutChar('#');
	RemotePutChar(HexToChar((sum >> 4) & 0x0f));
	RemotePutChar(HexToChar((sum >> 0) & 0x0f));
	
	return len;
}


void CGdbServer::RunServer(void)
{	
	char			recv_packt[4096];
	int				recv_len;
	unsigned char	recv_sum;
	char			c;
	
	for ( ; ; )
	{
		for ( ; ; )
		{
			printf("\n");

			// '$' を待つ
			while ( RemoteGetChar() != '$' )
				;

			// パケット受信
			recv_len = 0;
			recv_sum = 0;
			for ( ; ; )
			{
				c = RemoteGetChar();
				if ( c == '#' )
				{
					break;
				}
				
				recv_sum += c;
				recv_packt[recv_len++] = c;
			}
				
			unsigned char sum;
			sum  = CharToHex(RemoteGetChar()) * 16;
			sum += CharToHex(RemoteGetChar());
			
			printf("\n");
			if ( sum == recv_sum )
			{
				RemotePutChar('+');
				break;
			}
			RemotePutChar('-');
		}
		
		if ( recv_packt[0] == '?' )
		{
			// シグナル状態
			RemoteSendPacket("S05", 3);
		}
		if ( recv_packt[0] == 'g' )
		{
			// レジスタ取得
			RemoteSendPacket("S05", 3);
		}
		else
		{
			RemoteSendPacket("", 0);
		}
	}
	
	/*
	n = send(sock, "HELLO", 5, 0);
	if (n < 1) {
		printf("send : %d\n", WSAGetLastError());
		break;
	}
	*/
}


