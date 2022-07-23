


#pragma once

#include <random>
#include <queue>
#include <opencv2/opencv.hpp>
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/Axi4Stream.h"


namespace jelly {
namespace simulator {


// 画像保存用ノード
template<typename TAxi4Stream>
class Axi4StreamReaderNode : public Axi4StreamRead
{
    using rand_type = std::default_random_engine;
    using dist_type = std::bernoulli_distribution;

protected:
    std::queue<Axi4StreamData>  m_que;

    TAxi4Stream             m_axi4s;
    bool                    m_reset_pol = false;

    bool                    m_aresetn;
    bool                    m_aclk;
    bool                    m_tuser;
    bool                    m_tlast;
    int                     m_tdata;
    bool                    m_tvalid;
    bool                    m_tready = true;

    rand_type               m_rand;
    dist_type               m_dist;

    Axi4StreamReaderNode(TAxi4sVideo axi4s, bool reset_pol = false) : m_dist(0.0)
    {
        m_axi4s     = axi4s;
        m_reset_pol = reset_pol;
    }

public:
    static std::shared_ptr< Axi4StreamReaderNode > Create(TAxi4sVideo axi4s, bool reset_pol = false)
    {
        return std::shared_ptr< Axi4StreamReaderNode >(new Axi4StreamReaderNode(axi4s, reset_pol));
    }

    std::size_t GetSize(void) override {
        return m_que.size();
    }

    bool Read(Axi4StreamData& data) override {
        if ( m_que.empty() ) {
            return false;
        }
        data = m_que.front();
        m_que.pop();
        return true;
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

    // 画像書き込み
    void WriteImage(void)
    {
        if ( !m_img_enable ) {
            return;
        }

        // 上限指定があればそれ以上記録しない
        if ( m_limit_frame > 0 && m_frame_num >= m_limit_frame ) {
            return;
        }

        if ( !m_img.empty() ) {
            m_img_strage.push_back(m_img.clone());
            if ( !m_path.empty() ) {
                char fname[512];
                sprintf(fname, m_path.c_str(), m_frame_num);
                cv::imwrite(fname, m_img);
                std::cout << "image dump : " << fname << std::endl;
            }
        }

        m_frame_num++;
        m_img_enable = false;
        if ( m_img_flush ) {
            m_img = cv::Mat();
        }
    }

    void PutPixel(int pixel)
    {
        // 画像書き込み
        if ( m_x == 0 && m_y == 0 ) {
            WriteImage();
        }

        if ( m_img.empty() ) {
            m_img = cv::Mat::zeros(m_height, m_width, m_format);
        }
        m_img_enable = true;

        if ( m_x < m_img.cols && m_y < m_img.rows ) {
            switch ( m_format ) {
            case fmt_8uc1:
                m_img.at<uchar>(m_y, m_x) = pixel;
                break;
            
            case fmt_8uc3:
                m_img.at<cv::Vec3b>(m_y, m_x)[0] = ((pixel >> 0) & 0xff);
                m_img.at<cv::Vec3b>(m_y, m_x)[1] = ((pixel >> 8) & 0xff);
                m_img.at<cv::Vec3b>(m_y, m_x)[2] = ((pixel >> 16) & 0xff);
                break;
            }
        }
    }
    
    sim_time_t InitialProc(Manager* manager) override
    {
        if ( m_axi4s.tready ) {
            *m_axi4s.tready = 0;
        }
        return 0;
    }

    void FinalProc(Manager* manager) override
    {
        // 書き残しがあればフラッシュする
        WriteImage();
    }

    void PrefetchProc(Manager* manager) override
    {
        m_aresetn = m_reset_pol ? (*m_axi4s.aresetn == 0) : (*m_axi4s.aresetn != 0);
        m_aclk    = (*m_axi4s.aclk != 0);
        m_tuser   = ((*m_axi4s.tuser & 1) != 0);
        m_tlast   = (*m_axi4s.tlast != 0);
        m_tdata   = (int)*m_axi4s.tdata;
        m_tvalid  = (*m_axi4s.tvalid != 0);
        m_tready  = m_axi4s.tready ? (*m_axi4s.tready != 0) : true;
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
        // リセット解除の時だけ処理
        if ( !m_aresetn ) {
            if ( m_axi4s.tready ) {
                *m_axi4s.tready = 0;
            }
        }

        // ready があれば設定
        if ( m_axi4s.tready ) {
            *m_axi4s.tready = m_dist(m_rand) ? 0 : 1;
        }

        if ( !(m_tvalid && m_tready) ) {
            return 0;
        }

        if ( m_tuser ) {
            m_x = 0;
            m_y = 0;
        }
        
        PutPixel(m_tdata);

        m_x++;
        if ( m_tlast ) {
            m_x = 0;
            m_y++;
        }

        // 指定枚数で終了させる場合
        if ( m_limit_finish && m_limit_frame > 0 && m_frame_num >= m_limit_frame ) {
            manager->RequestFinish();
        }

        return 0;
    }

};


template<typename Tp>
std::shared_ptr< Axi4StreamReaderNode<Tp> > Axi4StreamReaderNode_Create(Tp axi4s, bool reset_pol = false)
{
    return Axi4StreamReaderNode<Tp>::Create(axi4s, reset_pol);
}


}
}


// end of file
