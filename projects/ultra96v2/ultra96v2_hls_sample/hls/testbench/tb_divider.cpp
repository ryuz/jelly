
#include "divider.h"

int main()
{
    int a = 12345;
    int b = 7;
    
    int c;
    divider(a, b, &c);
    
    if ( a/b != c ) {
        return 1;
    }
    
    return 0;
}
