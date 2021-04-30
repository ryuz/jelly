


#pragma once

#include <stdlib.h>
#include <opencv2/opencv.hpp>
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/Axi4Stream.h"

namespace jelly {
namespace simulator {

/*
template<typename Tareset, typename Taclk, typename Ttuser, typename Ttlast, typename Ttdata, typename Ttvalid, typename Ttready>
struct Axi4sVideo {
    Tareset *areset;
    Taclk   *aclk;
    Ttuser  *tuser;
    Ttlast  *tlast;
    Ttdata  *tdata;
    Ttvalid *tvalid;
    Ttready *tready;

    Axi4sVideo(){}
    Axi4sVideo(
            Tareset *areset_,
            Taclk   *aclk_,
            Ttuser  *tuser_,
            Ttlast  *tlast_,
            Ttdata  *tdata_,
            Ttvalid *tvalid_,
            Ttready *tready_) {
        areset = areset_;
        aclk = aclk_;
        tuser = tuser_;
        tlast = tlast_;
        tdata = tdata_;
        tvalid = tvalid_;
        tready = tready_;
    }
};
*/

template<typename TAxi4sVideo>
class Axi4sImageLoadNode : public Node
{
protected:
    TAxi4sVideo     m_axi4s;
    std::string     m_path;
    int             m_frame_num;
    bool            m_grayscale;
    cv::Mat         m_img;
    int             m_width  = 0;
    int             m_height = 0;
    int             m_x = 0;
    int             m_y = 0;

    bool            m_prev_clk = false;


    Axi4sImageLoadNode(TAxi4sVideo axi4s, std::string path, int init_num=0, bool grayscale=false)
    {
        m_axi4s     = axi4s;
        m_path      = path;
        m_frame_num = init_num;
        m_grayscale = grayscale;
    }

public:
    static std::shared_ptr< Axi4sImageLoadNode > Create(TAxi4sVideo axi4s, std::string path, int init_num=0, bool grayscale=false)
    {
        return std::shared_ptr< Axi4sImageLoadNode >(new Axi4sImageLoadNode(axi4s, path, init_num, grayscale));
    }

    void SetGrayscale(bool grayscale)
    {
        m_grayscale = grayscale;
    }

    void SetImageSize(int width, int height)
    {
        m_width  = width;
        m_height = height;
    }

    void SetImage(cv::Mat img)
    {
        m_img  = img;
    }


protected:
    int GetPixel(void)
    {
        int pixel = 0;

        // 画像読み込み
        if ( m_x == 0 && m_y == 0 && !m_path.empty() ) {
            char fname[512];
            sprintf(fname, m_path.c_str(), m_frame_num);
            cv::Mat img = cv::imread(fname, m_grayscale ? 0 : 1);
            if ( !img.empty() ) {
                std::cout << "image load : " << fname << std::endl;
                m_img = img;
            }
            else {
                std::cout << "load error : " << fname << std::endl;
            }
        }

        if ( !m_img.empty() ) {
            if ( m_width  <= 0 ) { m_width  = m_img.cols; }
            if ( m_height <= 0 ) { m_height = m_img.rows; }

            if ( m_x < m_img.cols && m_y < m_img.rows ) {
                if ( m_grayscale ) {
                    pixel = m_img.at<uchar>(m_y, m_x);
                }
                else {
                    pixel = (m_img.at<cv::Vec3b>(m_y, m_x)[0] << 0)
                          | (m_img.at<cv::Vec3b>(m_y, m_x)[1] << 8)
                          | (m_img.at<cv::Vec3b>(m_y, m_x)[2] << 16);
                }
            }
        }
        else {
            pixel = m_x + m_y;
        }
        
        m_x++;
        if ( m_x >= m_width ) {
            m_x = 0;
            m_y++;
            if ( m_y >= m_height ) {
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
        m_prev_clk = (*m_axi4s.aclk != 0);
    }

    void PostProc(Manager* manager) override
    {
        // リセット解除で posedge clk の時だけ処理
        if ( *m_axi4s.aresetn == 0 || !(!m_prev_clk && *m_axi4s.aclk != 0) ) {
            return;
        }

        // tready == 1 の時だけ処理
        if ( *m_axi4s.tready == 0 ) {
            return;
        }

        if ( true ) {
            *m_axi4s.tuser = (m_x == 0 && m_y == 0) ? 1 : 0;
            *m_axi4s.tlast = (m_x == m_width-1) ? 1 : 0;
            *m_axi4s.tdata = GetPixel();
            *m_axi4s.tvalid = 1;
        }
        else {
            *m_axi4s.tvalid = 0;
        }
    }
};


template<typename Tp>
std::shared_ptr< Axi4sImageLoadNode<Tp> > Axi4sImageLoadNode_Create(Tp axi4s, std::string path, int init_num=0, bool grayscale=false)
{
    return Axi4sImageLoadNode<Tp>::Create(axi4s, path, init_num, grayscale);
}


}
}


// end of file
