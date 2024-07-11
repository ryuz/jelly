#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <iostream>
#include <chrono>
#include <arm_neon.h>
#include <omp.h> 
#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"
//#include "jelly/UiomemAccessor.h"


int main(int argc, char *argv[])
{
    omp_set_num_threads(2);
    printf("使用可能な最大スレッド数：%d\n", omp_get_max_threads());

    printf("ReadPhysAddr   : 0x%lx\n", jelly::UdmabufAccessor::ReadPhysAddr  ("uiomem_ocm", "uiomem"));
    printf("ReadSize       : 0x%lx\n", jelly::UdmabufAccessor::ReadSize      ("uiomem_ocm", "uiomem"));
    printf("ReadSyncMode   : %d\n",    jelly::UdmabufAccessor::ReadSyncMode  ("uiomem_ocm", "uiomem"));
    printf("ReadSyncOffset : 0x%lx\n", jelly::UdmabufAccessor::ReadSyncOffset("uiomem_ocm", "uiomem"));
    return 0;
}



#if 0 

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


double read_simd_oneshot(void *addr, size_t size) {   
    cache_flush();

    auto ptr = (int32_t *)addr;
    auto len = size / sizeof(int32x4_t);

    // 時間計測開始
    auto start = std::chrono::system_clock::now();

    // 読み出し
    for ( size_t i = 0; i < len; i++ ) {
        volatile int32x4_t s = vld1q_s32(ptr);
        ptr += 4;
    }

    // 時間計測終了
    auto end = std::chrono::system_clock::now();

    // double型でナノ秒に変換
    double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    return elapsed / (1000*1000*1000);
}

double read_simd(void *addr, size_t size, int times) {
    double sum = 0;
    for ( int i = 0; i < times; i++ ) {
        sum += read_simd_oneshot(addr, size);
    }
    return sum / times;
}


double write_simd_oneshot(void *addr, size_t size) {   
    cache_flush();

    auto ptr = (int32_t *)addr;
    auto len = size / sizeof(int32x4_t);

    // 時間計測開始
    auto start = std::chrono::system_clock::now();

    // 読み出し
    volatile int32x4_t s = {0, 1, 2, 3};
    for ( size_t i = 0; i < len; i++ ) {
        vst1q_s32(ptr, s);
        ptr += 4;
    }

    // 時間計測終了
    auto end = std::chrono::system_clock::now();

    // double型でナノ秒に変換
    double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    return elapsed / (1000*1000*1000);
}

double write_simd(void *addr, size_t size, int times) {
    double sum = 0;
    for ( int i = 0; i < times; i++ ) {
        sum += write_simd_oneshot(addr, size);
    }
    return sum / times;
}

int32x4_t g_s32;
double read_simd_mp_oneshot(void *addr, size_t size) {   
    cache_flush();

    auto ptr = (int32_t *)addr;
    auto len = size / sizeof(int32x4_t);

    // 時間計測開始
    auto start = std::chrono::system_clock::now();

    // 読み出し
    volatile int32x4_t s;
    #pragma omp parallel for
    for ( size_t i = 0; i < len; i++ ) {
        s = vld1q_s32(&ptr[i*4]);
    }
    g_s32 = s;

    // 時間計測終了
    auto end = std::chrono::system_clock::now();

    // double型でナノ秒に変換
    double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    return elapsed / (1000*1000*1000);
}

double read_simd_mp(void *addr, size_t size, int times) {
    double sum = 0;
    for ( int i = 0; i < times; i++ ) {
        sum += read_simd_mp_oneshot(addr, size);
    }
    return sum / times;
}

double write_simd_mp_oneshot(void *addr, size_t size) {   
    cache_flush();

    auto ptr = (int32_t *)addr;
    auto len = size / sizeof(int32x4_t);

    // 時間計測開始
    auto start = std::chrono::system_clock::now();

    // 書き込み
    int32x4_t s = {0, 1, 2, 3};
    #pragma omp parallel for
    for ( size_t i = 0; i < len; i++ ) {
        vst1q_s32(&ptr[i*4], s);
    }

    // 時間計測終了
    auto end = std::chrono::system_clock::now();

    // double型でナノ秒に変換
    double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    return elapsed / (1000*1000*1000);
}

double write_simd_mp(void *addr, size_t size, int times) {
    double sum = 0;
    for ( int i = 0; i < times; i++ ) {
        sum += write_simd_mp_oneshot(addr, size);
    }
    return sum / times;
}

int main(int argc, char *argv[])
{
    omp_set_num_threads(2);
    printf("使用可能な最大スレッド数：%d\n", omp_get_max_threads());

    printf("ReadPhysAddr : 0x%x\n", UdmabufAccessor::ReadPhysAddr("uiomem_ocm", "uiomem"));
    return 0;


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


    // mmap uiomem OCM
    jelly::UiomemAccessor uiomem_ocm("uiomem_ocm", 0x40000);
    if ( !uiomem_ocm.IsMapped() ) {
        std::cout << "uiomem_ocm mmap error" << std::endl;
        return 1;
    }

    // mmap uiomem FPD0
    jelly::UiomemAccessor uiomem_fpd0("uiomem_pl_fpd0", 0x08000000);
    if ( !uiomem_fpd0.IsMapped() ) {
        std::cout << "uiomem_pl_fpd0 mmap error" << std::endl;
        return 1;
    }

    int    test_times = 200;
    size_t test_size  = 32*1024;
    
    uiomem_fpd0.SyncForDevice();

    /*
    {
        printf("<< Read Test >>\n");
        auto read_ddr_time = read_test(&test_array[0], test_size, test_times);
        printf("[DDR4-SDRAM]   : %8.3f  [Mbyte/s]\n", test_size / read_ddr_time / (1024*1024));

//        auto read_ocm_time = read_test(uio_ocm.GetPtr(), test_size, test_times);
//        printf("[OCM (uio)]    : %8.3f  [Mbyte/s]\n", test_size / read_ocm_time / (1024*1024));

//        auto read_fpd0_time = read_test(uio_fpd0.GetPtr(), test_size, test_times);
//        printf("[PL  (uio)]    : %8.3f  [Mbyte/s]\n", test_size / read_fpd0_time / (1024*1024));

        auto read_ocm_mem_time = read_test(uiomem_ocm.GetPtr(), test_size, test_times);
        printf("[OCM (uiomem)] : %8.3f  [Mbyte/s]\n", test_size / read_ocm_mem_time / (1024*1024));

        auto read_fpd0_mem_time = read_test(uiomem_fpd0.GetPtr(), test_size, test_times);
        printf("[PL  (uiomem)] : %8.3f  [Mbyte/s]\n", test_size / read_fpd0_mem_time / (1024*1024));
    }
    */
    
    {
        printf("<< Write Test >>\n");
        auto write_ddr_time = write_test(&test_array[0], test_size, test_times);
        printf("[DDR4-SDRAM] : %8.3f  [Mbyte/s]\n", test_size / write_ddr_time / (1024*1024));

//        auto write_ocm_time = write_test(uio_ocm.GetPtr(), test_size, test_times);
//        printf("[OCM (uio)]] : %8.3f  [Mbyte/s]\n", test_size / write_ocm_time / (1024*1024));

//        auto write_fpd0_time = write_test(uio_fpd0.GetPtr(), test_size, test_times);
//        printf("[PL  (uio)]] : %8.3f  [Mbyte/s]\n", test_size / write_fpd0_time / (1024*1024));

        auto write_ocm_mem_time = write_test(uiomem_ocm.GetPtr(), test_size, test_times);
        printf("[OCM (uiomem)]  : %8.3f  [Mbyte/s]\n", test_size / write_ocm_mem_time / (1024*1024));

        auto write_fpd0_mem_time = write_test(uiomem_fpd0.GetPtr(), test_size, test_times);
        printf("[PL  (uiomem)]  : %8.3f  [Mbyte/s]\n", test_size / write_fpd0_mem_time / (1024*1024));
    }
    
    {
        printf("<< SIMD Read Test >>\n");
        auto read_ddr_time = read_simd(&test_array[0], test_size, test_times);
        printf("[DDR4-SDRAM] : %8.3f  [Mbyte/s]\n", test_size / read_ddr_time / (1024*1024));

//        auto read_ocm_time = read_simd(uio_ocm.GetPtr(), test_size, test_times);
//        printf("[OCM (uio)]  : %8.3f  [Mbyte/s]\n", test_size / read_ocm_time / (1024*1024));

//        auto read_fpd0_time = read_simd(uio_fpd0.GetPtr(), test_size, test_times);
//        printf("[PL  (uio)]  : %8.3f  [Mbyte/s]\n", test_size / read_fpd0_time / (1024*1024));

        auto read_ocm_mem_time = read_simd(uiomem_ocm.GetPtr(), test_size, test_times);
        printf("[OCM (uiomem)]  : %8.3f  [Mbyte/s]\n", test_size / read_ocm_mem_time / (1024*1024));

        auto read_fpd0_mem_time = read_simd(uiomem_fpd0.GetPtr(), test_size, test_times);
        printf("[PL  (uiomem)]  : %8.3f  [Mbyte/s]\n", test_size / read_fpd0_mem_time / (1024*1024));
    }

    {
        printf("<< SIMD Write Test >>\n");
        auto write_ddr_time = write_simd(&test_array[0], test_size, test_times);
        printf("[DDR4-SDRAM] : %8.3f  [Mbyte/s]\n", test_size / write_ddr_time / (1024*1024));

//        auto write_ocm_time = write_simd(uio_ocm.GetPtr(), test_size, test_times);
//        printf("[OCM (uio)]] : %8.3f  [Mbyte/s]\n", test_size / write_ocm_time / (1024*1024));

//        auto write_fpd0_time = write_simd(uio_fpd0.GetPtr(), test_size, test_times);
//        printf("[PL  (uio)]] : %8.3f  [Mbyte/s]\n", test_size / write_fpd0_time / (1024*1024));

        auto write_ocm_mem_time = write_simd(uiomem_ocm.GetPtr(), test_size, test_times);
        printf("[OCM (uiomem)]] : %8.3f  [Mbyte/s]\n", test_size / write_ocm_mem_time / (1024*1024));

        auto write_fpd0_mem_time = write_simd(uiomem_fpd0.GetPtr(), test_size, test_times);
        printf("[PL  (uiomem)]] : %8.3f  [Mbyte/s]\n", test_size / write_fpd0_mem_time / (1024*1024));
    }
    
    /*

    {
        printf("<< OpenMP and SIMD Read Test >>\n");
        auto read_ddr_time = read_simd_mp(&test_array[0], test_size, test_times);
        printf("[DDR4-SDRAM] : %8.3f  [Mbyte/s]\n", test_size / read_ddr_time / (1024*1024));

        auto read_ocm_time = read_simd_mp(uio_ocm.GetPtr(), test_size, test_times);
        printf("[OCM (uio)]  : %8.3f  [Mbyte/s]\n", test_size / read_ocm_time / (1024*1024));

        auto read_fpd0_time = read_simd_mp(uio_fpd0.GetPtr(), test_size, test_times);
        printf("[PL  (uio)]  : %8.3f  [Mbyte/s]\n", test_size / read_fpd0_time / (1024*1024));
    }

    {
        printf("<< OpenMP and SIMD Write Test >>\n");
        auto write_ddr_time = write_simd_mp(&test_array[0], test_size, test_times);
        printf("[DDR4-SDRAM] : %8.3f  [Mbyte/s]\n", test_size / write_ddr_time / (1024*1024));

        auto write_ocm_time = write_simd_mp(uio_ocm.GetPtr(), test_size, test_times);
        printf("[OCM (uio)]] : %8.3f  [Mbyte/s]\n", test_size / write_ocm_time / (1024*1024));

        auto write_fpd0_time = write_simd_mp(uio_fpd0.GetPtr(), test_size, test_times);
        printf("[PL  (uio)]] : %8.3f  [Mbyte/s]\n", test_size / write_fpd0_time / (1024*1024));
    }
    */

    return 0;
}

#endif


// end of file
