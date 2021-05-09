
#pragma once


#include <memory>
#include <cstdint>
#include <vector>
#include <queue>
#include <functional>
#include <limits>
#include <mutex>
#include <atomic>
#include <thread>

#ifdef WITH_OPENCV2
#include <opencv2/opencv.hpp>
#endif


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
    virtual sim_time_t  Initialize(Manager* manager) { return Event(manager); };    // 登録時に一度呼ばれる
    virtual sim_time_t  Event(Manager* manager) { return 0; };  // 自分の登録したイベント時刻に呼ばれる
    virtual void        FirstProc(Manager* manager) {};     // シミュレーション開始時に一度呼ばれる
    virtual void        FinalProc(Manager* manager) {};     // シミュレーション終了時に一度呼ばれる
    virtual void        PreProc(Manager* manager) {};       // 何かのイベント(他人のイベント含む)前に呼ばれる
    virtual void        PostProc(Manager* manager) {};      // 何かのイベント(他人のイベント含む)後に呼ばれる
    virtual void        Eval(Manager* manager) {};          // 評価タイミングで呼ぶ(主に Verilator用)
    virtual void        Dump(Manager* manager) {};          // 波形ダンプタイミングで呼ぶ(主に Verilator用)
    virtual void        ThreadProc(Manager* manager) {};    // 別スレッドの処理
};


class Manager
{
    using mutex_t = std::recursive_mutex;

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
    std::atomic<sim_time_t> m_current_time    = 0;
    sim_time_t              m_time_unit       = 1000000;    // 1ns
    sim_time_t              m_time_resolution = 1000;       // 1ps

    bool                    m_first_done = false;
    bool                    m_final_done = false;
    std::atomic_bool        m_request_finish = false;

    std::vector<node_ptr_t> m_nodes;
    event_que_t             m_que{[](Event const &lhs, Event const &rhs) { return lhs.time > rhs.time; }};

    mutex_t                 m_mtx;
    std::atomic_bool        m_thread_enable = false;
    std::thread*            m_thread = nullptr;
    const int               m_thread_sleep = 10;

#ifdef WITH_OPENCV2
    std::string             m_imshow_name;
    int                     m_cv_key = -1;
    int                     m_cv_quit_key = -1;
#endif

    Manager() {}

public:
    ~Manager() {
        Final();
    }

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
        std::lock_guard<mutex_t>    lock(m_mtx);

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
        std::lock_guard<mutex_t>    lock(m_mtx);

        if ( node ) {
            m_que.push({m_current_time + time, node});
        }
    }

    void First(void)
    {
        if ( !m_first_done ) {
            {
                std::lock_guard<mutex_t>    lock(m_mtx);
                this->Eval();
                for ( auto& node : m_nodes ) { node->FirstProc(this); }
                m_first_done = true;
            }

            this->ThreadStart();
        }
    }

    void Final(void)
    {
        this->ThreadStop();

        if ( !m_final_done ) {
            std::lock_guard<mutex_t>    lock(m_mtx);
            for ( auto& node : m_nodes ) { node->FinalProc(this); }
            m_final_done = true;
        }
    }

    void PreProc(void) { 
        std::lock_guard<mutex_t>    lock(m_mtx);
        for ( auto& node : m_nodes ) { node->PreProc(this); }
    }

    void PostProc(void) { 
        std::lock_guard<mutex_t>    lock(m_mtx);
        for ( auto& node : m_nodes ) { node->PostProc(this); }
    }

    void Eval(void) { 
        std::lock_guard<mutex_t>    lock(m_mtx);
        for ( auto& node : m_nodes ) { node->Eval(this); }
    }

    void Dump(void)
    {
        std::lock_guard<mutex_t>    lock(m_mtx);
        for ( auto& node : m_nodes ) { node->Dump(this); }
    }

    std::string get_time_string(int w=0)
    {
        sim_time_t  n = m_current_time / m_time_resolution;
        
        if ( n == 0 ) { return "0"; }

        std::string tmp;
        int digit = 0;
        while ( n > 0 ) {
            tmp += '0' + n%10;
            n /= 10;
            if ( ++digit % 3 == 0 ) {
                tmp += ',';
            }
        }
        while ( ++digit < w ) {
            tmp += ' ';
        }

        std::string rev;
        rev.resize(tmp.size());
        std::copy(tmp.rbegin(), tmp.rend(), rev.begin());
        return rev;
    }

    void ThreadProc(void)
    {
        while ( m_thread_enable ) {
#ifdef WITH_OPENCV2
            m_cv_key = cv::waitKey(m_thread_sleep);
            if ( m_cv_quit_key >= 0 && m_cv_key == m_cv_quit_key ) {
                this->RequestFinish();
            }

            if ( !m_imshow_name.empty() ) {
                cv::Mat img = cv::Mat::zeros(64, 400, CV_8UC3);
                auto time_str = get_time_string(14);

                cv::putText(img, "time=" + time_str,
                            cv::Point(8, 50), cv::FONT_HERSHEY_SIMPLEX, 1, cv::Scalar(255, 255, 255), 1);
                cv::imshow(m_imshow_name, img);
            }
#else
            std::this_thread::sleep_for(std::chrono::milliseconds(m_thread_sleep));
#endif            
            {
                std::lock_guard<mutex_t>    lock(m_mtx);
                for ( auto& node : m_nodes ) { node->ThreadProc(this); }
            }
        }

#ifdef WITH_OPENCV2
        cv::destroyAllWindows();
#endif
    }
    
    void ThreadStart(void)
    {
        if ( m_thread ) { return; } // 既に起動済み
        if ( !m_thread_enable ) { return; }
        if ( !m_first_done || m_final_done ) { return; }

        // 開始
        m_thread = new std::thread(&Manager::ThreadProc, this);
    }

    void ThreadStop(void)
    {
        m_thread_enable = false;
        if ( m_thread ) {
            m_thread->join();
            delete m_thread;
            m_thread = nullptr;
        }
    }

public:
    void RequestFinish(void)
    {
        m_request_finish = true;
    }

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

        if ( m_request_finish ) {
            std::cout << "step finish" << std::endl;
            this->Finish();
            m_request_finish = false;
        }
    }

    void Run(double time=-1)
    {
        sim_time_t    end_time = std::numeric_limits<sim_time_t>::max();
        if ( time >= 0 ) {
            end_time = m_current_time + (sim_time_t)(time * m_time_unit);
        }

        while ( !m_final_done && m_current_time < end_time ) {
            sim_time_t old_time = m_current_time;
            Step();
            if ( m_current_time <= old_time ) { break; }
        }
    }

    void SetThreadEnable(bool enable)
    {
        if ( enable ) {
            m_thread_enable = true;
            this->ThreadStart();
        }
        else {
            m_thread_enable = false;
            this->ThreadStop();
        }
    }

    void SetControlCvWindow(std::string name, int quit_key=-1) 
    {
#ifdef WITH_OPENCV2
        m_imshow_name = name;
        m_cv_quit_key = quit_key;
#endif
    }

    int GetCvKey(void)
    {
#ifdef WITH_OPENCV2
        return m_cv_key;
#else
        return -1;
#endif
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
};

template<typename Tp>
std::shared_ptr< ResetNode<Tp> > ResetNode_Create(Tp* signal_reset, double time, bool active_high=true)
{
    return ResetNode<Tp>::Create(signal_reset, time, active_high);
}


}
}


// end of file
