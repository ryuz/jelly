// ---------------------------------------------------------------------------
//  RPU との通信
//                                  Copyright (C) 2015-2021 by Ryuz
//                                  https://github.com/ryuz/
// ---------------------------------------------------------------------------


#include <iostream>
#include <atomic>
#include <signal.h>
#include "jelly/UioAccessor.h"
#include "jelly/JellyRegs.h"

std::atomic_bool end_flag;

void signal_handler(int sig)
{
    end_flag = true;
}

int main()
{
    // mmap uio
    jelly::UioAccessor com_rx_acc("uio_pl_com0", 0x100);
    if ( !com_rx_acc.IsMapped() ) {
        std::cout << "uio_pl_com0 open error" << std::endl;
        return 1;
    }
//  std::cout << "COM0 ID     : 0x" << std::hex << com_rx_acc.ReadReg(REG_COMMUNICATION_PIPE_CORE_ID) << std::endl;
//  std::cout << "COM0 SERIAL : 0x" << std::hex << com_rx_acc.ReadReg(REG_COMMUNICATION_PIPE_CORE_SERIAL) << std::endl;

    /*
    jelly::UioAccessor com_tx_acc("uio_pl_com1", 0x100);
    if ( !com_rx_acc.IsMapped() || !com_tx_acc.IsMapped() ) {
        std::cout << "uio_pl_com1 open error" << std::endl;
        return 1;
    }
    std::cout << "COM1 ID     : 0x" << std::hex << com_tx_acc.ReadReg(REG_COMMUNICATION_PIPE_CORE_ID) << std::endl;
    std::cout << "COM1 SERIAL : 0x" << std::hex << com_tx_acc.ReadReg(REG_COMMUNICATION_PIPE_CORE_SERIAL) << std::endl;
    */

    end_flag = false;
    if ( signal(SIGINT, signal_handler) == SIG_ERR ) {
        return 1;
    }

    // Ctrl + C されるまでモニタする
    while ( !end_flag ) {
        // RX
        if ( com_rx_acc.ReadReg(REG_COMMUNICATION_PIPE_RX_STATUS) != 0 ) {
            char c = (char)com_rx_acc.ReadReg(REG_COMMUNICATION_PIPE_RX_DATA);
            std::cout << c << std::flush;
        }

        usleep(1000);
    }
}

// end of file
