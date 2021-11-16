

#pragma once

#include <string>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <thread>

#include "jelly/simulator/Manager.h"
#include "jelly/simulator/Wishbone.h"


namespace jelly {
namespace simulator {


template<typename TWishbone>
class WishboneAccessNode : public Node
{
protected:
    std::mutex              m_mtx;
    std::condition_variable m_cv;

    enum AccType {
        None,
        AccWait,
        AccWrite,
        AccRead,
        AccDisplay,
        VerboseOn,
        VerboseOff,
    };

    struct Access {
        AccType             acc_type=None;
        int                 wait_cycle=0;
        unsigned long long  adr;
        unsigned long long  dat;
        unsigned long long  sel;
        std::string         message;
    };    

    Access                  m_req_acc;
    unsigned long long      m_read_dat;

    TWishbone               m_wishbone;
    bool                    m_verbose;
    int                     m_wait_count = 0;

    bool                    m_rst_i;
    bool                    m_clk_i;
    unsigned long long      m_adr_o;
    unsigned long long      m_dat_i;
    unsigned long long      m_dat_o;
    unsigned long long      m_sel_o;
    bool                    m_we_o;
    bool                    m_stb_o;
    bool                    m_ack_i;

    WishboneAccessNode(TWishbone wishbone, bool verbose)
    {
        m_req_acc.acc_type = None;
        m_wishbone = wishbone;
        m_verbose  = verbose;
    }

public:
    static std::shared_ptr< WishboneAccessNode > Create(TWishbone wishbone, bool verbose=true)
    {
        return std::shared_ptr< WishboneAccessNode >(new WishboneAccessNode(wishbone, verbose));
    }

    void SetVerbose(bool verbose)
    {
        std::unique_lock<std::mutex> lock(m_mtx);
        m_req_acc.acc_type   = verbose ? VerboseOn : VerboseOff;
        m_req_acc.wait_cycle = 0;
        m_cv.wait(lock);
    }

    void Wait(int cycle)
    {
        std::unique_lock<std::mutex> lock(m_mtx);
        m_req_acc.acc_type = AccWait;
        m_req_acc.wait_cycle = cycle;
        m_cv.wait(lock);
    }

    void Write(unsigned long long adr, unsigned long long dat, unsigned long long  sel, int cycle=0)
    {
        std::unique_lock<std::mutex> lock(m_mtx);
        m_req_acc.acc_type = AccWrite;
        m_req_acc.wait_cycle = cycle;
        m_req_acc.adr = adr;
        m_req_acc.dat = dat;
        m_req_acc.sel = sel;
        m_cv.wait(lock);
    }

    unsigned long long Read(unsigned long long adr, int cycle=0)
    {
        std::unique_lock<std::mutex> lock(m_mtx);
        m_req_acc.acc_type = AccRead;
        m_req_acc.wait_cycle = cycle;
        m_req_acc.adr = adr;
        m_cv.wait(lock);
        return m_read_dat;
    }

    void Display(std::string message)
    {
        std::unique_lock<std::mutex> lock(m_mtx);
        m_req_acc.acc_type = AccDisplay;
        m_req_acc.wait_cycle = 0;
        m_req_acc.message = message;
        m_cv.wait(lock);
    }


protected:
    sim_time_t InitialProc(Manager* manager) override
    {
        *m_wishbone.adr_o = 0;
        *m_wishbone.dat_o = 0;
        *m_wishbone.we_o  = 0;
        *m_wishbone.sel_o = 0;
        *m_wishbone.stb_o = 0;
        return 0;
    }

    void PrefetchProc(Manager* manager) override
    {
        m_rst_i = (*m_wishbone.rst_i != 0);
        m_clk_i = (*m_wishbone.clk_i != 0);
        m_adr_o = (unsigned long long)(*m_wishbone.adr_o);
        m_dat_i = (unsigned long long)(*m_wishbone.dat_i);
        m_dat_o = (unsigned long long)(*m_wishbone.dat_o);
        m_sel_o = (unsigned long long)(*m_wishbone.sel_o);
        m_we_o  = (*m_wishbone.we_o != 0);
        m_stb_o = (*m_wishbone.stb_o != 0);
        m_ack_i = (*m_wishbone.ack_i != 0);
    }

    bool CheckProc(Manager* manager) override
    {
        std::unique_lock<std::mutex> lock(m_mtx);

        // 未動作で要求が無ければ何もしない
        if ( !m_stb_o && m_req_acc.acc_type == None ) {
            return false;
        }

        // 監視信号に変化があるか？
        if ( (*m_wishbone.clk_i != 0) == m_clk_i ) {
            return false;
        }

        // 変化を取り込み
        m_clk_i = (*m_wishbone.clk_i != 0);
        
        return m_clk_i;  // posedge aclk
    }
    
    sim_time_t EventProc(Manager* manager) override
    {
        std::unique_lock<std::mutex> lock(m_mtx);

        // リセット解除で posedge clk の時だけ処理
        if ( *m_wishbone.rst_i != 0 ) {
            return 0;
        }

        // busy なら現状維持
        if ( m_stb_o && !m_ack_i ) {
            return 0;
        }

        // アクセス完了なら
        if ( m_ack_i ) {
            if ( m_we_o ) {
                if ( m_verbose ) {
                    std::cout << std::hex << "[WISHBONE] write(adr: 0x" << m_adr_o << " dat: 0x" << m_dat_o << ")"<< std::endl;
                }
                if ( m_req_acc.acc_type == AccWrite ) {
                    m_req_acc.acc_type = None;
                    m_cv.notify_all();
                }
            }
            else {
                if ( m_verbose ) {
                    std::cout << std::hex << "[WISHBONE] read(adr: 0x" << m_adr_o << ") => 0x" << m_dat_i << std::endl;
                }
                if ( m_req_acc.acc_type == AccRead ) {
                    m_read_dat = m_dat_i;
                    m_req_acc.acc_type = None;
                    m_cv.notify_all();
                }
            }
        }
        *m_wishbone.stb_o = 0;

        // 要求が無いなら何もしない
        if ( m_req_acc.acc_type == None ) {
            return 0 ;
        }

        auto& acc = m_req_acc;
        if ( ++m_wait_count < acc.wait_cycle ) {
            return 0;
        }
        m_wait_count = 0;

        switch ( acc.acc_type ) {
        case AccWait:
            if ( m_verbose ) {
                std::cout << std::dec << "[WISHBONE] wait(" << acc.wait_cycle << ")" << std::endl;
            }
            m_req_acc.acc_type = None;
            m_cv.notify_all();
            break;

        case AccWrite:
            *m_wishbone.adr_o = acc.adr;
            *m_wishbone.dat_o = acc.dat;
            *m_wishbone.sel_o = acc.sel;
            *m_wishbone.we_o  = 1;
            *m_wishbone.stb_o = 1;
            break;

        case AccRead:
            *m_wishbone.adr_o = acc.adr;
            *m_wishbone.we_o  = 0;
            *m_wishbone.stb_o = 1;
            break;

        case AccDisplay:
            std::cout << "[WISHBONE] " << acc.message << std::endl;
            m_req_acc.acc_type = None;
            m_cv.notify_all();
            break;
        
        case VerboseOn:
            m_verbose = true;
            m_req_acc.acc_type = None;
            m_cv.notify_all();
            break;
        
        case VerboseOff:
            m_verbose = false;
            m_req_acc.acc_type = None;
            m_cv.notify_all();
            break;
        
        default:
            break;
        }

        return 0;
    }

    void ThreadProc(Manager* manager) override
    {
    }
};


template<typename Tp>
std::shared_ptr< WishboneAccessNode<Tp> > WishboneAccessNode_Create(Tp wishbone, bool verbose=true)
{
    return WishboneAccessNode<Tp>::Create(wishbone, verbose);
}


}
}


// end of file
