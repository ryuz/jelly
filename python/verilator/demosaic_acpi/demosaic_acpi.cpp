
#include <memory>

#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>

#include <verilated.h>
#include "Vsim_top.h"

#include "jelly/simulator/Manager.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
#include "jelly/simulator/VerilatorNode.h"
#include "jelly/simulator/WishboneMasterNode.h"
#include "jelly/simulator/Axi4StreamWriterNode.h"
#include "jelly/simulator/Axi4StreamReaderNode.h"


const int           DATA_WIDTH = 10;
const std::uint64_t DATA_MASK  = (1 << DATA_WIDTH) - 1;

namespace jsim = jelly::simulator;


#if VM_TRACE
#include <verilated_fst_c.h> 
#include <verilated_vcd_c.h> 
#endif

struct reg_acc_t {
    std::uint64_t   addr;
    std::uint64_t   data;
};

class DemosaicAcpi {
    std::shared_ptr<VerilatedContext>       m_contextp;
    std::shared_ptr<Vsim_top>               m_top;
    std::shared_ptr<jsim::QueuedBusAccess>  m_wb;
    std::shared_ptr<jsim::Axi4StreamWrite>  m_stream_writer;
    std::shared_ptr<jsim::Axi4StreamRead>   m_stream_reader;
    jsim::trace_ptr_t                       m_tfp = nullptr;
    jsim::manager_ptr_t                     m_mng;

    int                                     m_width = 0;
    int                                     m_height = 0;

public:

    DemosaicAcpi(int width, int height) {
        m_contextp = std::make_shared<VerilatedContext>();
        m_contextp->debug(0);
        m_contextp->randReset(2);
//      m_contextp->commandArgs(argc, argv);
    
        m_top = std::make_shared<Vsim_top>(m_contextp.get(), "top");

        m_tfp = nullptr;
#if VM_TRACE
        m_contextp->traceEverOn(true);
        m_tfp = std::make_shared<jsim::trace_t>();
        m_top->trace(m_tfp.get(), 100);
        m_tfp->open("sim_demosaic_acpi" TRACE_EXT);
#endif

        m_mng = jsim::Manager::Create();
        m_mng->AddNode(jsim::VerilatorNode_Create(m_top, m_tfp));
        m_mng->AddNode(jsim::ResetNode_Create(&m_top->aresetn,    100, false));
        m_mng->AddNode(jsim::ClockNode_Create(&m_top->aclk,       1000.0/100.0));
        m_mng->AddNode(jsim::ResetNode_Create(&m_top->s_wb_rst_i, 100));
        m_mng->AddNode(jsim::ClockNode_Create(&m_top->s_wb_clk_i, 1000.0/100.0));

        SetImageSize(width, height);

        jsim::Axi4Stream axi4s_src =
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
        
        m_stream_writer = jsim::Axi4StreamWriterNode_Create(axi4s_src);
        m_mng->AddNode(m_stream_writer);
        
        jsim::Axi4Stream axi4s_dst =
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
        
        m_stream_reader = jsim::Axi4StreamReaderNode_Create(axi4s_dst);
        m_mng->AddNode(m_stream_reader);

        jsim::WishboneMaster wishbone_signals =
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
        m_wb = jsim::WishboneMasterNode_Create(wishbone_signals, false);
        m_mng->AddNode(m_wb);
    }

    ~DemosaicAcpi() {
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

    void Run(double time=-1) {
        m_mng->Run(time);
    }


    void WriteReg(std::uint64_t addr, std::uint64_t data, std::uint64_t sel=0xff) {
        m_wb->Write(addr, data, sel);
    }

    void WaitBus(void) {
        while ( !m_wb->IsEmptyQueue() ) {
            m_mng->Run(10);
        }
        m_mng->Run(20);
    }


    void WriteStream(std::uint64_t data, std::uint8_t tlast, std::uint64_t tuser, std::uint8_t tvalid=1) {
        m_stream_writer->Write(jsim::Axi4StreamData(data, tlast, tuser, tvalid));
    }

    std::size_t GetWriteQueSize() {
        return m_stream_writer->GetSize();
    }


    std::uint64_t ReadStream() {
        jsim::Axi4StreamData data;
        m_stream_reader->Read(data);
        return data.tdata;
    }

    std::size_t GetReadQueSize() {
        return m_stream_reader->GetSize();
    }


    void WriteImage(pybind11::array_t<std::uint16_t> array)
    {
        pybind11::buffer_info info = array.request();
        auto ptr = (const std::uint16_t *)info.ptr;
        for ( int y = 0; y < m_height; ++y ) {
            for ( int x = 0; x < m_width; ++x ) {
                WriteStream(*ptr++, x==(m_width-1), x==0&&y==0);
            }
        }
    }

    pybind11::array_t<std::uint16_t> ReadImage(void)
    {
        // データが揃うまでシミュレーションを進める
        while ( GetReadQueSize() < m_height * m_width ) {
            Run(100);
        }

        // 読み出し
        std::vector<pybind11::ssize_t> shape{m_height, m_width, 3};
        pybind11::array_t<std::uint16_t> array{shape};
        pybind11::buffer_info info = array.request();
        auto ptr = (std::uint16_t *)info.ptr;
        for ( int i = 0; i < m_height*m_width; ++i ) {
            auto tdata = ReadStream();
            // OpenCV に合わせて BGR 順にする
            ptr[i*3 + 2] = (std::uint16_t)(tdata >> ((DATA_WIDTH*0)) & DATA_MASK);
            ptr[i*3 + 1] = (std::uint16_t)(tdata >> ((DATA_WIDTH*1)) & DATA_MASK);
            ptr[i*3 + 0] = (std::uint16_t)(tdata >> ((DATA_WIDTH*2)) & DATA_MASK);
        }
        return array;
    }
};



//namespace py = pybind11;

PYBIND11_MODULE(demosaic_acpi, p)
{
    pybind11::class_<DemosaicAcpi>(p, "DemosaicAcpi")
            .def(pybind11::init<int, int>())
            .def("set_image_size", &DemosaicAcpi::SetImageSize)
            .def("run",            &DemosaicAcpi::Run)
            .def("write_reg",      &DemosaicAcpi::WriteReg)
            .def("wait_bus",       &DemosaicAcpi::WaitBus)
            .def("write_stream",   &DemosaicAcpi::WriteStream)
            .def("write_que_size", &DemosaicAcpi::GetWriteQueSize)
            .def("read_stream",    &DemosaicAcpi::ReadStream)
            .def("read_que_size",  &DemosaicAcpi::GetReadQueSize)
            .def("write_image",    &DemosaicAcpi::WriteImage)
            .def("read_image",     &DemosaicAcpi::ReadImage)
            ;
}


/*
int main() {
    int w = 640;
    int h = 132;

    // レジスタ設定
    auto sim = new DemosaicAcpi(w, h);
    sim->Run(1000);
    sim->WriteReg(REG_IMG_DEMOSAIC_PARAM_PHASE, 3);
    sim->WriteReg(REG_IMG_DEMOSAIC_CTL_CONTROL, 3);
    sim->WaitBus();

    // 入力画像設定
    for ( int f = 0; f < 3; ++f ) {
        for ( int y = 0; y < h; ++y ) {
            for ( int x = 0; x < w; ++x ) {
                sim->WriteStream(x, x==(w-1), x==0&&y==0);
            }
        }
        for ( int i = 0; i < 1000; ++i ) {
            sim->WriteStream(0, 0, 0, 0);
        }
    }

    // シミュレーション進行
    sim->Run(2000000);

    // 結果サイズ確認
    std::cout << sim->GetReadQueSize() << std::endl;

    return 0;
}
*/


// end of file
