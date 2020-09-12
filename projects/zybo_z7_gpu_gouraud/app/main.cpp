
#include <iostream>
#include <cstdint>

#include "jelly/UioAccessor.h"


void gpu_test(void *gpu_addr);


int main()
{
   // mmap uio
    std::cout << "\nuio open" << std::endl;
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x01000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

	volatile uint32_t *map_addr = (volatile uint32_t *)uio_acc.GetPtr();
	gpu_test((void*)&map_addr[0x00100000/4]);
		
	return 0;
}



