

#ifndef __GdbServerTcp_h__
#define __GdbServerTcp_h__


#include <winsock2.h>
#include "GdbServer.h"


class CGdbServerTcp : public CGdbServer
{
public:
	CGdbServerTcp(int port);
	virtual ~CGdbServerTcp();
	
protected:
	int				RemoteGetChar(void);
	int				RemotePutChar(char c);
	virtual int		RemodePeekChar(void);
	
	bool				m_blConected;

	SOCKET				m_sock0;
	struct sockaddr_in	m_addr;
	struct sockaddr_in	m_client;
	SOCKET				m_sock;
};


#endif	// __GdbServerTcp_h__


// end of file
