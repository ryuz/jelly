


#pragma once

#include <random>
#include <queue>
#include <stdlib.h>
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/Axi4Stream.h"

namespace jelly {
namespace simulator {


template<typename TAxi4Stream>
class Axi4StreamWriterNode : public Axi4StreamWrite
{
    using rand_type = std::default_random_engine;
    using dist_type = std::bernoulli_distribution;

protected:
    std::queue<Axi4StreamData>  m_que;

    TAxi4Stream     m_axi4s;
    bool            m_reset_pol = false;

    bool            m_aclk = false;

    rand_type       m_rand;
    dist_type       m_dist;

    Axi4StreamWriterNode(TAxi4Stream axi4s, bool reset_pol=false) : m_dist(0.0)
    {
        m_axi4s     = axi4s;
        m_reset_pol = reset_pol;
    }

public:
    static std::shared_ptr< Axi4StreamWriterNode > Create(TAxi4Stream axi4s, bool reset_pol=false)
    {
        return std::shared_ptr< Axi4StreamWriterNode >(new Axi4StreamWriterNode(axi4s, reset_pol));
    }

    std::size_t GetSize(void) override {
        return m_que.size();
    }

    void Write(const Axi4StreamData& data) override {
        m_que.push(data);
    }

    void SetRandomWait(double rate)
    {
        dist_type::param_type   param(rate);
        m_dist.param(param);
    }

    void SetRandomSeed(std::uint32_t seed)
    {
        m_rand.seed(seed);
    }

protected:
    sim_time_t InitialProc(Manager* manager) override
    {
        *m_axi4s.tvalid = 0;
        return 0;
    }

    void PrefetchProc(Manager* manager) override
    {
        m_aclk = (*m_axi4s.aclk != 0);
    }

    bool CheckProc(Manager* manager) override
    {
        // 監視信号に変化があるか？
        if ( (*m_axi4s.aclk != 0) == m_aclk ) {
            return false;
        }

        // 変化を取り込み
        m_aclk = (*m_axi4s.aclk != 0);

        return m_aclk;  // posedge aclk
    }
    
    sim_time_t EventProc(Manager* manager) override
    {
        // リセット解除で posedge clk の時だけ処理
        if ( (!m_reset_pol && *m_axi4s.aresetn == 0) || (m_reset_pol && *m_axi4s.aresetn != 0) ) {
            return 0;
        }

        // tready無しか tready == 1 の時だけ処理
        if ( !(*m_axi4s.tvalid == 0 || !m_axi4s.tready || *m_axi4s.tready != 0) ) {
            return 0;
        }

        // データがあるときだけ送信
        if ( m_que.empty() ) {
            *m_axi4s.tvalid = 0;
            return 0;
        }

        // データ送信
        if ( m_dist(m_rand) ) {
            *m_axi4s.tvalid = 0;    // wait
        }
        else {
            m_axi4s.Set(m_que.front());
            m_que.pop();
        }
        return 0;
    }
};


template<typename Tp>
std::shared_ptr< Axi4StreamWriterNode<Tp> > Axi4StreamWriterNode_Create(Tp axi4s, bool reset_pol=false)
{
    return Axi4StreamWriterNode<Tp>::Create(axi4s, reset_pol);
}


}
}


// end of file
