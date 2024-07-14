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

void   CacheFlush(void);
void   MemoryTest(jelly::UdmabufAccessor& acc, size_t size);
double WriteTest(jelly::UdmabufAccessor& acc, size_t size, int times);
double ReadTest (jelly::UdmabufAccessor& acc, size_t size, int times);
void   AccessTest(const char *name, jelly::UdmabufAccessor acc);

jelly::UdmabufAccessor OpenUdmabufAccessor(const char *name, off_t offset, int flags) {
    jelly::UdmabufAccessor acc(name, offset, flags);
    if ( !acc.IsMapped() ) {
        printf("open error %s\n",  name);
        exit(1);
    }
    /*
    printf("[%s]\n", name);
    printf("PhysAddr   : 0x%lx\n", acc.GetPhysAddr  ());
    printf("Size       : 0x%lx\n", acc.GetSize      ());
    printf("SyncMode   : %d\n",    acc.GetSyncMode  ());
    printf("SyncOffset : 0x%lx\n", acc.GetSyncOffset());
    printf("\n");
    */

//  MemoryTest(acc, acc.GetSize());

    return acc;
}


int main(int argc, char *argv[])
{
    AccessTest("[DDR4 cached]",     OpenUdmabufAccessor("udmabuf_ddr4", 0, O_RDWR));
    AccessTest("[OCM  cached]",     OpenUdmabufAccessor("uiomem0", 0, O_RDWR));
    AccessTest("[PL   cached]",     OpenUdmabufAccessor("uiomem1", 0, O_RDWR));
    AccessTest("[DDR4 non-cached]", OpenUdmabufAccessor("udmabuf_ddr4", 0, O_RDWR | O_SYNC));
    return 0;

    auto acc_ddr4 = OpenUdmabufAccessor("udmabuf_ddr4", 0, flag);
    auto acc_ocm  = OpenUdmabufAccessor("uiomem0",   0, flag);
    auto acc_fpd0 = OpenUdmabufAccessor("uiomem1",  0, flag);
    return 0;

    if ( cache ) {
        printf("[Cache Enable]\n");
    }
    else {
        printf("[Cache Disable]\n");
    }

    const std::size_t test_size = 0x40000;
    {
        auto time = WriteTest(acc_ddr4, test_size, 256);
        printf("[write DDR4] : %8.3f  [Mbyte/s]\n", test_size / time / (1024*1024));
    }
    {
        auto time = ReadTest(acc_ddr4, test_size, 256);
        printf("[read  DDR4] : %8.3f  [Mbyte/s]\n", test_size / time / (1024*1024));
    }
    {
        auto time  = WriteTest(acc_ocm, test_size, 256);
        printf("[write OCM]  : %8.3f  [Mbyte/s]\n", test_size / time / (1024*1024));
    }
    /*
    {
        auto time  = ReadTest(acc_ocm, test_size, 256);
        printf("[read  OCM]  : %8.3f  [Mbyte/s]\n", test_size / time / (1024*1024));
    }
    {
        auto time  = WriteTest(acc_fpd0, test_size, 256);
        printf("[write FPD0] : %8.3f  [Mbyte/s]\n", test_size / time / (1024*1024));
    }
    {
        auto time  = ReadTest(acc_fpd0, test_size, 256);
        printf("[read  FPD0] : %8.3f  [Mbyte/s]\n", test_size / time / (1024*1024));
    }
    */
    
    CacheFlush();

    return 0;
}


// L2より大きなサイズをアクセスして確実にキャッシュを飛ばしておく
#define DUMMY_ARRAY_SIZE    (2 * 1024 * 1024 / 8)
static volatile int64_t dummy_array [DUMMY_ARRAY_SIZE];
void CacheFlush(void) {
    for ( size_t i = 0; i < DUMMY_ARRAY_SIZE; i++ ) {
        dummy_array[i] = i;
    }
    for ( size_t i = 0; i < DUMMY_ARRAY_SIZE; i++ ) {
        if ( dummy_array[i] != (int64_t)i ) {
            printf("memory error\n");
            exit(1);
        }
    }
}

// メモリテスト
void MemoryTest(jelly::UdmabufAccessor& acc, size_t size)
{
    CacheFlush();
    acc.SyncForCpu();
    for ( size_t i = 0; i < size/8; i++ ) {
        acc.WriteMem64(i*8, i);
    }
   acc.SyncForDevice();
    CacheFlush();
    acc.SyncForCpu();
    for ( size_t i = 0; i < size/8; i++ ) {
        if ( acc.ReadMem64(i*8) != i ) {
            printf("memory error\n");
            exit(1);
        }
    }
}

// アクセステスト
void AccessTest(const char *name, jelly::UdmabufAccessor acc) {
    const std::size_t test_size = 0x40000;
    {
        auto time = WriteTest(acc, test_size, 256);
        printf("%-18s write : %8.3f  [Mbyte/s]\n", name, test_size / time / (1024*1024));
    }
    {
        auto time = ReadTest(acc, test_size, 256);
        printf("%-18s read  : %8.3f  [Mbyte/s]\n", name, test_size / time / (1024*1024));
    }
}

// 読み出しテスト
double ReadTestOneshot(jelly::UdmabufAccessor& acc, size_t size)
{
    CacheFlush();

    // 時間計測開始
    auto start = std::chrono::system_clock::now();
    acc.SyncForCpu();

    // 読み出し
    for ( size_t i = 0; i < size/8; i++ ) {
        acc.ReadMem64(i*8);
    }

    // 時間計測終了
    auto end = std::chrono::system_clock::now();

    acc.SyncForDevice();

    // double型でナノ秒に変換
    double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    return elapsed / (1000*1000*1000);
}

double ReadTest(jelly::UdmabufAccessor& acc, size_t size, int times)
{
    double sum = 0;
    for ( int i = 0; i < times; i++ ) {
        sum += ReadTestOneshot(acc, size);
    }
    return sum / times;
}

// 書き込みテスト
double WriteTestOneshot(jelly::UdmabufAccessor& acc, size_t size)
{   
    CacheFlush();

    acc.SyncForCpu();

    // 時間計測開始
    auto start = std::chrono::system_clock::now();

    // 読み出し
    for ( size_t i = 0; i < size/8; i++ ) {
        acc.WriteMem64(i*8, i);
    }

    acc.SyncForDevice();

    // 時間計測終了
    auto end = std::chrono::system_clock::now();

    // double型でナノ秒に変換
    double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    return elapsed / (1000*1000*1000);
}

double WriteTest(jelly::UdmabufAccessor& acc, size_t size, int times) {
    double sum = 0;
    for ( int i = 0; i < times; i++ ) {
        sum += WriteTestOneshot(acc, size);
    }
    return sum / times;
}

// end of file
