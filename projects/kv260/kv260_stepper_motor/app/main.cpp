// ---------------------------------------------------------------------------
//  udmabuf テスト
//                                  Copyright (C) 2015-2020 by Ryuji Fuchikami
//                                  https://github.com/ryuz/
// ---------------------------------------------------------------------------


#include <iostream>
#include <unistd.h>

#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"

#define REG_STMC_CORE_ID        0x00
#define REG_STMC_CTL_ENABLE     0x01
#define REG_STMC_CTL_TARGET     0x02
#define REG_STMC_CTL_PWM        0x03
#define REG_STMC_TARGET_X       0x04
#define REG_STMC_TARGET_V       0x06
#define REG_STMC_TARGET_A       0x07
#define REG_STMC_MAX_V          0x09
#define REG_STMC_MAX_A          0x0a
#define REG_STMC_MAX_A_NEAR     0x0f
#define REG_STMC_CUR_X          0x10
#define REG_STMC_CUR_V          0x12
#define REG_STMC_CUR_A          0x13
#define REG_STMC_TIME           0x20

int main()
{
    // mmap uio
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x00800000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    // UIOの中をさらにコアごとに割り当て
    auto gid_acc  = uio_acc.GetAccessor(0x000000);
    auto stmc_acc = uio_acc.GetAccessor(0x410000);

    std::cout << "gid  : " << std::hex << gid_acc.ReadReg(0)  << std::endl;
    std::cout << "stmc : " << std::hex << stmc_acc.ReadReg(0) << std::endl;

	stmc_acc.WriteReg(REG_STMC_MAX_A,       100);
	stmc_acc.WriteReg(REG_STMC_MAX_V,    200000);
	stmc_acc.WriteReg(REG_STMC_CTL_ENABLE,    1);


    std::cout << "speed 1000" << std::endl;
    stmc_acc.WriteReg(REG_STMC_TARGET_V, 1000);
 	stmc_acc.WriteReg(REG_STMC_CTL_TARGET, 2);
	sleep(3);
    std::cout << "speed -5000" << std::endl;
    stmc_acc.WriteReg(REG_STMC_TARGET_V, -5000);
 	stmc_acc.WriteReg(REG_STMC_CTL_TARGET, 2);
	sleep(3);

	stmc_acc.WriteReg(REG_STMC_CTL_TARGET, 1);
	stmc_acc.WriteReg(REG_STMC_TARGET_X, 10000);
    std::cout << "go to 10000" << std::endl;
	sleep(3);
    std::cout << "go to -10000" << std::endl;
	stmc_acc.WriteReg(REG_STMC_TARGET_X, -10000);
	sleep(3);
    std::cout << "go to 0" << std::endl;
	stmc_acc.WriteReg(REG_STMC_TARGET_X, 0);
	sleep(3);

    std::cout << "stop" << std::endl;
	stmc_acc.WriteReg(REG_STMC_TARGET_A, 0);
 	stmc_acc.WriteReg(REG_STMC_TARGET_V, 0);
	stmc_acc.WriteReg(REG_STMC_CTL_TARGET, 2);
	sleep(1);

	stmc_acc.WriteReg(REG_STMC_CTL_TARGET, 4);
    for ( int i = 0; i < 2; ++i ) {
        std::cout << "accelerate +10" << std::endl;
        stmc_acc.WriteReg(REG_STMC_TARGET_A, +10);
        sleep(4);

        std::cout << "accelerate -10" << std::endl;
        stmc_acc.WriteReg(REG_STMC_TARGET_A, -10);
        sleep(4);
    }
	
    std::cout << "release" << std::endl;
    stmc_acc.WriteReg(REG_STMC_TARGET_A, 0);
	stmc_acc.WriteReg(REG_STMC_TARGET_V, 0);
	stmc_acc.WriteReg(REG_STMC_CTL_ENABLE, 0);

    return 0;
}

// end of file
