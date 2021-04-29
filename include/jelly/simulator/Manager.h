
#pragma once


#include <memory>
#include <cstdint>
#include <vector>
#include <queue>
#include <functional>
#include <limits>


namespace jelly {
namespace simulator {


class Node;
class Manager;

using   sim_time_t = std::uint64_t;
using   manager_ptr_t = std::shared_ptr<Manager>;
using   node_ptr_t = std::shared_ptr<Node>;


class Node
{
    friend Manager;

protected:
    virtual sim_time_t  Initialize(Manager* manager) { return Event(manager); };
    virtual sim_time_t  Event(Manager* manager) { return 0; };
    virtual void        FirstProc(Manager* manager) {};
    virtual void        FinalProc(Manager* manager) {};
    virtual void        PreProc(Manager* manager) {};
    virtual void        PostProc(Manager* manager) {};
    virtual void        Eval(Manager* manager) {};
    virtual void        Dump(Manager* manager) {};
};


class Manager
{
//    friend Node;

protected:

    struct Event {
        sim_time_t  time;
        node_ptr_t  node;
    };

    using event_que_t = std::priority_queue<
                                Event,
                                std::vector<Event>,
                                std::function<bool(Event const &, Event const &)> >;

protected:
    sim_time_t              m_current_time    = 0;
    sim_time_t              m_time_unit       = 1000000;    // 1ns
    sim_time_t              m_time_resolution = 1000;       // 1ps

    bool                    m_first_done = false;
    bool                    m_final_done = false;

    std::vector<node_ptr_t> m_nodes;
    event_que_t             m_que{[](Event const &lhs, Event const &rhs) { return lhs.time > rhs.time; }};

    Manager() {}

public:
    ~Manager() { Final(); }

    static manager_ptr_t Create(void)
    {
        return std::shared_ptr<Manager>(new Manager);
    }

    void SetTimeUnit(sim_time_t time_unit) { m_time_unit = time_unit; }
    void SetTimeResolution(sim_time_t time_resolution) { m_time_resolution = time_resolution; }
    sim_time_t GetSimTime(void) const { return m_current_time; }
    sim_time_t GetTimeUnit(void) const { return m_time_unit; }
    sim_time_t GetTimeResolution(void) const { return m_time_resolution; }

    double GetCurrentTime(void) const { return (double)m_current_time / (double)m_time_resolution; }

    void AddNode(node_ptr_t node)
    {
        if ( node ) {
            m_nodes.push_back(node);
            auto time = node->Initialize(this);
            if ( time > 0 ) {
                AddEvent(node, time);
            }
        }
    }


protected:
    void AddEvent(node_ptr_t node, sim_time_t time)
    {
        if ( node ) {
            m_que.push({m_current_time + time, node});
        }
    }

    void First(void)
    {
        if ( !m_first_done ) {
            this->Eval();
            for ( auto& node : m_nodes ) { node->FirstProc(this); }
            m_first_done = true;
        }
    }

    void Final(void)
    {
        if ( !m_final_done ) {
            for ( auto& node : m_nodes ) { node->FinalProc(this); }
            m_final_done = true;
        }
    }

    void PreProc(void) { 
        for ( auto& node : m_nodes ) { node->PreProc(this); }
    }

    void PostProc(void) { 
        for ( auto& node : m_nodes ) { node->PostProc(this); }
    }

    void Eval(void) { 
        for ( auto& node : m_nodes ) { node->Eval(this); }
    }

    void Dump(void)
    {
        for ( auto& node : m_nodes ) { node->Dump(this); }
    }

public:
    void Finish(void)
    {
        Final();
    }

    bool IsFinished(void)
    {
        return m_final_done;
    }

    void Step(void)
    {
        if ( m_final_done ) {
            return;
        }

        if ( !m_first_done ) {
            this->First();
        }

        if ( m_que.empty() ) { return; }

        // キュー先頭の時刻まで進める
        m_current_time = m_que.top().time;

        // 前処理
        this->PreProc();

        // 分解能未満は同時刻とみなす(これでいいのかは自信なし)
        auto limit_time = m_current_time + m_time_resolution;
        std::vector<node_ptr_t> events;
        while ( !m_que.empty() && m_que.top().time < limit_time ) {
            events.push_back(m_que.top().node);
            m_que.pop();
        }

        for ( auto& node : events ) {
            auto time = node->Event(this);
            if ( time > 0 ) {
                AddEvent(node, time);
            }
        }

        // 実行
        this->Eval();

        // 後処理
        this->PostProc();

        // ダンプ
        this->Dump();
    }

    void Run(double time=-1)
    {
        sim_time_t    end_time = std::numeric_limits<sim_time_t>::max();
        if ( time >= 0 ) {
            end_time = m_current_time + (sim_time_t)(time * m_time_unit);
        }

        while ( !m_final_done && m_current_time < end_time ) {
            auto old_time = m_current_time;
            Step();
            if ( m_current_time <= old_time ) { break; }
        }
    }
};


template<typename T>
class ClockNode : public Node
{
protected:
    T*      m_signal_clk;
    double  m_cycle;

    ClockNode(T* signal_clk, double cycle, bool first=true)
    {
        m_signal_clk = signal_clk;
        m_cycle      = cycle;

        *m_signal_clk = first ? 0 : 1;
    }

public:
    static std::shared_ptr<ClockNode> Create(T* signal_clk, double cycle, bool first=true)
    {
        return std::shared_ptr<ClockNode>(new ClockNode(signal_clk, cycle, first));
    }

protected:
    sim_time_t Event(Manager* manager) override
    {
        *m_signal_clk = !*m_signal_clk;

        return (sim_time_t)(m_cycle * manager->GetTimeUnit()) / 2;
    };

    template<typename Tp>
    friend std::shared_ptr< ClockNode<Tp> > ClockNode_Create(Tp* signal_clk, double cycle, bool first);
};

template<typename Tp>
std::shared_ptr< ClockNode<Tp> > ClockNode_Create(Tp* signal_clk, double cycle, bool first=true)
{
    return ClockNode<Tp>::Create(signal_clk, cycle, first);
}



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
    sim_time_t Initialize(Manager* manager) override
    {
        return (sim_time_t)(m_time * manager->GetTimeUnit());
    };

    sim_time_t Event(Manager* manager) override
    {
        *m_signal_reset = m_active_high ? 0 : 1;
        return 0;
    };

    template<typename Tp>
    friend std::shared_ptr< ResetNode<Tp> > ResetNode_Create(Tp* signal_reset, double time, bool active_high);
};

template<typename Tp>
std::shared_ptr< ResetNode<Tp> > ResetNode_Create(Tp* signal_reset, double time, bool active_high=true)
{
    return ResetNode<Tp>::Create(signal_reset, time, active_high);
}


}
}


// end of file
