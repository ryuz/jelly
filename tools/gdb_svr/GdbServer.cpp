

#include <stdio.h>
#include "GdbServer.h"


// コンストラクタ
CGdbServer::CGdbServer(CDebugControl* pDbgCtl)
{
	m_pDbgCtl = pDbgCtl;

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


int CGdbServer::SetWordString(char *buf, unsigned long word)
{
	int	len = 0;
	if ( m_blBigEndian )
	{
		buf[len++] = HexToChar((char)((word >> 28) & 0xf));
		buf[len++] = HexToChar((char)((word >> 24) & 0xf));
		buf[len++] = HexToChar((char)((word >> 20) & 0xf));
		buf[len++] = HexToChar((char)((word >> 16) & 0xf));
		buf[len++] = HexToChar((char)((word >> 12) & 0xf));
		buf[len++] = HexToChar((char)((word >>  8) & 0xf));
		buf[len++] = HexToChar((char)((word >>  4) & 0xf));
		buf[len++] = HexToChar((char)((word >>  0) & 0xf));
	}
	else
	{
		buf[len++] = HexToChar((char)((word >>  0) & 0xf));
		buf[len++] = HexToChar((char)((word >>  4) & 0xf));
		buf[len++] = HexToChar((char)((word >>  8) & 0xf));
		buf[len++] = HexToChar((char)((word >> 12) & 0xf));
		buf[len++] = HexToChar((char)((word >> 16) & 0xf));
		buf[len++] = HexToChar((char)((word >> 20) & 0xf));
		buf[len++] = HexToChar((char)((word >> 24) & 0xf));
		buf[len++] = HexToChar((char)((word >> 28) & 0xf));
	}
	
	return len;
}



void CGdbServer::RunServer(void)
{	
	char			recv_packt[4096];
	int				recv_len;
	unsigned char	recv_sum;
	char			c;

	char			send_packt[4096];
	int				send_len;
	int				i;

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
			send_len = 0;
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R0"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R1"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R2"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R3"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R4"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R5"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R6"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R7"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R8"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R9"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R10"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R11"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R12"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R13"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R14"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R15"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R16"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R17"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R18"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R19"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R20"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R21"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R22"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R23"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R24"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R25"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R26"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R27"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R28"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R29"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R30"));
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("R31"));

			send_len += SetWordString(&send_packt[send_len], 0);											// SR
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("LO"));			// LO
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("HI"));			// HI
			send_len += SetWordString(&send_packt[send_len], 0);											// BAD
			send_len += SetWordString(&send_packt[send_len], 0);											// CAUSE
			send_len += SetWordString(&send_packt[send_len], m_pDbgCtl->GetRegisterValue("COP0_DEEPC"));	// PC
			
			for ( i = 0; i < 90 - (32 + 6); i++ )
			{
				send_len += SetWordString(&send_packt[send_len], 0);
			}
			RemoteSendPacket(send_packt, send_len);
		}
		else if ( recv_packt[0] == 'M' )
		{
			unsigned char	ubBuf[4096];
			unsigned long	ulAddr = 0;
			unsigned long	ulSize = 0;
			int				ptr = 1;
			char			c;

			// アドレス
			while ( ptr < recv_len && (c = recv_packt[ptr++]) != ',' )
			{
				ulAddr = (ulAddr << 4) + CharToHex(c);
			}

			// アドレス
			while ( ptr < recv_len && (c = recv_packt[ptr++]) != ':' )
			{
				ulSize = (ulSize << 4) + CharToHex(c);
			}
			
			// データ
			for ( i = 0; ptr < recv_len && i < ulSize; i++ )
			{
				ubBuf[i]  = CharToHex(recv_packt[ptr++]) * 16;
				ubBuf[i] += CharToHex(recv_packt[ptr++]);
			}

			// 書き込み
			m_pDbgCtl->MemWrite(ulAddr, ubBuf, ulSize);

			
			RemoteSendPacket("OK", 2);
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


