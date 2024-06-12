/* ------------------------------------------------------------------------ */
/*  ARM プロセッサ固有機能                                                  */
/*                                               Copyright (C) 2021 by Ryuji Fuchikami */
/* ------------------------------------------------------------------------ */


#ifndef __arm_cpu__h__
#define __arm_cpu__h__


#define _ARMCPU_IMSK_F      0x40        /**< %jp{FIQ割込みマスクビット} */
#define _ARMCPU_IMSK_I      0x80        /**< %jp{IRQ割込みマスクビット} */

#define _ARMCPU_IMSK_LV0    0xc0        /**< %jp{割込みマスクレベル0(すべてマスク)} */
#define _ARMCPU_IMSK_LV1    0x80        /**< %jp{割込みマスクレベル1(FIQのみ許可)} */
#define _ARMCPU_IMSK_LV2    0x00        /**< %jp{割込みマスクレベル2(すべて許可)} */


#ifdef __cplusplus
extern "C" {
#endif

void            _armcpu_enable_bpredict(void);  /*  分岐予測有効化 */
void            _armcpu_disable_bpredict(void); /* 分岐予測無効化 */
void            _armcpu_enable_icache(void);    /* Iキャッシュ有効化 */
void            _armcpu_disable_icache(void);   /* Iキャッシュ無効化 */
void            _armcpu_enable_dcache(void);    /* Dキャッシュ有効化 */
void            _armcpu_disable_dcache(void);   /* Dキャッシュ無効化 */
void            _armcpu_enable_cache(void);     /* キャッシュ有効化 */
void            _armcpu_disable_cache(void);    /* キャッシュ無効化 */
void            _armcpu_enable_ecc(void);       /* ECC有効化 (必ずキャッシュOFF状態で呼ぶこと) */
void            _armcpu_disable_ecc(void);      /* ECC無効化 (必ずキャッシュOFF状態で呼ぶこと) */

/* Access to CP15 */
unsigned long   _armcpu_read_cp15_c0_c0_4(void);                /* read MPU Type Register */

void            _armcpu_write_cp15_c6_c1_0(unsigned long v);    /* write MPU Region Size and Enable Registers */
unsigned long   _armcpu_read_cp15_c6_c1_0(void);                /* read MPU Region Size and Enable Registers */

void            _armcpu_write_cp15_c6_c2_0(unsigned long v);    /* write MPU Region Number Register */
unsigned long   _armcpu_read_cp15_c6_c2_0(void);                /* read MPU Region Number Register */

void            _armcpu_write_cp15_c6_c1_4(unsigned long v);    /* write MPU Region Access Control Register */
unsigned long   _armcpu_read_cp15_c6_c1_4(void);                /* read MPU Region Access Control Register */

void            _armcpu_write_cp15_c6_c1_2(unsigned long v);    /* write Data MPU Region Size and Enable Register */
unsigned long   _armcpu_read_cp15_c6_c1_2(void);                /* read Data MPU Region Size and Enable Register */

#ifdef __cplusplus
}
#endif



#define _ARMCPU_MPU_DISABLE                 (0)
#define _ARMCPU_MPU_SIZE_32                 ((0x04 << 1) | 1)
#define _ARMCPU_MPU_SIZE_64                 ((0x05 << 1) | 1)
#define _ARMCPU_MPU_SIZE_128                ((0x06 << 1) | 1)
#define _ARMCPU_MPU_SIZE_256                ((0x07 << 1) | 1)
#define _ARMCPU_MPU_SIZE_512                ((0x08 << 1) | 1)
#define _ARMCPU_MPU_SIZE_1K                 ((0x09 << 1) | 1)
#define _ARMCPU_MPU_SIZE_2K                 ((0x0a << 1) | 1)
#define _ARMCPU_MPU_SIZE_4K                 ((0x0b << 1) | 1)
#define _ARMCPU_MPU_SIZE_8K                 ((0x0c << 1) | 1)
#define _ARMCPU_MPU_SIZE_16K                ((0x0d << 1) | 1)
#define _ARMCPU_MPU_SIZE_32K                ((0x0e << 1) | 1)
#define _ARMCPU_MPU_SIZE_64K                ((0x0f << 1) | 1)
#define _ARMCPU_MPU_SIZE_128K               ((0x10 << 1) | 1)
#define _ARMCPU_MPU_SIZE_256K               ((0x11 << 1) | 1)
#define _ARMCPU_MPU_SIZE_512K               ((0x12 << 1) | 1)
#define _ARMCPU_MPU_SIZE_1M                 ((0x13 << 1) | 1)
#define _ARMCPU_MPU_SIZE_2M                 ((0x14 << 1) | 1)
#define _ARMCPU_MPU_SIZE_4M                 ((0x15 << 1) | 1)
#define _ARMCPU_MPU_SIZE_8M                 ((0x16 << 1) | 1)
#define _ARMCPU_MPU_SIZE_16M                ((0x17 << 1) | 1)
#define _ARMCPU_MPU_SIZE_32M                ((0x18 << 1) | 1)
#define _ARMCPU_MPU_SIZE_64M                ((0x19 << 1) | 1)
#define _ARMCPU_MPU_SIZE_128M               ((0x1a << 1) | 1)
#define _ARMCPU_MPU_SIZE_256M               ((0x1b << 1) | 1)
#define _ARMCPU_MPU_SIZE_512M               ((0x1c << 1) | 1)
#define _ARMCPU_MPU_SIZE_1G                 ((0x1d << 1) | 1)
#define _ARMCPU_MPU_SIZE_2G                 ((0x1e << 1) | 1)
#define _ARMCPU_MPU_SIZE_4G                 ((0x1f << 1) | 1)

#define _ARMCPU_MPU_XN                      (1 << 12)
#define _ARMCPU_MPU_S                       (1 << 2)

#define _ARMCPU_MPU_AP_NO                   (0x0 << 8)
#define _ARMCPU_MPU_AP_FULL                 (0x3 << 8)

#define _ARMCPU_MPU_STRONGLY_ORDERED        ((0x0 << 3) | 0x0)
#define _ARMCPU_MPU_SHAREABLE_DEVICE        ((0x0 << 3) | 0x1)
#define _ARMCPU_MPU_WRITE_THROUGH           ((0x0 << 3) | 0x2)
#define _ARMCPU_MPU_WRITE_BACK              ((0x0 << 3) | 0x3)
#define _ARMCPU_MPU_NO_CACHEABLE            ((0x1 << 3) | 0x0)
#define _ARMCPU_MPU_WRITE_BACK_ALLOC        ((0x1 << 3) | 0x3)
#define _ARMCPU_MPU_NON_SHAREABLE_DEVICE    ((0x2 << 3) | 0x0)

#define _ARMCPU_MPU_2_NO_CACHEABLE          ((0x4 << 3) | 0x0)
#define _ARMCPU_MPU_2_WRITE_BACK_ALLOC      ((0x4 << 3) | 0x1)
#define _ARMCPU_MPU_2_WRITE_THROUGH         ((0x4 << 3) | 0x2)
#define _ARMCPU_MPU_2_WRITE_BACK            ((0x4 << 3) | 0x3)

#define vmpu_get_number_of_regions()        ((_armcpu_read_cp15_c0_c0_4() >> 8) & 0xff)
#define vmpu_set_region_number(v)           do { _armcpu_write_cp15_c6_c2_0(v); } while(0)
#define vmpu_set_region_base_address(v)     do { _armcpu_write_cp15_c6_c1_0(v); } while(0)
#define vmpu_set_region_size(v)             do { _armcpu_write_cp15_c6_c1_2(v); } while(0)
#define vmpu_set_region_access_control(v)   do { _armcpu_write_cp15_c6_c1_4(v); } while(0)


#endif  /* _ARMCPU__arch__proc__arm__arm_v7r__proc_h__ */


/* end of file */
