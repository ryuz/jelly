
#include "uart.h"

int a = 1;

int main()
{
    Uart_PutString("Hello World\r\n");
    for ( ; ; ) {
    }

    return 0;
}

