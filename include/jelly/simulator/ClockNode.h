
#pragma once


#include "jelly/simulator/Manager.h"


namespace jelly {
namespace simulator {


// クロック生成ノード
template<typename T>
class ClockNode : public Node
{
protected:
    T*      m_signal_clk;
    double  m_cycle;
    bool    m_first;

    ClockNode(T* signal_clk, double cycle, bool first=true)
    {
        m_signal_clk = signal_clk;
        m_cycle      = cycle;
        m_first      = first;
    }

public:
    static std::shared_ptr<ClockNode> Create(T* signal_clk, double cycle, bool first=true)
    {
        return std::shared_ptr<ClockNode>(new ClockNode(signal_clk, cycle, first));
    }

protected:
    sim_time_t InitialProc(Manager* manager) override
    {
        *m_signal_clk = m_first ? 0 : 1;
        return (sim_time_t)(m_cycle * manager->GetTimeUnit()) / 2;
    }
    
    sim_time_t EventProc(Manager* manager) override
    {
        *m_signal_clk = !*m_signal_clk;
        return (sim_time_t)(m_cycle * manager->GetTimeUnit()) / 2;
    };
};

template<typename Tp>
std::shared_ptr< ClockNode<Tp> > ClockNode_Create(Tp* signal_clk, double cycle, bool first=true)
{
    return ClockNode<Tp>::Create(signal_clk, cycle, first);
}


}
}


// end of file
