

#pragma once

#include <memory>
#include <string>

#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>

#include <verilated.h>

#include "jelly/simulator/Manager.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
#include "jelly/simulator/VerilatorNode.h"
#include "jelly/simulator/WishboneMasterNode.h"
#include "jelly/simulator/Axi4StreamWriterNode.h"
#include "jelly/simulator/Axi4StreamReaderNode.h"


#if VM_TRACE
#include <verilated_fst_c.h> 
#include <verilated_vcd_c.h> 
#endif


namespace jelly {
namespace simulator {


template <class Vsim_top, typename WT=std::uint8_t, typename RT=std::uint8_t, int WW=8, int RW=8, int WC=1, int RC=1>
class Axi4sVideoPybind11 {
    std::shared_ptr<VerilatedContext>       m_contextp;
    std::shared_ptr<Vsim_top>               m_top;
    std::shared_ptr<QueuedBusAccess>        m_wb;
    std::shared_ptr<Axi4StreamWrite>        m_stream_writer;
    std::shared_ptr<Axi4StreamRead>         m_stream_reader;
    trace_ptr_t                             m_tfp = nullptr;
    manager_ptr_t                           m_mng;

    int                                     m_width = 0;
    int                                     m_height = 0;

    const std::uint64_t                     WM = (1ULL << WW) - 1;
    const std::uint64_t                     RM = (1ULL << RW) - 1;

public:

    Axi4sVideoPybind11(int width, int height, std::string module_name="top", double clk_rate=10.0, double reset_time=100.0 ) {
        m_contextp = std::make_shared<VerilatedContext>();
        m_contextp->debug(0);
        m_contextp->randReset(2);
//      m_contextp->commandArgs(argc, argv);
    
        m_top = std::make_shared<Vsim_top>(m_contextp.get(), module_name.c_str());

        m_tfp = nullptr;
#if VM_TRACE
        m_contextp->traceEverOn(true);
        m_tfp = std::make_shared<trace_t>();
        m_top->trace(m_tfp.get(), 100);
        m_tfp->open((module_name + TRACE_EXT).c_str());
#endif

        m_mng = Manager::Create();
        m_mng->AddNode(VerilatorNode_Create(m_top, m_tfp, m_contextp));
        m_mng->AddNode(ResetNode_Create(&m_top->aresetn,    reset_time, false));
        m_mng->AddNode(ClockNode_Create(&m_top->aclk,       clk_rate));
        m_mng->AddNode(ResetNode_Create(&m_top->s_wb_rst_i, reset_time));
        m_mng->AddNode(ClockNode_Create(&m_top->s_wb_clk_i, clk_rate));

        SetImageSize(width, height);

        Axi4Stream axi4s_src =
                {
                    &m_top->aresetn,            // aresetn
                    &m_top->aclk,               // aclk
                    (int*)nullptr,              // tid
                    &m_top->s_axi4s_tuser,      // tuser
                    &m_top->s_axi4s_tlast,      // tlast
                    &m_top->s_axi4s_tdata,      // tdata
                    (int*)nullptr,              // tstrb
                    (int*)nullptr,              // tkeep
                    (int*)nullptr,              // tdest
                    &m_top->s_axi4s_tvalid,     // tvalid
                    &m_top->s_axi4s_tready      // tready
                };
        
        m_stream_writer = Axi4StreamWriterNode_Create(axi4s_src);
        m_mng->AddNode(m_stream_writer);
        
        Axi4Stream axi4s_dst =
                {
                    &m_top->aresetn,            // aresetn
                    &m_top->aclk,               // aclk
                    (int*)nullptr,              // tid
                    &m_top->m_axi4s_tuser,      // tuser
                    &m_top->m_axi4s_tlast,      // tlast
                    &m_top->m_axi4s_tdata,      // tdata
                    (int*)nullptr,              // tstrb
                    (int*)nullptr,              // tkeep
                    (int*)nullptr,              // tdest
                    &m_top->m_axi4s_tvalid,     // tvalid
                    &m_top->m_axi4s_tready      // tready
                };
        
        m_stream_reader = Axi4StreamReaderNode_Create(axi4s_dst);
        m_mng->AddNode(m_stream_reader);

        WishboneMaster wishbone_signals =
                {
                    &m_top->s_wb_rst_i,
                    &m_top->s_wb_clk_i,
                    &m_top->s_wb_adr_i,
                    &m_top->s_wb_dat_o,
                    &m_top->s_wb_dat_i,
                    &m_top->s_wb_sel_i,
                    &m_top->s_wb_we_i,
                    &m_top->s_wb_stb_i,
                    &m_top->s_wb_ack_o
                };
        m_wb = WishboneMasterNode_Create(wishbone_signals, false);
        m_mng->AddNode(m_wb);
    }

    ~Axi4sVideoPybind11() {
#if VM_TRACE
        m_tfp->close();
#endif

#if VM_COVERAGE
        m_contextp->coveragep()->write("coverage.dat");
#endif
    }

    void SetImageSize(int width, int height) {
        m_width  = width;
        m_height = height;
        m_top->param_img_width  = m_width;
        m_top->param_img_height = m_height;
    }

    void Step(void) {
        m_mng->Step();
    }

    void Run(double time=-1) {
        m_mng->Run(time);
    }

    void ReadReg(std::uint64_t addr) {
        m_wb->Read(addr);
    }

    std::uint64_t GetReadRegData(void) {
        std::uint64_t data;
        while ( !m_wb->GetReadData(data) ) {
            m_mng->Step();
        }
        return data;
    }

    void WriteReg(std::uint64_t addr, std::uint64_t data, std::uint64_t sel=0xff) {
        m_wb->Write(addr, data, sel);
    }

    void WriteIReg(std::uint64_t addr, std::int64_t data, std::uint64_t sel=0xff) {
        m_wb->Write(addr, data, sel);
    }


    void WaitBus(void) {
        while ( !m_wb->IsEmptyQueue() ) {
            m_mng->Step();
        }
    }


    void WriteStream(std::uint64_t data, std::uint8_t tlast, std::uint64_t tuser, std::uint8_t tvalid=1) {
        m_stream_writer->Write(Axi4StreamData(data, tlast, tuser, tvalid));
    }

    std::size_t GetWriteStreamSize() {
        return m_stream_writer->GetSize();
    }


    std::uint64_t ReadStream() {
        Axi4StreamData data;
        m_stream_reader->Read(data);
        return data.tdata;
    }

    std::size_t GetReadStreamSize() {
        return m_stream_reader->GetSize();
    }


    void WriteImage(pybind11::array_t<WT> array)
    {
        pybind11::buffer_info info = array.request();
        auto ptr = (const WT *)info.ptr;
        for ( int y = 0; y < m_height; ++y ) {
            for ( int x = 0; x < m_width; ++x ) {
                std::uint64_t data = 0;
                for ( int c = 0; c < WC; ++c ) {
                    data |= ((*ptr++ & WM) << (WW*c));
                }
                WriteStream(data, x==(m_width-1), x==0&&y==0);
            }
        }
    }

    pybind11::array_t<RT> ReadImage(void)
    {
        // データが揃うまでシミュレーションを進める
        while ( GetReadStreamSize() < m_height * m_width ) {
            Step();
        }

        // 読み出し
        std::vector<pybind11::ssize_t> shape{m_height, m_width, RC};
        pybind11::array_t<RT> array{shape};
        pybind11::buffer_info info = array.request();
        auto ptr = (RT *)info.ptr;
        for ( int i = 0; i < m_height*m_width; ++i ) {
            auto tdata = ReadStream();
            for ( int c = 0; c < RC; ++c ) {
                ptr[i*RC + c] = (RT)((tdata >> (RW*c)) & RM);
            }
        }
        return array;
    }
};


}
}


// 生成マクロ
#define JSIM_DEFINE_AXI4S_VIDEO_PYBIND11(ClassName, ModuleName, Vsim_top, WT, RT, WW, RW, WC, RC)  \
class ClassName : public jelly::simulator::Axi4sVideoPybind11<Vsim_top, WT, RT, WW, RW, WC, RC> { \
public: \
    ClassName(int width, int height) : jelly::simulator::Axi4sVideoPybind11<Vsim_top, WT, RT, WW, RW, WC, RC>(width, height, #ModuleName) {} \
}; \
PYBIND11_MODULE(ModuleName, p) { \
    pybind11::class_<ClassName>(p, #ClassName) \
            .def(pybind11::init<int, int>()) \
            .def("set_image_size",        &ClassName::SetImageSize) \
            .def("run",                   &ClassName::Run) \
            .def("read_reg",              &ClassName::ReadReg) \
            .def("get_read_reg_data",     &ClassName::GetReadRegData) \
            .def("write_reg",             &ClassName::WriteReg) \
            .def("write_ireg",            &ClassName::WriteIReg) \
            .def("wait_bus",              &ClassName::WaitBus) \
            .def("write_stream",          &ClassName::WriteStream) \
            .def("get_write_stream_size", &ClassName::GetWriteStreamSize) \
            .def("read_stream",           &ClassName::ReadStream) \
            .def("get_read_stream_size",  &ClassName::GetReadStreamSize) \
            .def("write_image",           &ClassName::WriteImage) \
            .def("read_image",            &ClassName::ReadImage) \
            ; \
}



// end of file
