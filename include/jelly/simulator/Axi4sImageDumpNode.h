


#pragma once

#include <random>
#include <stdlib.h>
#include <opencv2/opencv.hpp>
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/Axi4Stream.h"


namespace jelly {
namespace simulator {


// 画像保存用ノード
template<typename TAxi4sVideo>
class Axi4sImageDumpNode : public Node
{
    using rand_type = std::default_random_engine;
    using dist_type = std::bernoulli_distribution;

protected:
    TAxi4sVideo     m_axi4s;
    std::string     m_path;
    
    int             m_limit_frame = 0;
    bool            m_limit_finish = false;

    int             m_frame_num = 0;
    int             m_format = fmt_8uc3;
    bool            m_img_enable = false;
    bool            m_img_flush = true;
    int             m_width  = 256;
    int             m_height = 256;
    int             m_x = 0;
    int             m_y = 0;

    cv::Mat         m_img;

    std::string     m_imshow_name;

    bool            m_aresetn;
    bool            m_aclk;
    bool            m_tuser;
    bool            m_tlast;
    int             m_tdata;
    bool            m_tvalid;
    bool            m_tready = true;

    rand_type       m_rand;
    dist_type       m_dist;

    Axi4sImageDumpNode(TAxi4sVideo axi4s, std::string path, int format = fmt_8uc3, int width=256, int height=256) : m_dist(0.0)
    {
        m_axi4s     = axi4s;
        m_path      = path;
        m_format    = format;
        m_width     = width;
        m_height    = height;
    }

public:
    static std::shared_ptr< Axi4sImageDumpNode > Create(TAxi4sVideo axi4s, std::string path, int format = fmt_8uc3, int width=256, int height=256)
    {
        return std::shared_ptr< Axi4sImageDumpNode >(new Axi4sImageDumpNode(axi4s, path, format, width, height));
    }

    void SetFrameNum(int frame_num) { m_frame_num = frame_num; }
    int  GetFrameNum(void) const    { return m_frame_num; }

    void SetImageFormat(int format) { m_format = format; }
    int  GetImageFormat(void) const    { return m_format; }

    void SetImageWidth(int width) { m_width  = width; }
    void SetImageHeight(int height) { m_height = height; }
    int GetImageWidth(void) const { return m_width; }
    int GetImageHeight(void) const { return m_height; }

    void SetImageSize(int width, int height)
    {
        m_width  = width;
        m_height = height;
    }

    void SetImage(cv::Mat img) { m_img  = img; }
    cv::Mat GetImage(cv::Mat img) const { return m_img; }

    void SetImageFlush(bool img_flush) { m_img_flush = img_flush; }
    bool GetImageFlush(void) const { return m_img_flush; }

    // 記録制限
    void SetFrameLimit(int limit_frame, bool finish=false)
    {
        m_limit_frame = limit_frame;
        m_limit_finish = finish;
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

    void SetImageShow(std::string name) { m_imshow_name = name; }

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

        if ( !m_img.empty() && !m_path.empty() ) {
            char fname[512];
            sprintf(fname, m_path.c_str(), m_frame_num);
            cv::imwrite(fname, m_img);
            std::cout << "image dump : " << fname << std::endl;
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
    
    void FirstProc(Manager* manager) override
    {
        if ( m_axi4s.tready ) {
            *m_axi4s.tready = 0;
        }
    }

    void FinalProc(Manager* manager) override
    {
        // 書き残しがあればフラッシュする
        WriteImage();
    }

    void PreProc(Manager* manager) override
    {
        m_aresetn = (*m_axi4s.aresetn != 0);
        m_aclk    = (*m_axi4s.aclk != 0);
        m_tuser   = ((*m_axi4s.tuser & 1) != 0);
        m_tlast   = (*m_axi4s.tlast != 0);
        m_tdata   = (int)*m_axi4s.tdata;
        m_tvalid  = (*m_axi4s.tvalid != 0);
        m_tready  = m_axi4s.tready ? (*m_axi4s.tready != 0) : true;
    }

    void PostProc(Manager* manager) override
    {
        // posedge clk の時だけ処理
        if ( !(!m_aclk && *m_axi4s.aclk != 0) ) {
            return;
        }

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
            return;
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
    }

    void ThreadProc(Manager* manager) override
    {
        if ( !m_imshow_name.empty() && !m_img.empty() ) {
            cv::imshow(m_imshow_name, m_img);
        }
    }
};


template<typename Tp>
std::shared_ptr< Axi4sImageDumpNode<Tp> > Axi4sImageDumpNode_Create(Tp axi4s, std::string path, int format=fmt_8uc3, int width=256, int height=256)
{
    return Axi4sImageDumpNode<Tp>::Create(axi4s, path, format, width, height);
}


}
}


// end of file
