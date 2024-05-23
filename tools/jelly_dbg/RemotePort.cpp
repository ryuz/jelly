// ---------------------------------------------------------------------------
//  Jelly Debugger
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
// ---------------------------------------------------------------------------


#include "RemotePort.h"
#include <string.h>


// nop           8'h00
// nop                 8'h80
//
// status        8'h01
// status_ack          8'h81 status
//
// dbg_write     8'h02 sel+adr dat0 dat1 dat2 dat3
// dbg_write_ack                                    8'h82
//
// dbg_read      8'h03 sel+adr
// dbg_write_ack                8'h83 dat0 dat1 dat2 dat3
//
// mem_write     8'h04 size adr0 adr1 adr2 adr3 dat0 dat1 dat2 dat3 ....
// mem_write_ack                                                          8'h84
//
// mem_read      8'h05 size adr0 adr1 adr2 adr3 
// mem_write_ack                                 8'h85 dat0 dat1 dat2 dat3 ....


#define DBG_ADR_DBG_CTL			0
#define DBG_ADR_DBG_ADDR		2
#define DBG_ADR_REG_DATA		4
#define DBG_ADR_DBUS_DATA		6
#define DBG_ADR_IBUS_DATA		7



CRemotePort::CRemotePort()
{
}

CRemotePort::~CRemotePort()
{
}


bool CRemotePort::Connect(void)
{
	unsigned char	ubSendBuf[1];
	unsigned char	ubRecvBuf[2];
	
	// Connect
	ubSendBuf[0] = REMORT_CMD_NOP;
	Send(ubSendBuf, 1);
	if ( Recv(ubRecvBuf, 1) != 1 || ubRecvBuf[0] != REMORT_ACK_NOP )
	{
		return false;
	}
	
	// Status
	ubSendBuf[0] = REMORT_CMD_STATUS;
	Send(ubSendBuf, 1);
	if ( Recv(ubRecvBuf, 2) != 2 || ubRecvBuf[0] != REMORT_ACK_STATUS )
	{
		return false;
	}
	m_iEndian = (ubRecvBuf[1] & 0x01);
	
	return true;
}


void CRemotePort::Disconnect(void)
{
}

bool CRemotePort::DbgRegWrite(int iAddr, unsigned long ulData)
{
	unsigned char	ubSendBuf[6];
	unsigned char	ubRecvBuf[1];
	
	// CMD
	ubSendBuf[0] = REMORT_CMD_DBG_WRITE;
	ubSendBuf[1] = (unsigned char)(0xf0 | (iAddr & 0x0f));
	if ( m_iEndian == 0 )
	{
		// little endian
		ubSendBuf[2] = (unsigned char)((ulData >>  0) & 0xff);
		ubSendBuf[3] = (unsigned char)((ulData >>  8) & 0xff);
		ubSendBuf[4] = (unsigned char)((ulData >> 16) & 0xff);
		ubSendBuf[5] = (unsigned char)((ulData >> 24) & 0xff);
	}
	else
	{
		// big endian
		ubSendBuf[2] = (unsigned char)((ulData >> 24) & 0xff);
		ubSendBuf[3] = (unsigned char)((ulData >> 16) & 0xff);
		ubSendBuf[4] = (unsigned char)((ulData >>  8) & 0xff);
		ubSendBuf[5] = (unsigned char)((ulData >>  0) & 0xff);
	}
	Send(ubSendBuf, 6);
	
	// ACK
	if ( Recv(ubRecvBuf, 1) != 1 || ubRecvBuf[0] != REMORT_ACK_DBG_WRITE )
	{
		return false;
	}

	return true;
}


bool CRemotePort::DbgRegRead(int iAddr, unsigned long *pulData)
{
	unsigned char	ubSendBuf[2];
	unsigned char	ubRecvBuf[5];
	
	// CMD
	ubSendBuf[0] = REMORT_CMD_DBG_READ;
	ubSendBuf[1] = (unsigned char)(0xf0 | (iAddr & 0x0f));
	Send(ubSendBuf, 2);

	// ACK
	if ( Recv(ubRecvBuf, 5) != 5 || ubRecvBuf[0] != REMORT_ACK_DBG_READ )
	{
		return false;
	}
	
	if ( m_iEndian == 0 )
	{
		// little endian
		*pulData = ((unsigned long)ubRecvBuf[1] << 0)
					| ((unsigned long)ubRecvBuf[2] << 8)
					| ((unsigned long)ubRecvBuf[3] << 16)
					| ((unsigned long)ubRecvBuf[4] << 24);
	}
	else
	{
		// big endian
		*pulData = ((unsigned long)ubRecvBuf[1] << 24)
					| ((unsigned long)ubRecvBuf[2] << 16)
					| ((unsigned long)ubRecvBuf[3] << 8)
					| ((unsigned long)ubRecvBuf[4] << 0);
	}
	
	return true;
}


bool CRemotePort::CpuRegWrite(int iAddr, unsigned long ulData)
{
	// ADDR
	if ( !DbgRegWrite(DBG_ADR_DBG_ADDR, iAddr * 4) )
	{
		return false;
	}
	
	// DATA
	if ( !DbgRegWrite(DBG_ADR_REG_DATA, ulData) )
	{
		return false;
	}

	return true;
}


bool CRemotePort::CpuRegRead(int iAddr, unsigned long *pulData)
{
	// ADDR
	if ( !DbgRegWrite(DBG_ADR_DBG_ADDR, iAddr * 4) )
	{
		return false;
	}
	
	// DATA
	if ( !DbgRegRead(DBG_ADR_REG_DATA, pulData) )
	{
		return false;
	}
	
	return true;
}


bool CRemotePort::MemWriteWord(unsigned long ulAddr, unsigned long ulData)
{
	// ADDR
	if ( !DbgRegWrite(DBG_ADR_DBG_ADDR, ulAddr) )
	{
		return false;
	}
	
	// DATA
	if ( !DbgRegWrite(DBG_ADR_DBUS_DATA, ulData) )
	{
		return false;
	}
	
	return true;
}


bool CRemotePort::MemReadWord(unsigned long ulAddr, unsigned long* pulData)
{
	// ADDR
	if ( !DbgRegWrite(DBG_ADR_DBG_ADDR, ulAddr) )
	{
		return false;
	}
	
	// DATA
	if ( !DbgRegRead(DBG_ADR_DBUS_DATA, pulData) )
	{
		return false;
	}

	return true;
}



int CRemotePort::MemWrite(unsigned long ulAddr, const void* pData, int iSize)
{
	unsigned char	ubSendBuf[6+256];
	unsigned char	ubRecvBuf[1];
	int iTotalSize = 0;
	int iWriteSize;

	while ( iSize > 0 )
	{
		iWriteSize = iSize;
		if ( iWriteSize > 256 )
		{
			iWriteSize = 256;
		}
		
		// CMD
		ubSendBuf[0] = REMORT_CMD_MEM_WRITE;
		ubSendBuf[1] = (unsigned char)((iWriteSize - 1) & 0xff);
		if ( m_iEndian == 0 )
		{
			ubSendBuf[2] = (unsigned char)((ulAddr >>  0) & 0xff);
			ubSendBuf[3] = (unsigned char)((ulAddr >>  8) & 0xff);
			ubSendBuf[4] = (unsigned char)((ulAddr >> 16) & 0xff);
			ubSendBuf[5] = (unsigned char)((ulAddr >> 24) & 0xff);
		}
		else
		{
			ubSendBuf[2] = (unsigned char)((ulAddr >> 24) & 0xff);
			ubSendBuf[3] = (unsigned char)((ulAddr >> 16) & 0xff);
			ubSendBuf[4] = (unsigned char)((ulAddr >>  8) & 0xff);
			ubSendBuf[5] = (unsigned char)((ulAddr >>  0) & 0xff);
		}
		memcpy(&ubSendBuf[6], pData, iWriteSize);
		Send(ubSendBuf, 6 + iWriteSize);

		// ACK
		if ( (Recv(ubRecvBuf, 1) != 1) || ubRecvBuf[0] != REMORT_ACK_MEM_WRITE )
		{
			break;
		}
		
		pData       = (const char *)pData + iWriteSize;
		ulAddr     += iWriteSize;
		iSize      -= iWriteSize;
		iTotalSize += iWriteSize;
	}

	return iTotalSize;
}


int CRemotePort::MemRead(unsigned long ulAddr, void* pBuf, int iSize)
{
	unsigned char	ubSendBuf[6];
	unsigned char	ubRecvBuf[256+1];
	int iTotalSize = 0;
	int iReadSize;

	while ( iSize > 0 )
	{
		iReadSize = iSize;
		if ( iReadSize > 256 )
		{
			iReadSize = 256;
		}
		
		// CMD
		ubSendBuf[0] = REMORT_CMD_MEM_READ;
		ubSendBuf[1] = (unsigned char)((iReadSize - 1) & 0xff);
		if ( m_iEndian == 0 )
		{
			ubSendBuf[2] = (unsigned char)((ulAddr >>  0) & 0xff);
			ubSendBuf[3] = (unsigned char)((ulAddr >>  8) & 0xff);
			ubSendBuf[4] = (unsigned char)((ulAddr >> 16) & 0xff);
			ubSendBuf[5] = (unsigned char)((ulAddr >> 24) & 0xff);
		}
		else
		{
			ubSendBuf[2] = (unsigned char)((ulAddr >> 24) & 0xff);
			ubSendBuf[3] = (unsigned char)((ulAddr >> 16) & 0xff);
			ubSendBuf[4] = (unsigned char)((ulAddr >>  8) & 0xff);
			ubSendBuf[5] = (unsigned char)((ulAddr >>  0) & 0xff);
		}
		Send(ubSendBuf, 6);

		// ACK
		if ( Recv(ubRecvBuf, iReadSize+1) != (iReadSize+1) || ubRecvBuf[0] != REMORT_ACK_MEM_READ )
		{
			break;
		}
		
		memcpy(pBuf, &ubRecvBuf[1], iReadSize);
		pBuf        = (char *)pBuf + iReadSize;
		ulAddr     += iReadSize;
		iSize      -= iReadSize;
		iTotalSize += iReadSize;
	}
	
	return iTotalSize;
}

