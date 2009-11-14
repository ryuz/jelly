// ---------------------------------------------------------------------------
//  RzDebugger
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
// ---------------------------------------------------------------------------


#ifndef __JellyControl_h__
#define __JellyControl_h__


#include "DebugControl.h"


// CJellyControl
class CJellyControl : public CDebugControl
{
public:
	CJellyControl(CRemotePort *pPort);
	virtual ~CJellyControl();

	virtual int				GetStatus(void);
	virtual bool			Break(void);
	virtual bool			Run(void);
	virtual bool			Step(void);
	
	virtual unsigned long	GetPc(void);
	virtual bool			SetPc(unsigned long ulAddr);

	virtual int				GetRegisterNum(void);
	virtual const char*		GetRegisterName(int iIndex);
	virtual unsigned long	GetRegisterValue(int iIndex);
	
	virtual int				SetBreakPoint(unsigned long ulAddr);
	virtual bool			ClearBreakPoint(int iIndex);
	
	virtual int				GetBreakPointNum(void);
	virtual unsigned long	GetBreakPoint(int iIndex);

protected:
	bool			m_blBreakPointEnable[4];
	unsigned long	m_ulBreakPointAddr[4];
};


#endif	// __JellyControl_h__


