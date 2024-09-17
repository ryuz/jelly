#include <linux/init.h>
#include <linux/module.h>
#include <linux/types.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/sched.h>
#include <linux/device.h>

#include <linux/mm.h>
#include <linux/dma-mapping.h>
#include <linux/uaccess.h>
#include <linux/sched/mm.h>
#include <linux/pagemap.h>

#include <linux/device.h>
#include <linux/slab.h>

#include <asm/current.h>
#include <asm/uaccess.h>
#include <asm/io.h>


#define PL_BASE         0xa0000000
#define DMA0_BASE       (PL_BASE + 0x00000)
#define DMA1_BASE       (PL_BASE + 0x00800)
#define LED_BASE        (PL_BASE + 0x08000)
#define TIM_BASE        (PL_BASE + 0x10000)

#define REG_DMA_STATUS  0
#define REG_DMA_WSTART  1
#define REG_DMA_RSTART  2
#define REG_DMA_ADDR    3
#define REG_DMA_WDATA0  4
#define REG_DMA_WDATA1  5
#define REG_DMA_RDATA0  6
#define REG_DMA_RDATA1  7
#define REG_DMA_CORE_ID 8

#define REG_TIM_CONTROL 0
#define REG_TIM_COMPARE 1
#define REG_TIM_COUNTER 3


static volatile unsigned long *dma0;
static volatile unsigned long *dma1;
static volatile unsigned long *led;
static volatile unsigned long *tim;


MODULE_LICENSE("Dual MIT/GPL");

#define DRIVER_NAME "JellyTestDevice"

static const unsigned int MINOR_BASE = 0;
static const unsigned int MINOR_NUM  = 2;

static unsigned int devdrv_major;
static struct cdev  devdrv_cdev;

static int devdrv_open(struct inode *inode, struct file *file)
{
    printk("devdrv_open");
    return 0;
}

static int devdrv_close(struct inode *inode, struct file *file)
{
    printk("devdrv_close");
    return 0;
}

static ssize_t devdrv_read(struct file *filp, char __user *buf, size_t count, loff_t *f_pos)
{
    printk("devdrv_read");
    return 0;
}


static ssize_t devdrv_write(struct file *filp, const char __user *buf, size_t count, loff_t *f_pos)
{
    struct page *pages[1];
    unsigned long npages;
    int ret;
    dma_addr_t dma_addr;
    unsigned long user_addr = (unsigned long)buf;
    unsigned long user_base = user_addr & PAGE_MASK;
    unsigned long offset    = user_addr & ~PAGE_MASK;


    printk("devdrv_write");
    printk("PAGE_MASK : %lx", (unsigned long)PAGE_MASK);
    printk("ul size : %ld", sizeof(unsigned long));
    printk("user laddr : %016lx", (unsigned long)user_addr);
    printk("user base  : %016lx", (unsigned long)user_base);
    printk("user off   : %016lx", (unsigned long)offset);
    printk("user paddr : %016lx", (unsigned long)virt_to_phys(buf)); 

    ///////////////////////

    // ユーザー空間アドレスからページ数を計算
    npages = (count + (user_addr & (PAGE_SIZE - 1)) + PAGE_SIZE - 1) / PAGE_SIZE;

    // ページの配列を確保
//    pages = kcalloc(npages, sizeof(*pages), GFP_KERNEL);
//    if (!pages)
//        return -ENOMEM;
//    printk("npages : %p", npages);
//  printk("pages  : %d", pages);

//    ret = get_user_pages(current, current->mm, user_addr, npages, FOLL_WRITE, pages, NULL);
    ret = get_user_pages(user_base, 1, FOLL_FORCE, pages, NULL);
    if (ret < 0) {
        printk(KERN_ERR "Failed to get_user_pages: %d\n", ret);
        return ret;
    }
    dma_addr = page_to_phys(pages[0]);
    printk("pages[0] : %016lx\n", (unsigned long)pages[0]); 
    printk("dma_addr : %016lx\n", (unsigned long)dma_addr); 


    printk("<DMA0 read test>\n");
    dma0[REG_DMA_ADDR]   = dma_addr + offset;
    dma0[REG_DMA_RSTART] = 1;
    printk("REG_DMA_STATUS  : %016lx\n", dma0[REG_DMA_STATUS]);
    while ( dma0[REG_DMA_STATUS] )
          ;
    printk("REG_DMA_STATUS  : %016lx\n", dma0[REG_DMA_STATUS]);
    printk("REG_DMA0_RDATA0 : %016lx\n", dma0[REG_DMA_RDATA0]);
    printk("REG_DMA0_RDATA1 : %016lx\n", dma0[REG_DMA_RDATA1]);

    put_page(pages[0]);

    return count;
}


struct file_operations devdrv_fops = {
    .open    = devdrv_open,
    .release = devdrv_close,
    .read    = devdrv_read,
    .write   = devdrv_write,
};

static struct class *devdrv_class = NULL;


static int devdrv_init(void)
{
    printk("devdrv_init\n");

    int alloc_ret = 0;
    int cdev_err = 0;
    dev_t dev;

    alloc_ret = alloc_chrdev_region(&dev, MINOR_BASE, MINOR_NUM, DRIVER_NAME);
    if (alloc_ret != 0) {
        printk(KERN_ERR  "alloc_chrdev_region = %d\n", alloc_ret);
        return -1;
    }

    devdrv_major = MAJOR(dev);
    dev = MKDEV(devdrv_major, MINOR_BASE);

    cdev_init(&devdrv_cdev, &devdrv_fops);
    devdrv_cdev.owner = THIS_MODULE;

    cdev_err = cdev_add(&devdrv_cdev, dev, MINOR_NUM);
    if (cdev_err != 0) {
        printk(KERN_ERR  "cdev_add = %d\n", cdev_err);
        unregister_chrdev_region(dev, MINOR_NUM);
        return -1;
    }

    devdrv_class = class_create(THIS_MODULE, "jelly-devdrv");
    if (IS_ERR(devdrv_class)) {
        printk(KERN_ERR  "class_create\n");
        cdev_del(&devdrv_cdev);
        unregister_chrdev_region(dev, MINOR_NUM);
        return -1;
    }

    for (int minor = MINOR_BASE; minor < MINOR_BASE + MINOR_NUM; minor++) {
        device_create(devdrv_class, NULL, MKDEV(devdrv_major, minor), NULL, "jelly-devdrv%d", minor);
    }

    dma0 = (unsigned long *)ioremap(DMA0_BASE, 4096);
    dma1 = (unsigned long *)ioremap(DMA1_BASE, 4096);
    led  = (unsigned long *)ioremap(LED_BASE , 4096);
    tim  = (unsigned long *)ioremap(TIM_BASE , 4096);
    printk("dma0 : %016lx\n", (unsigned long)dma0);
    printk("dma1 : %016lx\n", (unsigned long)dma1);
    printk("led  : %016lx\n", (unsigned long)led);
    printk("tim  : %016lx\n", (unsigned long)tim);

    led[0] = 0;

    return 0;
}

static void devdrv_exit(void)
{
    printk("devdrv_exit\n");

    iounmap(dma0);
    iounmap(dma1);
    iounmap(led);
    iounmap(tim);

    dev_t dev = MKDEV(devdrv_major, MINOR_BASE);

    for (int minor = MINOR_BASE; minor < MINOR_BASE + MINOR_NUM; minor++) {
        device_destroy(devdrv_class, MKDEV(devdrv_major, minor));
    }

    class_destroy(devdrv_class);

    cdev_del(&devdrv_cdev);

    unregister_chrdev_region(dev, MINOR_NUM);
}

module_init(devdrv_init);
module_exit(devdrv_exit);

