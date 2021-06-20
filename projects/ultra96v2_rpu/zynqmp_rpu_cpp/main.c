
#include "uart.h"


int a[10];
int b[10] = {1, 2, 3};

int main()
{
    Uart_PutString("Hello World\r\n");
    
    return 0;
}

