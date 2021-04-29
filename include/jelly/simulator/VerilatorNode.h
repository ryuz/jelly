


#pragma once

#include "jelly/simulator/Manager.h"

#include <verilated.h>

#if VM_TRACE
#include <verilated_vcd_c.h> 
#include <verilated_fst_c.h> 
#endif


namespace jelly {
namespace simulator {


template<typename ModuleType, typename TraceType=VerilatedFstC>
class VerilatorNode : public Node
{
    using module_ptr_t = std::shared_ptr<ModuleType>;
    using trace_ptr_t  = std::shared_ptr<TraceType>;

protected:
    module_ptr_t     m_module;

#if VM_TRACE
    trace_ptr_t      m_tfp;
#endif
    
    VerilatorNode(module_ptr_t module, trace_ptr_t tfp=nullptr)
    {
        m_module = module;
        m_tfp    = tfp;
    }

public:
    static std::shared_ptr<VerilatorNode> Create(module_ptr_t module, trace_ptr_t tfp=nullptr)
    {
        return std::shared_ptr<VerilatorNode>(new VerilatorNode(module, tfp));
    }

protected:
    void Eval(Manager* manager) override
    {
        m_module->eval();
        if ( Verilated::gotFinish() ) {
            manager->Finish();
        }
    };

    void Dump(Manager* manager) override
    {
#if VM_TRACE
        if ( m_tfp ) {
            m_tfp->dump(manager->GetSimTime() / manager->GetTimeResolution());
        }
#endif
    };
};

}
}


// end of file
