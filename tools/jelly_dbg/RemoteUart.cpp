// ---------------------------------------------------------------------------
//  Jelly Debugger
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
// ---------------------------------------------------------------------------


#include "RemoteUart.h"


CRemoteUart::CRemoteUart(long lSpeed)
{
	m_hCom   = INVALID_HANDLE_VALUE;
	m_lSpeed = lSpeed;
}


CRemoteUart::~CRemoteUart()
{
	Close();
}


bool CRemoteUart::Open(const char* szName)
{
	DCB		dcb;

	/* COMポートオープン */
	m_hCom = CreateFile(szName, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	if ( m_hCom == INVALID_HANDLE_VALUE )
	{
		return false;
	}
	
	/* COM設定 */
	memset(&dcb, 0, sizeof(dcb));
	dcb.DCBlength = sizeof(dcb);
	GetCommState(m_hCom, &dcb);
	dcb.BaudRate          = m_lSpeed;				/* 通信速度 */
	dcb.fBinary           = TRUE;					/* バイナリモードの設定 */
    dcb.fParity           = FALSE;					/* パリティの設定 */
    dcb.fOutxCtsFlow      = FALSE;					/* CTS出力フローコントロールの設定 */
    dcb.fOutxDsrFlow      = FALSE;					/* DSR出力フローコントロールの設定 */
    dcb.fDtrControl       = DTR_CONTROL_DISABLE;	/* DTRフローコントロールの種類 */
    dcb.fDsrSensitivity   = FALSE;					/* DSR信号処理の設定 */
    dcb.fTXContinueOnXoff = FALSE;					/* XOFF送信後の処理の設定 */
    dcb.fOutX             = FALSE;					/* XON/XOFF出力フローコントロールの設定 */
    dcb.fInX              = FALSE;					/* XON/XOFF入力フローコントロールの設定 */
    dcb.fErrorChar        = 0;						/* パリティエラーの代替文字の設定 */
    dcb.fNull             = FALSE;                  /* NULLバイトの破棄 */
    dcb.fRtsControl       = RTS_CONTROL_DISABLE;	/* RTSフローコントロールの設定 */
    dcb.fAbortOnError     = FALSE;			        /* エラー時の動作 */
    dcb.ByteSize          = 8;						/* 1バイトのサイズ */
    dcb.Parity            = NOPARITY;				/* パリティの種類 */
    dcb.StopBits          = ONESTOPBIT;				/* ストップビットの種類 */
	if ( !SetCommState(m_hCom, &dcb) )
	{
		return false;
	}
	
	/* COMタイムアウト設定 */	
	COMMTIMEOUTS cto;
	memset(&cto, 0, sizeof(cto));
	GetCommTimeouts(m_hCom, &cto);
	cto.ReadIntervalTimeout         = MAXDWORD;
	cto.ReadTotalTimeoutMultiplier  = 20;
	cto.ReadTotalTimeoutConstant    = 100;
	cto.WriteTotalTimeoutMultiplier = 10;
	cto.WriteTotalTimeoutConstant   = 1000;
	SetCommTimeouts(m_hCom, &cto);
	
	/* COMバッファ設定 */
	SetupComm(m_hCom, 256 * 1024, 256 * 1024);
	
	return true;
}

// 閉じる
void CRemoteUart::Close(void)
{
	if ( m_hCom != INVALID_HANDLE_VALUE )
	{
		CloseHandle(m_hCom);
	}
	m_hCom = INVALID_HANDLE_VALUE;
}

// 送信
int CRemoteUart::Send(const unsigned char *pbyData, int iSize)
{
	if ( m_hCom == INVALID_HANDLE_VALUE )
	{
		return 0;
	}

	DWORD	dwWriteSize;
	if ( WriteFile(m_hCom, pbyData, iSize, &dwWriteSize, NULL) == 0 )
	{
		return 0;
	}

	return (int)dwWriteSize;
}

// 受信
int CRemoteUart::Recv(unsigned char *pbyBuf, int iSize)
{
	if ( m_hCom == INVALID_HANDLE_VALUE )
	{
		return 0;
	}

	DWORD	dwReadSize;
	if ( ReadFile(m_hCom, pbyBuf, iSize, &dwReadSize, NULL) == 0 )
	{
		return 0;
	}

	return (int)dwReadSize;
}


