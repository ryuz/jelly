// ---------------------------------------------------------------------------
//  RzDebugger
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
// ---------------------------------------------------------------------------


#include "DebugControl.h"


CDebugControl::CDebugControl(CRemotePort *pPort)
{
	m_pPort = pPort;
}

CDebugControl::~CDebugControl()
{
}

