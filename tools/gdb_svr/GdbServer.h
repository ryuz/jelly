

#ifndef __GdbServer_h__
#define __GdbServer_h__


#include <stdarg.h>
#include "JellyControl.h"


#define	GDBSERVER_MAX_BP_NUM	4096


struct TGdbServerBp
{
	bool			blValid;
	unsigned long	ulAddr;
	unsigned long	ulInst;
};


class CGdbServer
{
public:
	CGdbServer(CDebugControl* pDbgCtl);
	virtual ~CGdbServer();
	
	void	RunServer(void);

protected:
	virtual int		RemotePutChar(char c) = 0;
	virtual int		RemotePeekChar(void) = 0;
	virtual int		RemoteGetChar(void) = 0;

	virtual void	LogPrint(const char *fmt, ...);

	
	static char		HexToChar(char c);
	static int		CharToHex(char c);
	int				SetWordString(char *buf, unsigned long word);
	int				GetWordString(char *buf, unsigned long *word);

	int				RemoteSendPacket(char *buf, int len);
	
	void			SendThreadId(void);
	
	bool			AddBp(unsigned long ulAddr);
	bool			RemoveBp(unsigned long ulAddr);
	void			LoadBp(void);
	void			UnloadBp(void);
	
	
	CDebugControl*	m_pDbgCtl;

	bool			m_blLogEnable;
	bool			m_blBigEndian;
	
	TGdbServerBp	m_BpTable[GDBSERVER_MAX_BP_NUM];
};


#endif	// __GdbServer_h__

