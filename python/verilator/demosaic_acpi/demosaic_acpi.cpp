//#include <pybind11/pybind11.h>

#include <memory>
#include <verilated.h>
//#include <opencv2/opencv.hpp>
#include "Vsim_top.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
#include "jelly/simulator/VerilatorNode.h"
#include "jelly/simulator/WishboneMasterNode.h"
#include "jelly/simulator/Axi4StreamWriterNode.h"
//#include "jelly/simulator/Axi4sImageLoadNode.h"
//#include "jelly/simulator/Axi4sImageDumpNode.h"
#include "jelly/JellyRegs.h"



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
    jsim::trace_ptr_t                       m_tfp = nullptr;
    jsim::manager_ptr_t                     m_mng;

public:

    DemosaicAcpi() {
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

        m_top->param_img_width  = 640;
        m_top->param_img_height = 132;

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
        
        /*        
        jsim::Axi4sVideo axi4s_src =
                {
                    &m_top->aresetn,
                    &m_top->aclk,
                    &m_top->s_axi4s_tuser,
                    &m_top->s_axi4s_tlast,
                    &m_top->s_axi4s_tdata,
                    &m_top->s_axi4s_tvalid,
                    &m_top->s_axi4s_tready
                };

        jsim::Axi4sVideo axi4s_dst =
                {
                    &top->aresetn,
                    &top->aclk,
                    &top->m_axi4s_tuser,
                    &top->m_axi4s_tlast,
                    &top->m_axi4s_tdata,
                    &top->m_axi4s_tvalid,
                    &top->m_axi4s_tready
                };

        std::string s;
        auto image_src_load   = jsim::Axi4sImageLoadNode_Create(axi4s_src, "../BOAT.bmp", jsim::fmt_gray);
        auto image_dst_dump   = jsim::Axi4sImageDumpNode_Create(axi4s_dst, "img_%04d.png", jsim::fmt_gray, 256, 256);
        */

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
        m_wb = jsim::WishboneMasterNode_Create(wishbone_signals);
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
};



/*
namespace py = pybind11;

PYBIND11_MODULE(demosaic_acpi, p)
{
    py::class_<DemosaicAcpi>(p, "DemosaicAcpi")
            .def(py::init<>())
            .def("run",      &DemosaicAcpi::Run)
            .def("wite_reg", &DemosaicAcpi::WriteReg)
            .def("wait_bus", &DemosaicAcpi::WaitBus)
            ;
}
*/


int main() {
    auto sim = new DemosaicAcpi();
    sim->Run(1000);
    sim->WriteReg(REG_IMG_DEMOSAIC_PARAM_PHASE, 3);
    sim->WriteReg(REG_IMG_DEMOSAIC_CTL_CONTROL, 3);
    sim->WaitBus();


    int w = 640;
    int h = 132;
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

    sim->Run(4000000);
}



#if 0
int main(int argc, char** argv)
{
    auto contextp = std::make_shared<VerilatedContext>();
    contextp->debug(0);
    contextp->randReset(2);
    contextp->commandArgs(argc, argv);
    
    const auto top = std::make_shared<Vtop>(contextp.get(), "top");


    jsim::trace_ptr_t tfp = nullptr;
#if VM_TRACE
    contextp->traceEverOn(true);

    tfp = std::make_shared<jsim::trace_t>();
    top->trace(tfp.get(), 100);
    tfp->open("tb_verilator" TRACE_EXT);
#endif

    auto mng = jsim::Manager::Create();

    mng->AddNode(jsim::VerilatorNode_Create(top, tfp));

    mng->AddNode(jsim::ResetNode_Create(&top->reset, 100));
    mng->AddNode(jsim::ClockNode_Create(&top->clk,   1000.0/100.0));
    
    mng->Run(2000000);
//    mng->Run();

#if VM_TRACE
    tfp->close();
#endif

#if VM_COVERAGE
    contextp->coveragep()->write("coverage.dat");
#endif

    return 0;
}
#endif


// end of file
