#include <iostream>
#include <iomanip>
#include <string>

#include <string.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>


#define PAGE_SIZE       4096LL
#define PAGE_MASK       (PAGE_SIZE - 1)


template <typename T>
void write_data(std::int8_t* mem_ptr, std::uintptr_t addr, T data)
{
    auto offset = (addr & PAGE_MASK);
    *(reinterpret_cast<volatile T *>(&mem_ptr[offset])) = data;
 
    std::cout << "0x" << std::hex << std::setw(sizeof(void*)*2) << std::setfill('0') << addr << " : "
              << "0x" << std::hex << std::setw(sizeof(data)*2) << std::setfill('0') << (std::int64_t)data
              << " (" << std::dec << (std::int64_t)data << ")" << std::endl;
}


int main(int argc, char *argv[])
{
    // command line
    std::uintptr_t addr = 0;
    std::uintptr_t data = 0;
    int word_size = 4;
    int param = 0;
    for ( int i = 1; i < argc; ++i ) {
        if ( strcmp(argv[i], "-b") == 0 ) {
            word_size = 1;
        }
        else if ( strcmp(argv[i], "-h") == 0 ) {
            word_size = 2;
        }
        else if ( strcmp(argv[i], "-w") == 0 ) {
            word_size = 4;
        }
        else if ( strcmp(argv[i], "-d") == 0 ) {
            word_size = 8;
        }
        else if ( param == 0 ) {
            addr = (std::uintptr_t)strtoull(argv[i], nullptr, 0);
            param++;
        }
        else if ( param == 1 ) {
            data = (std::uintptr_t)strtoull(argv[i], nullptr, 0);
            param++;
        }
        else {
            std::cerr << "unknown option : " << argv[i] << std::endl;
            return 1;
        }
    } 
    if ( param != 2 ) {
        std::cerr << "Memory Write command" << std::endl;
        std::cerr << "[usage]" << std::endl;
        std::cerr << argv[0] << "[option] <addr> <data>" << std::endl;
        std::cerr << "  options:" << std::endl;
        std::cerr << "    -b byte(8bit)" << std::endl;
        std::cerr << "    -h half-work(16bit)" << std::endl;
        std::cerr << "    -w word(32bit)" << std::endl;
        std::cerr << "    -d double-word(64bit)" << std::endl;
        return 0;
    }

    // open
    auto fd = open("/dev/mem", O_RDWR | O_SYNC);
    if ( fd == -1) {
        std::cerr << "open error : /dev/mem" << std::endl;
        return 1;
    }

    // mmap
    std::uintptr_t  addr_base   = (addr & ~PAGE_MASK);
    std::uintptr_t  addr_offset = (addr &  PAGE_MASK);
    auto mem_ptr = (std::int8_t*)mmap(NULL, PAGE_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, addr_base);
    if ( mem_ptr == MAP_FAILED ) {
        std::cerr << "mmap error" << std::endl;
        return 1;
    }
    
    // access
    switch ( word_size ) {
    case 1: write_data<std::uint8_t >(mem_ptr, addr, data); break;
    case 2: write_data<std::uint16_t>(mem_ptr, addr, data); break;
    case 4: write_data<std::uint32_t>(mem_ptr, addr, data); break;
    case 8: write_data<std::uint64_t>(mem_ptr, addr, data); break;
    }
    
    munmap(mem_ptr, PAGE_SIZE);
    close(fd);
    
    return 0;
}


// end of file
