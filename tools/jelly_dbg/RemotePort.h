// ---------------------------------------------------------------------------
//  Jelly Debugger
//
//                                      Copyright (C) 2008 by Ryuz
// ---------------------------------------------------------------------------


#ifndef __RemotePort_h__
#define __RemotePort_h__

#define REMORT_CMD_NOP			0x00
#define REMORT_CMD_STATUS		0x01
#define REMORT_CMD_DBG_WRITE	0x02
#define REMORT_CMD_DBG_READ		0x03
#define REMORT_CMD_MEM_WRITE	0x04
#define REMORT_CMD_MEM_READ		0x05

#define REMORT_ACK_NOP			0x80
#define REMORT_ACK_STATUS		0x81
#define REMORT_ACK_DBG_WRITE	0x82
#define REMORT_ACK_DBG_READ		0x83
#define REMORT_ACK_MEM_WRITE	0x84
#define REMORT_ACK_MEM_READ		0x85


// Remote
class CRemotePort
{
public:
	CRemotePort();
	virtual ~CRemotePort() = 0;
	
	virtual bool	Open(const char* szName) = 0;
	virtual void	Close(void) = 0;
	virtual int		Send(const unsigned char *pbyData, int iSize) = 0;
	virtual int		Recv(unsigned char *pbyBuf, int iSize) = 0;	
	
	bool	Connect(void);
	void	Disconnect(void);
	
	bool	DbgRegWrite(int iAddr, unsigned long ulData);
	bool	DbgRegRead(int iAddr, unsigned long *pulData);
	
	bool	CpuRegWrite(int iAddr, unsigned long ulData);
	bool	CpuRegRead(int iAddr, unsigned long *pulData);
	
	int		MemWrite(unsigned long ulAddr, const void* pData, int iSize);
	bool	MemWriteWord(unsigned long ulAddr, unsigned long ulData);
	bool	MemWriteHalfWord(unsigned long ulAddr, unsigned short ulData);
	bool	MemWriteByte(unsigned long ulAddr, unsigned char ulData);
	
	int		MemRead(unsigned long ulAddr, void* pBuf, int iSize);
	bool	MemReadWord(unsigned long ulAddr, unsigned long* pulData);
	bool	MemReadHalfWord(unsigned long ulAddr, unsigned short* pulData);
	bool	MemReadByte(unsigned long ulAddr, unsigned char* pulData);


protected:
	int		m_iEndian;
};

#endif	// __RemotePort_h__
