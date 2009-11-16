// ---------------------------------------------------------------------------
//  RzDebugger
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
// ---------------------------------------------------------------------------


#ifndef __DebugControl_h__
#define __DebugControl_h__


#include "RemotePort.h"


// DebugControl
class CDebugControl
{
public:
	CDebugControl(CRemotePort *pPort);
	virtual ~CDebugControl();

	virtual int				GetStatus(void) = 0;
	virtual bool			Break(void) = 0;
	virtual bool			Run(void) = 0;
	virtual bool			Step(void) = 0;
	
	virtual unsigned long	GetPc(void) = 0;
	virtual bool			SetPc(unsigned long ulAddr) = 0;
	
	virtual int				GetRegisterNum(void) = 0;
	virtual const char*		GetRegisterName(int iIndex) = 0;
	virtual unsigned long	GetRegisterValue(int iIndex) = 0;
	virtual bool			SetRegisterValue(int iIndex, unsigned long ulData) = 0;

	virtual int				GetRegisterIndex(const char *pszName);
	virtual unsigned long	GetRegisterValue(const char *pszName);
	virtual bool			SetRegisterValue(const char *pszName, unsigned long ulData);
	
	virtual int				SetBreakPoint(unsigned long ulAddr) = 0;
	virtual bool			ClearBreakPoint(int iIndex) = 0;
	
	virtual int				GetBreakPointNum(void) = 0;
	virtual unsigned long	GetBreakPoint(int iIndex) = 0;
	
	bool	Connect(void)    { return m_pPort->Connect(); }
	void	Disconnect(void) { m_pPort->Disconnect(); }
	
	int		MemWrite(unsigned long ulAddr, const void* pData, int iSize)	{ return m_pPort->MemWrite(ulAddr, pData, iSize); }
	bool	MemWriteWord(unsigned long ulAddr, unsigned long ulData);
	bool	MemWriteHalfWord(unsigned long ulAddr, unsigned short ulData);
	bool	MemWriteByte(unsigned long ulAddr, unsigned char ulData);
	
	int		MemRead(unsigned long ulAddr, void* pBuf, int iSize)			{ return m_pPort->MemRead(ulAddr, pBuf, iSize); }
	bool	MemReadWord(unsigned long ulAddr, unsigned long* pulData);
	bool	MemReadHalfWord(unsigned long ulAddr, unsigned short* pulData);
	bool	MemReadByte(unsigned long ulAddr, unsigned char* pulData);
	
protected:
	CRemotePort *m_pPort;
};


#endif	// __DebugControl_h__
