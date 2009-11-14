
#include <stdio.h>
#include <winsock2.h>
#include "GdbServerTcp.h"


SOCKET sock;



int HexToChar(char c)
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

int CharToHex(char c)
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


int RemoteGetChar(void)
{
	char	c;

	while ( recv(sock, &c, 1, 0) != 1 )
	{
		Sleep(10);
	}
	printf("%c", c);
	
	return (int)(unsigned int)c;
}

int RemotePutChar(char c)
{
	printf("%c", c);
	return (send(sock, &c, 1, 0) == 1);
}


int RemoteSendPacket(char *buf, int len)
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



int main()
{
	WSADATA wsaData;
	SOCKET sock0;
	struct sockaddr_in addr;
	struct sockaddr_in client;
	int len;
	int n;

	if ( WSAStartup(MAKEWORD(2,0), &wsaData) != 0 )
	{
		return 1;
	}
	
	sock0 = socket(AF_INET, SOCK_STREAM, 0);
	if (sock0 == INVALID_SOCKET) {
		printf("socket : %d\n", WSAGetLastError());
		return 1;
	}
	
	addr.sin_family = AF_INET;
	addr.sin_port = htons(12345);
	addr.sin_addr.S_un.S_addr = INADDR_ANY;
	
	if (bind(sock0, (struct sockaddr *)&addr, sizeof(addr)) != 0) {
		printf("bind : %d\n", WSAGetLastError());
		return 1;
	}
	
	if (listen(sock0, 5) != 0) {
		printf("listen : %d\n", WSAGetLastError());
		return 1;
	}
	
	while (1)
	{
		len = sizeof(client);
		sock = accept(sock0, (struct sockaddr *)&client, &len);
		if (sock == INVALID_SOCKET)
		{
			printf("accept : %d\n", WSAGetLastError());
			break;
		}
		
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

		closesocket(sock);
	}
	
	WSACleanup();
	
	return 0;
}


