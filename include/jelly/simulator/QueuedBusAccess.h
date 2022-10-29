

#pragma once

#include <cstdint>
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
    virtual void Write(std::uint64_t adr, std::uint64_t dat, std::uint64_t sel, int cycle=0) {};
    virtual void Read(std::uint64_t adr, int cycle=0) {};
    virtual bool GetReadData(std::uint64_t& data) { return false; };
    virtual void Display(std::string message) {}
};

}
}


// end of file
