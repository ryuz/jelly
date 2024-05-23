// ---------------------------------------------------------------------------
//  RPU との通信
//                                  Copyright (C) 2015-2021 by Ryuji Fuchikami
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
    jelly::UioAccessor com0_rx_acc("uio_pl_com0", 0x10000);
    if ( !com0_rx_acc.IsMapped() ) {
        std::cout << "uio_pl_com0 open error" << std::endl;
        return 1;
    }
        
    end_flag = false;
    if ( signal(SIGINT, signal_handler) == SIG_ERR ) {
        return 1;
    }

    // Ctrl + C されるまでモニタする
    while ( !end_flag ) {
        // RX
        if ( com0_rx_acc.ReadReg(REG_COMMUNICATION_PIPE_RX_STATUS) != 0 ) {
            char c = (char)com0_rx_acc.ReadReg(REG_COMMUNICATION_PIPE_RX_DATA);
            std::cout << c << std::flush;
        }

        usleep(1000);
    }
}

// end of file
