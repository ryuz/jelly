// ハードウェアセットアップ

use core::ptr;
use pudding_pac::arm::cpu::*;
use pudding_pac::arm::mpu::*;

#[no_mangle]
pub unsafe extern "C" fn bootstrap() {
    // -----------------------------------
    //  MPU 設定
    // -----------------------------------

    // MPU設定
    let n = mpu_get_number_of_data_regions();
    for i in 0..n {
        set_mpu_data_region(i, 0, MpuSize::DISABLE, MpuAc::AP_NO);
    }

    // DDR4-SDRAM
    let mut region_num = 0;
    set_mpu_data_region(
        region_num,
        0x00000000,
        MpuSize::SIZE_2G,
        MpuAc::AP_FULL | MpuAc::WRITE_BACK_ALLOC,
    );

    // PL(FPD0)
    region_num += 1;
    set_mpu_data_region(
        region_num,
        0xa0000000,
        MpuSize::SIZE_256M,
        MpuAc::AP_FULL | MpuAc::NO_CACHEABLE,
    );

    // PL(FPD1)
    region_num += 1;
    set_mpu_data_region(
        region_num,
        0xb0000000,
        MpuSize::SIZE_256M,
        MpuAc::AP_FULL | MpuAc::NO_CACHEABLE,
    );

    // PL(FPD0)
    region_num += 1;
    set_mpu_data_region(
        region_num,
        0xc0000000,
        MpuSize::SIZE_512M,
        MpuAc::AP_FULL | MpuAc::NO_CACHEABLE,
    );

    // 256M of device memory from 0xE0000000 to 0xEFFFFFFF for PCIe Low
    region_num += 1;
    set_mpu_data_region(
        region_num,
        0xe0000000,
        MpuSize::SIZE_256M,
        MpuAc::AP_FULL | MpuAc::NON_SHAREABLE_DEVICE,
    );

    // 16M of device memory from 0xF8000000 to 0xF8FFFFFF for STM_CORESIGHT
    region_num += 1;
    set_mpu_data_region(
        region_num,
        0xf8000000,
        MpuSize::SIZE_16M,
        MpuAc::AP_FULL | MpuAc::NON_SHAREABLE_DEVICE,
    );

    // 1M of device memory from 0xF9000000 to 0xF90FFFFF for RPU_A53_GIC
    region_num += 1;
    set_mpu_data_region(
        region_num,
        0xf9000000,
        MpuSize::SIZE_1M,
        MpuAc::AP_FULL | MpuAc::NON_SHAREABLE_DEVICE,
    );

    // 16M of device memory from 0xFD000000 to 0xFDFFFFFF for FPS slaves
    region_num += 1;
    set_mpu_data_region(
        region_num,
        0xfd000000,
        MpuSize::SIZE_16M,
        MpuAc::AP_FULL | MpuAc::NON_SHAREABLE_DEVICE,
    );

    // 16M of device memory from 0xFE000000 to 0xFEFFFFFF for Upper LPS slaves
    region_num += 1;
    set_mpu_data_region(
        region_num,
        0xfe000000,
        MpuSize::SIZE_16M,
        MpuAc::AP_FULL | MpuAc::NON_SHAREABLE_DEVICE,
    );

    // 16M of device memory from 0xFF000000 to 0xFFFFFFFF for Lower LPS slaves, CSU, PMU, TCM, OCM
    region_num += 1;
    set_mpu_data_region(
        region_num,
        0xff000000,
        MpuSize::SIZE_16M,
        MpuAc::AP_FULL | MpuAc::NON_SHAREABLE_DEVICE,
    );

    // 256K of OCM RAM from 0xFFFC0000 to 0xFFFFFFFF marked as normal memory
    region_num += 1;
    set_mpu_data_region(
        region_num,
        0xff000000,
        MpuSize::SIZE_256K,
        MpuAc::AP_FULL | MpuAc::WRITE_BACK_ALLOC,
    );

    // -----------------------------------
    //  キャッシュ設定
    // -----------------------------------

    enable_ecc(); // ECC有効化
    enable_cache(); // キャッシュ有効化
    enable_bpredict(); // 分岐予測有効化

    extern "C" {
        static mut ___bss: u8;
        static mut ___bss_end: u8;
    }

    let count = &___bss_end as *const u8 as usize - &___bss as *const u8 as usize;
    ptr::write_bytes(&mut ___bss as *mut u8, 0, count);

    //    let count = &_edata as *const u8 as usize - &_sdata as *const u8 as usize;
    //    ptr::copy_nonoverlapping(&_sidata as *const u8, &mut _sdata as *mut u8, count);
}
