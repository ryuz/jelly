

#pragma once

#include <string>
#include "jelly/simulator/Manager.h"

namespace jelly {
namespace simulator {

// バスアクセスのキューイング
class QueuedBusAccess : public Node {
public:
    virtual bool IsEmptyQueue(void) { return true; }
    virtual void SetVerbose(bool verbose) {}
    virtual void Wait(int cycle) {}
    virtual void Write(unsigned long long adr, unsigned long long dat, unsigned long long  sel, int cycle=0) {};
    virtual void Read(unsigned long long adr, int cycle=0) {};
    virtual void Display(std::string message) {}
};

}
}


// end of file
