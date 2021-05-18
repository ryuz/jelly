
#pragma once


#include "jelly/simulator/Manager.h"


namespace jelly {
namespace simulator {


// リセット生成ノード
template<typename T>
class ResetNode : public Node
{
protected:
    T*      m_signal_reset;
    double  m_time;
    bool    m_active_high;

    ResetNode(T* signal_reset, double time, bool active_high=true)
    {
        m_signal_reset = signal_reset;
        m_time         = time;
        m_active_high  = active_high;

        *m_signal_reset = active_high ? 1 : 0;
    }

public:
    static std::shared_ptr<ResetNode> Create(T* signal_reset, double time, bool active_high=true)
    {
        return std::shared_ptr<ResetNode>(new ResetNode(signal_reset, time, active_high));
    }

protected:
    sim_time_t InitialProc(Manager* manager) override
    {
        return (sim_time_t)(m_time * manager->GetTimeUnit());
    };

    sim_time_t EventProc(Manager* manager) override
    {
        *m_signal_reset = m_active_high ? 0 : 1;
        return 0;
    };
};

template<typename Tp>
std::shared_ptr< ResetNode<Tp> > ResetNode_Create(Tp* signal_reset, double time, bool active_high=true)
{
    return ResetNode<Tp>::Create(signal_reset, time, active_high);
}


}
}


// end of file
