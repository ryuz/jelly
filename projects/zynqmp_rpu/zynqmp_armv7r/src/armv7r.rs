#![allow(dead_code)]


pub unsafe fn wfi() {
    asm!("wfi");
}

///  分岐予測有効化
pub unsafe fn enable_bpredict() {
    asm!(
        r#"
            mrc     p15, 0, r0, c1, c0, 1       /* Read ACTLR */
            bic     r0, r0, #0x1 << 17          /* Clear RSDIS bit 17 to enable return stack */
            bic     r0, r0, #0x1 << 16          /* Clear BP bit 15 and BP bit 16 */
            bic     r0, r0, #0x1 << 15          /* Normal operation, BP is taken from the global history table */
            mcr     p15, 0, r0, c1, c0, 1       /* Write ACTLR */
            dsb
        "#
    );
}

/// 分岐予測無効化
pub unsafe fn disable_bpredict() {
    asm!(
        r#"
            mrc     p15, 0, r0, c1, c0, 1       /* Read ACTLR */
            orr     r0, r0, #0x1 << 17          /* Enable RSDIS bit 17 to disable the return stack */
            orr     r0, r0, #0x1 << 16          /* Clear BP bit 15 and set BP bit 16:*/
            bic     r0, r0, #0x1 << 15          /* Branch always not taken and history table updates disabled*/
            mcr     p15, 0, r0, c1, c0, 1       /* Write ACTLR */
            dsb
        "#
    );
}

/// Iキャッシュ有効化
pub unsafe fn enable_icache() {
    asm!(
        r#"
            mrc     p15, 0, r1, c1, c0, 0   /* Read System Control Register configuration data */
            orr     r1, r1, #0x1 << 12      /* instruction cache enable */
            mcr     p15, 0, r0, c7, c5, 0   /* Invalidate entire instruction cache */
            mcr     p15, 0, r1, c1, c0, 0   /* enabled instruction cache */
            isb
        "#
    );
}

/// Iキャッシュ無効化
pub unsafe fn disable_icache() {
    asm!(
        r#"
            mrc     p15, 0, R1, c1, c0, 0   /* Read System Control Register configuration data */
            bic     r1, r1, #0x1 << 12      /* instruction cache enable */
            mcr     p15, 0, r1, c1, c0, 0   /* disabled instruction cache */
            isb
        "#
    );
}

/// Dキャッシュ有効化
pub unsafe fn enable_dcache() {
    asm!(
        r#"
            mrc     p15, 0, r1, c1, c0, 0   /* Read System Control Register configuration data */
            orr     r1, r1, #0x1 << 2
            dsb
            mcr     p15, 0, r0, c15, c5, 0  /* Invalidate entire data cache */
            mcr     p15, 0, r1, c1, c0, 0   /* enabled data cache */
        "#
    );
}

/// Dキャッシュ無効化
pub unsafe fn disable_dcache() {
    asm!(
        r#"
            mrc     p15, 0, r1, c1, c0, 0   /* Read System Control Register configuration data */
            bic     r1, r1, #0x1 << 2
            dsb
            mcr     p15, 0, r1, c1, c0, 0   /* disabled data cache */
            /* Clean entire data cache. This routine depends on the data cache size. It can be
            omitted if it is known that the data cache has no dirty data. */
        "#
    );
}

/// キャッシュ有効化
pub unsafe fn enable_cache() {
    asm!(
        r#"
            mrc     p15, 0, r1, c1, c0, 0   /* Read System Control Register configuration data */
            orr     r1, r1, #0x1 << 12      /* instruction cache enable */
            orr     r1, r1, #0x1 << 2       /* data cache enable */
            dsb
            mcr     p15, 0, r0, c15, c5, 0  /* Invalidate entire data cache */
            mcr     p15, 0, r0, c7, c5, 0   /* Invalidate entire instruction cache */
            mcr     p15, 0, r1, c1, c0, 0   /* enabled cache RAMs */
            isb
        "#
    );
}

/// キャッシュ無効化
pub unsafe fn disable_cache() {
    asm!(
        r#"
            mrc     p15, 0, r1, c1, c0, 0   /* Read System Control Register configuration data */
            bic     r1, r1, #0x1 << 12      /* instruction cache disable */
            bic     r1, r1, #0x1 << 2       /* data cache disable */
            dsb
            mcr     p15, 0, r1, c1, c0, 0   /* disabled cache RAMs */
            isb
            /* Clean entire data cache. This routine depends on the data cache size. It can be
            omitted if it is known that the data cache has no dirty data */
        "#
    );
}

/// ECC有効化 (必ずキャッシュOFF状態で呼ぶこと)
pub unsafe fn enable_ecc() {
    asm!(
        r#"
            mrc     p15, 0, r1, c1, c0, 1   /* Read Auxiliary Control Register */
            bic     r0, r0, #(0x1 << 5)     /* Generate abort on parity errors, with [5:3]= b000 */
            bic     r0, r0, #(0x1 << 4)
            bic     r0, r0, #(0x1 << 3)
            mcr     p15, 0, r1, c1, c0, 1   /* Write Auxiliary Control Register */
        "#
    );
}

/// ECC無効化 (必ずキャッシュOFF状態で呼ぶこと)
pub unsafe fn disable_ecc() {
    asm!(
        r#"
            mrc     p15, 0, r1, c1, c0, 1   /* Read Auxiliary Control Register */
            orr     r0, r0, #(0x1 << 5)     /* Disable parity checking, with [5:3]= b100 */
            bic     r0, r0, #(0x1 << 4)
            bic     r0, r0, #(0x1 << 3)
            mcr     p15, 0, r1, c1, c0, 1   /* Write Auxiliary Control Register */
        "#
    );
}

pub unsafe fn mpu_get_number_of_data_regions() -> u32 {
    let mut v: u32;
    asm!(
        "mrc     p15, 0, {0}, c0, c0, 4",
        out(reg) v,
    );
    return (v >> 8) & 0xff;
}

pub unsafe fn mpu_set_data_region_number(v: u32) {
    asm!(
        "mcr     p15, 0, {0}, c6, c2, 0",
        in(reg) v,
    );
}

pub unsafe fn mpu_set_data_region_base_address(v: u32) {
    asm!(
        "mcr     p15, 0, {0}, c6, c1, 0",
        in(reg) v,
    );
}

pub unsafe fn mpu_set_data_region_size(v: u32) {
    asm!(
        "mcr     p15, 0, {0}, c6, c1, 2",
        in(reg) v,
    );
}

pub unsafe fn mpu_set_data_region_access_control(v: u32) {
    asm!(
        "mcr     p15, 0, {0}, c6, c1, 4",
        in(reg) v,
    );
}



bitflags! {
    pub struct MpuSize: u32 {
        const DISABLE = 0;
        const SIZE_32 = (0x04 << 1) | 1;
        const SIZE_64 = (0x05 << 1) | 1;
        const SIZE_128 = (0x06 << 1) | 1;
        const SIZE_256 = (0x07 << 1) | 1;
        const SIZE_512 = (0x08 << 1) | 1;
        const SIZE_1K = (0x09 << 1) | 1;
        const SIZE_2K = (0x0a << 1) | 1;
        const SIZE_4K = (0x0b << 1) | 1;
        const SIZE_8K = (0x0c << 1) | 1;
        const SIZE_16K = (0x0d << 1) | 1;
        const SIZE_32K = (0x0e << 1) | 1;
        const SIZE_64K = (0x0f << 1) | 1;
        const SIZE_128K = (0x10 << 1) | 1;
        const SIZE_256K = (0x11 << 1) | 1;
        const SIZE_512K = (0x12 << 1) | 1;
        const SIZE_1M = (0x13 << 1) | 1;
        const SIZE_2M = (0x14 << 1) | 1;
        const SIZE_4M = (0x15 << 1) | 1;
        const SIZE_8M = (0x16 << 1) | 1;
        const SIZE_16M = (0x17 << 1) | 1;
        const SIZE_32M = (0x18 << 1) | 1;
        const SIZE_64M = (0x19 << 1) | 1;
        const SIZE_128M = (0x1a << 1) | 1;
        const SIZE_256M = (0x1b << 1) | 1;
        const SIZE_512M = (0x1c << 1) | 1;
        const SIZE_1G = (0x1d << 1) | 1;
        const SIZE_2G = (0x1e << 1) | 1;
        const SIZE_4G = (0x1f << 1) | 1;
    }
}

use bitflags::bitflags;

bitflags! {
    pub struct MpuAc: u32 {
        const XN = 1 << 12;
        const S = 1 << 2;
        const AP_NO = 0x0 << 8;
        const AP_FULL = 0x3 << 8;
        const STRONGLY_ORDERED = (0x0 << 3) | 0x0;
        const SHAREABLE_DEVICE = (0x0 << 3) | 0x1;
        const WRITE_THROUGH = (0x0 << 3) | 0x2;
        const WRITE_BACK = (0x0 << 3) | 0x3;
        const NO_CACHEABLE = (0x1 << 3) | 0x0;
        const WRITE_BACK_ALLOC = (0x1 << 3) | 0x3;
        const NON_SHAREABLE_DEVICE = (0x2 << 3) | 0x0;
        const L2_NO_CACHEABLE = (0x4 << 3) | 0x0;
        const L2_WRITE_BACK_ALLOC = (0x4 << 3) | 0x1;
        const L2_WRITE_THROUGH = (0x4 << 3) | 0x2;
        const L2_WRITE_BACK = (0x4 << 3) | 0x3;
    }
}

pub unsafe fn set_mpu_data_region(region_num: u32, address: u32, size: MpuSize, access_control: MpuAc) {
    mpu_set_data_region_number(region_num);
    mpu_set_data_region_base_address(address);
    mpu_set_data_region_size(size.bits());
    mpu_set_data_region_access_control(access_control.bits());
}

