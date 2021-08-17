
#pragma once


#include <iostream>
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
    bool    m_active = false;    // 処理フラグ

    virtual sim_time_t  InitialProc(Manager* manager) { return 0; }     // シミュレーション開始時に一度呼ばれる
    virtual void        FinalProc(Manager* manager) {}                  // シミュレーション終了時に一度呼ばれる
    virtual sim_time_t  EventProc(Manager* manager) { return 0; }       // イベント処理に呼ばれる
    virtual void        PrefetchProc(Manager* manager) {};              // 値フェッチの為に何かのイベント(他人のイベント含む)前に呼ばれる
    virtual bool        CheckProc(Manager* manager) { return false; }   // 自分に関連する事象変化が起こっていないかのチェックに呼ばれる
    virtual void        EvalProc(Manager* manager) {}                   // 評価を実施(主に Verilator用)
    virtual void        DumpProc(Manager* manager) {}                   // 波形ダンプタイミングで呼ぶ(主に Verilator用)
    virtual void        ThreadProc(Manager* manager) {}                 // 別スレッドの処理
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
        CallFinal();
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

    void CallInitial(void)
    {
        if ( !m_first_done ) {
            {
                std::lock_guard<mutex_t>    lock(m_mtx);
                for ( auto& node : m_nodes ) {
                    auto time = node->InitialProc(this);
                    if ( time > 0 ) {
                        AddEvent(node, time);
                    }
                }
                m_first_done = true;
            }

            this->ThreadStart();
        }
    }

    void CallFinal(void)
    {
        this->ThreadStop();

        if ( !m_final_done ) {
            std::lock_guard<mutex_t>    lock(m_mtx);
            for ( auto& node : m_nodes ) { node->FinalProc(this); }
            m_final_done = true;
        }
    }

    void CallPrefetch(void) { 
        std::lock_guard<mutex_t>    lock(m_mtx);
        for ( auto& node : m_nodes ) { node->PrefetchProc(this); }
    }

    void CallCheck(void) { 
        std::lock_guard<mutex_t>    lock(m_mtx);
        for ( auto& node : m_nodes ) {
            if ( !node->m_active ) {
                node->m_active = node->CheckProc(this);
            }
        }
    }

    bool CallEvent(void) { 
        std::lock_guard<mutex_t>    lock(m_mtx);
        bool busy = false;
        for ( auto& node : m_nodes ) {
            if ( node->m_active ) {
                auto time = node->EventProc(this);
                if ( time > 0 ) {
                    AddEvent(node, time);   // 次のイベントがあれば予約
                }
                node->m_active = false;
                busy = true;
            }
        }
        return busy;
    }

    void CallEval(void)
    {
        std::lock_guard<mutex_t>    lock(m_mtx);
        for ( auto& node : m_nodes ) { node->EvalProc(this); }
    }

    void CallDump(void)
    {
        std::lock_guard<mutex_t>    lock(m_mtx);
        for ( auto& node : m_nodes ) { node->DumpProc(this); }
    }

    std::string GetTimeString(int w=0)
    {
        sim_time_t  n = m_current_time / m_time_resolution;
        
        if ( n == 0 ) { return "0"; }

        std::string tmp;
        int digit = 0;
        while ( n > 0 ) {
            tmp += '0' + n%10;
            n /= 10;
            if ( ++digit % 3 == 0 && n > 0 ) {
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
                auto time_str = GetTimeString(14);

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
        CallFinal();
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
            this->CallInitial();
        }

        if ( m_que.empty() ) { return; }

        // キュー先頭の時刻まで進める
        m_current_time = m_que.top().time;

        // フラグクリア
        for ( auto& node : m_nodes ) {
            node->m_active = false;
        }

        // 前処理
        this->CallPrefetch();

        // 分解能未満は同時刻とみなす(これでいいのかは自信なし)
        auto limit_time = m_current_time + m_time_resolution;
        std::vector<node_ptr_t> events;
        while ( !m_que.empty() && m_que.top().time < limit_time ) {
            m_que.top().node->m_active = true;
            m_que.pop();
        }

        // イベントが無くなるまで実行
        while ( this->CallEvent() ) {
            this->CallEval();
            this->CallCheck();
        }

        // ダンプ
        this->CallDump();

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


}
}


// end of file
