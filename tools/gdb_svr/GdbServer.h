

#ifndef __GdbServer_h__
#define __GdbServer_h__


#include <stdarg.h>
#include "JellyControl.h"


class CGdbServer
{
public:
	CGdbServer(CDebugControl* pDbgCtl);
	virtual ~CGdbServer();
	
	void	RunServer(void);

protected:
	virtual int		RemotePutChar(char c) = 0;
	virtual int		RemoteGetChar(void) = 0;

	virtual void	LogPrint(const char *fmt, ...);

	
	static char		HexToChar(char c);
	static int		CharToHex(char c);
	int				SetWordString(char *buf, unsigned long word);
	int				GetWordString(char *buf, unsigned long *word);

	int				RemoteSendPacket(char *buf, int len);

	void			SendThreadId(void);

	CDebugControl*	m_pDbgCtl;

	bool			m_blLogEnable;
	bool			m_blBigEndian;
};


#endif	// __GdbServer_h__

