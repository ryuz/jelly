// ---------------------------------------------------------------------------
//  Jelly Debugger
//
//                                      Copyright (C) 2008 by Ryuz
// ---------------------------------------------------------------------------


#ifndef	__RemoteUart_h__
#define __RemoteUart_h__

#include "RemotePort.h"
#include <windows.h>


class CRemoteUart : public CRemotePort
{
public:
	CRemoteUart(long lSpeed = CBR_38400);
	virtual ~CRemoteUart();
	
	virtual bool		Open(const char* szName);
	virtual void		Close(void);
	virtual int			Send(const unsigned char *pbyData, int iSize);
	virtual int			Recv(unsigned char *pbyBuf, int iSize);

protected:
	HANDLE	m_hCom;
	long	m_lSpeed;
};


#endif	// __RemoteUart_h__

