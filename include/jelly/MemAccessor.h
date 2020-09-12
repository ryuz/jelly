// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef __RYUZ__JELLY__MEM_ACCESSOR_H__
#define __RYUZ__JELLY__MEM_ACCESSOR_H__


#include <cstring> 
#include <cstdint>
#include <memory>


namespace jelly {

// memory manager
class AccessorMemManager
{
protected:
    void*       m_ptr = nullptr;
    std::size_t m_size = 0;

    AccessorMemManager() {}
    AccessorMemManager(void* ptr, std::size_t size) { m_ptr = ptr; m_size = size; }

public:
    virtual ~AccessorMemManager() {}

    static std::shared_ptr<AccessorMemManager> Create(void* ptr, std::size_t size = 0)
    {
        return std::shared_ptr<AccessorMemManager>(new AccessorMemManager(ptr, size));
    }

    void*       GetPtr(void)  { return m_ptr; }
    std::size_t GetSize(void) { return m_size; }
};

// memory accessor
template <typename DataType=std::uintptr_t, typename MemAddrType=std::uintptr_t, typename RegAddrType=std::uintptr_t>
class MemAccessor_
{
protected:
    std::shared_ptr<AccessorMemManager>   m_mem_manager;
    void*                               m_base_ptr = nullptr;

public:
    ~MemAccessor_(){}
    MemAccessor_(){}

    MemAccessor_(std::shared_ptr<AccessorMemManager> mem_manager, std::size_t offset=0)
    {
        SetMemManager(mem_manager, offset);
    }

    MemAccessor_(void *ptr, std::size_t size=0, std::size_t offset=0)
    {
        SetMemManager(ptr, size, offset);
    }


    void  SetMemManager(std::shared_ptr<AccessorMemManager> mem_manager, std::size_t offset=0) {
        m_mem_manager = mem_manager;
        m_base_ptr = reinterpret_cast<void*>(reinterpret_cast<std::int8_t*>(m_mem_manager->GetPtr()) + offset);
    }

    void  SetMappedMemory(void *ptr, std::size_t size=0, std::size_t offset=0) {
        SetMemManager(AccessorMemManager::Create(ptr, size), offset);
    }

    std::shared_ptr<AccessorMemManager> GetManager(void)
    {
        return m_mem_manager;
    }

    std::size_t GetSize(void)
    {
        auto mem_manager = GetManager();
        if ( !mem_manager ) {
            return 0;
        }
        return mem_manager->GetSize();
    }


    template <typename DT=DataType, typename MT=MemAddrType, typename RT=RegAddrType>
    MemAccessor_<DT, MT, RT> GetAccessor_(MemAddrType addr)
    {
        return MemAccessor_<DT, MT, RT>(m_mem_manager, addr);
    }

    MemAccessor_<DataType, MemAddrType, RegAddrType> GetAccessor(MemAddrType addr)
    {
        return GetAccessor_<DataType, MemAddrType, RegAddrType>(addr);
    }

    MemAccessor_<std::uint64_t, MemAddrType, RegAddrType> GetAccessor64(MemAddrType addr)
    {
        return GetAccessor_<std::uint64_t, MemAddrType, RegAddrType>(addr);
    }

    MemAccessor_<std::uint32_t, MemAddrType, RegAddrType> GetAccessor32(MemAddrType addr)
    {
        return GetAccessor_<std::uint32_t, MemAddrType, RegAddrType>(addr);
    }

    MemAccessor_<std::uint16_t, MemAddrType, RegAddrType> GetAccessor16(MemAddrType addr)
    {
        return GetAccessor_<std::uint16_t, MemAddrType, RegAddrType>(addr);
    }

    MemAccessor_<std::uint8_t, MemAddrType, RegAddrType> GetAccessor8(MemAddrType addr)
    {
        return GetAccessor_<std::uint8_t, MemAddrType, RegAddrType>(addr);
    }


    template <typename DT=DataType, typename MT=MemAddrType, typename RT=RegAddrType>
    MemAccessor_<DT, MT, RT> GetRegAccessor_(RegAddrType reg)
    {
        return MemAccessor_<DT, MT, RT>(m_mem_manager, reg * sizeof(DataType));
    }

    MemAccessor_<DataType, MemAddrType, RegAddrType> GetRegAccessor(RegAddrType reg)
    {
        return GetRegAccessor_<DataType, MemAddrType, RegAddrType>(reg);
    }

    MemAccessor_<std::uint64_t, MemAddrType, RegAddrType> GetRegAccessor64(RegAddrType reg)
    {
        return GetRegAccessor_<std::uint64_t, MemAddrType, RegAddrType>(reg);
    }

    MemAccessor_<std::uint32_t, MemAddrType, RegAddrType> GetRegAccessor32(RegAddrType reg)
    {
        return GetRegAccessor_<std::uint32_t, MemAddrType, RegAddrType>(reg);
    }

    MemAccessor_<std::uint16_t, MemAddrType, RegAddrType> GetRegAccessor16(RegAddrType reg)
    {
        return GetRegAccessor_<std::uint16_t, MemAddrType, RegAddrType>(reg);
    }

    MemAccessor_<std::uint8_t, MemAddrType, RegAddrType> GetRegAccessor8(RegAddrType reg)
    {
        return GetRegAccessor_<std::uint8_t, MemAddrType, RegAddrType>(reg);
    }


    template <typename T=void*>
    T GetPtr_(MemAddrType addr=0)
    {
        return reinterpret_cast<T>(reinterpret_cast<std::int8_t*>(m_base_ptr) + addr);
    }

    void* GetPtr(MemAddrType addr=0)
    {
        return GetPtr_<void*>(addr);
    }


    template <typename T=DataType>
    void WriteMem_(MemAddrType addr, T data)
    {
        *GetPtr_<volatile T*>(addr) = data;
        // メモリバリアを入れるべきか悩む
    }

    template <typename T=DataType>
    T ReadMem_(MemAddrType addr)
    {
        // メモリバリアを入れるべきか悩む
        return *GetPtr_<volatile T*>(addr);
    }


    // memory access (byte addressing)
    void MemCopyFrom(MemAddrType dst_addr, const void* src_ptr, std::size_t size)
    {
        memcpy(GetPtr(dst_addr), src_ptr, size);
    }

    void MemCopyTo(void* dst_ptr, MemAddrType src_addr, std::size_t size)
    {
        memcpy(dst_ptr, GetPtr(src_addr), size);
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
        WriteMem_<T>(static_cast<MemAddrType>(reg * sizeof(DataType)), data);
    }

    template <typename T=DataType>
    T ReadReg_(RegAddrType reg)
    {
        return ReadMem_<T>(static_cast<MemAddrType>(reg * sizeof(DataType)));
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


using MemAccessor   = MemAccessor_<>;
using MemAccessor64 = MemAccessor_<std::uint64_t>;
using MemAccessor32 = MemAccessor_<std::uint32_t>;
using MemAccessor16 = MemAccessor_<std::uint16_t>;
using MemAccessor8  = MemAccessor_<std::uint8_t>;

}


#endif  // __RYUZ__JELLY__MEM_ACCESSOR_H__


// end of file
