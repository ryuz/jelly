// ハードウェア初期化

#[allow(dead_code)]
static MPU_DISABLE: u32 = 0;
#[allow(dead_code)]
static MPU_SIZE_32: u32 = (0x04 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_64: u32 = (0x05 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_128: u32 = (0x06 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_256: u32 = (0x07 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_512: u32 = (0x08 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_1K: u32 = (0x09 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_2K: u32 = (0x0a << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_4K: u32 = (0x0b << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_8K: u32 = (0x0c << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_16K: u32 = (0x0d << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_32K: u32 = (0x0e << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_64K: u32 = (0x0f << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_128K: u32 = (0x10 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_256K: u32 = (0x11 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_512K: u32 = (0x12 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_1M: u32 = (0x13 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_2M: u32 = (0x14 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_4M: u32 = (0x15 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_8M: u32 = (0x16 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_16M: u32 = (0x17 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_32M: u32 = (0x18 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_64M: u32 = (0x19 << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_128M: u32 = (0x1a << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_256M: u32 = (0x1b << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_512M: u32 = (0x1c << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_1G: u32 = (0x1d << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_2G: u32 = (0x1e << 1) | 1;
#[allow(dead_code)]
static MPU_SIZE_4G: u32 = (0x1f << 1) | 1;
#[allow(dead_code)]
static MPU_XN: u32 = 1 << 12;
#[allow(dead_code)]
static MPU_S: u32 = 1 << 2;

#[allow(dead_code)]
static MPU_AP_NO: u32 = 0x0 << 8;
#[allow(dead_code)]
static MPU_AP_FULL: u32 = 0x3 << 8;

#[allow(dead_code)]
static MPU_STRONGLY_ORDERED: u32 = (0x0 << 3) | 0x0;
#[allow(dead_code)]
static MPU_SHAREABLE_DEVICE: u32 = (0x0 << 3) | 0x1;
#[allow(dead_code)]
static MPU_WRITE_THROUGH: u32 = (0x0 << 3) | 0x2;
#[allow(dead_code)]
static MPU_WRITE_BACK: u32 = (0x0 << 3) | 0x3;
#[allow(dead_code)]
static MPU_NO_CACHEABLE: u32 = (0x1 << 3) | 0x0;
#[allow(dead_code)]
static MPU_WRITE_BACK_ALLOC: u32 = (0x1 << 3) | 0x3;
#[allow(dead_code)]
static MPU_NON_SHAREABLE_DEVICE: u32 = (0x2 << 3) | 0x0;

#[allow(dead_code)]
static MPU_2_NO_CACHEABLE: u32 = (0x4 << 3) | 0x0;
#[allow(dead_code)]
static MPU_2_WRITE_BACK_ALLOC: u32 = (0x4 << 3) | 0x1;
#[allow(dead_code)]
static MPU_2_WRITE_THROUGH: u32 = (0x4 << 3) | 0x2;
#[allow(dead_code)]
static MPU_2_WRITE_BACK: u32 = (0x4 << 3) | 0x3;

extern "C" {
    fn _armcpu_enable_bpredict(); //  分岐予測有効化
    fn _armcpu_disable_bpredict(); // 分岐予測無効化
    fn _armcpu_enable_icache(); // Iキャッシュ有効化
    fn _armcpu_disable_icache(); // Iキャッシュ無効化
    fn _armcpu_enable_dcache(); // Dキャッシュ有効化
    fn _armcpu_disable_dcache(); // Dキャッシュ無効化
    fn _armcpu_enable_cache(); // キャッシュ有効化
    fn _armcpu_disable_cache(); // キャッシュ無効化
    fn _armcpu_enable_ecc(); // ECC有効化 (必ずキャッシュOFF状態で呼ぶこと)
    fn _armcpu_disable_ecc(); // ECC無効化 (必ずキャッシュOFF状態で呼ぶこと)

    /* Access to CP15 */
    fn _armcpu_read_cp15_c0_c0_4() -> u32; // read MPU Type Register
    fn _armcpu_write_cp15_c6_c1_0(v: u32); // write MPU Region Size and Enable Registers
    fn _armcpu_read_cp15_c6_c1_0() -> u32; // read MPU Region Size and Enable Registers
    fn _armcpu_write_cp15_c6_c2_0(v: u32); // write MPU Region Number Register
    fn _armcpu_read_cp15_c6_c2_0() -> u32; // read MPU Region Number Register
    fn _armcpu_write_cp15_c6_c1_4(v: u32); // write MPU Region Access Control Register
    fn _armcpu_read_cp15_c6_c1_4() -> u32; // read MPU Region Access Control Register
    fn _armcpu_write_cp15_c6_c1_2(v: u32); // write Data MPU Region Size and Enable Register
    fn _armcpu_read_cp15_c6_c1_2() -> u32; // read Data MPU Region Size and Enable Register
}

fn vmpu_get_number_of_regions() -> u32 {
    unsafe { (_armcpu_read_cp15_c0_c0_4() >> 8) & 0xff }
}

fn vmpu_set_region_number(v: u32) {
    unsafe {
        _armcpu_write_cp15_c6_c2_0(v);
    }
}

fn vmpu_set_region_base_address(v: u32) {
    unsafe {
        _armcpu_write_cp15_c6_c1_0(v);
    }
}

fn vmpu_set_region_size(v: u32) {
    unsafe {
        _armcpu_write_cp15_c6_c1_2(v);
    }
}

fn vmpu_set_region_access_control(v: u32) {
    unsafe {
        _armcpu_write_cp15_c6_c1_4(v);
    }
}

// ハードウェアセットアップ
#[no_mangle]
pub unsafe extern "C" fn hw_setup() {
    // -----------------------------------
    //  MPU 設定
    // -----------------------------------

    // MPU設定
    let n = vmpu_get_number_of_regions();
    for i in 0..n {
        vmpu_set_region_number(i);
        vmpu_set_region_size(MPU_DISABLE);
    }
    let mut region_num = 0;

    // DDR4-SDRAM
    vmpu_set_region_number(region_num);
    region_num += 1;
    vmpu_set_region_base_address(0x00000000);
    vmpu_set_region_size(MPU_SIZE_2G);
    vmpu_set_region_access_control(MPU_AP_FULL | MPU_WRITE_BACK_ALLOC);

    /* PL(FPD0) */
    vmpu_set_region_number(region_num);
    region_num += 1;
    vmpu_set_region_base_address(0xa0000000);
    vmpu_set_region_size(MPU_SIZE_256M);
    vmpu_set_region_access_control(MPU_AP_FULL | MPU_NO_CACHEABLE);

    /* PL(FPD1) */
    vmpu_set_region_number(region_num);
    region_num += 1;
    vmpu_set_region_base_address(0xb0000000);
    vmpu_set_region_size(MPU_SIZE_256M);
    vmpu_set_region_access_control(MPU_AP_FULL | MPU_NO_CACHEABLE);

    /* PL(FPD0) */
    vmpu_set_region_number(region_num);
    region_num += 1;
    vmpu_set_region_base_address(0xc0000000);
    vmpu_set_region_size(MPU_SIZE_512M);
    vmpu_set_region_access_control(MPU_AP_FULL | MPU_NO_CACHEABLE);

    /* 256M of device memory from 0xE0000000 to 0xEFFFFFFF for PCIe Low */
    vmpu_set_region_number(region_num);
    region_num += 1;
    vmpu_set_region_base_address(0xe0000000);
    vmpu_set_region_size(MPU_SIZE_256M);
    vmpu_set_region_access_control(MPU_AP_FULL | MPU_NON_SHAREABLE_DEVICE);

    /* 16M of device memory from 0xF8000000 to 0xF8FFFFFF for STM_CORESIGHT */
    vmpu_set_region_number(region_num);
    region_num += 1;
    vmpu_set_region_base_address(0xf8000000);
    vmpu_set_region_size(MPU_SIZE_16M);
    vmpu_set_region_access_control(MPU_AP_FULL | MPU_NON_SHAREABLE_DEVICE);

    /* 1M of device memory from 0xF9000000 to 0xF90FFFFF for RPU_A53_GIC */
    vmpu_set_region_number(region_num);
    region_num += 1;
    vmpu_set_region_base_address(0xf9000000);
    vmpu_set_region_size(MPU_SIZE_1M);
    vmpu_set_region_access_control(MPU_AP_FULL | MPU_NON_SHAREABLE_DEVICE);

    /* 16M of device memory from 0xFD000000 to 0xFDFFFFFF for FPS slaves */
    vmpu_set_region_number(region_num);
    region_num += 1;
    vmpu_set_region_base_address(0xfd000000);
    vmpu_set_region_size(MPU_SIZE_16M);
    vmpu_set_region_access_control(MPU_AP_FULL | MPU_NON_SHAREABLE_DEVICE);

    /* 16M of device memory from 0xFE000000 to 0xFEFFFFFF for Upper LPS slaves */
    vmpu_set_region_number(region_num);
    region_num += 1;
    vmpu_set_region_base_address(0xfe000000);
    vmpu_set_region_size(MPU_SIZE_16M);
    vmpu_set_region_access_control(MPU_AP_FULL | MPU_NON_SHAREABLE_DEVICE);

    /* 16M of device memory from 0xFF000000 to 0xFFFFFFFF for Lower LPS slaves, CSU, PMU, TCM, OCM */
    vmpu_set_region_number(region_num);
    region_num += 1;
    vmpu_set_region_base_address(0xff000000);
    vmpu_set_region_size(MPU_SIZE_16M);
    vmpu_set_region_access_control(MPU_AP_FULL | MPU_NON_SHAREABLE_DEVICE);

    /* 256K of OCM RAM from 0xFFFC0000 to 0xFFFFFFFF marked as normal memory */
    vmpu_set_region_number(region_num); // region_num += 1;
    vmpu_set_region_base_address(0xfffc0000);
    vmpu_set_region_size(MPU_SIZE_256K);
    vmpu_set_region_access_control(MPU_AP_FULL | MPU_WRITE_BACK_ALLOC);

    /* ---------------------------------- */
    /*  キャッシュ設定                     */
    /* -----------------------------------*/

    _armcpu_enable_ecc(); /* ECC有効化 */
    _armcpu_enable_cache(); /* キャッシュ有効化 */
    _armcpu_enable_bpredict(); /* 分岐予測有効化 */
}
