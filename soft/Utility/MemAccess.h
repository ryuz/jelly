// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef	__RYUZ__JELLY__MEM_ACCESS_H__
#define	__RYUZ__JELLY__MEM_ACCESS_H__


#include <cstring> 
#include <cstdint>

namespace jelly {

template <typename DataType=std::uintptr_t, typename MemAddrType=std::uintptr_t, typename RegAddrType=std::uintptr_t>
class MemAccess_
{
protected:
    void*   m_base_ptr = nullptr;

public:
    MemAccess_(){}
    MemAccess_(void* base_ptr) { m_base_ptr = base_ptr; }
    ~MemAccess_(){}

    void  SetBasePtr(void *base_ptr) { m_base_ptr = base_ptr; }
    void* GetBasePtr(void) { return m_base_ptr; }
    
    template <typename T=void*>
    T GetPointer_(MemAddrType addr=0)
    {
        return reinterpret_cast<T>(reinterpret_cast<std::int8_t*>(m_base_ptr) + addr);
    }

    void* GetPointer(MemAddrType addr=0)
    {
        return GetPointer_<void*>(addr);
    }

    template <typename DT=DataType, typename MT=MemAddrType, typename RT=RegAddrType>
    MemAccess_<DT, MT, RT> GetMemAccess_(MemAddrType addr)
    {
        return MemAccess_<DT, MT, RT>(GetPointer(addr));
    }

    MemAccess_<DataType, MemAddrType, RegAddrType> GetMemAccess(MemAddrType addr)
    {
        return MemAccess_<DataType, MemAddrType, RegAddrType>(GetPointer(addr));
    }

    template <typename T=DataType>
    void WriteMem_(MemAddrType addr, T data)
    {
        *GetPointer_<volatile T*>(addr) = data;
        // メモリバリアを入れるべきか悩む
    }

    template <typename T=DataType>
    T ReadMem_(MemAddrType addr)
    {
        // メモリバリアを入れるべきか悩む
        return *GetPointer_<volatile T*>(addr);
    }


    // memory access (byte addressing)
    void MemCopyTo(MemAddrType dst_addr, const void* src_ptr, std::size_t size)
    {
        memcpy(GetPointer(dst_addr), src_ptr, size);
    }

    void MemCopyFrom(void* dst_ptr, MemAddrType src_addr, std::size_t size)
    {
        memcpy(dst_ptr, GetPointer(src_addr), size);
    }

    void WriteMem   (MemAddrType addr, DataType      data) { WriteMem_<DataType>     (addr, data); }
    void WriteMem64 (MemAddrType addr, std::uint64_t data) { WriteMem_<std::uint64_t>(addr, data); }
    void WriteMem32 (MemAddrType addr, std::uint32_t data) { WriteMem_<std::uint32_t>(addr, data); }
    void WriteMem16 (MemAddrType addr, std::uint16_t data) { WriteMem_<std::uint16_t>(addr, data); }
    void WriteMem8  (MemAddrType addr, std::uint8_t  data) { WriteMem_<std::uint8_t> (addr, data); }
    void WriteMemS64(MemAddrType addr, std::int64_t  data) { WriteMem_<std::int64_t> (addr, data); }
    void WriteMemS32(MemAddrType addr, std::int32_t  data) { WriteMem_<std::int32_t> (addr, data); }
    void WriteMemS16(MemAddrType addr, std::int16_t  data) { WriteMem_<std::int16_t> (addr, data); }
    void WriteMemS8 (MemAddrType addr, std::int8_t   data) { WriteMem_<std::int8_t>  (addr, data); }
    
    DataType        ReadMem   (MemAddrType addr) { return ReadMem_<DataType>     (addr); }
    std::uint64_t   ReadMem64 (MemAddrType addr) { return ReadMem_<std::uint64_t>(addr); }
    std::uint32_t   ReadMem32 (MemAddrType addr) { return ReadMem_<std::uint32_t>(addr); }
    std::uint16_t   ReadMem16 (MemAddrType addr) { return ReadMem_<std::uint16_t>(addr); }
    std::uint8_t    ReadMem8  (MemAddrType addr) { return ReadMem_<std::uint8_t> (addr); }
    std::int64_t    ReadMemS64(MemAddrType addr) { return ReadMem_<std::int64_t> (addr); }
    std::int32_t    ReadMemS32(MemAddrType addr) { return ReadMem_<std::int32_t> (addr); }
    std::int16_t    ReadMemS16(MemAddrType addr) { return ReadMem_<std::int16_t> (addr); }
    std::int8_t     ReadMemS8 (MemAddrType addr) { return ReadMem_<std::int8_t>  (addr); }


    // register access (word addressing with DataType)
    template <typename T=DataType>
    void WriteReg_(RegAddrType reg, T data)
    {
        WriteMem_(static_cast<MemAddrType>(reg*sizeof(DataType), data));
    }

    template <typename T=DataType>
    T ReadReg_(RegAddrType reg)
    {
        return ReadMem_(static_cast<MemAddrType>(reg*sizeof(DataType)));
    }

    void WriteReg   (MemAddrType reg, DataType      data) { WriteReg_<DataType>     (reg, data); }
    void WriteReg64 (MemAddrType reg, std::uint64_t data) { WriteReg_<std::uint64_t>(reg, data); }
    void WriteReg32 (MemAddrType reg, std::uint32_t data) { WriteReg_<std::uint32_t>(reg, data); }
    void WriteReg16 (MemAddrType reg, std::uint16_t data) { WriteReg_<std::uint16_t>(reg, data); }
    void WriteReg8  (MemAddrType reg, std::uint8_t  data) { WriteReg_<std::uint8_t> (reg, data); }
    void WriteRegS64(MemAddrType reg, std::int64_t  data) { WriteReg_<std::int64_t> (reg, data); }
    void WriteRegS32(MemAddrType reg, std::int32_t  data) { WriteReg_<std::int32_t> (reg, data); }
    void WriteRegS16(MemAddrType reg, std::int16_t  data) { WriteReg_<std::int16_t> (reg, data); }
    void WriteRegS8 (MemAddrType reg, std::int8_t   data) { WriteReg_<std::int8_t>  (reg, data); }

    DataType        ReadReg   (MemAddrType reg) { return ReadReg_<DataType>     (reg); }
    std::uint64_t   ReadReg64 (MemAddrType reg) { return ReadReg_<std::uint64_t>(reg); }
    std::uint32_t   ReadReg32 (MemAddrType reg) { return ReadReg_<std::uint32_t>(reg); }
    std::uint16_t   ReadReg16 (MemAddrType reg) { return ReadReg_<std::uint16_t>(reg); }
    std::uint8_t    ReadReg8  (MemAddrType reg) { return ReadReg_<std::uint8_t> (reg); }
    std::int64_t    ReadRegS64(MemAddrType reg) { return ReadReg_<std::int64_t> (reg); }
    std::int32_t    ReadRegS32(MemAddrType reg) { return ReadReg_<std::int32_t> (reg); }
    std::int16_t    ReadRegS16(MemAddrType reg) { return ReadReg_<std::int16_t> (reg); }
    std::int8_t     ReadRegS8 (MemAddrType reg) { return ReadReg_<std::int8_t>  (reg); }
};


using MemAccess   = MemAccess_<>;
using MemAccess64 = MemAccess_<std::uint64_t>;
using MemAccess32 = MemAccess_<std::uint32_t>;
using MemAccess16 = MemAccess_<std::uint16_t>;
using MemAccess8  = MemAccess_<std::uint8_t>;

}


#endif  // __RYUZ__JELLY__MEM_ACCESS_H__


// end of file
