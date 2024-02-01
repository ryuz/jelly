

#pragma once

#include <cstdint>
#include <string>
#include <queue>
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/Axi4Lite.h"
#include "jelly/simulator/QueuedBusAccess.h"

namespace jelly {
namespace simulator {


template<typename TAxi4Lite>
class Axi4LiteMasterNode : public QueuedBusAccess
{
protected:
    enum AccType {
        AccWait,
        AccWrite,
        AccRead,
        AccDisplay,
        VerboseOn,
        VerboseOff,
    };
    struct Access {
        AccType         acc_type;
        int             wait_cycle=0;
        std::uint64_t   addr;
        std::uint64_t   data;
        std::uint64_t   strb;
        std::string     message;
    };

    std::queue<Access>          m_acc_que;
    std::queue<std::uint64_t>   m_dat_que;

    TAxi4Lite                   m_axi4lite;
    bool                        m_verbose;
    int                         m_wait_count = 0;
    
    bool                        m_aresetn;
    bool                        m_aclk   ;
    std::uint64_t               m_awaddr ;
    std::uint64_t               m_awprot ;
    bool                        m_awvalid;
    bool                        m_awready;
    std::uint64_t               m_wdata  ;
    std::uint64_t               m_wstrb  ;
    bool                        m_wvalid ;
    bool                        m_wready ;
    std::uint64_t               m_bresp  ;
    bool                        m_bvalid ;
    bool                        m_bready ;
    std::uint64_t               m_araddr ;
    std::uint64_t               m_arprot ;
    bool                        m_arvalid;
    bool                        m_arready;
    std::uint64_t               m_rdata  ;
    std::uint64_t               m_rresp  ;
    bool                        m_rvalid ;
    bool                        m_rready ;

    Axi4LiteMasterNode(TAxi4Lite axi4lite, bool verbose)
    {
        m_axi4lite = axi4lite;
        m_verbose  = verbose;
    }

public:
    static std::shared_ptr< Axi4LiteMasterNode > Create(TAxi4Lite axi4lite, bool verbose=true)
    {
        return std::shared_ptr< Axi4LiteMasterNode >(new Axi4LiteMasterNode(axi4lite, verbose));
    }

    bool IsEmptyQueue(void) override {
        return m_acc_que.empty();
    }

    void SetVerbose(bool verbose) override
    {
        Access acc;
        acc.acc_type = verbose ? VerboseOn : VerboseOff;
        m_acc_que.push(acc);
    }

    void Wait(int cycle) override
    {
        Access acc;
        acc.acc_type   = AccWait;
        acc.wait_cycle = cycle;
        m_acc_que.push(acc);
    }

    void Write(std::uint64_t addr, std::uint64_t data, std::uint64_t strb, int cycle=0) override
    {
        Access acc;
        acc.acc_type   = AccWrite;
        acc.wait_cycle = cycle;
        acc.addr = addr;
        acc.data = data;
        acc.strb = strb;
        m_acc_que.push(acc);
    }

    void Read(std::uint64_t addr, int cycle=0) override
    {
        Access acc;
        acc.acc_type   = AccRead;
        acc.wait_cycle = cycle;
        acc.addr = addr;
        m_acc_que.push(acc);
    }

    bool GetReadData(std::uint64_t& data) override {
        if ( m_dat_que.empty() ) {
            return false;
        }
        data = m_dat_que.front();
        m_dat_que.pop();
        return true;
    };

    void Display(std::string message) override
    {
        Access acc;
        acc.acc_type = AccDisplay;
        acc.message = message;
        acc.wait_cycle = 0;
        m_acc_que.push(acc);
    }

    bool IsBusy(void) {
        return (!m_acc_que.empty() || m_wait_count > 0);
    }

    std::size_t GetReadDataCount(void) {
        return m_dat_que.size();
    }

    void WaitIdle(void) {
        assert(this->m_mng);
        while ( IsBusy() ) {
            this->m_mng->Step();
        }
    }

    void ExecWait(int cycle=0)
    {
        Wait(cycle);
        WaitIdle();
    }

    void ExecWrite(std::uint64_t addr, std::uint64_t data, std::uint64_t strb, int cycle=0)
    {
        Write(addr, data, strb, cycle);
        WaitIdle();
    }

    std::uint64_t ExecRead(std::uint64_t addr)
    {
        std::uint64_t data;
        WaitIdle();
        while ( GetReadData(data) ) { this->m_mng->Step(); }
        Read(addr);
        while ( !GetReadData(data) ) { this->m_mng->Step(); }
        return data;
    }

protected:
    sim_time_t InitialProc(Manager* manager) override
    {
        *m_axi4lite.awaddr  = 0;
        *m_axi4lite.awprot  = 0;
        *m_axi4lite.awvalid = 0;
        *m_axi4lite.wdata   = 0;
        *m_axi4lite.wstrb   = 0;
        *m_axi4lite.wvalid  = 0;
        *m_axi4lite.bready  = 0;
        *m_axi4lite.araddr  = 0;
        *m_axi4lite.arprot  = 0;
        *m_axi4lite.arvalid = 0;
        *m_axi4lite.rready  = 0;
        return 0;
    }

    void PrefetchProc(Manager* manager) override
    {
        m_aresetn = (*m_axi4lite.aresetn != 0);
        m_aclk    = (*m_axi4lite.aclk    != 0);
        m_awaddr  = (std::uint64_t)(*m_axi4lite.awaddr );
        m_awprot  = (std::uint64_t)(*m_axi4lite.awprot );
        m_awvalid = (*m_axi4lite.awvalid != 0);
        m_awready = (*m_axi4lite.awready != 0);
        m_wdata   = (std::uint64_t)(*m_axi4lite.wdata  );
        m_wstrb   = (std::uint64_t)(*m_axi4lite.wstrb  );
        m_wvalid  = (*m_axi4lite.wvalid  != 0);
        m_wready  = (*m_axi4lite.wready  != 0);
        m_bresp   = (std::uint64_t)(*m_axi4lite.bresp  );
        m_bvalid  = (*m_axi4lite.bvalid  != 0);
        m_bready  = (*m_axi4lite.bready  != 0);
        m_araddr  = (std::uint64_t)(*m_axi4lite.araddr );
        m_arprot  = (std::uint64_t)(*m_axi4lite.arprot );
        m_arvalid = (*m_axi4lite.arvalid != 0);
        m_arready = (*m_axi4lite.arready != 0);
        m_rdata   = (std::uint64_t)(*m_axi4lite.rdata  );
        m_rresp   = (std::uint64_t)(*m_axi4lite.rresp  );
        m_rvalid  = (*m_axi4lite.rvalid  != 0);
        m_rready  = (*m_axi4lite.rready  != 0);
    }

    bool is_busy(void)
    {
        return m_awvalid || m_wvalid || m_arvalid || m_bready || m_rready;
    }

    bool CheckProc(Manager* manager) override
    {
        // 未動作でキューが空なら何もしない
        if ( !is_busy() && m_acc_que.empty() ) {
            return false;
        }

        // 監視信号に変化があるか？
        if ( (*m_axi4lite.aclk != 0) == m_aclk ) {
            return false;
        }

        // 変化を取り込み
        m_aclk = (*m_axi4lite.aclk != 0);
        
        return m_aclk;  // posedge aclk
    }
    
    sim_time_t EventProc(Manager* manager) override
    {
        // リセット解除で posedge clk の時だけ処理
        if ( *m_axi4lite.aresetn == 0 ) {
            return 0;
        }

        // コマンド完了なら0
        if ( m_awvalid && m_awready ) {
            *m_axi4lite.awvalid = 0;
        }
        if ( m_wvalid && m_wready ) {
            *m_axi4lite.wvalid = 0;
        }
        if ( m_arvalid && m_arready ) {
            *m_axi4lite.arvalid = 0;
        }

        // アクセス完了なら
        if ( m_bvalid && m_bready ) {
            if ( m_verbose ) {
                std::cout << std::hex << "[AXI4-Lite] write(addr: 0x" << m_awaddr << " data: 0x" << m_wdata << " strb: 0x" << m_wstrb << ")  resp:0x" << m_bresp << std::endl;
            }
            *m_axi4lite.bready = 0;
        }
        if ( m_rvalid && m_rready ) {
            m_dat_que.push(m_rdata);
            if ( m_verbose ) {
                std::cout << std::hex << "[AXI4-Lite] read(adr: 0x" << m_araddr << ") => 0x" << m_rdata << "  resp:0x" << m_rresp << std::endl;
            }
            *m_axi4lite.rready = 0;
        }

        // busy なら現状維持
        if ( is_busy() ) {
            return 0;
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
                std::cout << std::dec << "[AXI4-Lite] wait(" << acc.wait_cycle << ")" << std::endl;
            }
            break;

        case AccWrite:
            *m_axi4lite.awaddr  = acc.addr;
            *m_axi4lite.awprot  = 0;
            *m_axi4lite.awvalid = 1;
            *m_axi4lite.wdata   = acc.data;
            *m_axi4lite.wstrb   = acc.strb;
            *m_axi4lite.wvalid  = 1;
            *m_axi4lite.bready  = 1;
            break;

        case AccRead:
            *m_axi4lite.araddr  = acc.addr;
            *m_axi4lite.arprot  = 0;
            *m_axi4lite.arvalid = 1;
            *m_axi4lite.rready  = 1;
            break;

        case AccDisplay:
            std::cout << "[AXI4-Lite] " << acc.message << std::endl;
            break;
        
        case VerboseOn:
            m_verbose = true;
            break;
        
        case VerboseOff:
            m_verbose = false;
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
std::shared_ptr< Axi4LiteMasterNode<Tp> > Axi4LiteMasterNode_Create(Tp axi4lite, bool verbose=true)
{
    return Axi4LiteMasterNode<Tp>::Create(axi4lite, verbose);
}


}
}


// end of file
