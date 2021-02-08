// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef __RYUZ__JELLY__MEM_ACCESSOR_H__
#define __RYUZ__JELLY__MEM_ACCESSOR_H__

#ifdef __JELLY__PYBIND11__
#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>
#endif

#include <cstring> 
#include <cstdint>
#include <memory>


namespace jelly {

// memory manager
class AccessorMemManager
{
protected:
    void*       m_ptr  = nullptr;
    std::size_t m_size = 0;

    AccessorMemManager() {}
    AccessorMemManager(void* ptr, std::size_t size)
    {
        m_ptr = ptr;
        m_size = size;
    }

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
    std::shared_ptr<AccessorMemManager> m_mem_manager;
    void*                               m_base_ptr = nullptr;
    std::size_t                         m_reg_unit = sizeof(DataType);

public:
    ~MemAccessor_(){}
    MemAccessor_(){}

    MemAccessor_(std::shared_ptr<AccessorMemManager> mem_manager, std::size_t offset=0, std::size_t reg_unit = sizeof(DataType))
    {
        SetMemManager(mem_manager, offset);
        m_reg_unit = reg_unit;
    }

    MemAccessor_(void *ptr, std::size_t size=0, std::size_t offset=0, std::size_t reg_unit = sizeof(DataType))
    {
        SetMemManager(ptr, size, offset);
        m_reg_unit = reg_unit;
    }


    void SetMemManager(std::shared_ptr<AccessorMemManager> mem_manager, std::size_t offset=0)
    {
        m_mem_manager = mem_manager;
        m_base_ptr = reinterpret_cast<void*>(reinterpret_cast<std::int8_t*>(m_mem_manager->GetPtr()) + offset);
    }

    void SetMappedMemory(void *ptr, std::size_t size=0, std::size_t offset=0) {
        SetMemManager(AccessorMemManager::Create(ptr, size), offset);
    }

    std::size_t GetOffset(void)
    {
        return (std::size_t)(reinterpret_cast<std::int8_t*>(m_base_ptr) - reinterpret_cast<std::int8_t*>(m_mem_manager->GetPtr()));
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

    void SetRegAddrUnit(std::size_t reg_unit = sizeof(DataType))
    {
        m_reg_unit = reg_unit;
    }

    std::size_t GetRegAddrUnit(void)
    {
        return m_reg_unit;
    }

    template <typename DT=DataType, typename MT=MemAddrType, typename RT=RegAddrType>
    MemAccessor_<DT, MT, RT> GetAccessor_(MemAddrType addr, std::size_t reg_unit=0)
    {
        if ( reg_unit==0 ) { reg_unit = m_reg_unit; }
        return MemAccessor_<DT, MT, RT>(m_mem_manager, GetOffset() + addr, reg_unit);
    }

    MemAccessor_<DataType, MemAddrType, RegAddrType> GetAccessor(MemAddrType addr, std::size_t reg_unit=0)
    {
        return GetAccessor_<DataType, MemAddrType, RegAddrType>(addr, reg_unit);
    }

    MemAccessor_<std::uint64_t, MemAddrType, RegAddrType> GetAccessor64(MemAddrType addr, std::size_t reg_unit=8)
    {
        return GetAccessor_<std::uint64_t, MemAddrType, RegAddrType>(addr, reg_unit);
    }

    MemAccessor_<std::uint32_t, MemAddrType, RegAddrType> GetAccessor32(MemAddrType addr, std::size_t reg_unit=4)
    {
        return GetAccessor_<std::uint32_t, MemAddrType, RegAddrType>(addr, reg_unit);
    }

    MemAccessor_<std::uint16_t, MemAddrType, RegAddrType> GetAccessor16(MemAddrType addr, std::size_t reg_unit=2)
    {
        return GetAccessor_<std::uint16_t, MemAddrType, RegAddrType>(addr, reg_unit);
    }

    MemAccessor_<std::uint8_t, MemAddrType, RegAddrType> GetAccessor8(MemAddrType addr, std::size_t reg_unit=1)
    {
        return GetAccessor_<std::uint8_t, MemAddrType, RegAddrType>(addr, reg_unit);
    }


    template <typename DT=DataType, typename MT=MemAddrType, typename RT=RegAddrType>
    MemAccessor_<DT, MT, RT> GetAccessorReg_(RegAddrType reg, std::size_t reg_unit=0)
    {
        return MemAccessor_<DT, MT, RT>(m_mem_manager, GetOffset() + reg * sizeof(DataType), reg_unit);
    }
    
    MemAccessor_<DataType, MemAddrType, RegAddrType> GetAccessorReg(RegAddrType reg, std::size_t reg_unit=0)
    {
        return GetAccessorReg_<DataType, MemAddrType, RegAddrType>(reg, reg_unit);
    }

    MemAccessor_<std::uint64_t, MemAddrType, RegAddrType> GetAccessor64Reg(RegAddrType reg, std::size_t reg_unit=8)
    {
        return GetAccessorReg_<std::uint64_t, MemAddrType, RegAddrType>(reg, reg_unit);
    }

    MemAccessor_<std::uint32_t, MemAddrType, RegAddrType> GetAccessor32Reg(RegAddrType reg, std::size_t reg_unit=4)
    {
        return GetAccessorReg_<std::uint32_t, MemAddrType, RegAddrType>(reg, reg_unit);
    }

    MemAccessor_<std::uint16_t, MemAddrType, RegAddrType> GetAccessor16Reg(RegAddrType reg, std::size_t reg_unit=2)
    {
        return GetAccessorReg_<std::uint16_t, MemAddrType, RegAddrType>(reg, reg_unit);
    }

    MemAccessor_<std::uint8_t, MemAddrType, RegAddrType> GetAccessor8Reg(RegAddrType reg, std::size_t reg_unit=1)
    {
        return GetAccessorReg_<std::uint8_t, MemAddrType, RegAddrType>(reg, reg_unit);
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


    void ReadImage2d(int pixel_size, std::size_t width, std::size_t height,
                    void*       dst_ptr,    std::size_t dst_step=0, std::size_t dst_offset_x=0, std::size_t dst_offset_y=0,
                    MemAddrType mem_addr=0, std::size_t mem_step=0, std::size_t mem_offset_x=0, std::size_t mem_offset_y=0)
    {
        if ( dst_step <= 0 ) { dst_step = width*pixel_size; }
        if ( mem_step <= 0 ) { mem_step = width*pixel_size; }

        char*           d_ptr  = (char *)dst_ptr + dst_offset_y * dst_step + dst_offset_x * pixel_size;
        MemAddrType     m_addr = mem_addr        + mem_offset_y * mem_step + mem_offset_x * pixel_size;
        
        for ( std::size_t y = 0; y < height; ++y ) {
            MemCopyTo(d_ptr, m_addr, width*pixel_size);
            d_ptr  += dst_step;
            m_addr += mem_step;
        }
    }

    void WriteImage2d(int pixel_size, std::size_t width, std::size_t height,
                    const void* src_ptr,    std::size_t src_step=0, std::size_t src_offset_x=0, std::size_t src_offset_y=0,
                    MemAddrType mem_addr=0, std::size_t mem_step=0, std::size_t mem_offset_x=0, std::size_t mem_offset_y=0)
    {
        if ( src_step <= 0 ) { src_step = width*pixel_size; }
        if ( mem_step <= 0 ) { mem_step = width*pixel_size; }

        const char*     s_ptr  = (const char *)src_ptr + src_offset_y * src_step + src_offset_x * pixel_size;
        MemAddrType     m_addr = mem_addr              + mem_offset_y * mem_step + mem_offset_x * pixel_size;
        
        for ( std::size_t y = 0; y < height; ++y ) {
            MemCopyFrom(m_addr, s_ptr, width*pixel_size);
            s_ptr  += src_step;
            m_addr += mem_step;
        }
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
        WriteMem_<T>(static_cast<MemAddrType>(reg * m_reg_unit), data);
    }

    template <typename T=DataType>
    T ReadReg_(RegAddrType reg)
    {
        return ReadMem_<T>(static_cast<MemAddrType>(reg * m_reg_unit));
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


#ifdef __JELLY__PYBIND11__
    template<typename T>
    pybind11::array_t<T> GetArray_(std::vector<ssize_t> shape, std::size_t offset=0)
    {
        std::size_t size = 1;
        for (auto s : shape) {
            size *= s;
        }

        pybind11::array_t<T> a{shape};
        pybind11::buffer_info info = a.request();
        MemCopyTo(info.ptr, offset, size*sizeof(T));
        return a;
    }
#endif
};


using MemAccessor   = MemAccessor_<>;
using MemAccessor64 = MemAccessor_<std::uint64_t>;
using MemAccessor32 = MemAccessor_<std::uint32_t>;
using MemAccessor16 = MemAccessor_<std::uint16_t>;
using MemAccessor8  = MemAccessor_<std::uint8_t>;

}


#endif  // __RYUZ__JELLY__MEM_ACCESSOR_H__


// end of file
