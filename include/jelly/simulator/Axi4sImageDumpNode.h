


#pragma once

#include <stdlib.h>
#include <opencv2/opencv.hpp>
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/Axi4Stream.h"


namespace jelly {
namespace simulator {


template<typename TAxi4sVideo>
class Axi4sImageDumpNode : public Node
{
protected:
    TAxi4sVideo     m_axi4s;
    std::string     m_path;
    int             m_frame_num;
    bool            m_grayscale;
    bool            m_img_enable = false;
    bool            m_img_flush = true;
    cv::Mat         m_img;
    int             m_width  = 512;
    int             m_height = 512;
    int             m_x = 0;
    int             m_y = 0;

    bool            m_aresetn;
    bool            m_aclk;
    bool            m_tuser;
    bool            m_tlast;
    int             m_tdata;
    bool            m_tvalid;
    bool            m_tready = true;

    Axi4sImageDumpNode(TAxi4sVideo axi4s, std::string path, int init_num=0, bool grayscale=false)
    {
        m_axi4s     = axi4s;
        m_path      = path;
        m_frame_num = init_num;
        m_grayscale = grayscale;
    }

public:
    static std::shared_ptr< Axi4sImageDumpNode > Create(TAxi4sVideo axi4s, std::string path, int init_num=0, bool grayscale=false)
    {
        return std::shared_ptr< Axi4sImageDumpNode >(new Axi4sImageDumpNode(axi4s, path, init_num, grayscale));
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

    // 画像書き込み
    void WriteImage(void)
    {
        if ( !m_img_enable ) {
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
            m_img = cv::Mat::zeros(m_height, m_width, m_grayscale ? CV_8UC1 : CV_8UC3);
        }
        m_img_enable = true;

        if ( m_x < m_img.cols && m_y < m_img.rows ) {
            if ( m_grayscale ) {
                m_img.at<uchar>(m_y, m_x) = pixel;
            }
            else {
                m_img.at<cv::Vec3b>(m_y, m_x)[0] = ((pixel >> 0) & 0xff);
                m_img.at<cv::Vec3b>(m_y, m_x)[1] = ((pixel >> 8) & 0xff);
                m_img.at<cv::Vec3b>(m_y, m_x)[2] = ((pixel >> 16) & 0xff);
            }
        }
    }
    
    void FirstProc(Manager* manager) override
    {
        if ( m_axi4s.tready ) {
            *m_axi4s.tready = 1;
        }
    }

    void PreProc(Manager* manager) override
    {
        m_aresetn = (*m_axi4s.aresetn != 0);
        m_aclk    = (*m_axi4s.aclk != 0);
        m_tuser   = ((*m_axi4s.tuser & 1) != 0);
        m_tlast   = (*m_axi4s.tlast != 0);
        m_tdata   = (int)*m_axi4s.tdata;
        m_tvalid  = (*m_axi4s.tvalid != 0);
    }

    void PostProc(Manager* manager) override
    {
        // リセット解除で posedge clk の時だけ処理
        if ( !m_aresetn || !(!m_aclk && *m_axi4s.aclk != 0) ) {
            return;
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
    }
};


template<typename Tp>
std::shared_ptr< Axi4sImageDumpNode<Tp> > Axi4sImageDumpNode_Create(Tp axi4s, std::string path, int init_num=0, bool grayscale=false)
{
    return Axi4sImageDumpNode<Tp>::Create(axi4s, path, init_num, grayscale);
}


}
}


// end of file
