


#pragma once

#include <random>
#include <stdlib.h>
#include <opencv2/opencv.hpp>
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/Axi4Stream.h"

namespace jelly {
namespace simulator {


template<typename TAxi4sVideo>
class Axi4sImageLoadNode : public Node
{
    using rand_type = std::default_random_engine;
    using dist_type = std::bernoulli_distribution;

protected:
    TAxi4sVideo     m_axi4s;
    std::string     m_path;

    int             m_limit_frame = 0;
    bool            m_limit_finish = false;
    
    int             m_frame_num = 0;
    int             m_format = CV_8UC3;
    int             m_width  = 0;
    int             m_height = 0;
    int             m_x = 0;
    int             m_y = 0;

    int             m_x_blank = 0;
    int             m_y_blank = 0;
    int             m_blank_count = 0;

    cv::Mat         m_img;
    bool            m_aclk = false;

    rand_type       m_rand;
    dist_type       m_dist;

    std::string     m_imshow_name;
    cv::Mat         (*m_preproc)(cv::Mat, int frame_num) = nullptr;

    Axi4sImageLoadNode(TAxi4sVideo axi4s, std::string path, int format = fmt_8uc3) : m_dist(0.0)
    {
        m_axi4s  = axi4s;
        m_path   = path;
        m_format = format;
    }

public:
    static std::shared_ptr< Axi4sImageLoadNode > Create(TAxi4sVideo axi4s, std::string path, int format = fmt_8uc3)
    {
        return std::shared_ptr< Axi4sImageLoadNode >(new Axi4sImageLoadNode(axi4s, path, format));
    }

    void SetFrameNum(int frame_num) { m_frame_num = frame_num; }
    int  GetFrameNum(void) const    { return m_frame_num; }

    void SetImageFormat(int format) { m_format = format; }
    int  GetImageFormat(void) const    { return m_format; }

    void SetImageWidth(int width) { m_width  = width; }
    void SetImageHeight(int height) { m_height = height; }
    int GetImageWidth(void) const { return m_width; }
    int GetImageHeight(void) const { return m_height; }

    void SetImageSize(int width, int height) {
        m_width  = width;
        m_height = height;
    }

    void SetImage(cv::Mat img) { m_img  = img; }
    cv::Mat GetImage(cv::Mat img) const { return m_img; }

    // フレーム制限
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

    void SetBlankX(int blank) { m_x_blank = blank; }
    int  GetBlankX(void) const { return m_x_blank; }
    void SetBlankY(int blank) { m_y_blank = blank; }
    int  GetBlankY(void) const { return m_y_blank; }

    void SetImageShow(std::string name) { m_imshow_name = name; }
    void SetImagePreProc(cv::Mat (*proc)(cv::Mat, int frame_num)) { m_preproc = proc; }


protected:
    int GetPixel(void)
    {
        int pixel = 0;

        // 画像読み込み
        if ( m_x == 0 && m_y == 0 && !m_path.empty() ) {
            char fname[512];
            sprintf(fname, m_path.c_str(), m_frame_num);
            cv::Mat img = cv::imread(fname, m_format == fmt_8uc1 ? 0 : 1);
            if ( m_preproc ) {
                img = m_preproc(img, m_frame_num);
            }
            if ( !img.empty() ) {
                std::cout << "image load : " << fname << std::endl;
                m_img = img;
            }
            else {
                std::cout << "load error : " << fname << std::endl;
            }
            m_frame_num++;
        }

        if ( !m_img.empty() ) {
            if ( m_width  <= 0 ) { m_width  = m_img.cols; }
            if ( m_height <= 0 ) { m_height = m_img.rows; }

            if ( m_x < m_img.cols && m_y < m_img.rows ) {
                switch ( m_format ) {
                case fmt_8uc1:
                    pixel = m_img.at<uchar>(m_y, m_x);
                    break;
                
                case fmt_8uc3:
                    pixel = (m_img.at<cv::Vec3b>(m_y, m_x)[0] << 0)
                          | (m_img.at<cv::Vec3b>(m_y, m_x)[1] << 8)
                          | (m_img.at<cv::Vec3b>(m_y, m_x)[2] << 16);
                    break;
                }
            }
        }
        else {
            pixel = m_x + m_y;
        }
        
        m_x++;
        if ( m_x >= m_width ) {
            m_blank_count = m_x_blank;
            m_x = 0;
            m_y++;
            if ( m_y >= m_height ) {
                m_blank_count = m_x_blank + m_y_blank;
                m_x = 0;
                m_y = 0;
            }
        }

        return pixel;
    }

    void FirstProc(Manager* manager) override
    {
        *m_axi4s.tuser  = 0;
        *m_axi4s.tlast  = 0;
        *m_axi4s.tdata  = 0;
        *m_axi4s.tvalid = 0;
    }

    void PreProc(Manager* manager) override
    {
        m_aclk = (*m_axi4s.aclk != 0);
    }

    void PostProc(Manager* manager) override
    {
        // リセット解除で posedge clk の時だけ処理
        if ( *m_axi4s.aresetn == 0 || !(!m_aclk && *m_axi4s.aclk != 0) ) {
            return;
        }

        // tready == 1 の時だけ処理
        if ( *m_axi4s.tready == 0 ) {
            return;
        }

        // フレーム数制限
        if ( m_limit_frame > 0 && m_frame_num >= m_limit_frame ) {
            if ( m_limit_finish ) {
                manager->RequestFinish();
            }
            return;
        }

        // ブランク挿入
        if ( m_blank_count > 0 ) {
            m_blank_count--;
            *m_axi4s.tvalid = 0;
            return;
        }

        // 画像データ
        if ( m_dist(m_rand) ) {
            *m_axi4s.tvalid = 0;    // wait
        }
        else {
            *m_axi4s.tuser = (m_x == 0 && m_y == 0) ? 1 : 0;
            *m_axi4s.tlast = (m_x == m_width-1) ? 1 : 0;
            *m_axi4s.tdata = GetPixel();
            *m_axi4s.tvalid = 1;
        }
    }

    void ThreadProc(Manager* manager) override
    {
        if ( !m_img.empty() && !m_imshow_name.empty() ) {
            cv::imshow(m_imshow_name, m_img);
        }
    }
};


template<typename Tp>
std::shared_ptr< Axi4sImageLoadNode<Tp> > Axi4sImageLoadNode_Create(Tp axi4s, std::string path, bool grayscale=false)
{
    return Axi4sImageLoadNode<Tp>::Create(axi4s, path, grayscale);
}


}
}


// end of file
