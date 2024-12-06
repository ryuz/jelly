#include <iostream>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>


int main()
{
    // デバイスオープン
    auto fd = open("/dev/mem", O_RDWR);
    if ( fd <= 0 ) {
        std::cout << "open error" << std::endl;
        return 1;
    }
    
    // メモリをマップ
    auto iomap = mmap(0, 0x10000, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0xa0000000);
    if ( iomap == nullptr ) {
        std::cout << "mmap error" << std::endl;
        close(fd);
        return 1;
    }

    // LED点滅
    for ( int i = 0; i < 10; ++i ) {
        *(volatile unsigned char *)iomap ^= 1;
        usleep(500000);
    }

    // クローズ
    munmap(iomap, 0x10000);
    close(fd);

    return 0;
}
