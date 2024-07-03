#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <iostream>
#include <chrono>

#include "jelly/UioAccessor.h"

#define DUMMY_ARRAY_SIZE    (1024 * 1024 / 8)
static volatile int64_t dummy_array [DUMMY_ARRAY_SIZE];
int64_t cache_flush() {
    int64_t s = 0;
    for ( size_t i = 0; i < DUMMY_ARRAY_SIZE; i++ ) {
        s += dummy_array[i];
    }
    return s;
}

static int64_t test_array [256*1024 / 8];


int g_v;
double read_test_oneshot(void *addr, size_t size) {   
    cache_flush();

    auto ptr = (volatile uint64_t *)addr;
    auto len = size / sizeof(uint64_t);

    // 時間計測開始
    auto start = std::chrono::system_clock::now();

    // 読み出し
    uint64_t s = 0;
    for ( size_t i = 0; i < len; i++ ) {
        s += ptr[i];
    }
    g_v = s;

    // 時間計測終了
    auto end = std::chrono::system_clock::now();

    // double型でナノ秒に変換
    double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    return elapsed / (1000*1000*1000);
}

double read_test(void *addr, size_t size, int times) {
    double sum = 0;
    for ( int i = 0; i < times; i++ ) {
        sum += read_test_oneshot(addr, size);
    }
    return sum / times;
}


double write_test_oneshot(void *addr, size_t size) {   
    cache_flush();

    auto ptr = (volatile uint64_t *)addr;
    auto len = size / sizeof(uint64_t);

    // 時間計測開始
    auto start = std::chrono::system_clock::now();

    // 読み出し
    for ( size_t i = 0; i < len; i++ ) {
        ptr[i] = i;
    }

    // 時間計測終了
    auto end = std::chrono::system_clock::now();

    // double型でナノ秒に変換
    double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    return elapsed / (1000*1000*1000);
}

double write_test(void *addr, size_t size, int times) {
    double sum = 0;
    for ( int i = 0; i < times; i++ ) {
        sum += write_test_oneshot(addr, size);
    }
    return sum / times;
}


int main(int argc, char *argv[])
{
    // mmap uio FPD0
    jelly::UioAccessor uio_fpd0("uio_pl_fpd0", 0x08000000);
    if ( !uio_fpd0.IsMapped() ) {
        std::cout << "uio_pl_fpd0 mmap error" << std::endl;
        return 1;
    }

    // mmap uio FPD0
    jelly::UioAccessor uio_ocm("uio_ocm", 0x08000000);
    if ( !uio_ocm.IsMapped() ) {
        std::cout << "uio_ocm mmap error" << std::endl;
        return 1;
    }

    int    test_times = 100;
    size_t test_size  = 32*1024;

    printf("<< Read Test>>\n");
    auto read_ddr_time = read_test(&test_array[0], test_size, test_times);
    printf("[DDR4-SDRAM] : %8.3f  [Mbyte/s]\n", test_size / read_ddr_time / (1024*1024));

    auto read_ocm_time = read_test(uio_ocm.GetPtr(), test_size, test_times);
    printf("[OCM (uio)]  : %8.3f  [Mbyte/s]\n", test_size / read_ocm_time / (1024*1024));

    auto read_fpd0_time = read_test(uio_fpd0.GetPtr(), test_size, test_times);
    printf("[PL  (uio)]  : %8.3f  [Mbyte/s]\n", test_size / read_fpd0_time / (1024*1024));


    printf("<< Write Test>>\n");
    auto write_ddr_time = write_test(&test_array[0], test_size, test_times);
    printf("[DDR4-SDRAM] : %8.3f  [Mbyte/s]\n", test_size / write_ddr_time / (1024*1024));

    auto write_ocm_time = write_test(uio_ocm.GetPtr(), test_size, test_times);
    printf("[OCM (uio)]] : %8.3f  [Mbyte/s]\n", test_size / write_ocm_time / (1024*1024));

    auto write_fpd0_time = write_test(uio_fpd0.GetPtr(), test_size, test_times);
    printf("[PL  (uio)]] : %8.3f  [Mbyte/s]\n", test_size / write_fpd0_time / (1024*1024));

    return 0;
}

// end of file
