

#pragma once

#include <random>
#include <queue>
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/Wishbone.h"


namespace jelly {
namespace simulator {


template<typename TWishbone>
class WishboneMasterNode : public Node
{
protected:
    enum AccType {
        AccWait,
        AccWrite,
        AccRead,
    };    
    struct Access {
        AccType             acc_type;
        int                 wait_cycle;
        unsigned long long  adr;
        unsigned long long  dat;
        unsigned long long  sel;
    };

    std::queue<Access>  m_acc_que;

    TWishbone           m_wishbone;
    bool                m_verbose;
    int                 m_wait_count = 0;

    bool                m_rst_i;
    bool                m_clk_i;
    unsigned long long  m_adr_o;
    unsigned long long  m_dat_i;
    unsigned long long  m_dat_o;
    unsigned long long  m_sel_o;
    bool                m_we_o;
    bool                m_stb_o;
    bool                m_ack_i;

    WishboneMasterNode(TWishbone wishbone, bool verbose)
    {
        m_wishbone = wishbone;
        m_verbose  = verbose;
    }

public:
    static std::shared_ptr< WishboneMasterNode > Create(TWishbone wishbone, bool verbose=true)
    {
        return std::shared_ptr< WishboneMasterNode >(new WishboneMasterNode(wishbone, verbose));
    }

    void Wait(int cycle)
    {
        Access acc;
        acc.acc_type   = AccWait;
        acc.wait_cycle = cycle;
        m_acc_que.push(acc);
    }

    void Write(unsigned long long adr, unsigned long long dat, unsigned long long  sel, int cycle=0)
    {
        Access acc;
        acc.acc_type   = AccWrite;
        acc.wait_cycle = cycle;
        acc.adr = adr;
        acc.dat = dat;
        acc.sel = sel;
        m_acc_que.push(acc);
    }

    void Read(unsigned long long adr, int cycle=0)
    {
        Access acc;
        acc.acc_type   = AccRead;
        acc.wait_cycle = cycle;
        acc.adr = adr;
        m_acc_que.push(acc);
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
//      std::cout << "p";//  << std::endl;

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
        // キューが空なら何もしない
        if ( m_acc_que.empty() ) {
            return false;
        }

        // 監視信号に変化があるか？
        if ( (*m_wishbone.clk_i != 0) == m_clk_i ) {
            return false;
        }

//        std::cout << "c";//  << std::endl;

        // 変化を取り込み
        m_clk_i = (*m_wishbone.clk_i != 0);
        
        return m_clk_i;  // posedge aclk
    }
    
    sim_time_t EventProc(Manager* manager) override
    {
        // リセット解除で posedge clk の時だけ処理
        if ( *m_wishbone.rst_i != 0 ) {
            return 0;
        }

        // busy なら現状維持
        if ( m_stb_o && !m_ack_i ) {
            return 0;
        }

        // アクセス完了なら
        if ( m_ack_i && m_verbose ) {
            if ( m_we_o ) {
                std::cout << "[WISHBONE] write(adr:" << m_adr_o << " dat:" << m_dat_o << ")"<< std::endl;
            }
            else {
                std::cout << "[WISHBONE] read(adr:" << m_adr_o << ") => " << m_dat_i << std::endl;
            }
        }

        // キューが空なら何もしない
        if ( m_acc_que.empty() ) {
            return 0 ;
        }

        auto& acc = m_acc_que.front();
        if ( ++m_wait_count < acc.wait_cycle ) {
            return 0;
        }
        m_wait_count = 0;

        switch ( acc.acc_type ) {
        case AccWait:
            if ( m_verbose ) {
                std::cout << "[WISHBONE] wait(" << acc.wait_cycle << ")" << std::endl;
            }
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
        }
        m_acc_que.pop();

        return 0;
    }

    void ThreadProc(Manager* manager) override
    {
    }
};


template<typename Tp>
std::shared_ptr< WishboneMasterNode<Tp> > WishboneMasterNode_Create(Tp wishbone, bool verbose=true)
{
    return WishboneMasterNode<Tp>::Create(wishbone, verbose);
}


}
}


// end of file
