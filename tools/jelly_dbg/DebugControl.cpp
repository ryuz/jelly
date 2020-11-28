// ---------------------------------------------------------------------------
//  RzDebugger
//
//                                      Copyright (C) 2008 by Ryuz
// ---------------------------------------------------------------------------


#include <string.h>
#include "DebugControl.h"


CDebugControl::CDebugControl(CRemotePort *pPort)
{
	m_pPort = pPort;
}

CDebugControl::~CDebugControl()
{
}


int CDebugControl::GetRegisterIndex(const char *pszName)
{
	int iRegNum = GetRegisterNum();
	for ( int i = 0; i < iRegNum; i++ )
	{
		if ( stricmp(GetRegisterName(i), pszName) == 0 )
		{
			return i;
		}
	}
	
	return -1;
}


unsigned long CDebugControl::GetRegisterValue(const char *pszName)
{
	int iIndex = GetRegisterIndex(pszName);
	if ( iIndex < 0 )
	{
		return 0;
	}

	return GetRegisterValue(iIndex);
}

bool CDebugControl::SetRegisterValue(const char *pszName, unsigned long ulData)
{
	int iIndex = GetRegisterIndex(pszName);
	if ( iIndex < 0 )
	{
		return false;
	}

	return SetRegisterValue(iIndex, ulData);
}

