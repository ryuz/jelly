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


#define TEST_SIZE   (128*1024)


void   CacheFlush(void);
void   MemoryTest(jelly::UdmabufAccessor& acc, size_t size);
double WriteTest(jelly::UdmabufAccessor& acc, size_t size, int times);
double ReadTest (jelly::UdmabufAccessor& acc, size_t size, int times);
void   AccessTest(const char *name, jelly::UdmabufAccessor acc);
void   ApiTest(const char *name, jelly::UdmabufAccessor acc);

jelly::UdmabufAccessor OpenUdmabufAccessor(const char *device_name, const char *module_name, off_t offset, int flags) {
    jelly::UdmabufAccessor acc(device_name, module_name, offset, flags);
    if ( !acc.IsMapped() ) {
        printf("open error %s\n", device_name);
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

    MemoryTest(acc, acc.GetSize());

    return acc;
}


int main(int argc, char *argv[])
{
    AccessTest("[DDR4 cached]",     OpenUdmabufAccessor("udmabuf_ddr4", "u-dma-buf", 0, O_RDWR));
    AccessTest("[DDR4 non-cached]", OpenUdmabufAccessor("udmabuf_ddr4", "u-dma-buf", 0, O_RDWR | O_SYNC));
    AccessTest("[OCM  cached]",     OpenUdmabufAccessor("uiomem_ocm",   "uiomem",    0, O_RDWR));
    AccessTest("[OCM  non-cached]", OpenUdmabufAccessor("uiomem_ocm",   "uiomem",    0, O_RDWR | O_SYNC));
    AccessTest("[PL   cached]",     OpenUdmabufAccessor("uiomem_fpd0",  "uiomem",    0, O_RDWR));
    AccessTest("[PL   non-cached]", OpenUdmabufAccessor("uiomem_fpd0",  "uiomem",    0, O_RDWR | O_SYNC));
    printf("\n");
    ApiTest("[DDR4 cached]",     OpenUdmabufAccessor("udmabuf_ddr4", "u-dma-buf", 0, O_RDWR));
    ApiTest("[OCM  cached]",     OpenUdmabufAccessor("uiomem_ocm",   "uiomem",    0, O_RDWR));
    ApiTest("[PL   cached]",     OpenUdmabufAccessor("uiomem_fpd0",  "uiomem",    0, O_RDWR));

    CacheFlush();

    // ファイルアクセスタイム
    /*
    for ( int i = 0; i < 5; ++ i) {
        auto start = std::chrono::system_clock::now();

        int fd  = open("/sys/class/uiomem/uiomem_fpd0/sync_owner", O_RDONLY);
        if ( fd == -1) { fprintf(stderr, "open error\n"); return 0; }
//      char  buf[64];
//      int len = read(fd, buf, sizeof(buf));
//      if ( len < 1 ) { fprintf(stderr, "read error : %s\n", path); close(fd); return 0; }
        close(fd);

        auto end = std::chrono::system_clock::now();
        double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
        printf("open-close : %8.3f [us]\n", elapsed / 1000.0);
    }
    */

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

void ApiTest(const char *name, jelly::UdmabufAccessor acc)
{
    CacheFlush();

    // ファイルアクセス時間
    /*
    {
        acc.GetSyncOwner();
        auto start = std::chrono::system_clock::now();
        acc.GetSyncOwner();
        auto end = std::chrono::system_clock::now();
        double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
        printf("%-18s api-time        : %8.3f [us]\n", name, elapsed / 1000.0);
    }
    */

    acc.SyncForDevice();
    acc.SyncForCpu();
    acc.SyncForDevice();
    acc.SyncForCpu();

    // 読み出し時間
    {
        auto start = std::chrono::system_clock::now();
        for ( size_t i = 0; i < TEST_SIZE/8; i++ ) {
            acc.ReadMem64(i*8);
        }
        auto end = std::chrono::system_clock::now();
        double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
        printf("%-18s read-time       : %8.3f [us]\n", name, elapsed / 1000.0);
    }

    // 書き込み時間
    {
        auto start = std::chrono::system_clock::now();
        for ( size_t i = 0; i < TEST_SIZE/8; i++ ) {
            acc.WriteMem64(i*8, i);
        }
        auto end = std::chrono::system_clock::now();
        double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
        printf("%-18s write-time      : %8.3f [us]\n", name, elapsed / 1000.0);
    }

    // invalidate 用データを詰めておく
    for ( size_t i = 0; i < TEST_SIZE/8; ++i ) {
        acc.ReadMem64(i*8);
    }
    acc.SyncForDevice();

    {
        auto start = std::chrono::system_clock::now();
        acc.SyncForCpu();
        auto end = std::chrono::system_clock::now();
        double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
        printf("%-18s sync_for_cpu    : %8.3f [us]\n", name, elapsed / 1000.0);
    }

    // flush用データを詰めておく
    for ( size_t i = 0; i < TEST_SIZE/8; ++i ) {
        acc.WriteMem64(i*8, i);
    }

    {
        auto start = std::chrono::system_clock::now();
        acc.SyncForDevice();
        auto end = std::chrono::system_clock::now();
        double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
        printf("%-18s sync_for_device : %8.3f [us]\n", name, elapsed / 1000.0);
    }
}


// アクセステスト
void AccessTest(const char *name, jelly::UdmabufAccessor acc) {
    const std::size_t test_size = TEST_SIZE;
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
