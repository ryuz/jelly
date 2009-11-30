// ---------------------------------------------------------------------------
//  RzDebugger
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
// ---------------------------------------------------------------------------


#include "JellyControl.h"


#define DBG_CTL			0
#define DBG_ADDR		2
#define REG_DATA		4
#define DBUS_DATA		6
#define IBUS_DATA		7


struct TJellyRegister
{
	const char*		pszName;
	unsigned long	ulAddr;
};

static TJellyRegister	JellyRegister[] =
	{
		{"R0",	0x20},
		{"R1",	0x21},
		{"R2",	0x22},
		{"R3",	0x23},
		{"R4",	0x24},
		{"R5",	0x25},
		{"R6",	0x26},
		{"R7",	0x27},
		{"R8",	0x28},
		{"R9",	0x29},
		{"R10",	0x2a},
		{"R11",	0x2b},
		{"R12",	0x2c},
		{"R13",	0x2d},
		{"R14",	0x2e},
		{"R15",	0x2f},
		{"R16",	0x30},
		{"R17",	0x31},
		{"R18",	0x32},
		{"R19",	0x33},
		{"R20",	0x34},
		{"R21",	0x35},
		{"R22",	0x36},
		{"R23",	0x37},
		{"R24",	0x38},
		{"R25",	0x39},
		{"R26",	0x3a},
		{"R27",	0x3b},
		{"R28",	0x3c},
		{"R29",	0x3d},
		{"R30",	0x3e},
		{"R31",	0x3f},
		{"HI",	0x10},
		{"LO",	0x11},
		{"COP0_STATUS",	0x4c},
		{"COP0_CAUSE",	0x4d},
		{"COP0_EPC",	0x4e},
		{"COP0_DBBP0",	0x50},
		{"COP0_DBBP0",	0x51},
		{"COP0_DBBP0",	0x52},
		{"COP0_DBBP0",	0x53},
		{"COP0_DEBUG",	0x57},
		{"COP0_DEEPC",	0x58},
	};



CJellyControl::CJellyControl(CRemotePort *pPort) : CDebugControl(pPort)
{
	int i;
	for ( i = 0; i < 4; i++ )
	{
		m_blBreakPointEnable[i] = false;
		m_ulBreakPointAddr[i]   = 0;
	}
}

CJellyControl::~CJellyControl()
{
}


// status
int CJellyControl::GetStatus(void)
{
	unsigned long ulStatus;

	if ( !m_pPort->DbgRegRead(DBG_CTL, &ulStatus) )
	{
		return -1;
	}
	
	return (ulStatus & 0x00000001) ? 1 : 0;
}


bool CJellyControl::Break(void)
{
	unsigned long ulStatus;
	int i;
	
	// read status
	if ( !m_pPort->DbgRegRead(DBG_CTL, &ulStatus) )
	{
		return false;
	}
	
	ulStatus |= 0x00000002;
	if ( !m_pPort->DbgRegWrite(DBG_CTL, ulStatus) )
	{
		return false;
	}

	for ( i = 0; i < 100; i++ )
	{
		if ( GetStatus() == 1 )
		{
			return true;
		}
	}
	
	return false;	// time out
}


bool CJellyControl::Run(void)
{
	// clear STEP
	unsigned long ulCop0Debug;
	if ( !m_pPort->CpuRegRead(0x57, &ulCop0Debug) )
	{
		return false;
	}
	ulCop0Debug &= ~0x01000000;
	if ( !m_pPort->CpuRegWrite(0x57, ulCop0Debug) )
	{
		return false;
	}
	
	// release debug
	unsigned long ulStatus;
	if ( !m_pPort->DbgRegRead(DBG_CTL, &ulStatus) )
	{
		return false;
	}
	ulStatus &= ~0x00000003;
	if ( !m_pPort->DbgRegWrite(DBG_CTL, ulStatus) )
	{
		return false;
	}
	
	return true;
}


bool CJellyControl::Step(void)
{
	// set STEP
	unsigned long ulCop0Debug;
	if ( !m_pPort->CpuRegRead(0x57, &ulCop0Debug) )
	{
		return false;
	}
	ulCop0Debug |= 0x01000000;
	if ( !m_pPort->CpuRegWrite(0x57, ulCop0Debug) )
	{
		return false;
	}
	
	// release debug
	unsigned long ulStatus;
	if ( !m_pPort->DbgRegRead(DBG_CTL, &ulStatus) )
	{
		return false;
	}
	ulStatus &= ~0x00000003;
	if ( !m_pPort->DbgRegWrite(DBG_CTL, ulStatus) )
	{
		return false;
	}
	
	return true;
}


unsigned long CJellyControl::GetPc(void)
{
	unsigned long ulCop0Deepc;
	unsigned long ulCop0Debug;
	
	if ( !m_pPort->CpuRegRead(0x58, &ulCop0Deepc) )
	{
		return -1;
	}
	if ( !m_pPort->CpuRegRead(0x57, &ulCop0Debug) )
	{
		return -1;
	}
	if ( ulCop0Debug & 0x80000000 )
	{
		ulCop0Deepc += 4;
	}
	
	return ulCop0Deepc;
}


bool CJellyControl::SetPc(unsigned long ulAddr)
{
	unsigned long ulCop0Deepc;
	unsigned long ulCop0Debug;
	
	// Œ»Ý‚ÌPCŽæ“¾
	if ( !m_pPort->CpuRegRead(0x58, &ulCop0Deepc) )
	{
		return false;
	}
	if ( !m_pPort->CpuRegRead(0x57, &ulCop0Debug) )
	{
		return false;
	}
	if ( ulCop0Debug & 0x80000000 )
	{
		ulCop0Deepc += 4;
	}
	
	// •Ï‰»‚ª‚ ‚ê‚ÎÄÝ’è
	if ( ulCop0Deepc != ulAddr)
	{
		ulCop0Debug &= ~0x80000000;
		if ( !m_pPort->CpuRegWrite(0x57, ulCop0Debug) )
		{
			return false;
		}
		if ( !m_pPort->CpuRegWrite(0x58, ulAddr) )
		{
			return false;
		}
	}

	return true;
}


int CJellyControl::GetRegisterNum(void)
{
	return sizeof(JellyRegister) / sizeof(JellyRegister[0]);
}

const char* CJellyControl::GetRegisterName(int iIndex)
{
	return JellyRegister[iIndex].pszName;
}

unsigned long CJellyControl::GetRegisterValue(int iIndex)
{
	unsigned long ulValue;

	if ( !m_pPort->CpuRegRead(JellyRegister[iIndex].ulAddr, &ulValue) )
	{
		return 0;
	}

	return ulValue; 
}


bool CJellyControl::SetRegisterValue(int iIndex, unsigned long ulData)
{
	return m_pPort->CpuRegWrite(JellyRegister[iIndex].ulAddr, ulData);
}



int CJellyControl::SetBreakPoint(unsigned long ulAddr)
{
	int i;

	for ( i = 0; i < 4; i++ )
	{
		if ( !m_blBreakPointEnable[i] )
		{
			unsigned long ulDebug;
			m_pPort->CpuRegWrite(0x50 + i, ulAddr);
			m_pPort->CpuRegRead(0x57 + i, &ulDebug);
			ulDebug |= (1 << i);
			m_pPort->CpuRegWrite(0x57 + i, ulDebug);
			
			m_blBreakPointEnable[i] = true;
			m_ulBreakPointAddr[i]   = ulAddr;
			return i;
		}
	}

	return -1;
}


bool CJellyControl::ClearBreakPoint(int iIndex)
{
	if ( iIndex < 0 || iIndex >= 4 )
	{
		return false;
	}

			unsigned long ulDebug;
	m_pPort->CpuRegRead(0x57 + iIndex, &ulDebug);
	ulDebug &= ~(1 << iIndex);
	m_pPort->CpuRegWrite(0x57 + iIndex, ulDebug);
	
	m_blBreakPointEnable[iIndex] = false;
	m_ulBreakPointAddr[iIndex]   = 0;

	return true;
}

int CJellyControl::GetBreakPointNum(void)
{
	return 0;
}

unsigned long CJellyControl::GetBreakPoint(int iIndex)
{
	return 0;
}
	

