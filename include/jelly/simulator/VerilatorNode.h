


#pragma once

#include "jelly/simulator/Manager.h"

#include <verilated.h>

#if VM_TRACE
#include <verilated_fst_c.h> 
#include <verilated_vcd_c.h> 
#endif


namespace jelly {
namespace simulator {

#if VM_TRACE

#if VM_TRACE_FST
#define TRACE_EXT   ".fst"
using trace_t     = VerilatedFstC;
#else
#define TRACE_EXT   ".vcd"
using trace_t     = VerilatedVcdC;
#endif
using trace_ptr_t = std::shared_ptr<trace_t>;

#else

using trace_ptr_t = void*;

#endif

using context_ptr_t = std::shared_ptr<VerilatedContext>;


template<typename ModuleType>
class VerilatorNode : public Node
{
    using module_ptr_t  = std::shared_ptr<ModuleType>;

protected:
    module_ptr_t     m_module;
    trace_ptr_t      m_tfp;
    context_ptr_t    m_contextp;
    
    VerilatorNode(module_ptr_t module, trace_ptr_t tfp=nullptr, context_ptr_t contextp=nullptr)
    {
        m_module   = module;
        m_tfp      = tfp;
        m_contextp = contextp;
    }

public:
    static std::shared_ptr<VerilatorNode> Create(module_ptr_t module, trace_ptr_t tfp=nullptr, context_ptr_t contextp=nullptr)
    {
        return std::shared_ptr<VerilatorNode>(new VerilatorNode(module, tfp, contextp));
    }

protected:
    void FinalProc(Manager* manager) override
    {
        m_module->final();
    }

    void EvalProc(Manager* manager) override
    {
        if ( m_contextp ) { m_contextp->time(manager->GetSimTime()); }
        m_module->eval();
        if ( Verilated::gotFinish() ) {
            manager->Finish();
        }
    }

    void DumpProc(Manager* manager) override
    {
#if VM_TRACE
        if ( m_tfp ) {
            m_tfp->dump(manager->GetSimTime() / manager->GetTimeResolution());
        }
#endif
    }
};

template<typename ModuleTp>
std::shared_ptr< VerilatorNode<ModuleTp> > VerilatorNode_Create(std::shared_ptr<ModuleTp> module, trace_ptr_t tfp=nullptr, context_ptr_t contextp=nullptr)
{
    return VerilatorNode<ModuleTp>::Create(module, tfp, contextp);
}

}
}

// end of file
