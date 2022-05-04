

#include "uart.h"


#define UART0_BASE_ADDR                 0xff000000
#define UART1_BASE_ADDR                 0xff010000

#define UART_BASE_ADDR                  UART1_BASE_ADDR

#define UART_Control                    ((volatile unsigned long *)(UART_BASE_ADDR + 0x00000000))
#define UART_Mode                       ((volatile unsigned long *)(UART_BASE_ADDR + 0x00000004))
#define UART_Intrpt_en                  ((volatile unsigned long *)(UART_BASE_ADDR + 0x00000008))
#define UART_Intrpt_dis                 ((volatile unsigned long *)(UART_BASE_ADDR + 0x0000000C))
#define UART_Intrpt_mask                ((volatile unsigned long *)(UART_BASE_ADDR + 0x00000010))
#define UART_Chnl_int_sts               ((volatile unsigned long *)(UART_BASE_ADDR + 0x00000014))
#define UART_Baud_rate_gen              ((volatile unsigned long *)(UART_BASE_ADDR + 0x00000018))
#define UART_Rcvr_timeout               ((volatile unsigned long *)(UART_BASE_ADDR + 0x0000001C))
#define UART_Rcvr_FIFO_trigger_level    ((volatile unsigned long *)(UART_BASE_ADDR + 0x00000020))
#define UART_Modem_ctrl                 ((volatile unsigned long *)(UART_BASE_ADDR + 0x00000024))
#define UART_Modem_sts                  ((volatile unsigned long *)(UART_BASE_ADDR + 0x00000028))
#define UART_Channel_sts                ((volatile unsigned long *)(UART_BASE_ADDR + 0x0000002C))
#define UART_TX_RX_FIFO                 ((volatile unsigned char *)(UART_BASE_ADDR + 0x00000030))
#define UART_Baud_rate_divider          ((volatile unsigned long *)(UART_BASE_ADDR + 0x00000034))
#define UART_Flow_delay                 ((volatile unsigned long *)(UART_BASE_ADDR + 0x00000038))
#define UART_Tx_FIFO_trigger_level      ((volatile unsigned long *)(UART_BASE_ADDR + 0x00000044))
#define UART_Rx_FIFO_byte_status        ((volatile unsigned long *)(UART_BASE_ADDR + 0x00000048))




/* UARTの初期化 */
void Uart_Initialize(void)
{
#if 0
    *UART_Control           = 0x28;     /* 停止 */
    *UART_Baud_rate_gen     = 0x7c;     /* 115200bps */
    *UART_Baud_rate_divider = 0x06;
    *UART_Control           = 0x03;     /* TX/RXリセット */
    *UART_Control           = 0x00;
    *UART_Control           = 0x14;     /* 開始 */
    *UART_Mode              = 0x20;     /* non-parity */

    *UART_Intrpt_en = 0x07; 
#endif
}


/* 1文字出力 */
void Uart_PutChar(int c)
{
    while ( *UART_Channel_sts & 0x10 )
        ;
    
    *UART_TX_RX_FIFO = c;
}


/* 文字列出力 */
void Uart_PutString(const char *text)
{
    while ( *text != '\0' )
    {
        if ( *text == '\n' )
        {
            Uart_PutChar('\r');
            Uart_PutChar('\n');
        }
        else
        {
            Uart_PutChar(*text);
        }
        
        text++;
    }
}


char Uart_hex2asc(int a)
{
    if ( a < 10 )
    {
        return '0' + a;
    }
    return 'a' + a - 10;
}


void Uart_PutHexByte(char c)
{
    Uart_PutChar(Uart_hex2asc((c >> 4) & 0xf));
    Uart_PutChar(Uart_hex2asc((c >> 0) & 0xf));
}

void Uart_PutHexWord(int i)
{
    Uart_PutHexByte((i >> 8) & 0xff);
    Uart_PutHexByte((i >> 0) & 0xff);
}


/* end of file */
