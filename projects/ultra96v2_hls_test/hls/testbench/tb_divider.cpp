
#include "divider.h"

int main()
{
    int a = 12345;
    int b = 7;
    
    int c;
    divider(a, b, &c);
    
    if ( a/b != c ) {
        printf("error!!\n");
        return 1;
    }
    
    return 0;
}
