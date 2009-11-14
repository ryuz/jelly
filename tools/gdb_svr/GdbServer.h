

#ifndef __GdbServer_h__
#define __GdbServer_h__


#include <stdarg.h>


class CGdbServer
{
public:
	CGdbServer();
	virtual ~CGdbServer();
	
	void	RunServer(void);

protected:
	virtual int		RemotePutChar(char c) = 0;
	virtual int		RemoteGetChar(void) = 0;

	virtual void	LogPrint(const char *fmt, ...);

	
	static char		HexToChar(char c);
	static int		CharToHex(char c);

	int				RemoteSendPacket(char *buf, int len);

	bool	m_blLogEnable;
	bool	m_blBigEndian;
};


#endif	// __GdbServer_h__

